---
title: pprof使用
date: 2023-4-13 17:38:00
tags:
- 原创
categories:
- golang
---

## 作用

pprof可以用来分析程序的性能，pprof 有以下 4 种类型：

- CPU profiling（CPU 性能分析）：这是最常使用的一种类型。用于分析函数或方法的执行耗时；用于找出哪些函数或代码片段消耗了大量的 CPU 时间。
- Memory profiling：也常使用。用于分析程序的内存占用情况；
- Block profiling：这是 Go 独有的，用于记录 goroutine 在等待共享资源花费的时间；
- Mutex profiling：与 Block profiling 类似，但是只记录因为锁竞争导致的等待或延迟。

## 使用

### 基本使用

#### 启动

引用pprof包

单独启动一个pprof的HTTP服务，如果之前没有启动http服务，可以启动一个pprof的单独goroutine，如下：

```go
go func() {
	http.ListenAndServe("localhost:6060", nil)
}()
```

比如下面之前没有启动http服务，下面的代码没有启动单独的goroutine而是只启动了一个可以pprof的服务：

```go
package main

import (
	"net/http"
	_ "net/http/pprof"
)

func main() {
	http.ListenAndServe("localhost:8080", nil) // Start the HTTP server on port 8080
}
```

如果之前已经启动了http服务，那么在http服务的/debug/pprof路由可以查看pprof的结果，如下：

```go
package main

import (
	"fmt"
	"net/http"
	_ "net/http/pprof"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello, World!") // Send "Hello, World!" as the response
	})
	http.ListenAndServe("localhost:8080", nil) // Start the HTTP server on port 8080
}
```

#### 查看

程序启动后，查看 http://localhost:8080/debug/pprof，可以看到

![image-20230413103046287](/Users/rhettnina/Library/Application Support/typora-user-images/image-20230413103046287.png)

### CPU profiling（CPU分析）

`pprof` 的 CPU profiling 结果包括以下信息：

1. 函数耗时：可以看到每个函数在 CPU 上的运行耗时，包括累计 CPU 时间和 CPU 时间百分比。
2. 函数调用关系：可以查看函数之间的调用关系，了解函数之间的调用深度和调用频率。
3. 内联函数：可以看到哪些函数在编译时被内联展开，以及内联展开后的耗时。
4. 热点函数：可以查看耗时最高的函数，帮助你找到可能的性能瓶颈。
5. 执行栈信息：可以查看每个函数在被调用时的执行栈信息，帮助你定位耗时较高的代码路径。
6. 源代码位置：可以查看每个函数在源代码中的位置，帮助你定位到具体的代码行。

CPU profiling 结果可能会受到多种因素的影响，例如采样频率、运行环境等，因此在分析 profiling 结果时要结合实际情况进行综合判断。

pprof会分析pprof.StartCPUProfile()到pprof.StopCPUProfile()之间的所有代码，所以可以在StartCPUProfile执行defer StopCPUProfile，可以分析出StartCPUProfile后执行的所有代码。

StartCPUProfile接收一个io.Writer类型的参数，pprof会将分析的结果写到这个参数里。

#### 启动

```go
package main

import (
	"fmt"
	"math/rand"
	"os"
	"runtime/pprof"
	"time"
)

func busyLoop() {
	for i := 0; i < 10000000; i++ {
		rand.Intn(100)
	}
}

func slowFunction() {
	time.Sleep(time.Second)
}

func main() {
	// 创建一个文件用于保存 profiling 数据
	f, err := os.Create("profile.prof")
	if err != nil {
		fmt.Println("无法创建文件:", err)
		return
	}
	defer f.Close()

	// 开始 CPU profiling
	err = pprof.StartCPUProfile(f)
	if err != nil {
		fmt.Println("无法开始 CPU profiling:", err)
		return
	}
	defer pprof.StopCPUProfile()

	// 模拟一个耗时的函数
	slowFunction()

	// 模拟一个消耗 CPU 的循环
	busyLoop()

	// 生成一些 profiling 数据
	for i := 0; i < 10; i++ {
		busyLoop()
	}

	fmt.Println("CPU profiling 已经停止，结果保存在 profile.prof 文件中。")
}
```

#### 查看与分析

程序执行完毕后，会生成一个profile.prof文件，可以分析这个文件来知晓刚刚执行的情况。

执行 `go tool pprof profile.prof`，会出现一个命令交互界面：

