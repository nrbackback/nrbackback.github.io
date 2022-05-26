---
title: prometheus入门
date: 2021-5-26 17:38:00
categories:
- 运维
---

## Go Application

例子来源于<https://prometheus.io/docs/guides/go-application/，用到了官方client：https://github.com/prometheus/client_golang>

prometheus有一个官方Go客户端库，可以用它来检测Go程序。下面这个例子中，会创建一个go应用，该应用将指标数据通过HTTP传送给prometheus。

```go
package main

import (
        "net/http"

        "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
        http.Handle("/metrics", promhttp.Handler())
        http.ListenAndServe(":2112", nil)
}
```

增加自定义指标myapp_processed_ops_total：

```go
package main

import (
        "net/http"
        "time"

        "github.com/prometheus/client_golang/prometheus"
        "github.com/prometheus/client_golang/prometheus/promauto"
        "github.com/prometheus/client_golang/prometheus/promhttp"
)

func recordMetrics() {
        go func() {
                for {
                        opsProcessed.Inc()
                        time.Sleep(2 * time.Second)
                }
        }()
}

var (
        opsProcessed = promauto.NewCounter(prometheus.CounterOpts{
                Name: "myapp_processed_ops_total",
                Help: "The total number of processed events",
               // ConstLabels: prometheus.Labels(map[string]string{"date": "Thursday"}),
        })
)

func main() {
        recordMetrics()

        http.Handle("/metrics", promhttp.Handler())
        http.ListenAndServe(":2112", nil)
}
```

## 我写的exporter

```go
package main

import (
 "fmt"
 "net/http"
)

func main() {
 http.HandleFunc("/metrics", HelloServer)
 http.ListenAndServe(":7777", nil)
}

var t = `# HELP myapp_processed_ops_total1 The total number of processed events
# TYPE myapp_processed_ops_total1 counter
myapp_processed_ops_total1{date="Thursday"} 1622`

func HelloServer(w http.ResponseWriter, r *http.Request) {
 fmt.Fprintf(w, t)
}
```

这个demo的metrics数据可以被prometheus成功获取。

似乎只要实现metrics，返回结构化的数据就可以了。

PS：返回数据

![WX20220526-173011@2x.png](http://tva1.sinaimg.cn/large/006gLprLgy1h2lxrjsnwwj31iu0oadmi.jpg)

![WX20220526-172920@2x.png](http://tva1.sinaimg.cn/large/006gLprLgy1h2lxqws4xxj31ko0q6dll.jpg)
