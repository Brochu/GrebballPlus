#include <stdio.h>
#include <string>

/*
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

#include <dpp/dpp.h>
void test_dpp() {
    std::string token = "ASDF";
    dpp::cluster bot(token);
}
*/

void log_message(const char *mess) {
    static std::string app_name = "Grebball++";
    printf("[%s] %s\n", app_name.c_str(), mess);
}

int main(void) {
    log_message("Starting...");
    log_message("Ending...");

    return 0;
}

