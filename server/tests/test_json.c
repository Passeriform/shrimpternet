#if defined HEADERS
#include <string.h>

#include <utility/json.h>
#elif defined TESTS

#define JSON_ASSERT_NULL(node) do { ASSERT((node).type == JSON_NULL); } while(0)
#define JSON_ASSERT_BOOL(node, expected) do { ASSERT((node).type == JSON_BOOL && (node).value.boolean == (expected)); } while(0)
#define JSON_ASSERT_NUMBER(node, expected) do { ASSERT((node).type == JSON_NUMBER && (node).value.number == (expected)); } while(0)
#define JSON_ASSERT_STRING(node, expected) do { ASSERT((node).type == JSON_STRING && strcmp((node).value.string, (expected)) == 0); } while(0)
#define JSON_ASSERT_OBJECT_WITH_COUNT(node, expected) do { ASSERT((node).type == JSON_OBJECT && (node).value.object->count == (expected)); } while(0)
#define JSON_ASSERT_ARRAY_WITH_COUNT(node, expected) do { ASSERT((node).type == JSON_ARRAY && (node).value.array->count == (expected)); } while(0)

TEST("empty object") {
    json_value json;

    ASSERT(json_parse_value("{}", &json) != NULL);
    JSON_ASSERT_OBJECT_WITH_COUNT(json, 0);

    json_free(&json);
}

TEST("empty array") {
    json_value json;

    ASSERT(json_parse_value("[]", &json) != NULL);
    JSON_ASSERT_ARRAY_WITH_COUNT(json, 0);

    json_free(&json);
}

TEST("flat object") {
    json_value json;
    json_parse_value("{\"label\":\"descriptor\",\"numeral\":3.14,\"check\":true,\"optional\":null}", &json);

    JSON_ASSERT_OBJECT_WITH_COUNT(json, 4);
    const json_object * const root = json.value.object;
        ASSERT(strcmp(root->keys[0], "label") == 0);
        JSON_ASSERT_STRING(root->values[0], "descriptor");

        ASSERT(strcmp(root->keys[1], "numeral") == 0);
        JSON_ASSERT_NUMBER(root->values[1], 3.14);

        ASSERT(strcmp(root->keys[2], "check") == 0);
        JSON_ASSERT_BOOL(root->values[2], true);

        ASSERT(strcmp(root->keys[3], "optional") == 0);
        JSON_ASSERT_NULL(root->values[3]);

    json_free(&json);
}

TEST("flat array") {
    json_value json;
    json_parse_value("[\"key\",6.022,null,false,-1.171]", &json);

    JSON_ASSERT_ARRAY_WITH_COUNT(json, 5);
    const json_array * const root = json.value.array;
        JSON_ASSERT_STRING(root->values[0], "key");
        JSON_ASSERT_NUMBER(root->values[1], 6.022);
        JSON_ASSERT_NULL(root->values[2]);
        JSON_ASSERT_BOOL(root->values[3], false);
        JSON_ASSERT_NUMBER(root->values[4], -1.171);

    json_free(&json);
}

TEST("nested json") {
    json_value json;
    json_parse_value("{\"k1\":[1.2,{\"v1a2k1\":null}],\"k2\":{\"v2k1\":[[],[\"v2v1a2a1\"]]}}", &json);

    JSON_ASSERT_OBJECT_WITH_COUNT(json, 2);
    const json_object * const root = json.value.object;
        ASSERT(strcmp(root->keys[0], "k1") == 0);
        JSON_ASSERT_ARRAY_WITH_COUNT(root->values[0], 2);
        const json_array * const v1arr = root->values[0].value.array;
            JSON_ASSERT_NUMBER(v1arr->values[0], 1.2);
            JSON_ASSERT_OBJECT_WITH_COUNT(v1arr->values[1], 1);
            const json_object * const v1a2obj = v1arr->values[1].value.object;
                ASSERT(strcmp(v1a2obj->keys[0], "v1a2k1") == 0);
                JSON_ASSERT_NULL(v1a2obj->values[0]);

        ASSERT(strcmp(root->keys[1], "k2") == 0);
        JSON_ASSERT_OBJECT_WITH_COUNT(root->values[1], 1);
        const json_object * const v2obj = root->values[1].value.object;
            ASSERT(strcmp(v2obj->keys[0], "v2k1") == 0);
            JSON_ASSERT_ARRAY_WITH_COUNT(v2obj->values[0], 2);
            const json_array * const v2v1arr = v2obj->values[0].value.array;
                JSON_ASSERT_ARRAY_WITH_COUNT(v2v1arr->values[0], 0);
                JSON_ASSERT_ARRAY_WITH_COUNT(v2v1arr->values[1], 1);
                const json_array * const v2v1a2arr = v2v1arr->values[1].value.array;
                    JSON_ASSERT_STRING(v2v1a2arr->values[0], "v2v1a2a1");

    json_free(&json);
}

TEST("whitespaces") {
    json_value json;
    json_parse_value(" \t\r\n{ \"a\" :\n [ 1 \r,\t2 ] ,\r\n \"b\" : \"c\" }\n", &json);

    JSON_ASSERT_OBJECT_WITH_COUNT(json, 2);
    const json_object * const root = json.value.object;
        ASSERT(strcmp(root->keys[0], "a") == 0);
        JSON_ASSERT_ARRAY_WITH_COUNT(root->values[0], 2);
        const json_array * const v1arr = root->values[0].value.array;
            JSON_ASSERT_NUMBER(v1arr->values[0], 1);
            JSON_ASSERT_NUMBER(v1arr->values[1], 2);

        ASSERT(strcmp(root->keys[1], "b") == 0);
        JSON_ASSERT_STRING(root->values[1], "c");

    json_free(&json);
}

TEST("escaped quotes in strings") {
    json_value json;
    json_parse_value("{\"\\\"calm\\\" key\": \"says {} \\\"hi\\\"\"}", &json);

    JSON_ASSERT_OBJECT_WITH_COUNT(json, 1);
    const json_object * const root = json.value.object;
        ASSERT(strcmp(root->keys[0], "\\\"calm\\\" key") == 0);
        JSON_ASSERT_STRING(root->values[0], "says {} \\\"hi\\\"");

    json_free(&json);
}
#endif
