package main

import "core:c"
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
    heartbeat_interval: int,
};

heartbeat_req :: struct {
    op: int,
    d: int,
};

hb_thread_data :: struct {
    ez: curl.HANDLE,
    interval: u32,
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

    evt_proc :: proc(data: [^]byte, size, len: u64, curl: curl.HANDLE ) {
    };

    ez := curl.easy_init();
    defer curl.easy_cleanup(ez);
    curl.easy_setopt(ez, curl.CURLoption.CURLOPT_URL, "wss://gateway.discord.gg");
    curl.easy_setopt(ez, curl.CURLoption.CURLOPT_CONNECT_ONLY, 2);
    //TODO: Look into using callbacks instead of CONNECT_ONLY
    // How would we handle heartbeat in this case?

    code := curl.easy_perform(ez);
    fmt.printfln("[Grebball++] [code=%v]", code);
    sys.Sleep(100);
    fmt.println("[Grebball++] ready to recv");

    buf_len :: 256;
    buffer: [buf_len]byte;
    nread: c.size_t = 0;
    meta: ^curl.ws_frame;
    code = curl.ws_recv(ez, &buffer, c.size_t(buf_len), &nread, &meta);

    hello: hello_evt;
    _ = json.unmarshal(buffer[:], &hello, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    defer free_all(context.temp_allocator);
    fmt.printfln("[Grebball++] [code=%v] recv", code);
    fmt.printfln("    meta: %v", meta^);
    fmt.printfln("    Hello event: %v", hello);

    data := hb_thread_data{ ez = ez, interval = cast(u32)hello.d.heartbeat_interval };
    th := thread.create_and_start_with_data(&data, proc(datap: rawptr) {
        data: hb_thread_data = (cast(^hb_thread_data)datap)^;

        hb_str: strings.Builder;
        strings.builder_init_len_cap(&hb_str, 0, 256);

        //for {
            strings.builder_reset(&hb_str);
            fmt.sbprint(&hb_str, "{\"op\": 1, \"d\": null}");
        //    sent: c.size_t = 0;
        //    curl.ws_send(data.ez, &hb_str.buf, len(hb_str.buf), &sent, 256, cast(u32)curl.WS_Flags.CURLWS_TEXT);
        //}
        fmt.println("[Grebball++] Hello from thread, got this data:");
        fmt.printfln("    HB Interval: %v", data.interval);
        fmt.println("[Grebball++] example message: %v", strings.to_string(hb_str));
        sys.Sleep(1000);
        //sys.Sleep(data.interval);
        fmt.println("[Grebball++] HB thread done");
        //TODO: Handle heartbeat here
    });
    defer thread.destroy(th);

    sys.Sleep(2000);
    //TODO: loop with recv
    // with CURLcode == AGAIN, wait then try again
    // with valid message, process command [and maybe reply]
    // disconnect, quit loop
    // after disconnect, check if reconnect logic is needed
    sent: c.size_t = 0;
    close_buf: [0]byte;
    code = curl.ws_send(ez, &buffer, 0, &sent, 0, cast(u32)curl.WS_Flags.CURLWS_CLOSE);
    fmt.printfln("[Grebball++] [code=%v] send - close", code);
}
