

---
title: 编写中，未定稿
draft: true  # 设置为草稿
date: 2023-01-01 11:00:00
categories:
- 数据库
---




tcpdump底层使用的是libpcap，libpcap也是好多抓包工具使用的底层包。tcpdump运行时是在用户态，那么用户态的tcpdump是如何抓到内核态的数据包的呢？

> 操作系统把虚拟控制系统分为两个部分，分别为内核空间和用户空间。

