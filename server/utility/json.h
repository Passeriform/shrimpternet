#pragma once

#ifndef JSON_H
#define JSON_H

#include <stdbool.h>

typedef enum JSON_VALUE_TYPE {
    JSON_NULL,
    JSON_BOOL,
    JSON_NUMBER,
    JSON_STRING,
    JSON_OBJECT,
    JSON_ARRAY,
} json_value_t;

typedef struct JSON_VALUE json_value;

typedef struct JSON_OBJECT {
    char ** keys;
    json_value * values;
    int count;
} json_object;

typedef struct JSON_ARRAY {
    json_value * values;
    int count;
} json_array;

struct JSON_VALUE {
    json_value_t type;
    union {
        char null;
        bool boolean;
        double number;
        char * string;
        json_object * object;
        json_array * array;
    } value;
};

/* Parses `JSON` string into json_value.
 * Returns the pointer to the last character of the parsed string.
 * Dies if any error is encountered. */
const char * json_parse_value(const char * start, json_value * target);

/* Prints json_value to stdout */
void json_print(const json_value * value, int depth);

/* Frees everything `value` owns.
 * `value` itself is not freed.
 * Dies if any error is encountered. */
void json_free(json_value * value);

#endif