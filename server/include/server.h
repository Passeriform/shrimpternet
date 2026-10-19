#pragma once

#ifndef SERVER_H
#define SERVER_H

void serve_file(int client_fd, const char * prefix_dir, const char * path);
int run_server(int port, void (*handle_client)(int client_fd));

#endif