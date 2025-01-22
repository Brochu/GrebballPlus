package curl

import "core:c"
import "core:fmt"
import "core:strings"
foreign import curl "libcurl.lib"

builder_write :: proc(data: [^]byte, size, len: u64, dst: ^strings.Builder) -> u64 {
    strings.write_bytes(dst, data[0:len]);

    //TODO: find a way to get websocket data on main thread?
    // maybe need to swap to recv / sent model
    // setup CURLOPT for ConnectOnly
    fmt.printfln("[CURL] %v", strings.to_string(dst^))
    return size * len;
}

void :: struct {};
HANDLE :: distinct ^void;

CURLcode :: enum {
    OK = 0,
    UNSUPPORTED_PROTOCOL,    /* 1 */
    FAILED_INIT,             /* 2 */
    URL_MALFORMAT,           /* 3 */
    NOT_BUILT_IN,            /* 4 - [was obsoleted in August 2007 for
                              7.17.0, reused in April 2011 for 7.21.5] */
    COULDNT_RESOLVE_PROXY,   /* 5 */
    COULDNT_RESOLVE_HOST,    /* 6 */
    COULDNT_CONNECT,         /* 7 */
    WEIRD_SERVER_REPLY,      /* 8 */
    REMOTE_ACCESS_DENIED,    /* 9 a service was denied by the server
                              due to lack of access - when login fails
                              this is not returned. */
    FTP_ACCEPT_FAILED,       /* 10 - [was obsoleted in April 2006 for
                              7.15.4, reused in Dec 2011 for 7.24.0]*/
    FTP_WEIRD_PASS_REPLY,    /* 11 */
    FTP_ACCEPT_TIMEOUT,      /* 12 - timeout occurred accepting server
                              [was obsoleted in August 2007 for 7.17.0,
                              reused in Dec 2011 for 7.24.0]*/
    FTP_WEIRD_PASV_REPLY,    /* 13 */
    FTP_WEIRD_227_FORMAT,    /* 14 */
    FTP_CANT_GET_HOST,       /* 15 */
    HTTP2,                   /* 16 - A problem in the http2 framing layer.
                              [was obsoleted in August 2007 for 7.17.0,
                              reused in July 2014 for 7.38.0] */
    FTP_COULDNT_SET_TYPE,    /* 17 */
    PARTIAL_FILE,            /* 18 */
    FTP_COULDNT_RETR_FILE,   /* 19 */
    OBSOLETE20,              /* 20 - NOT USED */
    QUOTE_ERROR,             /* 21 - quote command failure */
    HTTP_RETURNED_ERROR,     /* 22 */
    WRITE_ERROR,             /* 23 */
    OBSOLETE24,              /* 24 - NOT USED */
    UPLOAD_FAILED,           /* 25 - failed upload "command" */
    READ_ERROR,              /* 26 - could not open/read from file */
    OUT_OF_MEMORY,           /* 27 */
    OPERATION_TIMEDOUT,      /* 28 - the timeout time was reached */
    OBSOLETE29,              /* 29 - NOT USED */
    FTP_PORT_FAILED,         /* 30 - FTP PORT operation failed */
    FTP_COULDNT_USE_REST,    /* 31 - the REST command failed */
    OBSOLETE32,              /* 32 - NOT USED */
    RANGE_ERROR,             /* 33 - RANGE "command" did not work */
    OBSOLETE34,              /* 34 */
    SSL_CONNECT_ERROR,       /* 35 - wrong when connecting with SSL */
    BAD_DOWNLOAD_RESUME,     /* 36 - could not resume download */
    FILE_COULDNT_READ_FILE,  /* 37 */
    LDAP_CANNOT_BIND,        /* 38 */
    LDAP_SEARCH_FAILED,      /* 39 */
    OBSOLETE40,              /* 40 - NOT USED */
    OBSOLETE41,              /* 41 - NOT USED starting with 7.53.0 */
    ABORTED_BY_CALLBACK,     /* 42 */
    BAD_FUNCTION_ARGUMENT,   /* 43 */
    OBSOLETE44,              /* 44 - NOT USED */
    INTERFACE_FAILED,        /* 45 - CURLOPT_INTERFACE failed */
    OBSOLETE46,              /* 46 - NOT USED */
    TOO_MANY_REDIRECTS,      /* 47 - catch endless re-direct loops */
    UNKNOWN_OPTION,          /* 48 - User specified an unknown option */
    SETOPT_OPTION_SYNTAX,    /* 49 - Malformed setopt option */
    OBSOLETE50,              /* 50 - NOT USED */
    OBSOLETE51,              /* 51 - NOT USED */
    GOT_NOTHING,             /* 52 - when this is a specific error */
    SSL_ENGINE_NOTFOUND,     /* 53 - SSL crypto engine not found */
    SSL_ENGINE_SETFAILED,    /* 54 - can not set SSL crypto engine as
                              default */
    SEND_ERROR,              /* 55 - failed sending network data */
    RECV_ERROR,              /* 56 - failure in receiving network data */
    OBSOLETE57,              /* 57 - NOT IN USE */
    SSL_CERTPROBLEM,         /* 58 - problem with the local certificate */
    SSL_CIPHER,              /* 59 - could not use specified cipher */
    PEER_FAILED_VERIFICATION, /* 60 - peer's certificate or fingerprint
                               was not verified fine */
    BAD_CONTENT_ENCODING,    /* 61 - Unrecognized/bad encoding */
    OBSOLETE62,              /* 62 - NOT IN USE since 7.82.0 */
    FILESIZE_EXCEEDED,       /* 63 - Maximum file size exceeded */
    USE_SSL_FAILED,          /* 64 - Requested FTP SSL level failed */
    SEND_FAIL_REWIND,        /* 65 - Sending the data requires a rewind
                              that failed */
    SSL_ENGINE_INITFAILED,   /* 66 - failed to initialise ENGINE */
    LOGIN_DENIED,            /* 67 - user, password or similar was not
                              accepted and we failed to login */
    TFTP_NOTFOUND,           /* 68 - file not found on server */
    TFTP_PERM,               /* 69 - permission problem on server */
    REMOTE_DISK_FULL,        /* 70 - out of disk space on server */
    TFTP_ILLEGAL,            /* 71 - Illegal TFTP operation */
    TFTP_UNKNOWNID,          /* 72 - Unknown transfer ID */
    REMOTE_FILE_EXISTS,      /* 73 - File already exists */
    TFTP_NOSUCHUSER,         /* 74 - No such user */
    OBSOLETE75,              /* 75 - NOT IN USE since 7.82.0 */
    OBSOLETE76,              /* 76 - NOT IN USE since 7.82.0 */
    SSL_CACERT_BADFILE,      /* 77 - could not load CACERT file, missing
                              or wrong format */
    REMOTE_FILE_NOT_FOUND,   /* 78 - remote file not found */
    SSH,                     /* 79 - error from the SSH layer, somewhat
                              generic so the error message will be of
                              interest when this has happened */

    SSL_SHUTDOWN_FAILED,     /* 80 - Failed to shut down the SSL
                              connection */
    AGAIN,                   /* 81 - socket is not ready for send/recv,
                              wait till it is ready and try again (Added
                              in 7.18.2) */
    SSL_CRL_BADFILE,         /* 82 - could not load CRL file, missing or
                              wrong format (Added in 7.19.0) */
    SSL_ISSUER_ERROR,        /* 83 - Issuer check failed.  (Added in
                              7.19.0) */
    FTP_PRET_FAILED,         /* 84 - a PRET command failed */
    RTSP_CSEQ_ERROR,         /* 85 - mismatch of RTSP CSeq numbers */
    RTSP_SESSION_ERROR,      /* 86 - mismatch of RTSP Session Ids */
    FTP_BAD_FILE_LIST,       /* 87 - unable to parse FTP file list */
    CHUNK_FAILED,            /* 88 - chunk callback reported error */
    NO_CONNECTION_AVAILABLE, /* 89 - No connection available, the
                              session will be queued */
    SSL_PINNEDPUBKEYNOTMATCH, /* 90 - specified pinned public key did not
                               match */
    SSL_INVALIDCERTSTATUS,   /* 91 - invalid certificate status */
    HTTP2_STREAM,            /* 92 - stream error in HTTP/2 framing layer
                              */
    RECURSIVE_API_CALL,      /* 93 - an api function was called from
                              inside a callback */
    AUTH_ERROR,              /* 94 - an authentication function returned an
                              error */
    HTTP3,                   /* 95 - An HTTP/3 layer problem */
    QUIC_CONNECT_ERROR,      /* 96 - QUIC connection error */
    PROXY,                   /* 97 - proxy handshake error */
    SSL_CLIENTCERT,          /* 98 - client-side certificate required */
    UNRECOVERABLE_POLL,      /* 99 - poll/select returned fatal error */
    TOO_LARGE,               /* 100 - a value/data met its maximum */
    ECH_REQUIRED,            /* 101 - ECH tried but failed */
    LAST /* never use! */
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

GLOBAL_ALL: c.long = (1 << 0) | (1 << 1);

slist :: struct {
    data: cstring,
    next: ^void,
};

ws_frame :: struct {
    age: c.int,       /* zero */
    flags: c.int,     /* See the CURLWS_* defines */
    offset: c.int64_t,    /* the offset of this data into the frame */
    bytesleft: c.int64_t, /* number of pending bytes left of the payload */
    len: c.size_t,       /* size of the current data chunk */
};

@(link_prefix = "curl_")
foreign curl {
    version :: proc() -> cstring ---
    global_init :: proc(flags: c.long) ---
    global_cleanup :: proc() ---

    easy_init :: proc() -> HANDLE ---
    easy_cleanup :: proc(h: HANDLE) ---
    easy_setopt :: proc(h: HANDLE, opt: CURLoption, #c_vararg args:..any) ---
    easy_perform :: proc(h: HANDLE) -> CURLcode ---
    easy_strerror :: proc(code: CURLcode) -> cstring ---

    ws_recv :: proc(
        h: HANDLE,
        buf: rawptr, buf_len: c.size_t,
        nread: ^c.size_t, metap: ^^ws_frame
    ) -> CURLcode ---

    ws_send :: proc(
        h: HANDLE,
        buf: rawptr, buf_len: c.size_t,
        sent: ^c.size_t, frag_size: c.int64_t,
        flags: c.uint
    ) -> CURLcode ---

    slist_append :: proc(list: rawptr, str: cstring) -> ^slist ---
    slist_free_all :: proc(list: rawptr) ---
}