```shell
go tool pprof profile.prof
Type: cpu
Time: Apr 13, 2023 at 11:08am (CST)
Duration: 3.43s, Total samples = 2.01s (58.68%)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) 
```

可以输出一些命令，如输入top查看耗时最高的10个函数

```shell
go tool pprof profile.prof
Type: cpu
Time: Apr 13, 2023 at 11:08am (CST)
Duration: 3.43s, Total samples = 2.01s (58.68%)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) top
Showing nodes accounting for 2010ms, 100% of 2010ms total
Showing top 10 nodes out of 12
      flat  flat%   sum%        cum   cum%
     760ms 37.81% 37.81%     1340ms 66.67%  math/rand.(*lockedSource).Int63
     450ms 22.39% 60.20%     1790ms 89.05%  math/rand.(*Rand).Int31n
     450ms 22.39% 82.59%      450ms 22.39%  sync.(*Mutex).Unlock (inline)
     190ms  9.45% 92.04%     1980ms 98.51%  math/rand.(*Rand).Intn
      90ms  4.48% 96.52%       90ms  4.48%  math/rand.(*rngSource).Uint64 (inline)
      40ms  1.99% 98.51%      130ms  6.47%  math/rand.(*rngSource).Int63 (inline)
      30ms  1.49%   100%     2010ms   100%  main.busyLoop (inline)
         0     0%   100%     2010ms   100%  main.main
         0     0%   100%     1340ms 66.67%  math/rand.(*Rand).Int31 (inline)
         0     0%   100%     1340ms 66.67%  math/rand.(*Rand).Int63 (inline)
```

默认显示耗时最高的10个函数，也可以执行top1 top3这样的topN获取耗时最高的N个函数。

执行`list xx`查看函数某个函数的各个模块调用耗时：

```shell
(pprof) list  main.main
Total: 2.01s
ROUTINE ======================== main.main in /Users/rhettnina/我的本地文件/a工作/code/work-assist/pprof/main.go
         0      2.01s (flat, cum)   100% of Total
         .          .     37:
         .          .     38:   // 模拟一个耗时的函数
         .          .     39:   slowFunction()
         .          .     40:
         .          .     41:   // 模拟一个消耗 CPU 的循环
         .      180ms     42:   busyLoop()
         .          .     43:
         .          .     44:   // 生成一些 profiling 数据
         .          .     45:   for i := 0; i < 10; i++ {
         .      1.83s     46:           busyLoop()
         .          .     47:   }
         .          .     48:
         .          .     49:   fmt.Println("CPU profiling 已经停止，结果保存在 profile.prof 文件中。")
         .          .     50:}
```

可以看到main里的各个部分的函数分别耗时多少。

PS：有的时候执行top显示为空，是因为因为启用 CPU profiling 之后，运行时每隔 10ms 会中断一次，记录每个 goroutine 当前执行的堆栈，以此来分析耗时。如果程序在10ms内执行完毕了，可能就不会记录到任何信息，所以top命令显示为空。

### Memory profiling（内存分析）

`pprof` 的 Memory profiling 结果包括以下信息：

1. 内存分配：可以查看每个函数或代码片段在内存中分配的对象数量、大小、内存分配的累计字节数等信息，帮助你了解每个函数的内存分配情况。
2. 内存使用：可以查看每个函数或代码片段在内存中使用的对象数量、大小、内存使用的累计字节数等信息，帮助你了解每个函数的内存使用情况。
3. 内存释放：可以查看每个函数或代码片段在内存中释放的对象数量、大小、内存释放的累计字节数等信息，帮助你了解每个函数的内存释放情况。
4. 内存分配堆栈：可以查看每个函数在内存分配时的堆栈信息，帮助你定位到内存分配较高的代码路径。
5. 内存使用堆栈：可以查看每个函数在内存使用时的堆栈信息，帮助你定位到内存使用较高的代码路径。

#### 启动

下面是两个比较常用的函数。

`pprof.Lookup("heap")`这是一个 pprof 提供的用于获取**堆内存分析数据的函数**。通过这个函数，我们可以获得用于 heap（堆）的 Memory profiling 数据。

`WriteTo(f, 0)`：这是将堆内存分析数据写入到文件（f）中的操作。`f` 是一个已经创建好的文件对象，`0` 是指导写入的标志位，其中 0 表示默认标志位，用于输出完整的内存分析数据。

