package curl

import "core:c"
import "core:fmt"
import "core:log"
import "core:mem"
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

// simple get request, if response's size > 4096, set bufCap to receive the whole data
// 简单get请求, 如果预料回包比较大的时候, 必须正确设置bufCap，让bufCap大小大于回包总数据大小
easyGet :: proc(
	url: string,
	headers: []string = {},
	caPath: string = "",
	verbose: bool = true,
	bufCap: int = 4096,
) -> []u8 {
	easy := easyNew(bufCap)
	defer easyFree(easy)

	easyAppendHeaders(easy, headers)
	easySetUrl(easy, url)
	if len(caPath) > 0 {
		easySetCaInfo(easy, caPath)
	} else {
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYPEER, 0)
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYHOST, 0)
	}
	easySetGetData(easy)
	if verbose {
		easySetVerbose(easy)
	}
	easyPerform(easy)
	if verbose {
		log.infof("receive data: %s", easy.buf)
	}
	return easy.buf[:]
}

// simple post request, if response's size > 4096, set bufCap to receive the whole data
// 简单post请求, 如果预料回包比较大的时候, 必须正确设置bufCap，让bufCap大小大于回包总数据大小
easyPost :: proc(
	url: string,
	headers: []string = {},
	body: []byte = {},
	caPath: string = "",
	verbose: bool = true,
	bufCap: int = 4096,
) -> []u8 {
	easy := easyNew(bufCap)
	defer easyFree(easy)
	easyAppendHeaders(easy, headers)

	easySetUrl(easy, url)
	if len(caPath) > 0 {
		easySetCaInfo(easy, caPath)
	} else {
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYPEER, 0)
		easy_setopt(easy.cURL, CURLOPT_SSL_VERIFYHOST, 0)
	}
	easySetPostData(easy, body)
	if verbose {
		easySetVerbose(easy)
	}
	easyPerform(easy)
	if verbose {
		log.infof("receive data: %s", easy.buf)
	}
	return easy.buf[:]
}

easyNew :: proc(bufCap: int = 4096) -> ^Easy {
	easy := new(Easy)
	easy.cURL = easy_init()
	easy.headers = headerNew()
	// 不设置容量会导致比较长的数据不能接收完全
	// if you don't set cap, the longer data might not receive the whole data

	// resolve can't receive the whole data
	arena := &mem.Dynamic_Arena{}
	mem.dynamic_arena_init(arena)
	context.allocator = mem.dynamic_arena_allocator(arena)

	easy.buf = make([dynamic]u8, 0, bufCap)
	return easy
}

easyFree :: proc(easy: ^Easy) {
	easy_cleanup(easy.cURL)
	headerFreeAll(easy.headers)

	delete(easy.buf)
	free(easy)
}

