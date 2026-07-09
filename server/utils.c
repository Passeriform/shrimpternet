#include "utils.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

const char *get_mime(const char *path) {
    const char *ext = strrchr(path, '.');
    if (!ext) return "application/octet-stream";
    if (!strcmp(ext, ".html")) return "text/html";
    if (!strcmp(ext, ".css"))  return "text/css";
    if (!strcmp(ext, ".js"))   return "application/javascript";
    if (!strcmp(ext, ".png"))  return "image/png";
    if (!strcmp(ext, ".jpg") || !strcmp(ext, ".jpeg")) return "image/jpeg";
    return "application/octet-stream";
}

int resolve_safe_path(const char *base_dir, const char *req_path, char *out_path) {
    char raw_target[PATH_MAX * 2];
    snprintf(raw_target, sizeof(raw_target), "%s%s", base_dir, req_path);

    if (!realpath(raw_target, out_path) || strncmp(out_path, base_dir, strlen(base_dir)) != 0) {
        return -1;
    }

    struct stat st;
    if (stat(out_path, &st) == 0 && S_ISDIR(st.st_mode)) {
        char index_target[PATH_MAX * 2];
        snprintf(index_target, sizeof(index_target), "%s/index.html", out_path);
        
        if (!realpath(index_target, out_path) || strncmp(out_path, base_dir, strlen(base_dir)) != 0) {
            return -1;
        }
    }
    return 0;
}
