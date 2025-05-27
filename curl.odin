package curl

/*
The comments are from C.
Os comentos são de C.
注释来自c。
*/

// odinfmt: disable
when ODIN_OS == .Windows {
    foreign import curl {
        `D:/space/scode/curl-8.8.0/builds/libcurl-vc-x64-release-static-ipv6-sspi-schannel/lib/libcurl_a.lib`, // replace this
        "system:advapi32.lib",
        "system:crypt32.lib",
        "system:normaliz.lib",
        "system:ws2_32.lib",
        "system:wldap32.lib",
    }
}
// odinfmt: enable

@(link_prefix = "curl_")
foreign curl {
	version :: proc() -> cstring ---
	global_init :: proc(globalOpt: int) -> (code: int) ---
	global_cleanup :: proc() ---
	slist_append :: proc(slist: curl_slist, header: cstring) -> curl_slist ---
	slist_free_all :: proc(slist: curl_slist) ---

	// easy
	easy_init :: proc() -> CURL ---
	easy_cleanup :: proc(cUrl: CURL) ---
	easy_setopt :: proc(cUrl: CURL, curlopt: int, #c_vararg params: ..any) -> (code: int) ---
	// Re-initializes a CURL handle to the default values.
	// This puts back the handle to the same state as it was in when it was just created.
	// It does keep: live connections, the Session ID cache, the DNS cache and the cookies.
	easy_reset :: proc(cUrl: CURL) ---
	easy_recv :: proc(cUrl: CURL, buffer: cstring, buflen: uint, n: ^uint) -> (code: int) ---
	easy_send :: proc(cUrl: CURL, buffer: cstring, buflen: uint, n: ^uint) -> (code: int) ---
	easy_perform :: proc(cUrl: CURL) -> (code: int) ---
	easy_strerror :: proc(code: int) -> cstring ---
}

CURL :: rawptr
curl_slist :: rawptr

// global opt
GLOBAL_SSL :: 1 << 0
GLOBAL_WIN32 :: 1 << 1
GLOBAL_ALL :: GLOBAL_SSL | GLOBAL_WIN32

// CURLcode
CURLcode :: enum int {
	CURLE_OK = 0,
	CURLE_UNSUPPORTED_PROTOCOL, /* 1 */
	CURLE_FAILED_INIT, /* 2 */
	CURLE_URL_MALFORMAT, /* 3 */
	CURLE_NOT_BUILT_IN, /* 4 - [was obsoleted in August 2007 for
                                    7.17.0, reused in April 2011 for 7.21.5] */
	CURLE_COULDNT_RESOLVE_PROXY, /* 5 */
	CURLE_COULDNT_RESOLVE_HOST, /* 6 */
	CURLE_COULDNT_CONNECT, /* 7 */
	CURLE_WEIRD_SERVER_REPLY, /* 8 */
	CURLE_REMOTE_ACCESS_DENIED, /* 9 a service was denied by the server
                                    due to lack of access - when login fails
                                    this is not returned. */
	CURLE_FTP_ACCEPT_FAILED, /* 10 - [was obsoleted in April 2006 for
                                    7.15.4, reused in Dec 2011 for 7.24.0]*/
	CURLE_FTP_WEIRD_PASS_REPLY, /* 11 */
	CURLE_FTP_ACCEPT_TIMEOUT, /* 12 - timeout occurred accepting server
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in Dec 2011 for 7.24.0]*/
	CURLE_FTP_WEIRD_PASV_REPLY, /* 13 */
	CURLE_FTP_WEIRD_227_FORMAT, /* 14 */
	CURLE_FTP_CANT_GET_HOST, /* 15 */
	CURLE_HTTP2, /* 16 - A problem in the http2 framing layer.
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in July 2014 for 7.38.0] */
	CURLE_FTP_COULDNT_SET_TYPE, /* 17 */
	CURLE_PARTIAL_FILE, /* 18 */
	CURLE_FTP_COULDNT_RETR_FILE, /* 19 */
	CURLE_OBSOLETE20, /* 20 - NOT USED */
	CURLE_QUOTE_ERROR, /* 21 - quote command failure */
	CURLE_HTTP_RETURNED_ERROR, /* 22 */
	CURLE_WRITE_ERROR, /* 23 */
	CURLE_OBSOLETE24, /* 24 - NOT USED */
	CURLE_UPLOAD_FAILED, /* 25 - failed upload "command" */
	CURLE_READ_ERROR, /* 26 - couldn't open/read from file */
	CURLE_OUT_OF_MEMORY, /* 27 */
	CURLE_OPERATION_TIMEDOUT, /* 28 - the timeout time was reached */
	CURLE_OBSOLETE29, /* 29 - NOT USED */
	CURLE_FTP_PORT_FAILED, /* 30 - FTP PORT operation failed */
	CURLE_FTP_COULDNT_USE_REST, /* 31 - the REST command failed */
	CURLE_OBSOLETE32, /* 32 - NOT USED */
	CURLE_RANGE_ERROR, /* 33 - RANGE "command" didn't work */
	CURLE_HTTP_POST_ERROR, /* 34 */
	CURLE_SSL_CONNECT_ERROR, /* 35 - wrong when connecting with SSL */
	CURLE_BAD_DOWNLOAD_RESUME, /* 36 - couldn't resume download */
	CURLE_FILE_COULDNT_READ_FILE, /* 37 */
	CURLE_LDAP_CANNOT_BIND, /* 38 */
	CURLE_LDAP_SEARCH_FAILED, /* 39 */
	CURLE_OBSOLETE40, /* 40 - NOT USED */
	CURLE_FUNCTION_NOT_FOUND, /* 41 - NOT USED starting with 7.53.0 */
	CURLE_ABORTED_BY_CALLBACK, /* 42 */
	CURLE_BAD_FUNCTION_ARGUMENT, /* 43 */
	CURLE_OBSOLETE44, /* 44 - NOT USED */
	CURLE_INTERFACE_FAILED, /* 45 - CURLOPT_INTERFACE failed */
	CURLE_OBSOLETE46, /* 46 - NOT USED */
	CURLE_TOO_MANY_REDIRECTS, /* 47 - catch endless re-direct loops */
	CURLE_UNKNOWN_OPTION, /* 48 - User specified an unknown option */
	CURLE_SETOPT_OPTION_SYNTAX, /* 49 - Malformed setopt option */
	CURLE_OBSOLETE50, /* 50 - NOT USED */
	CURLE_OBSOLETE51, /* 51 - NOT USED */
	CURLE_GOT_NOTHING, /* 52 - when this is a specific error */
	CURLE_SSL_ENGINE_NOTFOUND, /* 53 - SSL crypto engine not found */
	CURLE_SSL_ENGINE_SETFAILED, /* 54 - can not set SSL crypto engine as
                                    default */
	CURLE_SEND_ERROR, /* 55 - failed sending network data */
	CURLE_RECV_ERROR, /* 56 - failure in receiving network data */
	CURLE_OBSOLETE57, /* 57 - NOT IN USE */
	CURLE_SSL_CERTPROBLEM, /* 58 - problem with the local certificate */
	CURLE_SSL_CIPHER, /* 59 - couldn't use specified cipher */
	CURLE_PEER_FAILED_VERIFICATION, /* 60 - peer's certificate or fingerprint
                                     wasn't verified fine */
	CURLE_BAD_CONTENT_ENCODING, /* 61 - Unrecognized/bad encoding */
	CURLE_OBSOLETE62, /* 62 - NOT IN USE since 7.82.0 */
	CURLE_FILESIZE_EXCEEDED, /* 63 - Maximum file size exceeded */
	CURLE_USE_SSL_FAILED, /* 64 - Requested FTP SSL level failed */
	CURLE_SEND_FAIL_REWIND, /* 65 - Sending the data requires a rewind
                                    that failed */
	CURLE_SSL_ENGINE_INITFAILED, /* 66 - failed to initialise ENGINE */
	CURLE_LOGIN_DENIED, /* 67 - user, password or similar was not
                                    accepted and we failed to login */
	CURLE_TFTP_NOTFOUND, /* 68 - file not found on server */
	CURLE_TFTP_PERM, /* 69 - permission problem on server */
	CURLE_REMOTE_DISK_FULL, /* 70 - out of disk space on server */
	CURLE_TFTP_ILLEGAL, /* 71 - Illegal TFTP operation */
	CURLE_TFTP_UNKNOWNID, /* 72 - Unknown transfer ID */
	CURLE_REMOTE_FILE_EXISTS, /* 73 - File already exists */
	CURLE_TFTP_NOSUCHUSER, /* 74 - No such user */
	CURLE_OBSOLETE75, /* 75 - NOT IN USE since 7.82.0 */
	CURLE_OBSOLETE76, /* 76 - NOT IN USE since 7.82.0 */
	CURLE_SSL_CACERT_BADFILE, /* 77 - could not load CACERT file, missing
                                    or wrong format */
	CURLE_REMOTE_FILE_NOT_FOUND, /* 78 - remote file not found */
	CURLE_SSH, /* 79 - error from the SSH layer, somewhat
                                    generic so the error message will be of
                                    interest when this has happened */
	CURLE_SSL_SHUTDOWN_FAILED, /* 80 - Failed to shut down the SSL
                                    connection */
	CURLE_AGAIN, /* 81 - socket is not ready for send/recv,
                                    wait till it's ready and try again (Added
                                    in 7.18.2) */
	CURLE_SSL_CRL_BADFILE, /* 82 - could not load CRL file, missing or
                                    wrong format (Added in 7.19.0) */
	CURLE_SSL_ISSUER_ERROR, /* 83 - Issuer check failed.  (Added in
                                    7.19.0) */
	CURLE_FTP_PRET_FAILED, /* 84 - a PRET command failed */
	CURLE_RTSP_CSEQ_ERROR, /* 85 - mismatch of RTSP CSeq numbers */
	CURLE_RTSP_SESSION_ERROR, /* 86 - mismatch of RTSP Session Ids */
	CURLE_FTP_BAD_FILE_LIST, /* 87 - unable to parse FTP file list */
	CURLE_CHUNK_FAILED, /* 88 - chunk callback reported error */
	CURLE_NO_CONNECTION_AVAILABLE, /* 89 - No connection available, the
                                    session will be queued */
	CURLE_SSL_PINNEDPUBKEYNOTMATCH, /* 90 - specified pinned public key did not
                                     match */
	CURLE_SSL_INVALIDCERTSTATUS, /* 91 - invalid certificate status */
	CURLE_HTTP2_STREAM, /* 92 - stream error in HTTP/2 framing layer
                                    */
	CURLE_RECURSIVE_API_CALL, /* 93 - an api function was called from
                                    inside a callback */
	CURLE_AUTH_ERROR, /* 94 - an authentication function returned an
                                    error */
	CURLE_HTTP3, /* 95 - An HTTP/3 layer problem */
	CURLE_QUIC_CONNECT_ERROR, /* 96 - QUIC connection error */
	CURLE_PROXY, /* 97 - proxy handshake error */
	CURLE_SSL_CLIENTCERT, /* 98 - client-side certificate required */
	CURLE_UNRECOVERABLE_POLL, /* 99 - poll/select returned fatal error */
	CURLE_TOO_LARGE, /* 100 - a value/data met its maximum */
	CURLE_ECH_REQUIRED, /* 101 - ECH tried but failed */
	CURL_LAST, /* never use! */
}

// curlopt type
CURLOPTTYPE_LONG :: 0
CURLOPTTYPE_OBJECTPOINT :: 10000
CURLOPTTYPE_FUNCTIONPOINT :: 20000
CURLOPTTYPE_OFF_T :: 30000
CURLOPTTYPE_BLOB :: 40000

CURLOPTTYPE_STRINGPOINT :: CURLOPTTYPE_OBJECTPOINT
CURLOPTTYPE_SLISTPOINT :: CURLOPTTYPE_OBJECTPOINT
CURLOPTTYPE_CBPOINT :: CURLOPTTYPE_OBJECTPOINT
CURLOPTTYPE_VALUES :: CURLOPTTYPE_LONG
// curlopt type end

// curl option

CURLOPT_WRITEDATA :: CURLOPTTYPE_CBPOINT + 1 // This is the FILE * or void * the regular output should be written to. 
CURLOPT_URL :: CURLOPTTYPE_STRINGPOINT + 2 // The full URL to get/put 
CURLOPT_PORT :: CURLOPTTYPE_LONG + 3 // Port number to connect to, if other than default.
CURLOPT_PROXY :: CURLOPTTYPE_STRINGPOINT + 4 // Name of proxy to use.
CURLOPT_USERPWD :: CURLOPTTYPE_STRINGPOINT + 5 // "user:password;options" to use when fetching. 
CURLOPT_PROXYUSERPWD :: CURLOPTTYPE_STRINGPOINT + 6 // "user:password" to use with proxy.
CURLOPT_RANGE :: CURLOPTTYPE_STRINGPOINT + 7 // Range to get, specified as an ASCII string.
CURLOPT_READDATA :: CURLOPTTYPE_CBPOINT + 9 // Specified file stream to upload from (use as input):
CURLOPT_ERRORBUFFER :: CURLOPTTYPE_OBJECTPOINT + 10 // Buffer to receive error messages in, must be at least CURL_ERROR_SIZE bytes big.
// Function that will be called to store the output (instead of fwrite).
// The parameters will use fwrite() syntax, make sure to follow them.
CURLOPT_WRITEFUNCTION :: CURLOPTTYPE_FUNCTIONPOINT + 11
// Function that will be called to read the input (instead of fread). 
// The parameters will use fread() syntax, make sure to follow them.
CURLOPT_READFUNCTION :: CURLOPTTYPE_FUNCTIONPOINT + 12
CURLOPT_TIMEOUT :: CURLOPTTYPE_LONG + 13 // Time-out the read operation after this amount of seconds 

/* If CURLOPT_READDATA is used, this can be used to inform libcurl about
* how large the file being sent really is. That allows better error
* checking and better verifies that the upload was successful. -1 means
* unknown size.
*
* For large file support, there is also a _LARGE version of the key
* which takes an off_t type, allowing platforms with larger off_t
* sizes to handle larger files.  See below for INFILESIZE_LARGE.
*/
CURLOPT_INFILESIZE :: CURLOPTTYPE_LONG + 14
CURLOPT_POSTFIELDS :: CURLOPTTYPE_OBJECTPOINT + 15 // POST static input fields.
CURLOPT_REFERER :: CURLOPTTYPE_STRINGPOINT + 16 // Set the referrer page (needed by some CGIs)
// Set the FTP PORT string (interface name, named or numerical IP address) 
// Use i.e '-' to use default address.
CURLOPT_FTPPORT :: CURLOPTTYPE_STRINGPOINT + 17
CURLOPT_USERAGENT :: CURLOPTTYPE_STRINGPOINT + 18 // Set the User-Agent string (examined by some CGIs)
CURLOPT_HTTPHEADER :: CURLOPTTYPE_OBJECTPOINT + 23
CURLOPT_CAINFO :: CURLOPTTYPE_OBJECTPOINT + 65
CURLOPT_SSL_VERIFYHOST :: CURLOPTTYPE_LONG + 81

CURLOPT_VERBOSE :: CURLOPTTYPE_LONG + 41
CURLOPT_POST :: CURLOPTTYPE_LONG + 47
CURLOPT_FOLLOWLOCATION :: CURLOPTTYPE_LONG + 52
CURLOPT_POSTFIELDSIZE :: CURLOPTTYPE_LONG + 60
CURLOPT_TIMEOUT_MS :: CURLOPTTYPE_LONG + 155
CURLOPT_SSL_VERIFYPEER :: CURLOPTTYPE_LONG + 306
CURLOPT_DOH_SSL_VERIFYHOST :: CURLOPTTYPE_LONG + 307
CURLOPT_DOH_SSL_VERIFYSTATUS :: CURLOPTTYPE_LONG + 308
// curl option end
