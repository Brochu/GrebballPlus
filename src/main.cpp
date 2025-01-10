#include <stdio.h>
#include <string.h>

/*
//TODO: Look into moving this to it's own object file to avoid re-compiles
#include <curl/curl.h>
static size_t write_res(void *contents, size_t size, size_t len, void *user_ptr) {
    ((std::string*)user_ptr)->append((char*)contents, size*len);
    return size * len;
};

void test_curl() {
    char url[512];
    sprintf(url, "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?dates=%i&seasontype=%i&week=%i", 2024, 3, 1);
    printf("[Grebball++] url = %s\n", url);

    std::string response;

    CURL *ez = curl_easy_init();
    curl_easy_setopt(ez, CURLOPT_URL, url);
    curl_easy_setopt(ez, CURLOPT_WRITEFUNCTION, write_res);
    curl_easy_setopt(ez, CURLOPT_WRITEDATA, &response);
    CURLcode code = curl_easy_perform(ez);

    printf("[Grebball++] CURLcode -> %i\n", code);
    printf("[Grebball++] response -> %s\n", response.c_str());

    curl_easy_cleanup(ez);
}

//TODO: Look into moving this to it's own object file to avoid re-compiles
#include <dpp/dpp.h>
void test_dpp() {
    std::string token = "ASDF";
    dpp::cluster bot(token);
}
*/

#define GPP_LOG(fmt, ...) printf("[%s] " fmt "\n", "Grebball++", __VA_ARGS__);

typedef struct {
    char bot_token[256];
} gpp_config;

gpp_config load_config() {
    char buf[1024];
    FILE *f = NULL;

    fopen_s(&f, "./config.cfg", "r");
    fread_s(buf, 1024, 1, 1024, f);
    fclose(f);

    // Maybe split by lines later?
    char *start = buf, *end = buf;
    while(*start != '=') ++start;
    end = ++start;
    while(*end != '\n') ++end;

    gpp_config conf;
    strncpy_s(conf.bot_token, start, end-start);
    return  conf;
}

int main(void) {
    GPP_LOG("Starting...");
    auto conf = load_config();
    GPP_LOG("Using token -> '%s'", conf.bot_token);
    GPP_LOG("Ending...");

    // Work on simple config loading
    return 0;
}

