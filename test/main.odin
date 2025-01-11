package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "curl"

URL_BASE :: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard";

EspnRoot :: struct {
    events: [dynamic]json.Value,
}

write_func :: proc(contents: rawptr, size, len: c.size_t, user_ptr: rawptr) -> c.size_t {
    src := (cast(^strings.Builder)user_ptr);
    dst := (cast([^]byte)contents);
    strings.write_bytes(src, dst[0:len]);

    return size * len;
}

main :: proc() {
    ver := curl.version();
    fmt.printfln("[Grebball++] curl version: %v", ver);

    h: ^curl.Handle = curl.easy_init();
    fmt.printfln("[Grebball++] easy handle: %p", h);

    url_builder: strings.Builder;
    strings.builder_init_len_cap(&url_builder, 0, 128);
    defer strings.builder_destroy(&url_builder);
    season := 2024;
    type := 3;
    week := 1;
    fmt.sbprintf(&url_builder, "%v?dates=%v&seasontype=%v&week=%v", URL_BASE, season, type, week);
    fmt.printfln("[Grebball++] URL: %v", strings.to_string(url_builder));

    response: strings.Builder;
    strings.builder_init_len_cap(&response, 0, 1024);
    defer strings.builder_destroy(&response);

    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, strings.to_cstring(&url_builder));
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, write_func);

    code: curl.CURLcode = curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    data, _ := json.parse(response.buf[:]);
    defer json.destroy_value(data);

    evts := data.(json.Object)["events"].(json.Array);
    for e in evts {
        comp := e.(json.Object)["competitions"].(json.Array)[0].(json.Object)["competitors"].(json.Array);
        away := comp[0];
        home := comp[1];
        fmt.printfln("    %v vs. %v",
            away.(json.Object)["team"].(json.Object)["abbreviation"],
            home.(json.Object)["team"].(json.Object)["abbreviation"],
        );
    }

    curl.easy_cleanup(h);
    fmt.printfln("[Grebball++] easy handle: %p", h);

    fmt.printfln("[Grebball++] Done");
}