```go
package main

import (
	"fmt"
	"os"
	"runtime/pprof"
)

func main() {
	// 创建一个文件用于存储 pprof 输出
	f, err := os.Create("mem.prof")
	if err != nil {
		fmt.Println("Failed to create profile file:", err)
		return
	}
	defer f.Close()

	// 开始 Memory profiling
	// WriteHeapProfile是Lookup("heap").WriteTo(w, 0)的缩写
	if err := pprof.WriteHeapProfile(f); err != nil {
		fmt.Println("Failed to start memory profiling:", err)
		return
	}
	// 模拟一个占用内存的操作
	var s []byte
	for i := 0; i < 1000000; i++ {
		s = append(s, byte(i))
	}
	// 结束 Memory profiling
	pprof.StopCPUProfile()
	fmt.Println("Memory profiling completed. Output saved to mem.prof")
}
```

#### 查看与分析

与上面的CPU profiling进行的运行时间分析不同，这里分析的是内存占用大小，所以数据统计维度是内存的占用大小。比如执行top会列出占用内存最多的函数，list 函数名会列出这个函数的各个部分占用了多少内存。

```shell
o tool pprof mem.prof  
Type: inuse_space
Time: Apr 13, 2023 at 2:36pm (CST)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) top
Showing nodes accounting for 1536.81kB, 100% of 1536.81kB total
Showing top 10 nodes out of 14
      flat  flat%   sum%        cum   cum%
  512.56kB 33.35% 33.35%   512.56kB 33.35%  runtime.allocm
  512.20kB 33.33% 66.68%   512.20kB 33.33%  runtime.malg
  512.05kB 33.32%   100%   512.05kB 33.32%  runtime.main
         0     0%   100%   512.56kB 33.35%  runtime.mstart
         0     0%   100%   512.56kB 33.35%  runtime.mstart0
         0     0%   100%   512.56kB 33.35%  runtime.mstart1
         0     0%   100%   512.56kB 33.35%  runtime.newm
         0     0%   100%   512.20kB 33.33%  runtime.newproc.func1
         0     0%   100%   512.20kB 33.33%  runtime.newproc1
         0     0%   100%   512.56kB 33.35%  runtime.resetspinning
(pprof) list runtime.allocm
Total: 1.50MB
ROUTINE ======================== runtime.allocm in /usr/local/Cellar/go@1.17/1.17.12/libexec/src/runtime/proc.go
  512.56kB   512.56kB (flat, cum) 33.35% of Total
         .          .   1870:           }
         .          .   1871:           sched.freem = newList
         .          .   1872:           unlock(&sched.lock)
         .          .   1873:   }
         .          .   1874:
  512.56kB   512.56kB   1875:   mp := new(m)
         .          .   1876:   mp.mstartfn = fn
         .          .   1877:   mcommoninit(mp, id)
         .          .   1878:
         .          .   1879:   // In case of cgo or Solaris or illumos or Darwin, pthread_create will make us a stack.
         .          .   1880:   // Windows and Plan 9 will layout sched stack on OS stack.
(pprof) list runtime.main
Total: 1.50MB
ROUTINE ======================== runtime.main in /usr/local/Cellar/go@1.17/1.17.12/libexec/src/runtime/proc.go
  512.05kB   512.05kB (flat, cum) 33.32% of Total
         .          .    211:           }
         .          .    212:   }()
         .          .    213:
         .          .    214:   gcenable()
         .          .    215:
  512.05kB   512.05kB    216:   main_init_done = make(chan bool)
         .          .    217:   if iscgo {
         .          .    218:           if _cgo_thread_start == nil {
         .          .    219:                   throw("_cgo_thread_start missing")
         .          .    220:           }
         .          .    221:           if GOOS != "windows" {
```

## 火焰图

### 简介

火焰图可以清楚看到上述的CPU profiling和Memory profiling二者的效果



### 使用

对于上述生成的分析文件，执行

```
go tool pprof -http :8080 cpu.profile
```

执行`brew install graphviz`，在 http://localhost:8080/ui/ 查看

![image-20230413153052155](../images/image-20230413153052155.png)

可点击最上面的菜单View查看其他维度的分析。查看火焰图。

![image-20230413153457756](../images/image-20230413153457756.png)

## 其他

关于CPU profiling和Memory profiling的三方包推荐 https://github.com/pkg/profile
