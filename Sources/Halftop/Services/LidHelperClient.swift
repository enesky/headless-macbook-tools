import Darwin
import Foundation

enum LidHelperClient {
    private static let socketPath = "/var/run/clamshell-ready-lid-helper.sock"

    static func send(_ command: String) throws {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw LidSleepOverrideError.helperUnavailable }
        defer { close(fd) }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)

        let pathBytes = Array(socketPath.utf8)
        guard pathBytes.count < MemoryLayout.size(ofValue: address.sun_path) else {
            throw LidSleepOverrideError.helperUnavailable
        }

        withUnsafeMutableBytes(of: &address.sun_path) { rawBuffer in
            rawBuffer.copyBytes(from: pathBytes)
            rawBuffer[pathBytes.count] = 0
        }

        let length = socklen_t(MemoryLayout<sa_family_t>.size + pathBytes.count + 1)
        let connected = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                Darwin.connect(fd, sockaddrPointer, length)
            }
        }

        guard connected == 0 else { throw LidSleepOverrideError.helperUnavailable }

        let request = Array((command + "\n").utf8)
        let sent = request.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, request.count) }
        guard sent == request.count else {
            throw LidSleepOverrideError.commandFailed("could not send command to privileged helper")
        }

        var response = [UInt8](repeating: 0, count: 256)
        let received = Darwin.read(fd, &response, response.count - 1)
        guard received > 0 else {
            throw LidSleepOverrideError.commandFailed("empty response from privileged helper")
        }

        let output = String(decoding: response.prefix(Int(received)), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard output == "OK" else {
            throw LidSleepOverrideError.commandFailed(output)
        }
    }
}
