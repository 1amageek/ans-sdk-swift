# ANS Swift SDK

Swift 6.4 client SDK for Agent Name Service.

```swift
import ANS

let name = try ANS::Name(rawValue: "ans://v1.0.0.agent.example.com")
let host = try ANS::Host(rawValue: "agent.example.com")
```

The package exposes a single library product named `ANS`. The module is the
namespace, so public types use primitive names such as `Name`, `Client`, and
`Verifier`.
