import AppKit
import CoreImage

@MainActor enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        let context = CIContext()

        for name in ["headless-menu-iconTemplate", "headless-menu-iconTemplate@2x"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let source = CIImage(contentsOf: url),
                  let inverted = CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey: source])?.outputImage,
                  let mask = CIFilter(name: "CIMaskToAlpha", parameters: [kCIInputImageKey: inverted])?.outputImage,
                  let cgImage = context.createCGImage(mask, from: source.extent) else { continue }

            let representation = NSBitmapImageRep(cgImage: cgImage)
            representation.size = image.size
            image.addRepresentation(representation)
        }

        image.isTemplate = true
        return image
    }()
}
