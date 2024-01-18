---
title: 编写中，未定稿
draft: true  # 设置为草稿
date: 2023-01-01 11:00:00
categories:
- 数据库
---

数据包进入OS及出去的顺序：

`网卡nic` -> `tcpdump` -> `iptables(netfilter)` -> `app` -> `iptables(netfilter)` -> `tcpdump` -> `网卡nic`

