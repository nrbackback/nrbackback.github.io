---
title: go zero使用记录
date: 2022-10-22 13:24:00
categories:
- golang
---
## 格式化api文件

```go
 goctl api format --dir=.  
```

## 根据.api文件生成swagger

安装：

```shell
GOPROXY=https://goproxy.cn/,direct go install github.com/zeromicro/goctl-swagger@latest
```

生成文件：

```shell
~/mylocalfile/aWork/code/packet-api >> goctl api plugin -plugin goctl-swagger="swagger -filename packet.json" -api service/packet/api/packet.api -dir doc
```

生成json文件的swagger文档后，Cmd+Shift+P后选择Preview Swagger，可以预览效果

## 创建微服务实战

### protoc的使用

如果使用any类型和value类型，需要类似如下操作，待补充：

参考了https://www.liwenzhou.com/posts/Go/protobuf/

```shell
goctl rpc protoc youwei.proto --go_out=./types --go-grpc_out=./types --zrpc_out=.   --proto_path=/Users/back/go/src/google/protobuf/src/  --proto_path=.
```

value类型的使用处转换方法参考如下： `count = int(value.GetNumberValue())`

如果想把int类型unmarshal到proto定义生成的字段，需要在proto里把字段定义为value类型而不是any类型，使用any类型会报错，value类型对于number string bool list这些单值都可以成功unmarshal。

proto定义参考如下：

```protobuf
syntax = "proto3";

import "google/protobuf/any.proto";
import "google/protobuf/struct.proto";

package p;

option go_package = "./p";

message Edge {
  map<string, google.protobuf.Any> properties = 1;
  google.protobuf.Value group_value = 2;
}
```

我发现修改proto或者模板之后重新用goctl生成的话，如果新生成的文件和原来生成的文件不同，也不会覆盖掉原来生成的文件，除非把原来生成的文件删掉。

## rpc服务启动太慢，调用rpc经常超时的解决

发现每次启动rpc服务的时候，都要好几秒才能启动成功。api服务调用rpc服务的接口，还经常超时，即使设置了5秒甚至10秒超时时间的context。

api服务启动也慢，不知道是不是因为api服务在启动中需要连接rpc服务，因为rpc太慢导致的。

。。。。。。。。。。。待补充
