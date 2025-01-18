package curl

import "core:c"
import "core:fmt"
import "core:strings"
foreign import curl "libcurl.lib"

builder_write :: proc(contents: rawptr, size, len: u64, user_ptr: rawptr) -> u64 {
    dst := (cast(^strings.Builder)user_ptr);
    data := (cast([^]byte)contents);
    strings.write_bytes(dst, data[0:len]);

    //TODO: find a way to get websocket data on main thread?
    // maybe need to swap to recv / sent model
    // setup CURLOPT for ConnectOnly
    fmt.printfln("[CURL] %v", strings.to_string(dst^))
    return size * len;
}

CURLcode :: enum {
    OK,
};

CURLoption :: enum {
    CURLOPT_CONNECT_ONLY = 141,

    CURLOPT_WRITEDATA = 10001,
    CURLOPT_URL = 10002,
    CURLOPT_HTTPHEADER = 10023,

    CURLOPT_WRITEFUNCTION = 20011,
};

/* flag bits */
WS_Flags :: enum {
    CURLWS_TEXT       = (1<<0),
    CURLWS_BINARY     = (1<<1),
    CURLWS_CONT       = (1<<2),
    CURLWS_CLOSE      = (1<<3),
    CURLWS_PING       = (1<<4),
    CURLWS_OFFSET     = (1<<5),
}

slist :: struct {
    data: cstring,
    next: rawptr,
};

//TODO: Double check parameter types here
ws_frame :: struct {
    age: int,       /* zero */
    flags: int,     /* See the CURLWS_* defines */
    offset: int,    /* the offset of this data into the frame */
    bytesleft: int, /* number of pending bytes left of the payload */
    len: c.size_t,       /* size of the current data chunk */
};

@(link_prefix = "curl_")
foreign curl {
    version :: proc() -> cstring ---
    easy_init :: proc() -> rawptr ---
    easy_cleanup :: proc(h: rawptr) ---
    easy_setopt :: proc(h: rawptr, opt: CURLoption, #c_vararg args:..any) ---
    easy_perform :: proc(h: rawptr) -> CURLcode ---

    //TODO: Double check parameter types here
    ws_send :: proc(h, buf: rawptr, buf_len: c.size_t, sent: ^c.size_t, frag_size: c.size_t, flags: int) -> CURLcode ---
    ws_recv :: proc(h, buf: rawptr, buf_len: c.size_t, nread: ^c.size_t, metap: ^^ws_frame) -> CURLcode ---

    slist_append :: proc(list: rawptr, str: cstring) -> ^slist ---
    slist_free_all :: proc(list: rawptr) ---
}
