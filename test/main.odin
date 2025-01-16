package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:time"

import "curl"
import fb"football"
import cfg"config"

TRACK_MEM :: #config(TRACK_MEM, false);

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

    /*
    if err := fb.init(); err != .None {
        fmt.printfln("[Grebball++] Could not allocated resources for football requests: %v", err);
    }
    defer fb.free();

    matches := fb.fetch_week(2024, 2, 18);
    defer fb.delete_matches(matches);

    buff := make([]u8, 32);
    for m in matches {
        date_part := time.to_string_yyyy_mm_dd(m.start_time, buff[:]);
        time_str := time.time_to_string_hms(m.start_time, buff[len(date_part):]);
        fmt.printfln("[%v](%v %v) %v: %v VS. %v :%v", m.id, date_part, time_str,
            m.away_team, m.away_score,
            m.home_score, m.home_team
        );
    }
    */

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

    code := curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    fmt.printfln("[Grebball++] gateway result: %v", strings.to_string(sb));
    //TODO: Next steps, negociate connection with Discord's WebSocket
}
