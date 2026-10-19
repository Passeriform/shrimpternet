#pragma once

#ifndef CONFIG_H
#define CONFIG_H

typedef struct CONFIG {
    const char * const base_dir;
    const char * const assets_dir;
} config;

const config * config_init(const char * const base_path);

const config * config_get(void);

void config_free(void);

#endif