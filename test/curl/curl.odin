package curl

import "core:c"
foreign import curl "libcurl.lib"

Handle :: struct{};
CURLcode :: enum {
    OK,
};

CURLoption :: enum {
    CURLOPT_WRITEDATA = 10001,
    CURLOPT_URL = 10002,

    CURLOPT_WRITEFUNCTION = 20011,
}

@(link_prefix = "curl_")
foreign curl {
    version :: proc() -> cstring ---
    easy_init :: proc() -> ^Handle ---
    easy_cleanup :: proc(h: ^Handle) ---
    easy_setopt :: proc(^Handle, CURLoption, #c_vararg ..any) ---
    easy_perform :: proc(h: ^Handle) -> CURLcode ---
}