easySetPost :: proc(easy: ^Easy) {
	code := easy_setopt(easy.cURL, CURLOPT_POST, 1)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set post failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetUrl :: proc(easy: ^Easy, url: string) {
	// 类似这种情况, 看起来mem.free后url也会被正确传递过去, 不确定odin做了什么, 理论上free后url如果是一个地址的话数据应该会被释放
	url := strings.clone_to_cstring(url)
	defer mem.free(rawptr(url))

	code := easy_setopt(easy.cURL, CURLOPT_URL, url)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set url failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetFollowLocation :: proc(easy: ^Easy) {
	code := easy_setopt(easy.cURL, CURLOPT_FOLLOWLOCATION, 1)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set follow_location failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetCaInfo :: proc(easy: ^Easy, caPath: string) {
	path := strings.clone_to_cstring(caPath)
	defer mem.free(rawptr(path))

	code := easy_setopt(easy.cURL, CURLOPT_CAINFO)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set ca_info failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetVerbose :: proc(easy: ^Easy) {
	code := easy_setopt(easy.cURL, CURLOPT_VERBOSE, 1)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set verbose failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetTimeoutMS :: proc(easy: ^Easy, timeout: u64) {
	code := easy_setopt(easy.cURL, CURLOPT_TIMEOUT_MS, timeout)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set timeout_ms failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetTimeout :: proc(easy: ^Easy, timeout: u64) {
	code := easy_setopt(easy.cURL, CURLOPT_TIMEOUT, timeout)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set timeout failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetHeader :: proc(easy: ^Easy) {
	code := easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, easy.headers.inner)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set header failed, code=%d, msg=%s", code, easy_strerror(code))
		return
	}
}

easySetWriteFunction :: proc(
	easy: ^Easy,
	writeFn: proc(
		buffer: cstring,
		size: c.size_t,
		nitems: c.size_t,
		output: ^[dynamic]u8,
	) -> c.size_t,
) {
	code := easy_setopt(easy.cURL, CURLOPT_WRITEFUNCTION, writeFn)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set write_function failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetWriteData :: proc(easy: ^Easy, writeData: ^[dynamic]u8) {
	code := easy_setopt(easy.cURL, CURLOPT_WRITEDATA, writeData)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set write_data failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetPostFieldSize :: proc(easy: ^Easy, size: uint) {
	code := easy_setopt(easy.cURL, CURLOPT_POSTFIELDSIZE, size)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set post_field_size failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easySetPostFields :: proc(easy: ^Easy, data: []byte) {
	code := easy_setopt(easy.cURL, CURLOPT_POSTFIELDS, data)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set post_field failed, code=%d, msg=%s", code, easy_strerror(code))
	}
}

easyClearHeader :: proc(easy: ^Easy) {
	code := easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, nil)
	if CURLcode(code) != .CURLE_OK {
		log.warnf("clear header failed, code=%d, msg=%s", code, easy_strerror(code))
		return
	}
	headerFreeAll(easy.headers)
}

easyAddHeader :: proc(easy: ^Easy, header: string) {
	headerAppend(easy.headers, header)
}

easyAppendHeaders :: proc(easy: ^Easy, headers: []string) {
	for header in headers {
		easyAddHeader(easy, header)
	}
}

easySetGetData :: proc(easy: ^Easy) {
	easySetFollowLocation(easy)
	easySetWriteFunction(easy, easyDefaultWriteFn)
	easySetWriteData(easy, &easy.buf)
}

easySetPostData :: proc(easy: ^Easy, data: []byte) {
	easySetPost(easy)
	easySetFollowLocation(easy)

	easySetWriteFunction(easy, easyDefaultWriteFn)
	easySetWriteData(easy, &easy.buf)

	easySetPostFieldSize(easy, len(data))
	easySetPostFields(easy, data)
}

easyPerform :: proc(easy: ^Easy) {
	easySetHeader(easy)
	code := easy_perform(easy.cURL)
	if CURLcode(code) != .CURLE_OK {
		// might returns error code 23: Failed writing received data to disk/application, doesn't seem to affect the results
		log.warnf("perform failed, code=%d, msg=%s", code, easy_strerror(code))
		return
	}
}

easyDefaultWriteFn :: proc(
	buffer: cstring,
	size: c.size_t,
	nitems: c.size_t,
	output: ^[dynamic]u8,
) -> c.size_t {
	if output == nil {return 0}
	dataLen := size * nitems
	data := (string(buffer))[:dataLen]
	// fmt.printfln("size=%d, nitems=%d, buf=%v, output=%v", size, nitems, data, output == nil)
	append(output, data)
	return len(output)
}

HeaderList :: struct {
	inner: curl_slist,
}

headerNew :: proc() -> ^HeaderList {
	hl := new(HeaderList)
	hl.inner = nil
	return hl
}

headerFreeAll :: proc(hl: ^HeaderList) {
	slist_free_all(hl.inner)
	free(hl)
}

headerAppend :: proc(hl: ^HeaderList, header: string) -> ^HeaderList {
	cstr := strings.clone_to_cstring(header)
	defer mem.free(rawptr(cstr))

	hl.inner = slist_append(hl.inner, cstr)
	return hl
}
