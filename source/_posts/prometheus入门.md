---
title: prometheus入门xx
date: 2022-5-26 17:00:00
tags:
- 原创
categories:
- 运维
---

## 启动

`prometheus --config.file=prometheus.yml`

可以在<http://localhost:9090/metrics查看prometheus>的指标

<http://localhost:9090查看prometheus>的状态

## 在浏览器中查询指标

在<http://localhost:9090/metrics>中操作

### 选择Table

选择Table，输入查询条件，可以查看<http://localhost:9090/metrics>返回的数据（当然也可以查看这个接口之外的数据，这部分没介绍暂时？？？？？？），查询条件可以为：

```
promhttp_metric_handler_requests_total
promhttp_metric_handler_requests_total{code="200"}
count(promhttp_metric_handler_requests_total)
```

关于查询条件的编写，可以参考[querying/basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### 选择Grafana

```
rate(promhttp_metric_handler_requests_total{code="200"}[1m])
```

可以看到每秒返回状态码 200 的 HTTP 请求率（过去一分钟内每秒返回状态码 200 的 HTTP 请求率（以秒为单位））

## 原理相关

![WX20220526-134751@2x.png](http://tva1.sinaimg.cn/large/006gLprLgy1h2lrcor0vpj31j80qkwmb.jpg)

### prometheus如何获取数据

通过Pull的方式或者Push

Pull：通过exporter暴露的接口，prometheus定期调用该接口**Pull**数据

Push：可以将数据**Push**到Push Gateway，prometheus再通过**Pull**的方式从Push Gateway获取数据。可以把Push Gateway理解为一种特殊的exporter。

### prometheus的工作流程

1. Prometheus server 定期从静态配置的主机或服务发现的 targets 拉取数据（zookeeper，consul，DNS SRV Lookup等方式）

2. 当新拉取的数据大于配置内存缓存区的时候，Prometheus会将数据持久化到磁盘，也可以远程持久化到云端。

3. Prometheus通过PromQL、API、Console和其他可视化组件如Grafana、Promdash展示数据。

4. Prometheus 可以配置rules，然后定时查询数据，当条件触发的时候，会将告警推送到配置的Alertmanager。

5. Alertmanager收到告警的时候，会根据配置，聚合，去重，降噪，最后发出警告。

### 数据

#### 数据格式

prometheus采集的数据需要为如下的格式，即键值对

key{metadata}value （metadata也可以称为labels）

比如`node_disk_reads_completed_total{device="disk0", key2="2"} 3.0556147e+07`

#### 指标类型

**Counter(计数器)**

**Gauges**：处理随时间变化而变化的一些指标，比如内存变化。

**Histogram(直方图**) 可以看[官方](https://prometheus.io/docs/tutorials/understanding_metric_types/)给的例子，推荐使用

**Summary(摘要)**

#### PromQL

这是prometheus自己内置的SQL查询语言

PromQL会处理两种向量：

即时向量：当前时间某个指标的数据向量。

时间范围向量：某个时间段内，某个指标的数据向量。

#### 数据可视化

一般用grafana

## exporter

### 作用

exporter是用于采集数据的组件，被安装在采集目标上。

exporter采集数据后，传递数据给prometheus。主要传递方式是exporter会暴露一个HTTP接口，prometheus通过**Pull**的方式周期性的拉取数据。

server需要知道各种exporter的api地址且api返回的数据需要是规范化的。只要遵循规范， 可以根据需求开发出各种 exporter (比如专门采集redis数据的exporter需要在被调用的时候采集redis各项数据作为返回值， 同样采集mysql、linux、docker的exporter也是一样的工作原理， 还有其他的各种汇报数据的exporter，例如汇报机器数据的node_exporter，汇报MondogDB信息的 MongoDB_exporter 等等)。

prometheus的yml配置文件可以指定多个scrape_configs的targets

### 举例

#### Node Exporter

启动Node Exporter`node_exporter`，node_exporter在9100

`prometheus_node.yml`内容如下：

```
global:
  scrape_interval: 15s

scrape_configs:
- job_name: node
  static_configs:
  - targets: ['localhost:9100']
```

启动prometheus  `prometheus --config.file=./prometheus_node.yml`

可以在localhost:9090/graph查询到node_exporter的一些指标，比如node_exporter_build_info。node_exporter的指标可以通过<http://localhost:9100/metrics>查看

#### mysql exporter

通过`mysqld_exporter --config.my-cnf="mysql_exporter.cnf"`启动，启动后的部分日志为：

```
ts=2022-05-26T06:58:58.408Z caller=mysqld_exporter.go:303 level=info msg="Listening on address" address=:9104
```

可以看到端口号。

修改prometheus配置文件，在static_configs添加`['localhost:9104']`

```diff
    static_configs:
+      - targets: ['localhost:9104']
```

重启prometheus

#### redis exporter

启动`redis_exporter redis/localhost:6379 & -web.listenaddress localhost:9121`

修改prometheus配置文件，在static_configs添加`['localhost:9121']`

```diff
    static_configs:
+      - targets: ['localhost:9121']
```

重启prometheus

## grafana

普罗米修斯默认的页面没有很直观，安装grafana可以看起来更直观。

启动`brew services start grafana`

打开<http://localhost:3000即可访问grafana>

可以在<http://localhost:3000/d/UDdpyzz7z/prometheus-2-0-stats?orgId=1&refresh=1m看到prometheus>的整个监控信息

如果发现grafana一些面板需要插件才可以显示，使用`grafana-cli plugins install <plugin>`安装插件然后重启grafana查看面板。
