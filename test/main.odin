package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "curl"

URL_BASE :: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard";

EspnRoot :: struct {
    events: [dynamic]EspnEvent,
}

EspnEvent :: struct {
    id: int,
    competitions: [dynamic]EspnCompetition,
}

EspnCompetition :: struct {
    date: string,
    competitors: [dynamic]EspnCompetitior,
}

EspnCompetitior :: struct {
    team: EspnTeam,
    score: string,
}

EspnTeam :: struct {
    displayName: string,
}

main :: proc() {
    ver := curl.version();
    fmt.printfln("[Grebball++] curl version: %v", ver);

    h: rawptr = curl.easy_init();
    fmt.printfln("[Grebball++] easy handle: %p", h);

    url_builder: strings.Builder;
    strings.builder_init_len_cap(&url_builder, 0, 128);
    defer strings.builder_destroy(&url_builder);
    season := 2023;
    type := 3;
    week := 5;
    fmt.sbprintf(&url_builder, "%v?dates=%v&seasontype=%v&week=%v", URL_BASE, season, type, week);
    fmt.printfln("[Grebball++] URL: %v", strings.to_string(url_builder));

    response: strings.Builder;
    strings.builder_init_len_cap(&response, 0, 1024);
    defer strings.builder_destroy(&response);

    write_func :: proc(contents: rawptr, size, len: c.size_t, user_ptr: rawptr) -> c.size_t {
        src := (cast(^strings.Builder)user_ptr);
        dst := (cast([^]byte)contents);
        strings.write_bytes(src, dst[0:len]);

        return size * len;
    }
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, strings.to_cstring(&url_builder));
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, write_func);

    code: curl.CURLcode = curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    out: EspnRoot;
    err := json.unmarshal(response.buf[:], &out, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    fmt.printfln("[Grebball++] first event: %v", out.events[0]);

    //evts := data.(json.Object)["events"].(json.Array);
    //for e in evts {
    //    comp := e.(json.Object)["competitions"].(json.Array)[0].(json.Object)["competitors"].(json.Array);
    //    away := comp[0];
    //    home := comp[1];
    //    fmt.printfln("    %v vs. %v",
    //        away.(json.Object)["team"].(json.Object)["abbreviation"],
    //        home.(json.Object)["team"].(json.Object)["abbreviation"],
    //    );
    //}

    headers: ^curl.slist= nil;
    headers = curl.slist_append(headers, "Authorization: Bot TOKEN_HERE");
    fmt.printfln("[Grebball++] slist for headers: %p", headers);

    curr := headers;
    for (curr != nil) {
        fmt.printfln("    - '%v'", curr.data);
        curr = cast(^curl.slist)curr.next;
    }

    strings.builder_reset(&response);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, "https://discord.com/api/v10/gateway");
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, write_func);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_HTTPHEADER, headers);

    code = curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    fmt.printfln("[Grebball++] gateway result: %v", strings.to_string(response));

    curl.easy_cleanup(h);
    fmt.printfln("[Grebball++] easy handle: %p", h);

    curl.slist_free_all(headers);
    fmt.printfln("[Grebball++] slist for headers: %p", headers);

    fmt.printfln("[Grebball++] Done");
    free_all(context.temp_allocator);
}
