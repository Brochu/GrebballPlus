package main

import "core:fmt"
import "core:strings"

import "curl"
import fb"football"

main :: proc() {
    if err := fb.init(); err != .None {
        fmt.printfln("[Grebball++] Could not allocated resources for football requests: %v", err);
    }
    defer fb.free();

    matches := fb.fetch_week(2024, 2, 18);
    defer fb.delete_matches(matches);

    for m in matches {
        fmt.printfln("    - %v", m);
    }
}

GATEWAY_URL := "https://discord.com/api/v10/gateway/bot";
BOT_TOKEN := strings.trim_right(#load("./token.cfg", string), "\r\n");

discord_gateway :: proc() {
    fmt.printfln("[Grebball++] Using token: '%v'", BOT_TOKEN);

    sb: strings.Builder;
    strings.builder_init_len_cap(&sb, 0, 1024);
    defer strings.builder_destroy(&sb);
    fmt.sbprintf(&sb, "Authorization: Bot %v", BOT_TOKEN);

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

    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, GATEWAY_URL);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &sb);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, curl.builder_write);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_HTTPHEADER, headers);

    code := curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    fmt.printfln("[Grebball++] gateway result: %v", strings.to_string(sb));
}
