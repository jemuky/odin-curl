package curl

import "core:c"
import "core:log"
import "core:strings"

/*
the simple wrapper for the easy
简单的curl easy客户端的包装

To avoid conflicts with curl, both are named in camelCase
避免与curl自带函数名称混淆，都命名为小驼峰
*/

Easy :: struct {
	cURL:    CURL,
	buf:     [dynamic]u8,
	headers: ^HeaderList,
}

// simple get request
// 简单get请求
Easy_get :: proc(
	url: string,
	headers: []string = {},
	caPath: string = "",
	verbose: bool = true,
	pcap: int = 4096,
) -> ^Easy {
	easy := Easy_new(pcap)

	Easy_append_headers(easy, headers)
	Easy_set_url(easy, url)
	if len(caPath) > 0 {
		Easy_set_ca_info(easy, caPath)
	} else {
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYPEER, 0)
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYHOST, 0)
	}
	Easy_set_get_data(easy)
	if verbose {
		Easy_verbose(easy)
	}
	Easy_perform(easy)
	if verbose {
		log.infof("receive data: %s", easy.buf)
	}
	return easy
}

// simple post request
// 简单post请求
Easy_post :: proc(
	url: string,
	headers: []string = {},
	body: []byte = {},
	caPath: string = "",
	verbose: bool = true,
	pcap: int = 4096,
) -> ^Easy {
	easy := Easy_new(pcap)

	Easy_append_headers(easy, headers)

	Easy_set_url(easy, url)
	if len(caPath) > 0 {
		Easy_set_ca_info(easy, caPath)
	} else {
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYPEER, 0)
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYHOST, 0)
	}
	Easy_set_post_data(easy, body)
	if verbose {
		Easy_verbose(easy)
	}
	Easy_perform(easy)
	if verbose {
		log.infof("receive data: %s", easy.buf)
	}
	return easy
}

Easy_new :: proc(pcap: int = 4096) -> ^Easy {
	easy := new(Easy)
	easy.cURL = easy_init()
	easy.headers = Header_new()

	easy.buf = make([dynamic]u8, 0, pcap)
	return easy
}

Easy_free :: proc(easy: ^Easy) {
	easy_cleanup(easy.cURL)
	Header_free_all(easy.headers)

	delete(easy.buf)
	free(easy)
}

easy_ok_or_warn :: proc(code: int, procName: string) {
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set %s failed, code=%d, msg=%s", procName, code, easy_strerror(code))
	}
}

Easy_set_post :: proc(easy: ^Easy) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_POST, 1), #procedure)
}

Easy_set_url :: proc(easy: ^Easy, url: string) {
	// 类似这种情况, 看起来delete url也会被正确传递过去, 不确定odin做了什么, 理论上delete后url如果是一个地址的话数据应该会被释放
	url := strings.clone_to_cstring(url)
	defer delete(url)

	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_URL, url), #procedure)
}

Easy_set_follow_location :: proc(easy: ^Easy) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_FOLLOWLOCATION, 1), #procedure)
}

Easy_set_ca_info :: proc(easy: ^Easy, caPath: string) {
	path := strings.clone_to_cstring(caPath)
	defer delete(path)

	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_CAINFO), #procedure)
}

Easy_verbose :: proc(easy: ^Easy) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_VERBOSE, 1), #procedure)
}

Easy_set_timeout_ms :: proc(easy: ^Easy, timeout: u64) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_TIMEOUT_MS, timeout), #procedure)
}

Easy_set_timeout :: proc(easy: ^Easy, timeout: u64) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_TIMEOUT, timeout), #procedure)
}

Easy_set_header :: proc(easy: ^Easy) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, easy.headers.inner), #procedure)
}

Easy_set_write_function :: proc(
	easy: ^Easy,
	writeFn: proc(
		buffer: cstring,
		size: c.size_t,
		nitems: c.size_t,
		output: ^[dynamic]u8,
	) -> c.size_t,
) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_WRITEFUNCTION, writeFn), #procedure)
}

Easy_set_write_data :: proc(easy: ^Easy, writeData: ^[dynamic]u8) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_WRITEDATA, writeData), #procedure)
}

Easy_set_post_field_size :: proc(easy: ^Easy, size: uint) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_POSTFIELDSIZE, size), #procedure)
}

Easy_set_post_fields :: proc(easy: ^Easy, data: []byte) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_POSTFIELDS, data), #procedure)
}

Easy_clear_header :: proc(easy: ^Easy) {
	easy_ok_or_warn(easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, nil), #procedure)
	Header_free_all(easy.headers)
}

Easy_add_header :: proc(easy: ^Easy, header: string) {
	Header_append(easy.headers, header)
}

Easy_append_headers :: proc(easy: ^Easy, headers: []string) {
	for header in headers {
		Easy_add_header(easy, header)
	}
}

Easy_set_get_data :: proc(easy: ^Easy) {
	Easy_set_follow_location(easy)
	Easy_set_write_function(easy, easy_default_write_fn)
	Easy_set_write_data(easy, &easy.buf)
}

Easy_set_post_data :: proc(easy: ^Easy, data: []byte) {
	Easy_set_post(easy)
	Easy_set_follow_location(easy)

	Easy_set_write_function(easy, easy_default_write_fn)
	Easy_set_write_data(easy, &easy.buf)

	Easy_set_post_field_size(easy, len(data))
	Easy_set_post_fields(easy, data)
}

Easy_perform :: proc(easy: ^Easy) {
	Easy_set_header(easy)

	easy_ok_or_warn(easy_perform(easy.cURL), #procedure)
}

easy_default_write_fn :: proc(
	buffer: cstring,
	size: c.size_t,
	nitems: c.size_t,
	output: ^[dynamic]u8,
) -> c.size_t {
	if output == nil {return 0}
	dataLen := size * nitems
	data := (string(buffer))[:dataLen]
	// fmt.printfln("size=%d, nitems=%d, buf=%s", size, nitems, data)
	// fmt.printfln("size=%d, nitems=%d", size, nitems)
	append(output, data)
	return dataLen
}

HeaderList :: struct {
	inner: curl_slist,
}

Header_new :: proc() -> ^HeaderList {
	hl := new(HeaderList)
	hl.inner = nil
	return hl
}

Header_free_all :: proc(hl: ^HeaderList) {
	slist_free_all(hl.inner)
	free(hl)
}

Header_append :: proc(hl: ^HeaderList, header: string) -> ^HeaderList {
	cstr := strings.clone_to_cstring(header)
	defer delete(cstr)

	hl.inner = slist_append(hl.inner, cstr)
	return hl
}
