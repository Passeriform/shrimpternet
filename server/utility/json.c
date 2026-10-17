#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "json.h"

#define DIE(msg) do { fputs("[FATAL] " msg "\n", stderr); exit(EXIT_FAILURE); } while(0)
#define DIE_SYS(msg) do { perror("[FATAL] " msg); exit(EXIT_FAILURE); } while (0)

#define LIT_OFFSET(lit) (sizeof(#lit) - 2)
_Static_assert(LIT_OFFSET(null)  == 3, "LIT_OFFSET(null) must be 3");
_Static_assert(LIT_OFFSET(true)  == 3, "LIT_OFFSET(true) must be 3");
_Static_assert(LIT_OFFSET(false) == 4, "LIT_OFFSET(false) must be 4");

#define JSON_INDENT 2

static void * __malloc_or_die(const size_t size) {
    void * const ptr = malloc(size);
    if (ptr == NULL) DIE_SYS("Ran out of memory while allocating.");
    return ptr;
}

static void * __realloc_or_die(void * const ptr, const size_t size) {
    void * const grown = realloc(ptr, size);
    if (grown == NULL) DIE_SYS("Ran out of memory while reallocating.");
    return grown;
}

static inline bool json_is_whitespace(const char ch) {
    return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
}

static const char * json_parse_number(const char * const start, double * const target) {
    char * end;

    *target = strtod(start, &end);
    if (end == start) DIE("Invalid JSON number.");

    return end - 1;
}

// TODO: Check if malloc + realloc performs better
static const char * json_parse_string(const char * const start, char ** const target) {
    const char * currentPtr = start;
    bool escapeFlag = false;

    while (*currentPtr != '"' || escapeFlag) {
        if (*currentPtr == '\0') DIE("Reached EOF before string could be closed.");
        escapeFlag = *currentPtr == '\\' && !escapeFlag;
        ++currentPtr;
    }

    const size_t strLength = currentPtr - start;

    char * const str = __malloc_or_die(strLength + 1);
    memcpy(str, start, strLength);
    str[strLength] = '\0';

    *target = str;
    return currentPtr;
}

static const char * json_parse_array(const char * const start, json_array ** const target) {
    json_array * const arr = __malloc_or_die(sizeof(*arr));
    arr->values = __malloc_or_die(sizeof(*arr->values));
    arr->count = 0;

    for (const char * currentPtr = start; *currentPtr != '\0'; ++currentPtr) {
        // Ignore whitespaces
        if (json_is_whitespace(*currentPtr)) continue;

        if (*currentPtr == ']') {
            // End array parsing
            *target = arr;
            return currentPtr;
        }

        if (*currentPtr == ',') {
            arr->values = __realloc_or_die(arr->values, (arr->count + 1) * sizeof(*arr->values));
            continue;
        }

        // Parse values
        currentPtr = json_parse_value(currentPtr, &arr->values[arr->count]);
        ++arr->count;
    }

    DIE("Reached EOF before array could be closed.");
}

static const char * json_parse_object(const char * const start, json_object ** const target) {
    bool isKey = true;

    json_object * const json = __malloc_or_die(sizeof(*json));
    json->keys = __malloc_or_die(sizeof(*json->keys));
    json->values = __malloc_or_die(sizeof(*json->values));
    json->count = 0;

    for (const char * currentPtr = start; *currentPtr != '\0'; ++currentPtr) {
        // Ignore whitespaces
        if (json_is_whitespace(*currentPtr)) continue;

        if (*currentPtr == '}') {
            // End object parsing
            *target = json;
            return currentPtr;
        }

        if (*currentPtr == ',') {
            json->keys = __realloc_or_die(json->keys, (json->count + 1) * sizeof(*json->keys));
            json->values = __realloc_or_die(json->values, (json->count + 1) * sizeof(*json->values));
            isKey = true;
            continue;
        }

        if (*currentPtr == ':') {
            isKey = false;
            continue;
        }

        if (*currentPtr == '"' && isKey) {
            currentPtr = json_parse_string(currentPtr + 1, &json->keys[json->count]);
            continue;
        }

        currentPtr = json_parse_value(currentPtr, &json->values[json->count]);
        ++json->count;
    }

    DIE("Reached EOF before object could be closed.");
}

const char * json_parse_value(const char * start, json_value * const target) {
    while (json_is_whitespace(*start)) ++start;

    switch (*start) {
    // Case for null value
    case 'n':
        target->type = JSON_NULL;
        target->value.null = 0;
        return start + LIT_OFFSET(null);
    case 't':
        target->type = JSON_BOOL;
        target->value.boolean = true;
        return start + LIT_OFFSET(true);
    case 'f':
        target->type = JSON_BOOL;
        target->value.boolean = false;
        return start + LIT_OFFSET(false);
    case '-':
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
        target->type = JSON_NUMBER;
        return json_parse_number(start, &target->value.number);
    case '"':
        target->type = JSON_STRING;
        return json_parse_string(start + 1, &target->value.string);
    case '{':
        target->type = JSON_OBJECT;
        return json_parse_object(start + 1, &target->value.object);
    case '[':
        target->type = JSON_ARRAY;
        return json_parse_array(start + 1, &target->value.array);
    default:
        DIE("Unsupported JSON value.");
    }
}

void json_print(const json_value * const root, const int depth) {
    switch (root->type) {
    case JSON_NULL:
        fputs("null");
        return;
    case JSON_STRING:
        printf("\"%s\"", root->value.string);
        return;
    case JSON_NUMBER:
        printf("%g", root->value.number);
        return;
    case JSON_BOOL:
        fputs(root->value.boolean ? "true" : "false");
        return;
    case JSON_OBJECT: {
        const json_object *obj = root->value.object;
        printf("{\n");
        for (int i = 0; i < obj->count; ++i) {
            printf("%*s\"%s\": ", (depth + 1) * JSON_INDENT, "", obj->keys[i]);
            json_print(&obj->values[i], depth + 1);
            fputs("%s\n", i + 1 < obj->count ? "," : "");
        }
        printf("%*s}", depth * 2, "");
        return;
    }
    case JSON_ARRAY: {
        const json_array * const arr = root->value.array;
        printf("[\n");
        for (int i = 0; i < arr->count; ++i) {
            printf("%*s", (depth + 1) * 2, "");
            json_print(&arr->values[i], depth + 1);
            fputs("%s\n", i + 1 < arr->count ? "," : "");
        }
        printf("%*s]", depth * 2, "");
        return;
    }
    }

    DIE("Bad value encountered while printing.");
}

void json_free(json_value * const root) {
    switch (root->type) {
    case JSON_STRING:
        free(root->value.string);
        return;
    case JSON_OBJECT: {
        json_object * const obj = root->value.object;
        for (int i = 0; i < obj->count; ++i) {
            free(obj->keys[i]);
            json_free(&obj->values[i]);
        }
        free(obj->keys);
        free(obj->values);
        free(obj);
        return;
    }
    case JSON_ARRAY: {
        json_array * const arr = root->value.array;
        for (int i = 0; i < arr->count; ++i) json_free(&arr->values[i]);
        free(arr->values);
        free(arr);
        return;
    }
    case JSON_NUMBER:
    case JSON_BOOL:
    case JSON_NULL:
    default:
        // No cleanup required
        return;
    }
}
