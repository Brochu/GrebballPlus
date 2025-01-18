package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:strings"
import sys"core:sys/windows"
import "core:thread"
import "core:time"

import "curl"
import fb"football"
import cfg"config"

TRACK_MEM :: #config(TRACK_MEM, false);

gateway_res :: struct {
    url: string,
    session_start_limit: session_start,
    shards: int,
}
session_start :: struct {
    max_concurrency: int,
    remaining: int,
    reset_after: int,
    total: int,
}

hello_evt :: struct {
    op: int,
    d: heartbeat_d,
};
heartbeat_d :: struct {
    heartbeat_interval: int,
};

heartbeat_req :: struct {
    op: int,
    d: int,
}

main :: proc() {
when TRACK_MEM {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }
}

    cfg.init();
    defer cfg.free();

    fmt.println("Config table:");
    for k, v in cfg.Table  {
        fmt.printfln("[%v] -> %v", k, v);
    }

    discord_gateway();
}

GATEWAY_URL := "GATEWAY_URL";
BOT_TOKEN := "DISCORD_TOKEN"

discord_gateway :: proc() {
    token := cfg.Table[BOT_TOKEN];
    fmt.printfln("[Grebball++] Using token: '%v'", token);

    sb: strings.Builder;
    strings.builder_init_len_cap(&sb, 0, 1024);
    defer strings.builder_destroy(&sb);
    fmt.sbprintf(&sb, "Authorization: Bot %v", token);

    headers: ^curl.slist= nil;
    headers = curl.slist_append(headers, strings.to_cstring(&sb));
    defer curl.slist_free_all(headers);

    fmt.printfln("[Grebball++] slist for headers: %p", headers);
    curr := headers;
    for (curr != nil) {
        fmt.printfln("    - '%v'", curr.data);
        curr = cast(^curl.slist)curr.next;
    }

    strings.builder_reset(&sb);
    h := curl.easy_init();
    defer curl.easy_cleanup(h);

    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, cfg.Table[GATEWAY_URL]);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &sb);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, curl.builder_write);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_HTTPHEADER, headers);

    //code := curl.easy_perform(h);
    //gate_res: gateway_res;
    //_ = json.unmarshal(sb.buf[:], &gate_res, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    //fmt.printfln("[Grebball++] [CODE=%v] gateway response:", code);
    //fmt.printfln("    url: %v", gate_res.url);

    //strings.builder_reset(&sb);
    //curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, gate_res.url);
    //curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &sb);
    //curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, curl.builder_write);
    //curl.easy_setopt(h, curl.CURLoption.CURLOPT_HTTPHEADER, headers);

    //code = curl.easy_perform(h);
    //fmt.printfln("[Grebball++] [CODE=%v] web socket:", code);
    //fmt.printfln("    %v", strings.to_string(sb));

    //TODO: Start heartbeat timer, using time.accurate_sleep
    //sys.Sleep(heartbeat interval)
    //will probably need a mutex set on the CURL handle?
    //1. get messages from bot / gen responses, 2. send heartbeats

    th := thread.create_and_start(proc() {
        for i in 0..<10 {
            fmt.printfln("[THREAD] Hello!");
            sys.Sleep(100);
        }
    });
    defer thread.destroy(th);

    sys.Sleep(50);
    thread.join(th);

    free_all(context.temp_allocator);
}
