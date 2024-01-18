---
title: 编写中，未定稿
draft: true  # 设置为草稿
date: 2023-01-01 11:00:00
categories:
- 数据库
---
数据包进入OS及出去的顺序：

进入的流量：`网卡nic` -> `tcpdump` -> `iptables(netfilter)` -> `app`

出去的流量：`app` -> `iptables(netfilter)` -> `tcpdump` -> `网卡nic`





iptables工具/命令是一个广泛使用的防火墙工具，iptables会利用内核的netfilter来过滤数据包，其实是通过触发hook来实现过滤的。

所有经过网络层的进出流量都会触发hook，

## Netfilter hook

一共有5个netfilter对外提供的，用于注册勾子函数的勾子节点，可以来把自定义的hook勾子函数注册到netfilter的调用栈中。

每个数据包会触发哪些勾子函数取决于数据包的流向（进流量还是出流量），数据包的目的地，数据包在上一个节点是被丢弃了还是拒绝了。

上述的5个勾子节点如下：

- NF_IP_PRE_ROUTING：进入网络栈后的数据包会立刻触发该勾子，该勾子会 在任何路由策略做出数据包该发往哪里的决定前 会被触发。

- NF_IP_LOCAL_IN：如果是进的数据包且数据包的目标是本机， 在数据包被路由后，该勾子会被触发。

- NF_IP_FORWARD：如果是进的数据包且数据包的目标不是本机而是需要本机转发到其他主机的， 在数据包被路由后，该勾子会被触发。

- NF_IP_LOCAL_OUT：本机要出去的数据包达到网络栈时就会立刻触发该勾子。

- NF_IP_POST_ROUTING：任何出去或者转发的流量，在路由做出判断后，在线路上被发送出去前，会触发此勾子。

在这些勾子注册的内核模块需要提供一个数字用来决定当勾子被触发时，该内核模块何时被执行。该数字时用来决定多个内核模块的执行顺序的。每个内核模块被调用后都会返回给netfilter一个结果，该解决告诉netfilter应该如何处理当前数据包。

## IPtables 和 chains

iptables使用一个tables表格来管理自己的rule规则。tables表格根据规则作出的结果对规则进行分类。比如，如果某个规则时对网络地址做翻译的，那么这个规则会被放在nat表格里。如果这个规则时用来决定是否让当前数据包包前往包的目的地，那么这个规则会被放到filter表格里。

通过每一个iptables表格，规则会在不同的chain里被进一步组织。table是通过rule的目标来分类的，内置的chain则代表了触发该chain的netfilter的hook。内置的chain的名字上反映了和chain相关联的netfilter hook：

- PREROUTING：会被NF_IP_PRE_ROUTING hook触发
- INPUT：会被NF_IP_LOCAL_IN hook触发
- FORWARD：会被NF_IP_FORWARD hook触发
- OUTPUT：会被NF_IP_LOCAL_OUT hook hook触发
- POSTROUTING：会被NF_IP_POST_ROUTING hook触发

TODO:下面的不晓得啥意思，后面看看再补充上

Chains allow the administrator to control where in a packet’s delivery path a rule will be evaluated. Since each table has multiple chains, a table’s influence can be exerted at multiple points in processing. Because certain types of decisions only make sense at certain points in the network stack, every table will not have a chain registered with each kernel hook.

There are only five `netfilter` kernel hooks, so chains from multiple tables are registered at each of the hooks. For instance, three tables have `PREROUTING` chains. When these chains register at the associated `NF_IP_PRE_ROUTING` hook, they specify a priority that dictates what order each table’s `PREROUTING` chain is called. Each of the rules inside the highest priority `PREROUTING` chain is evaluated sequentially before moving onto the next `PREROUTING` chain. We will take a look at the specific order of each chain in a moment.

## 哪些tables是可用的

让我们退后一步，看看ipatables命令提供的table表。这些代表了不同的rule集合，这些rule集合按照各自的关注领域组织，集合的目的就是为了evaluate评估数据包。

### Filter table

filter table是iptables里最广泛使用的一个。filter table用于决定某个数据包应该继续前往其目的地还是拒绝该数据包的请求。如果用防火墙相关的说法来说，filter table的功能就是"filtering"即过滤数据包。filter table提供了人们讨论起防火墙时会想到的大部分功能。

### NAT table

nat table用于实现网络地址转换rule规则。当数据包进入网络栈时，表格里的rule会决定是否需要修改以及如何修改数据包的源地址和目的地址，从而来影响数据包和任何流量的路由方式。当数据包无法直接进去网络时，NAT table通常用于将数据包路由到网络中。

### Manage table

manage table用于使用不同的方法修改数据包的IP header。例如，你可以修改数据包的TTL，或者延长或者缩短数据包可以维持的有效网络跳点数。其他IP header也可以通过类似的方法修改。

该table还可以在数据包上放置内部内核“标记”，以便在其他表和其他网络工具中进行进一步处理。 该标记不会触及实际的数据包，而是将标记添加到数据包的内核表示中。

### raw table

iptables 防火墙是有状态的，这意味着数据包将根据其与先前数据包的关系进行评估。建立在 netfilter 框架之上的连接跟踪功能允许 iptables 将数据包视为正在进行的连接或会话的一部分，而不是视为离散的、不相关的数据包流。连接跟踪逻辑通常在数据包到达网络接口后立即应用。

“raw”表的功能定义非常狭窄。 它的唯一目的是提供一种标记数据包的机制，以便选择退出连接跟踪。

### Security table

安全表用于在数据包上设置内部SELinux安全上下文标记，这将影响SELinux或其他可以解释SELinux安全上下文的系统如何处理数据包。 这些标记可以应用于每个数据包或每个连接。

## chain和table的关系







































