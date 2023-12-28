

数据包进入OS及出去的顺序：

`网卡nic` -> `tcpdump` -> `iptables(netfilter)` -> `app` -> `iptables(netfilter)` -> `tcpdump` -> `网卡nic`

