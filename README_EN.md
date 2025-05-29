# odin-libcurl
Odin bindings for libcurl

They are based on curl 8.8.0 version.

# Dependencies
- curl static library [link](https://github.com/curl/curl)  

# Tested platforms
- Windows using Microsoft Visual Studio 2022 64-bit.(cl version 19.29.30158)

# Usage
1. `git clone ` this
2. Add the path of `libcurl` to the corresponding `foreign import curl {` below
  - build `libcurl` on windows
    1. open the `x64 Native Tools Command Prompt for VS 2019`, or other versions, change dir to the source of the curl
    2. `set RTLIBCFG=static`
    3. `nmake /f Makefile.vc mode=static`, you can add others params, see `winbuild/README.md` in the source of the curl
3. `import curl "odin-curl"`
4. (optional)set log procedure(`core:log`) to print logs
5. get start, for example:  
```odin
// set logger procedure
my_logger_proc :: proc(
	data: rawptr,
	level: runtime.Logger_Level,
	text: string,
	options: runtime.Logger_Options,
	location := #caller_location,
) {
	fmt.printfln(text)
}
// set current logger
context.logger.procedure = my_logger_proc

Query :: struct {
	taskId: string `json:"task_id,omitempty"`,
}

// encode to json
q: Query = {
  taskId = "6d50114b-1c13-4cd6-954e-99c5c5385a17",
}
data, _ := json.marshal(q)
// post request
res := curl.easyPost(
  "https://xxx/xxx/xxx",
  {"Content-Type: application/json"},
  body = data,
  caPath = "",
  verbose = false,
  bufCap = 10000, // if data is too long, set bufCap, default 4096
)
// decode response body
ress := Res{}
err := json.unmarshal(res[:], &ress)
if err != nil {
  fmt.eprintfln("unmarshal failed, err=%v, res=%s", err, res)
  return
}
// process ress
```

# Known Issues
1. might returns error code 23: Failed writing received data to disk/application, 见[curl issune](https://github.com/curl/curl/issues/5200), doesn't seem to affect the results
