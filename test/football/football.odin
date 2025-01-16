package football

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:time"

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
    start_time: time.Time,
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

fetch_week :: proc(season, type, week: int, allocator: mem.Allocator = context.allocator) -> [dynamic]NFLMatch {
    strings.builder_reset(&url_str);
    strings.builder_reset(&response);
    fmt.sbprintf(&url_str, "%v?dates=%v&seasontype=%v&week=%v", URL_BASE, season, type, week);

    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_URL, strings.to_cstring(&url_str));
    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_WRITEDATA, &response);
    curl.easy_setopt(curl_h, curl.CURLoption.CURLOPT_WRITEFUNCTION, curl.builder_write);
    code: curl.CURLcode = curl.easy_perform(curl_h);

    out: EspnRoot;
    err := json.unmarshal(response.buf[:], &out, json.DEFAULT_SPECIFICATION, context.temp_allocator);
    results := make([dynamic]NFLMatch, len(out.events), len(out.events));
    arr: [32]byte;
    for e, i in out.events {
        test := strconv.itoa(arr[:], e.id);
        results[i].id, _ = strings.clone_from_bytes(arr[:len(test)], allocator);

        away_comp := e.competitions[0].competitors[0];
        home_comp := e.competitions[0].competitors[1];
        results[i].away_team, _ = strings.clone(away_comp.team.abbreviation, allocator);
        results[i].home_team, _ = strings.clone(home_comp.team.abbreviation, allocator);
        results[i].away_score = strconv.atoi(away_comp.score);
        results[i].home_score = strconv.atoi(home_comp.score);

        date_str, _ := strings.replace(e.competitions[0].date, "Z", ":00Z", 1);
        results[i].start_time, _ = time.iso8601_to_time_utc(date_str);
    }

    free_all(context.temp_allocator);
    return results;
}

delete_matches :: proc(matches: [dynamic]NFLMatch) {
    for m in matches {
        delete(m.id);
        delete(m.away_team);
        delete(m.home_team);
    }
    delete(matches);
}
