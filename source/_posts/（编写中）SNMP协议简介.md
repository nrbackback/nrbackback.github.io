---
title: SNMP协议简介
date: 2023-3-7 11:30:00
categories:
- 网络
---

mac安装SNMP客户端

```shell
$ brew install net-snmp
```

可以使用snmpget命令来获取指定OID的值。例如：

```shell
$ snmpget -v2c -c communitystring localhost 1.3.6.1.2.1.1.1.0
```

-v2c表示使用SNMP版本2c协议，-c表示指定SNMP社区字符串，这里是获取本机上的OID为1.3.6.1.2.1.1.1.0的信息。

为什么我获取我localhost的信息提示`Timeout: No Response from 127.0.0.1.`



正在看 https://cloud.tencent.com/developer/article/1366122

相应的数字表示（对象标识符OID，唯一标识一个MIB对象）为：

1.3.6.1.2.1.4.3

