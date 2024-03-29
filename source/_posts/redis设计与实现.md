---
title: redis设计与实现（更新中）
date: 2022-7-30 11:00:00
---

redis设计与实现（注意记录的时候要记录每个大小章节而不只括起来的部分）

## 前言

redis内置了**集合数据类型**，并支持对集合执行交集、并集、差集等集合计算操作

redis可以存储二进制位，使用SETBIT命令

## 第一章 引言

redis是用C写的，本书的粘贴的源代码就是C语言代码

## 第一部分 数据结构与对象

## 第二章 简单动态字符串

redis没有直接使用C语言传统的字符串表示（以空字符串结尾的字符串数组），而是自己构建了一种名为**简单动态字符串（simple dynamic string，SDS）**的抽象类型。当redis需要的不仅仅是一个字符串字面量，而是一个可以被修改的字符串值时，就会使用SDS表示字符串值。

比如`SET msg "hello world"`，执行完成后redis会在数据库创建一个键值对，键和值底层实现都是SDS。

### SDS的定义

```c
struct sddshdr {
	int len; // 记录 buf 数组中已使用字节的数量，等于SDS所保存字符串的长度
	int free; // 记录 buf 数组中未使用字节的数量
	char buf[]; // 字节数组，用于保存字符串
}
```

### SDS与C字符串的区别

1. 获取字符串长度的复杂度：SDS有一个len属性，记录了SDS本身的长度，所以获取一个SDS长度的复杂度为O(1)。而C字符串需要遍历整个字符串直到结尾的空字符串，故时间复杂度为O(n)。

2. 是否会发生缓冲区溢出：C字符串因为不记录自身的长度容易造成缓冲区溢出。SDS则完全杜绝缓冲区溢出，因为对SDS修改前，API会首先检查SDS的空间是否满足要求，不满足则修改SDS的空间。

3. 修改字符串产生的内存重分配次数

   C字符串的增长操作需要程序通过内存重分配来扩展底层数组的空间大小，忘记这一步会发生**缓冲区溢出**。缩短操作则需要程序释放字符串不需要的空间，否则会发生**内存泄露**。

   SDS因为包含了未使用的字节，未使用的字节解除了字符串长度和底层数组长度之间的关联。

