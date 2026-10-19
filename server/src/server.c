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
#include <cwalk.h>

#include <server.h>

#define DIE(msg) do { perror("[FATAL] " msg); exit(EXIT_FAILURE); } while(0)

static const char *get_mime(const char *path) {
    const char *ext = strrchr(path, '.');
    if (!ext) return "application/octet-stream";
    if (!strcmp(ext, ".html")) return "text/html";
    if (!strcmp(ext, ".css"))  return "text/css";
    if (!strcmp(ext, ".js"))   return "application/javascript";
    if (!strcmp(ext, ".png"))  return "image/png";
    if (!strcmp(ext, ".json"))  return "application/json";
    if (!strcmp(ext, ".jpg") || !strcmp(ext, ".jpeg")) return "image/jpeg";
    if (!strcmp(ext, ".png")) return "image/png";
    if (!strcmp(ext, ".ico")) return "image/x-icon";
    if (!strcmp(ext, ".svg")) return "image/svg+xml";
    return "application/octet-stream";
}

static int resolve_safe_path(const char * base_dir, const char * req_path, char * out_path) {
    char target[PATH_MAX];
    struct stat st;

    cwk_path_join(base_dir, req_path, target, sizeof target);
    if (!realpath(target, out_path)) return -1;

    if (stat(out_path, &st) == 0 && S_ISDIR(st.st_mode)) {
        cwk_path_join(out_path, "index.html", target, sizeof target);
        if (!realpath(target, out_path)) return -1;
    }

    return cwk_path_get_intersection(base_dir, out_path) == strlen(base_dir) ? 0 : -1;
}

void serve_file(int client_fd, const char * prefix_dir, const char * path) {
    char target[PATH_MAX];
    if (resolve_safe_path(prefix_dir, path, target) < 0) {
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

int run_server(int port, void (*handle_client)(int client_fd)) {
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

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) continue;

        if (fork() == 0) {
            close(server_fd);
            handle_client(client_fd);
            close(client_fd);
            return EXIT_SUCCESS;
        }
        
        close(client_fd);
    }
}