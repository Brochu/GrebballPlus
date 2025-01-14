package football

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:strings"
import dt"core:time/datetime"

import "../curl"

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
    abbreviation: string,
}

NFLMatch :: struct {
    id: string,
    away_team: string,
    home_team: string,
    away_score: int,
    home_score: int,
    date: dt.DateTime,
}

URL_BASE :: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard";

//TODO: Look into threadlocal values?
url_str: strings.Builder;
response: strings.Builder;

curl_h: rawptr;

init :: proc(allocator: mem.Allocator = context.allocator) -> mem.Allocator_Error {
    curl_h = curl.easy_init();

    strings.builder_init_len_cap(&url_str, 0, 128, allocator) or_return;
    strings.builder_init_len_cap(&response, 0, 1024, allocator) or_return;

    return .None;
}

free :: proc() {
    strings.builder_destroy(&response);
    strings.builder_destroy(&url_str);

    curl.easy_cleanup(curl_h);
}

fetch_week :: proc(season, type, week: int) -> [dynamic]NFLMatch {
    strings.builder_reset(&url_str);
    strings.builder_reset(&response);
    fmt.sbprintf(&url_str, "%v?dates=%v&seasontype=%v&week=%v", URL_BASE, season, type, week);
    fmt.printfln("[Grebball++] URL: %v", strings.to_string(url_str));

    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_URL, strings.to_cstring(&url_str));
    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_WRITEFUNCTION, curl.builder_write);

    code: curl.CURLcode = curl.easy_perform(curl_h);
    fmt.printfln("[Grebball++] request code: %v", code);

    out: EspnRoot;
    err := json.unmarshal(response.buf[:], &out, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    fmt.println("[Grebball++] Events:");
    for e in out.events {
        fmt.printfln("    -%v", e);
    }

    //region, ok := tz.region_load("local");
    //defer tz.region_destroy(region);
    //fmt.printfln("    region: %v", region);

    //for e in out.events {
    //    str_date, _ := strings.replace(e.competitions[0].date, "Z", ":00Z", 1);
    //    t, read := time.iso8601_to_time_utc(str_date);
    //    dt, _ := time.time_to_datetime(t);
    //    //dt, off, is_leap, read := time.rfc3339_to_components(e.competitions[0].date);
    //    fmt.printfln("    %v", dt);
    //    new_dt, success := tz.datetime_to_tz(dt, region);
    //    fmt.printfln("    [%v]%v", success, new_dt);
    //    fmt.printfln("    [%v][%v] '%v'(%v) - %v VS, %v - '%v'(%v)", e.id, e.competitions[0].date,
    //        e.competitions[0].competitors[0].team.displayName, e.competitions[0].competitors[0].team.abbreviation, e.competitions[0].competitors[0].score,
    //        e.competitions[0].competitors[1].score, e.competitions[0].competitors[1].team.displayName, e.competitions[0].competitors[1].team.abbreviation
    //    );
    //    fmt.println();
    //}

    free_all(context.temp_allocator);
    //TODO: Fill results and allocate needed memory
    return {};
}
