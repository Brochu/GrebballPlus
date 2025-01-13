package curl

import "core:c"
foreign import curl "libcurl.lib"

CURLcode :: enum {
    OK,
};

CURLoption :: enum {
    CURLOPT_WRITEDATA = 10001,
    CURLOPT_URL = 10002,
    CURLOPT_HTTPHEADER = 10023,

    CURLOPT_WRITEFUNCTION = 20011,
};

slist :: struct {
    data: cstring,
    next: rawptr,
};

@(link_prefix = "curl_")
foreign curl {
    version :: proc() -> cstring ---
    easy_init :: proc() -> rawptr ---
    easy_cleanup :: proc(h: rawptr) ---
    easy_setopt :: proc(h: rawptr, opt: CURLoption, #c_vararg args:..any) ---
    easy_perform :: proc(h: rawptr) -> CURLcode ---

    slist_append :: proc(list: rawptr, str: cstring) -> ^slist ---
    slist_free_all :: proc(list: rawptr) ---
}
