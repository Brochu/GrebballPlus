package config

import "core:fmt"
import "core:mem"
import os"core:os/os2"
import "core:strings"

CONFIG_PATH :: "./dev.cfg"

Table: map[string]string

init :: proc(allocator: mem.Allocator = context.allocator) -> mem.Allocator_Error {
    fhandle, err := os.open(CONFIG_PATH, os.O_RDONLY);
    defer os.close(fhandle);
    assert(err == nil);

    fsize, _ := os.file_size(fhandle);
    buffer := make([]byte, fsize, context.temp_allocator) or_return;
    n, _ := os.read(fhandle, buffer);

    content := strings.trim_right(cast(string)buffer, "\r\n");
    Table = make(map[string]string);
    for line in strings.split_lines_iterator(&content) {
        elems, _ := strings.split_n(line, "=", 2, allocator);
        defer delete(elems);

        key_str := strings.clone(elems[0]);
        val_str := strings.clone(elems[1]);
        Table[key_str] = val_str;
    }

    free_all(context.temp_allocator);
    return .None;
}

free :: proc() {
    for k, v in Table {
        delete(k);
        delete(v);
    }
    delete(Table);
}
