---
title: 编写中，未定稿
draft: true  # 设置为草稿
date: 2023-01-01 11:00:00
categories:
- 数据库
---



我把代码复制到了 ~/我的本地文件/代码/fromweb 目录下了。目前clone了gin项目和go-gin-example项目。



8.19 正在阅读 go-gin-example 项目

读取配置和数据库初始化的过程，可以放在func init() 里，参考：

```go
func init() {
	setting.Setup() // 读取配置文件的所有部分，并对申明好了的全局配置变量赋值
	models.Setup() // 初始化mysql db，并自定义了Create Update Delete时的回调函数
	logging.Setup() // 初始化日志，是基于标准库里面的日志包初始化的
	gredis.Setup() // 初始化redis，包括设置连接redis时会调用的Dial函数
	util.Setup() // 设置pkg包里jwtSecret的值
}
```

init已经看完了，下面就是看 routers.InitRouter() 的具体内容

准备看   r.POST("/auth", api.GetAuth) 及之后的内容了。

项目里使用到了https://github.com/beego/beego框架，用了其validation包做数据验证，其他的包没有使用。

> beego框架可以用于开发包括传统的 Web 网站、API 服务、后台管理系统

validation包的使用方法可以参考：

```go
type auth struct {
	Username string `valid:"Required; MaxSize(50)"` // 这个地方要遵循 validation 的语法
	Password string `valid:"Required; MaxSize(50)"`
}
a := auth{Username: username, Password: password}
ok, _ := valid.Valid(&a)
```

用到了https://github.com/unknwon/com包，这个是针对 Go 编程语言常用函数的开源项目。



router目录存放了rest api的路由定义和rest api的rest部分，而且router的目录结构和路由的结构也是一样的

```shell
.
├── api
│   ├── auth.go
│   ├── upload.go
│   └── v1
│       ├── article.go
│       └── tag.go
└── router.go
```

























TODO

全局搜TODO tag，都是一些我没有看懂的逻辑



































