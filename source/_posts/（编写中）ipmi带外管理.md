

其他参考

https://blog.csdn.net/pytanght/article/details/19756253

https://www.jianshu.com/p/f0366f577e95

https://www.cnblogs.com/machangwei-8/p/10350824.html



## 简介

IPMI（Intelligent Platform Management Interface）是一种由Intel开发的远程管理技术，通常用于管理和监视计算机系统。可以通过IPMI监控服务器的物理特征，如温度，电压等。只要机器接通电源即可，即使没有启动操作系统，就可以进行监控。目前最新版本是IPMI2.0。

IPMI可以让管理员通过网络连接访问计算机系统，以便在操作系统不可用或发生故障的情况下进行管理和维护。比如服务器宕机的时候，无法通过SSH连接的话可以通过IPMI来重启。



常见的设备管理方式有SNMP、RMON、Web、TELNET，这些管理方式属于带内管理

在计算机领域，带外管理（Out-of-band management）是指使用独立管理通道进行设备维护。它允许系统管理员远程监控和管理服务器、路由器、网络交换机和其他网络设备。带外管理通过部署与数据通道物理隔离的管理通道来解决这个限制。带外网管是指通过专门的网管通道实现对网络的管理，**将网管数据与业务数据分开**，为网管数据建立独立通道。

相对的，带内管理是指使用常规数据通道（例如以太网、互联网）来管理设备。带内管理的明显限制是这种管理容易受到被管理设备受攻击或损害的影响。带内管理使得网络中的网管数据和业务数据在相同的链路中传输，当管理数据（包括SNMP，Netflow，Radius，计费等）较多时，将会影响到整个网络的性能；管理数据的流量较少，对整个网络的性能影响不明显，可采用带内管理。带内网管，网管系统必须通过网络来管理设备。如果无法通过网络访问被管理对象，带内网管系统就失效了，这时候带外网管系统就排上用场了。



尽管 IPMI 和 HTTP 没有直接的关系，但是**有些服务器供应商提供了基于 HTTP 协议的 IPMI 远程管理界面**，这意味着管理员可以使用 Web 浏览器来访问服务器的 IPMI 远程管理功能。在这种情况下，HTTP 协议被用于提供 IPMI 远程管理功能的 Web 接口，以便管理员可以通过 Web 界面来管理服务器硬件。

wireshark中可以抓到IPMI的数据



## 确认是否支持IPMI

大部分厂商的服务器如戴尔，NEC的都支持IPMI2.0，**第一步就是应该先查看产品手册或者在BIOS查看服务器是否支持IPMI。**

大多数现代的Linux操作系统都支持IPMI技术。mac不支持IPMI协议。

Linux机器执行：

```shell
dmidecode -t 38
```

如果命令返回IPMI版本和其他相关信息，则说明系统具有IPMI硬件，即支持IPMI技术。

> 这里我的Linux机器（Red Hat版本）上执行了这个命令返回了如下结果。
>
> ![image-20230320151138038](../images/image-20230320151138038.png)

下面的操作基于我的机器

安装ipmitool和OpenIPMI工具包，这两个都是支持IPMI管理的必备工具包

```shell
sudo yum install ipmitool OpenIPMI
```

加载IPMI驱动程序：使用以下命令加载IPMI驱动程序：

```
sudo modprobe ipmi_devintf
```

启动IPMI服务：使用以下命令启动IPMI服务：

```
sudo systemctl start ipmi.service
```

设置IPMI用户：使用以下命令设置IPMI用户：

```
sudo ipmitool user set name 1 admin
```

执行这个报错了。。。。。。。。。。。

```
Could not open device at /dev/ipmi0 or /dev/ipmi/0 or /dev/ipmidev/0: No such file or directory
```



之前启动IPMI服务时，需要内核加载命令，命令报错了

```
sudo modprobe ipmi_si
```

```
modprobe: ERROR: could not insert 'ipmi_si': No such device
```

> 如果出现 "no such device" 错误消息，则表示系统中没有找到名为 ipmi_si 的内核模块。这可能是因为系统中没有安装这个模块，或者是因为这个模块并不适用于当前系统的内核版本。
>
> 如果您希望使用 ipmi_si 模块，可以尝试检查当前系统是否安装了这个模块，或者尝试在系统中安装这个模块。您还可以尝试检查内核版本，看看这个模块是否与当前内核版本兼容。
>
> [参考](https://juejin.cn/s/modprobe%20ipmi_si%20no%20such%20device)







ipmi_si 仅适用于真实硬件，不可以在虚拟机上。 你可以使用类似 virt-manager 的东西来查看 VM 控制台

> 如何判断机器是物理机还是虚拟机
>
> ```
> systemd-detect-virt
> ```
>
> 如果输出none表示为物理机，否则为虚拟机
>
> 我的机器上执行的结果是
>
> ```shell
> systemd-detect-virt
> kvm
> ```

## IPMI管理工具

这里使用的IPMI管理工具为ipmitool，在mac上的安装方法为：

```shell
brew install ipmitool
```





确定IPMI的地址：查看BIOS设置或IPMI配置实用程序





服务器需要本身支持IPMI，还需要额外安装ipmi驱动和工具，





[这个好像很有用](https://blog.csdn.net/adsjlnmj66029/article/details/101567983)



---------

dev是设备(device)的英文缩写。/dev这个目录对所有的用户都十分重要。因为在这个目录中包含了所有Linux系统中使用的外部设备。但是这里并不是放的外部设备的驱动程序，这一点和**[windows](http://www.ltesting.net/html/75/category-catid-375.html)**,dos操作系统不一样。它实际上是一个访问这些外部设备的端口。



SDK https://github.com/bougou/go-ipmi





[原文](https://www.servethehome.com/download-supermicro-ipmiview-latest-version/)

What I usually do is go directly to Supermicro’s FTP site, in the IPMIView folder, found here: [ftp://ftp.supermicro.com/utility/IPMIView/](ftp://ftp.supermicro.com/utility/IPMIView/) to download IPMIView.





参考

[1](https://www.cnblogs.com/bakari/archive/2012/08/05/2623780.html)

