# awada

Why we need awada server beside the openclaw channel?

部分第三方消息服务提供商（比如企微 bot、个微 bot）要求有固定公网 IP 作为接收端，而 openclaw 更多的应用场景是本地部署，没有公网 IP，或者我们希望从多个通道接收消息，然后分发给不同的 openclaw 实例处理，这都需要有一个放置于公网的集中中转站。

另外，对于企业级用户，如果私密要求特别高，希望自己掌控完整的 remote 端 到 openclaw workstation 通信，即中间所有的通信都是self host，awada server 也是一个"开箱即用"的方案。
