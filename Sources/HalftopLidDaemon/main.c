#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const char *socket_path = "/var/run/clamshell-ready-lid-helper.sock";
static volatile sig_atomic_t should_stop = 0;

static void handle_signal(int signal_number) {
    (void)signal_number;
    should_stop = 1;
}

static int run_pmset(const char *source, const char *key, const char *value) {
    pid_t pid = fork();
    if (pid < 0) {
        return errno;
    }

    if (pid == 0) {
        execl("/usr/bin/pmset", "pmset", source, key, value, (char *)NULL);
        _exit(127);
    }

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        return errno;
    }

    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        return EIO;
    }

    return 0;
}

static int write_all(int fd, const char *message) {
    size_t remaining = strlen(message);
    const char *cursor = message;
    while (remaining > 0) {
        ssize_t written = write(fd, cursor, remaining);
        if (written < 0) {
            if (errno == EINTR) { continue; }
            return -1;
        }
        cursor += written;
        remaining -= (size_t)written;
    }
    return 0;
}

static void handle_client(int client_fd, uid_t allowed_uid) {
    uid_t peer_uid = 0;
    gid_t peer_gid = 0;
    if (getpeereid(client_fd, &peer_uid, &peer_gid) != 0 || peer_uid != allowed_uid) {
        write_all(client_fd, "ERR unauthorized\n");
        return;
    }

    char buffer[32] = {0};
    ssize_t count = read(client_fd, buffer, sizeof(buffer) - 1);
    if (count <= 0) {
        write_all(client_fd, "ERR empty command\n");
        return;
    }

    buffer[strcspn(buffer, "\r\n")] = '\0';

    const char *source = "-b";
    const char *key = "disablesleep";
    const char *value = NULL;
    if (strcmp(buffer, "enable") == 0) {
        value = "1";
    } else if (strcmp(buffer, "disable") == 0) {
        value = "0";
    } else if (strcmp(buffer, "energy-b-low-0") == 0) {
        key = "lowpowermode"; value = "0";
    } else if (strcmp(buffer, "energy-b-low-1") == 0) {
        key = "lowpowermode"; value = "1";
    } else if (strcmp(buffer, "energy-c-low-0") == 0) {
        source = "-c"; key = "lowpowermode"; value = "0";
    } else if (strcmp(buffer, "energy-c-low-1") == 0) {
        source = "-c"; key = "lowpowermode"; value = "1";
    } else if (strcmp(buffer, "energy-b-power-0") == 0) {
        key = "powermode"; value = "0";
    } else if (strcmp(buffer, "energy-b-power-1") == 0) {
        key = "powermode"; value = "1";
    } else if (strcmp(buffer, "energy-b-power-2") == 0) {
        key = "powermode"; value = "2";
    } else if (strcmp(buffer, "energy-c-power-0") == 0) {
        source = "-c"; key = "powermode"; value = "0";
    } else if (strcmp(buffer, "energy-c-power-1") == 0) {
        source = "-c"; key = "powermode"; value = "1";
    } else if (strcmp(buffer, "energy-c-power-2") == 0) {
        source = "-c"; key = "powermode"; value = "2";
    } else {
        write_all(client_fd, "ERR invalid command\n");
        return;
    }

    int result = run_pmset(source, key, value);
    if (result == 0) {
        write_all(client_fd, "OK\n");
    } else {
        char message[128];
        snprintf(message, sizeof(message), "ERR pmset failed: %s\n", strerror(result));
        write_all(client_fd, message);
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3 || strcmp(argv[1], "--allowed-uid") != 0) {
        fprintf(stderr, "usage: %s --allowed-uid <uid>\n", argv[0]);
        return 64;
    }

    char *end = NULL;
    unsigned long parsed_uid = strtoul(argv[2], &end, 10);
    if (end == argv[2] || *end != '\0') {
        fprintf(stderr, "invalid uid: %s\n", argv[2]);
        return 64;
    }
    uid_t allowed_uid = (uid_t)parsed_uid;

    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);

    int server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return 71;
    }

    unlink(socket_path);

    struct sockaddr_un address;
    memset(&address, 0, sizeof(address));
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, socket_path, sizeof(address.sun_path) - 1);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) != 0) {
        perror("bind");
        close(server_fd);
        return 71;
    }

    if (chown(socket_path, allowed_uid, -1) != 0 || chmod(socket_path, 0600) != 0) {
        perror("socket permissions");
        close(server_fd);
        unlink(socket_path);
        return 71;
    }

    if (listen(server_fd, 4) != 0) {
        perror("listen");
        close(server_fd);
        unlink(socket_path);
        return 71;
    }

    while (!should_stop) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EINTR) { continue; }
            perror("accept");
            break;
        }
        handle_client(client_fd, allowed_uid);
        close(client_fd);
    }

    close(server_fd);
    unlink(socket_path);
    return 0;
}
