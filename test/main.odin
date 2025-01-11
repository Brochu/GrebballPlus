package main

import "core:fmt"
import "curl"

main :: proc() {
    res := curl.test(35, 34);
    fmt.printfln("[Grebball++] -> 35 + 34 = %v", res);
    ver := curl.curl_version();
    fmt.printfln("[Grebball++] curl version: %v", ver);
}
