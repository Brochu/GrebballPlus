package curl

import "core:c"
foreign import msvcrt "system:msvcrt"
foreign import curl "libcurl_a.lib"

foreign curl {
    curl_version :: proc() -> cstring ---
}

test :: proc(a, b: int) -> int {
    return a + b;
}
