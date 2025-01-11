package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "curl"

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

    url: cstring = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?dates=2024&seasontype=3&week=1"
    response: strings.Builder;
    strings.builder_init_len_cap(&response, 0, 1024);
    defer strings.builder_destroy(&response);

    curl.easy_setopt(h, curl.CURLoption.CURLOPT_URL, url);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(h, curl.CURLoption.CURLOPT_WRITEFUNCTION, write_func);

    code: curl.CURLcode = curl.easy_perform(h);
    fmt.printfln("[Grebball++] request code: %v", code);
    data, _ := json.parse(response.buf[:]);
    evts := data.(json.Object)["events"].(json.Array);
    away := evts[0].(json.Object)["competitions"].(json.Array)[0].(json.Object)["competitors"].(json.Array)[0];
    home := evts[0].(json.Object)["competitions"].(json.Array)[0].(json.Object)["competitors"].(json.Array)[1];
    fmt.printfln("[Grebball++] Away team: %v", away.(json.Object)["team"].(json.Object)["displayName"]);
    fmt.printfln("[Grebball++] Home team: %v", home.(json.Object)["team"].(json.Object)["displayName"]);

    curl.easy_cleanup(h);
    fmt.printfln("[Grebball++] easy handle: %p", h);

    fmt.printfln("[Grebball++] Done");
}
