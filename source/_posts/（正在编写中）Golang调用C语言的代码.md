---
title: Golang调用C语言的代码
draft: true  # 设置为草稿
date: 2024-04-17 11:00:00
categories:
- Golang
---

一般在Golang中调用C都是因为Golang的代码性能遇到瓶颈，所以该用运行速度更快的C代替之前Golang写的瓶颈部分代码。或者在想要用的功能Golang没有三方包而C语言有三方包时，可以把调用三方包的部分用C写。

比如我就是在写一个抓包程序时，发现抓包部分代码（基于gopacket实现）在大流量场景（大于5GBytes/s）下会丢包，抓到的包的数量比tcpdump抓到的小，但是用libpcap抓包就没有发现包丢失的情况。于是决定把抓包部分代码由基于gopacket的Golang代码改成基于libpcap的C代码。因为本质上gopacket也是基于libpcap实现的，但是在libpcap上加了很多自定义的功能，可能是这些功能导致了gopacket抓包有瓶颈限制。修改完毕后，只有抓包部分是C语言写的，main函数还是基于Golang的，main函数中会调用C语言的抓包部分，抓包部分抓到包后会把包传给数据包处理部分，数据包处理部分依然是用Golang写的。下面介绍具体的实现。



```shell
gcc -fPIC -c callee.c
```

将callee.c编译成callee.o的目标文件。

```shell
gcc -shared -o libcallee.so callee.o
```

将目标文件转成成 *libcallee.so* 动态库文件