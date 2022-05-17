---
title: git branch m git checkout u 用法
date: 2022-4-24 10:00:00
tags:
- 原创
categories:
- go
---

今日在写一个函数的单元测试，该函数的大概逻辑就是请求一个指定接口（如POST <https://test.com/add>。因为<https://test/com/add不一定总是可访问的，可能因为网络原因无法访问，直接在单元测试调用函数的话，会发生意料之外的网络问题导致的错误。所以为了保证单元测试总是有预期的效果，不受网络等三方环境影响，最好的方式是mock该接口。下面是mock>指定接口的方法。
