#pragma once

#ifndef SERVER_H
#define SERVER_H

const char *get_mime(const char *path);
int resolve_safe_path(const char *base_dir, const char *req_path, char *out_path);

#endif