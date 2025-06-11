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
easyGet :: proc(
	url: string,
	headers: []string = {},
	caPath: string = "",
	verbose: bool = true,
	pcap: int = 4096,
) -> ^Easy {
	easy := easyNew(pcap)

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
	return easy
}

// simple post request
// 简单post请求
easyPost :: proc(
	url: string,
	headers: []string = {},
	body: []byte = {},
	caPath: string = "",
	verbose: bool = true,
	pcap: int = 4096,
) -> ^Easy {
	easy := easyNew(pcap)

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
	return easy
}

easyNew :: proc(pcap: int = 4096) -> ^Easy {
	easy := new(Easy)
	easy.cURL = easy_init()
	easy.headers = headerNew()

	easy.buf = make([dynamic]u8, 0, pcap)
	return easy
}

easyFree :: proc(easy: ^Easy) {
	easy_cleanup(easy.cURL)
	headerFreeAll(easy.headers)

	delete(easy.buf)
	free(easy)
}

easyOkOrWarn :: proc(code: int, procName: string) {
	if CURLcode(code) != .CURLE_OK {
		log.warnf("set %s failed, code=%d, msg=%s", procName, code, easy_strerror(code))
	}
}

easySetPost :: proc(easy: ^Easy) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_POST, 1), #procedure)
}

easySetUrl :: proc(easy: ^Easy, url: string) {
	// 类似这种情况, 看起来delete url也会被正确传递过去, 不确定odin做了什么, 理论上delete后url如果是一个地址的话数据应该会被释放
	url := strings.clone_to_cstring(url)
	defer delete(url)

	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_URL, url), #procedure)
}

easySetFollowLocation :: proc(easy: ^Easy) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_FOLLOWLOCATION, 1), #procedure)
}

easySetCaInfo :: proc(easy: ^Easy, caPath: string) {
	path := strings.clone_to_cstring(caPath)
	defer delete(path)

	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_CAINFO), #procedure)
}

easySetVerbose :: proc(easy: ^Easy) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_VERBOSE, 1), #procedure)
}

easySetTimeoutMS :: proc(easy: ^Easy, timeout: u64) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_TIMEOUT_MS, timeout), #procedure)
}

easySetTimeout :: proc(easy: ^Easy, timeout: u64) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_TIMEOUT, timeout), #procedure)
}

easySetHeader :: proc(easy: ^Easy) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, easy.headers.inner), #procedure)
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
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_WRITEFUNCTION, writeFn), #procedure)
}

easySetWriteData :: proc(easy: ^Easy, writeData: ^[dynamic]u8) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_WRITEDATA, writeData), #procedure)
}

easySetPostFieldSize :: proc(easy: ^Easy, size: uint) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_POSTFIELDSIZE, size), #procedure)
}

easySetPostFields :: proc(easy: ^Easy, data: []byte) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_POSTFIELDS, data), #procedure)
}

easyClearHeader :: proc(easy: ^Easy) {
	easyOkOrWarn(easy_setopt(easy.cURL, CURLOPT_HTTPHEADER, nil), #procedure)
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

	easyOkOrWarn(easy_perform(easy.cURL), #procedure)
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
	// fmt.printfln("size=%d, nitems=%d, buf=%s", size, nitems, data)
	// fmt.printfln("size=%d, nitems=%d", size, nitems)
	append(output, data)
	return dataLen
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
	defer delete(cstr)

	hl.inner = slist_append(hl.inner, cstr)
	return hl
}
