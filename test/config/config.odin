package config

import "core:io"
import "core:mem"

Table :: map[string]string

init :: proc(allocator: mem.Allocator = context.allocator) -> mem.Allocator_Error {
    return .None;
}

free :: proc() {
}
