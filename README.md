# ANS Swift SDK

Swift 6.3+ client SDK for Agent Name Service.

```swift
import ANS

let name = try Name(rawValue: "ans://v1.0.0.agent.example.com")
let host = try Host(rawValue: "agent.example.com")
```

The package exposes primitive public names such as `Name`, `Cache`, `Client`,
and `Verifier`. Use Swift module selector syntax only when another module or
local scope defines the same name, such as `ANS::Name`.

The package uses one `ANS` target for Apple platforms, WebAssembly, Embedded
Swift, and other runtimes. It does not own networking, `URLSession`,
`FoundationNetworking`, or platform certificate stores. Badge transport and
runtime integration are supplied by the host.

`Cache` provides host and host-version badge caching with TTL, stale retention,
and capacity limits. On Apple platforms and WASM it uses `Mutex`; on Embedded
Swift the host can inject monotonic nanoseconds for TTL behavior.

Registry support covers the v1 management flow plus the v2 `/ans/agents`,
server-renewal, and verified-identity surfaces. Transparency support includes
agent and identity reads, SCITT receipts/status tokens, root keys, checkpoints,
and C2SP tiles.

SCITT support includes status-token verification, optional receipt verification,
root-key lookup and refresh, verifier-side caches, and an agent-side header
supplier for outgoing `X-ANS-Status-Token` and optional `X-SCITT-Receipt`
headers.
