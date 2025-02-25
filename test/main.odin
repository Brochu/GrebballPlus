package main

import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:slice"
import "core:strings"
import sys"core:sys/windows"
import "core:time"

import "curl"
import fb"football"
import cfg"config"

TRACK_MEM :: #config(TRACK_MEM, false);

gateway_res :: struct {
    url: string,
    session_start_limit: session_start,
    shards: int,
};
session_start :: struct {
    max_concurrency: int,
    remaining: int,
    reset_after: int,
    total: int,
};

hello_evt :: struct {
    op: int,
    d: heartbeat_d,
};
heartbeat_d :: struct {
    heartbeat_interval: u32,
};

heartbeat_req :: struct {
    op: c.size_t,
    d: any,
};

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
    fmt.println();

    //discord_gateway();
    web_socket();
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

    code := curl.easy_perform(h);
    gate_res: gateway_res;
    _ = json.unmarshal(sb.buf[:], &gate_res, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    fmt.printfln("[Grebball++] [CODE=%v; '%v'] gateway response:", code, curl.easy_strerror(code));
    fmt.printfln("    url: %v", gate_res.url);
    free_all(context.temp_allocator);
}

web_socket :: proc() {
    curl.global_init(curl.GLOBAL_ALL);
    defer curl.global_cleanup();

    ez := curl.easy_init();
    defer curl.easy_cleanup(ez);
    curl.easy_setopt(ez, curl.CURLoption.CURLOPT_URL, "wss://gateway.discord.gg");
    curl.easy_setopt(ez, curl.CURLoption.CURLOPT_CONNECT_ONLY, 2);

    code := curl.easy_perform(ez);
    sys.Sleep(100);
    fmt.printfln("[Grebball++] [code=%v ; %v] WS connected!", code, curl.easy_strerror(code));

    buf_len :: 256;
    buffer: [buf_len]byte;
    nbytes: c.size_t = 0;
    meta: ^curl.ws_frame;
    code = curl.ws_recv(ez, &buffer, c.size_t(buf_len), &nbytes, &meta);
    fmt.printfln("[Grebball++] [code=%v ; %v] Read hello message?", code, curl.easy_strerror(code));
    fmt.printfln("    meta: %v", meta^);
    fmt.printfln("    buffer: %v", string(buffer[:]));

    hello: hello_evt;
    _ = json.unmarshal(buffer[:], &hello, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    defer free_all(context.temp_allocator);

    interval: u32 = hello.d.heartbeat_interval - 15;
    last_hb := time.tick_now();
    wait: u32 = 3000;
    hb_count := 0;
    for hb_count < 5 {
        dur :=time.tick_since(last_hb);
        ms := cast(u32)time.duration_milliseconds(dur);
        if ms >= interval {
            last_hb = time.tick_now();
            hb_count += 1;
            send_heartbeat(ez);
            sys.Sleep(wait);
            continue;
        }

        slice.fill(buffer[:], 0);
        code = curl.ws_recv(ez, &buffer, c.size_t(buf_len), &nbytes, &meta);
        if code == .OK {
            fmt.printfln("[Grebball++] [code=%v ; %v] Got new messsage", code, curl.easy_strerror(code));
            fmt.printfln("    meta: %v", meta^);
            fmt.printfln("    buffer: %v", string(buffer[:]));
        } else if code == .AGAIN {
            fmt.printfln("[Grebball++] [code=%v ; %v] No messages ready", code, curl.easy_strerror(code));
        }

        w := math.min(wait, interval - ms);
        fmt.printfln("[Grebball++] wait for %v", w);
        sys.Sleep(math.min(wait, w));
    }

    slice.fill(buffer[:], 0);
    code = curl.ws_send(ez, &buffer, 0, &nbytes, 0, cast(u32)curl.WS_Flags.CURLWS_CLOSE);
    fmt.printfln("[Grebball++] [code=%v ; %v] WS disconnected!", code, curl.easy_strerror(code));
}

send_heartbeat :: proc(ez: curl.HANDLE) {
    msg: string = "{\"op\":1,\"d\":null}";
    nbytes: c.size_t = 0;
    fmt.printfln("msg: %v", msg);

    curl.ws_send(ez, raw_data(msg), len(msg), &nbytes, 256, cast(u32)curl.WS_Flags.CURLWS_TEXT);
    fmt.printfln("nbytes: %v", nbytes);
}
