4.2更新

gopacket的snapshot配置是干什么的

在 GoPacket 中，`snapshot` 是一个参数，用于指定从网络接口读取数据包时每个数据包的最大长度。它决定了每次读取数据包时需要分配多少内存空间来存储接收到的数据包内容。

通常情况下，`snapshot` 的值应该大于或等于网络接口支持的最大数据包长度。如果设置的值小于实际接收到的数据包长度，则可能会导致数据包被截断，部分数据丢失。因此，建议将 `snapshot` 设置为一个较大的值，以确保能够完整接收到所有数据包。

另外，设置 `snapshot` 过大可能会导致内存浪费，因为每个数据包都会分配足够大的内存空间来存储。因此，在选择 `snapshot` 的值时，需要根据实际情况权衡考虑网络接口支持的最大数据包长度和内存的使用情况。

## 如何定位包丢失

丢包含义：数据在网络上传输，受网络设备，网络质量等原因的影响，使得**接收到的数据少于发送出去的数据，造成丢包。**



丢包原因主要会涉及⽹卡设备、⽹卡驱动、内核协议栈三⼤类



## 解码选项

解码选项是gopacket里的一个struct，名为DecodeOptions，可以自定义在解码时的一些配置，DecodeOptions的定义如下：

```shell
type DecodeOptions struct {
	// Lazy decoding decodes the minimum number of layers needed to return data
	// for a packet at each function call.  Be careful using this with concurrent
	// packet processors, as each call to packet.* could mutate the packet, and
	// two concurrent function calls could interact poorly.
	Lazy bool
	// NoCopy decoding doesn't copy its input buffer into storage that's owned by
	// the packet.  If you can guarantee that the bytes underlying the slice
	// passed into NewPacket aren't going to be modified, this can be faster.  If
	// there's any chance that those bytes WILL be changed, this will invalidate
	// your packets.
	NoCopy bool
	// SkipDecodeRecovery skips over panic recovery during packet decoding.
	// Normally, when packets decode, if a panic occurs, that panic is captured
	// by a recover(), and a DecodeFailure layer is added to the packet detailing
	// the issue.  If this flag is set, panics are instead allowed to continue up
	// the stack.
	SkipDecodeRecovery bool
	// DecodeStreamsAsDatagrams enables routing of application-level layers in the TCP
	// decoder. If true, we should try to decode layers after TCP in single packets.
	// This is disabled by default because the reassembly package drives the decoding
	// of TCP payload data after reassembly.
	DecodeStreamsAsDatagrams bool
}
```

合理设置它们的值将会大大提高包读取和解析的速度。

### lazy decode

在从网卡实时读取数据包的时候，可以设置在获取到数据包时延迟解析数据包的各层，代码参考如下：

```shell
	handle, err = pcap.OpenLive(device, snaplen, promiscuous, timeout)
	defer handle.Close()
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	packetSource.DecodeOptions = gopacket.DecodeOptions{Lazy: true, NoCopy: true}
	for packet := range packetSource.Packets() {
	// 可以读取数据包的各层数据
	}
```

主要通过

```shell
packetSource.DecodeOptions = gopacket.DecodeOptions{Lazy: true, NoCopy: true}
```

的Lazy选项设置为true来实现数据包的延迟解析。不设置为true即默认情况下，gopacket会在接收到数据包后立刻解析然后接收下一个数据包。如果设置为true，则会接收到数据包后不解析然后立刻接收下一个数据包，数据包的解析操作会在需要访问这些字段和数据时才进行解析。这样可以减少解析过程中的内存和CPU消耗，并提高性能。

举例来说，可能只对数据包的部分字段感兴趣，比如源地址、目的地址和协议类型等。启用 `Lazy` 选项后，`gopacket` 将只解析这些字段，而对于其他字段，只有在获取他们值的时候才会触发解析数据包的操作，且只解析尽可能少的数据，即不做多余的操作。

在大流量的情况下，比如1秒钟内有非常多的数据包，那么将lazy设置为true可以增加数据包的读取速率。设置为false读取会慢，性能所限可能会丢失部分数据包。

### nocopy decode

在设置 `NoCopy` 选项为 `true` 时，`gopacket` 将尽量避免在解析数据包时进行内存拷贝操作。通常情况下，在解析数据包时，会涉及到从原始数据包中提取字段数据，然后将其拷贝到新的内存区域中进行处理。启用 `NoCopy` 选项后，`gopacket` 将尝试使用零拷贝技术，直接在原始数据包的内存中进行操作，避免不必要的内存拷贝操作，从而提高解析性能。

在处理大量数据包时，启用 `NoCopy` 选项可以显著减少内存开销和CPU消耗，尤其是对于大型数据包或高速网络流量的处理。但是需要注意，使用 `NoCopy` 选项可能会增加代码的复杂性，因为需要确保你的代码不会修改原始数据包，以避免出现数据损坏或意外行为。

设置方法可以参考上面的代码，如果只是读取数据包那么可以设置为true，则会大大提高性能减少内存拷贝等。如果涉及到修改数据包，则不要设置为true，设置为true会破坏原始数据包的值。

### SkipDecodeRecovery

当设置为 `true` 时，`SkipDecodeRecovery` 将告诉 `gopacket` 在解析数据包时不进行恢复处理。通常情况下，如果 `gopacket` 在解析数据包时遇到错误或异常情况，它会尝试进行恢复处理，以尽可能多地解析出有效的数据。这种恢复处理可能包括尝试从错误中恢复，忽略部分损坏的数据，并尝试继续解析。

但是，在某些情况下，可能希望完全避免 `gopacket` 的恢复处理，而是直接在解析过程中忽略任何错误或异常情况，并接受可能的数据丢失或不完整。这时，可以将 `SkipDecodeRecovery` 设置为 `true`，告诉 `gopacket` 在解析数据包时不进行任何恢复处理，直接返回解析错误。

总的来说，设置 `SkipDecodeRecovery` 为 `true` 可以提高解析性能，但同时也可能导致更多的解析错误或数据丢失。因此，在使用时需要根据具体情况进行权衡和选择。

### DecodeStreamsAsDatagrams

翻译为编码数据流为数据报，即忽略数据流，只将每个包看成单个数据报。

通常情况下，在网络数据流中，数据包之间可能存在关联性，例如TCP连接中的数据包之间的序列关系。如果想要忽略这种关联性，将每个数据包视为独立的数据报进行解析，可以启用 `DecodeStreamsAsDatagrams` 选项。

启用此选项的常见用例包括对UDP数据包进行解析，因为UDP是无连接的协议，每个UDP数据包都是独立的数据报。此外，对于一些特定的网络流量分析场景，如果你希望忽略连接之间的关联性，也可以考虑启用此选项。


