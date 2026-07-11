#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <jansson.h>
#include "libbootkit/ops.h"
#include "batch.h"
#include "utils.h"

int batch_init(void *input, size_t size, void **ctx) {
    json_error_t error;
    json_t *root = json_loadb((const char *)input, size, 0, &error);
    if (!root) {
        printf("failed to parse JSON: %s\n", error.text);
        return -1;
    }
    if (!json_is_array(root)) {
        printf("JSON root is not an array\n");
        json_decref(root);
        return -1;
    }
    *ctx = root;
    return 0;
}

int batch_get_count(void *ctx) {
    return (int)json_array_size((json_t *)ctx);
}

int batch_get_kbag(void *ctx, int idx, uint8_t *kbag, size_t *len) {
    json_t *entry = json_array_get((json_t *)ctx, (size_t)idx);
    if (!entry) return -1;

    json_t *kbag_obj = json_object_get(entry, "kbag");
    if (!kbag_obj || !json_is_string(kbag_obj)) {
        printf("no kbag at index %d\n", idx);
        return -1;
    }

    const char *kbag_str = json_string_value(kbag_obj);
    size_t kbag_str_len = strlen(kbag_str);
    size_t kbag_len = kbag_str_len / 2;

    if (kbag_len > KBAG_LEN_256) {
        printf("KBAG @ index %d is too long\n", idx);
        return -1;
    }

    str2hex(kbag_str_len, kbag, kbag_str);
    *len = kbag_len;
    return 0;
}

int batch_set_key(void *ctx, int idx, uint8_t *kbag, size_t len) {
    json_t *entry = json_array_get((json_t *)ctx, (size_t)idx);
    if (!entry) return -1;

    char tmp[len * 2 + 1];
    hex2str(tmp, (int)len, kbag);

    json_object_set_new(entry, "key", json_string(tmp));
    return 0;
}

int batch_write(void *ctx, const char *path) {
    if (json_dump_file((json_t *)ctx, path, JSON_INDENT(2)) != 0) {
        printf("failed to write batch\n");
        return -1;
    }
    return 0;
}

void batch_quiesce(void **ctx) {
    json_decref((json_t *)*ctx);
    *ctx = NULL;
}
