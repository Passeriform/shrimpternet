#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <config.h>
#include <server.h>

#define DIE(msg) do { perror("[FATAL] " msg); exit(EXIT_FAILURE); } while(0)
#define RESPOND(client_fd, code, message) do { dprintf(client_fd, "HTTP/1.1 %d %s\r\n\r\n", code, message); } while(0)

void handle_client(int client_fd) {
    const config * cfg = config_get();

    char buf[2048] = {0};
    char method[16], path[1024];

    if (read(client_fd, buf, sizeof(buf) - 1) <= 0) return;

    if (sscanf(buf, "%15s %1023s", method, path) != 2) {
        RESPOND(client_fd, 400, "Bad Request");
        return;
    }

    if (strcmp(path, "/meta") == 0) {
        // TODO: Create in-memory store on startup and open stream
        serve_file(client_fd, cfg->base_dir, "/meta.json");
    } else if (strncmp(path, "/blogs", 6) == 0) {
        if(strcmp(method, "GET") != 0) {
            RESPOND(client_fd, 400, "Bad Request");
            return;
        }

        serve_file(client_fd, cfg->base_dir, path);
    } else if (strncmp(path, "/youtube", 8) == 0) {
        if(strcmp(method, "GET") != 0) {
            RESPOND(client_fd, 400, "Bad Request");
            return;
        }

        serve_file(client_fd, cfg->base_dir, path);
    } else {
        serve_file(client_fd, cfg->assets_dir, path);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <directory-path> [port]\n", argv[0]);
        return EXIT_FAILURE;
    }

    int port = (argc >= 3) ? atoi(argv[2]) : 8080;
    const config * cfg = config_init(argv[1]);

    printf("[INFO] Starting server on port %d\n - Content served from %s\n - Web landing served from %s\n", port, cfg->base_dir, cfg->assets_dir);

    int status = run_server(port, handle_client);

    config_free();

    return status;
}
