# odin-curl
libcurl 的odin语言绑定

基于curl 8.8.0.

# 依赖于
- curl静态库 [链接](https://github.com/curl/curl)  

# 测试平台
- Windows用`Microsoft Visual Studio 2022 64位`.(cl版本19.29.30158)

# 用法
1. 用git克隆当前仓库
2. 加`libcurl`库到对应系统标识下的`foreign import curl {`
  - 构建windows版本的`libcurl`
    1. 使用`win+q`打开`x64 Native Tools Command Prompt for VS 2019`, 或者其他版本如`x64 Native Tools Command Prompt for VS 2022`等, cd到在curl源码路径下
    2. 输入`set RTLIBCFG=static`
    3. 输入`nmake /f Makefile.vc mode=static`, 可以添加别的参数, 参见curl源码路径下`winbuild/README.md`
3. 在自己项目中导入当前仓库, `import curl "odin-curl"`
4. (可选)设置log的过程(函数)(`core:log`)用来打印一些日志, 默认log不做任何事, 当前仓库使用了`log.warnf`, 在`easyGet`和`easyPost`时指定`verbose`参数时使用了`log.infof`
5. 开始使用, 见下面例子
```odin
// 设置日志
logger := log.create_console_logger()
defer log.destroy_console_logger(logger)
context.logger = logger

// 请求结构
Query :: struct {
	taskId: string `json:"task_id,omitempty"`,
}

q: Query = {
  taskId = "6d50114b-1c13-4cd6-954e-99c5c5385a17",
}
// 请求编码为json
data, _ := json.marshal(q)
// post请求
easy := curl.Easy_post(
  "https://xxx/xxx/xxx",
  {"Content-Type: application/json"},
  body = data,
  caPath = "",
  verbose = false,
  pcap = 2048, // 预先设置容量，默认4096
)
defer curl.Easy_free(easy)
// 解码
res := Res{}
err := json.unmarshal(easy.buf[:], &res)
if err != nil {
  fmt.eprintfln("unmarshal failed, err=%v, res=%s", err, res)
  return
}
// 处理json解码后的结构数据res
```

# 已知问题
1. 在`curl_easy_perform`时可能会返回错误码`23: Failed writing received data to disk/application`, 见[curl issue](https://github.com/curl/curl/issues/5200), 服务端返回, 看起来不会影响结果
