#include <stdio.h>
#include <string>
#include <string.h>

#define GPP_LOG(fmt, ...) printf("[%s] " fmt "\n", "GB++", __VA_ARGS__);

#include <curl/curl.h>
#include <curl/websockets.h>
static size_t write_res(void *contents, size_t size, size_t len, void *user_ptr) {
    ((std::string*)user_ptr)->append((char*)contents, size*len);
    return size * len;
};

void test_curl() {
    char * ver = curl_version();
    printf("[Grebball++] curl version = %s\n", ver);
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
    //printf("[Grebball++] response -> %s\n", response.c_str());

    curl_easy_cleanup(ez);
}

void test_websocket() {
    CURL *ez = curl_easy_init();
    curl_easy_setopt(ez, CURLOPT_URL, "wss://gateway.discord.gg");
    curl_easy_setopt(ez, CURLOPT_CONNECT_ONLY, 2L);
    CURLcode code = curl_easy_perform(ez);

    GPP_LOG("(%i) connect to WS ->", code);
    Sleep(100);

    const size_t buf_len = 1024;
    size_t nread = 0;
    char buffer[buf_len];
    const curl_ws_frame *meta;
    code = curl_ws_recv(ez, buffer, buf_len, &nread, &meta);
    GPP_LOG("(%i) RECV ->", code);
    GPP_LOG("(%zu) %s", nread, buffer);

    code = curl_ws_send(ez, "", 0, &nread, 0, CURLWS_CLOSE);
    GPP_LOG("(%i) SEND, close ->", code);

    curl_easy_cleanup(ez);
    GPP_LOG("WebSockets: DONE");
}

/*
#include <dpp/dpp.h>
void test_dpp(char *token) {
    dpp::cluster bot(token);

    bot.on_log(dpp::utility::cout_logger());
    bot.on_ready([&bot](const dpp::ready_t& event) {
        GPP_LOG("Got %s event from %s", event.raw_event.c_str(), bot.me.id.str().c_str());
    });

    bot.start(dpp::st_wait);
}
*/

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

    test_curl();
    test_websocket();
    //test_dpp(conf.bot_token);

    GPP_LOG("Ending...");
    return 0;
}

