#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cwalk.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#elif defined(__APPLE__) && defined(__MACH__)
#include <limits.h>
#include <mach-o/dyld.h>
#elif defined(__FreeBSD__)
#include <limits.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#elif defined(__linux__)
#include <limits.h>
#include <unistd.h>
#elif defined(__NetBSD__)
#include <limits.h>
#include <unistd.h>
#else
#error "Unsupported platform: implement resolve_binary_path() for it"
#endif

#include "config.h"

#define DIE(msg) do { perror("[FATAL] " msg); exit(EXIT_FAILURE); } while(0)
#define ASSETS_WALK "../../share/assets"

#if defined(_WIN32)
#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif
#endif

#if defined(__linux__)
#define PROC_EXE_LINK "/proc/self/exe"
#elif defined(__NetBSD__)
#define PROC_EXE_LINK "/proc/curproc/exe"
#endif

static const config * global_config = NULL;

static void resolve_binary_path(char * const buffer, const size_t size) {
#if defined(_WIN32)
    const DWORD length = GetModuleFileNameA(NULL, buffer, (DWORD)size);
    const bool found = length > 0 && length < size;

#elif defined(__APPLE__) && defined(__MACH__)
    uint32_t length = (uint32_t)size;
    const bool found = _NSGetExecutablePath(buffer, &length) == 0;

#elif defined(__FreeBSD__)
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
    size_t length = size;
    const bool found = sysctl(mib, 4, buffer, &length, NULL, 0) == 0;

#elif defined(__linux__) || defined(__NetBSD__)
    const ssize_t length = readlink(PROC_EXE_LINK, buffer, size - 1);
    const bool found = length > 0;
    if (found) buffer[length] = '\0';
#endif

    if (!found) {
        DIE("Could not resolve running binary executable path.");
    }
}

const config * config_init(const char * const base_path) {
    if (global_config) DIE("Config cannot be reinitialized.");
    if (!base_path) DIE("Base path wasn't supplied.");

    char bin_path[PATH_MAX];
    resolve_binary_path(bin_path, sizeof(bin_path));

    const size_t base_length = strlen(base_path);
    const size_t assets_length = cwk_path_join(bin_path, ASSETS_WALK, NULL, 0);

    // TODO: Use shared __malloc_or_die here.
    char * const resolved_base_dir = malloc(base_length + 1);
    char * const resolved_assets_dir = malloc(assets_length + 1);
    config * const cfg = malloc(sizeof(*cfg));
    if (!resolved_base_dir || !resolved_assets_dir || !cfg) DIE("Could not allocate memory for config initialization.");

    memcpy(resolved_base_dir, base_path, base_length + 1);
    cwk_path_join(bin_path, ASSETS_WALK, resolved_assets_dir, assets_length + 1);

    const config tmp = {
        .base_dir = resolved_base_dir,
        .assets_dir = resolved_assets_dir,
    };
    memcpy(cfg, &tmp, sizeof(tmp));

    global_config = cfg;
    return global_config;
}

const config * config_get(void) {
    return global_config;
}

void config_free(void) {
    if (!global_config) return;

    free((void *)global_config->base_dir);
    free((void *)global_config->assets_dir);
    free((void *)global_config);

    global_config = NULL;
}
