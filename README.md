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
    3. `nmake /f Makefile.vc mode=static`
3. `import curl "odin-curl"`
4. (optional)set logFunc(`core:log`) to print logs
5. use
```odin
Query :: struct {
	taskId: string `json:"task_id,omitempty"`,
}

q: Query = {
  taskId = "6d50114b-1c13-4cd6-954e-99c5c5385a17",
}
data, _ := json.marshal(q)
res := curl.easyPost(
  "https://xxx/xxx/xxx",
  {"Content-Type: application/json"},
  body = data,
  caPath = "",
  verbose = false,
)
ress := Res{}
err := json.unmarshal(res[:], &ress)
if err != nil {
  fmt.eprintfln("unmarshal failed, err=%v, res=%s", err, res)
  return
}
// process ress
```

# Known Issues
1. The longer data might not receive the whole data
