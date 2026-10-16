#include <fcntl.h>
#include <limits.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sendfile.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

#include "utils.h"

#define DIE(msg) do { perror("[FATAL] " msg); exit(EXIT_FAILURE); } while(0)

static void serve_file(int client_fd, const char *base_dir, char *path) {
    char target[PATH_MAX];
    if (resolve_safe_path(base_dir, path, target) < 0) {
        dprintf(client_fd, "HTTP/1.1 404 Not Found\r\n\r\n");
        return;
    }

    struct stat st;
    int file_fd = open(target, O_RDONLY);
    if (file_fd < 0 || fstat(file_fd, &st) < 0 || !S_ISREG(st.st_mode)) {
        if (file_fd >= 0) close(file_fd);
        dprintf(client_fd, "HTTP/1.1 404 Not Found\r\n\r\n");
        return;
    }

    dprintf(client_fd, 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %ld\r\n"
        "Connection: close\r\n\r\n", 
        get_mime(target), st.st_size);

    off_t offset = 0;
    sendfile(client_fd, file_fd, &offset, st.st_size);
    close(file_fd);
}

static void handle_client(int client_fd, const char *base_dir, const char *assets_dir) {
    char buf[2048] = {0};
    char method[16], path[1024];

    if (read(client_fd, buf, sizeof(buf) - 1) <= 0) return;

    if (sscanf(buf, "%15s %1023s", method, path) != 2) {
        dprintf(client_fd, "HTTP/1.1 400 Bad Request\r\n\r\n");
        return;
    }

    if (strcmp(path, "/meta") == 0) {
        serve_file(client_fd, base_dir, "/meta.json");
    } else if (strncmp(path, "/blogs", 6) == 0) {
        if(strcmp(method, "GET") != 0) {
            dprintf(client_fd, "HTTP/1.1 400 Bad Request\r\n\r\n");
            return;
        }

        serve_file(client_fd, base_dir, path);
    } else {
        serve_file(client_fd, assets_dir, path);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <directory-path> <web-assets-path> [port]\n", argv[0]);
        return EXIT_FAILURE;
    }

    char base_dir[PATH_MAX];
    if (!realpath(argv[1], base_dir)) DIE("Target routing directory invalid");

    char assets_dir[PATH_MAX];
    if (!realpath(argv[2], assets_dir)) DIE("Landing web assets directory invalid");

    int port = (argc >= 4) ? atoi(argv[3]) : 8080;

    signal(SIGCHLD, SIG_IGN);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) DIE("Socket creation error");

    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int));

    struct sockaddr_in address = {
        .sin_family = AF_INET,
        .sin_port = htons(port),
        .sin_addr.s_addr = INADDR_ANY
    };

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) DIE("Bind execution failed");
    if (listen(server_fd, 1024) < 0) DIE("Listen context failed");

    printf("[INFO] Server started on port %d serving from %s\n", port, base_dir);

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) continue;

        if (fork() == 0) {
            close(server_fd);
            handle_client(client_fd, base_dir, assets_dir);
            close(client_fd);
            return EXIT_SUCCESS;
        }
        
        close(client_fd);
    }
}
