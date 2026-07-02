# ANS Swift SDK

Swift 6.4 client SDK for Agent Name Service.

```swift
import ANS

let name = try Name(rawValue: "ans://v1.0.0.agent.example.com")
let host = try Host(rawValue: "agent.example.com")
```

The package exposes primitive public names such as `Name`, `Client`, and
`Verifier`. Use Swift module selector syntax only when another module or local
scope defines the same name, such as `ANS::Name`.

For robots and other constrained runtimes, the package also exposes
`ANSEmbedded`. That target imports no Foundation, URLSession, JSON, or CryptoKit
and is intended for static verification from values supplied by the host
firmware.
