<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Matrix][matrix badge]][matrix]

</div>

# Jot
Very simple JWT/JWK library for Swift

There are a lot of really good libraries out there for handling this stuff. However, many of them have the goal of supporting all possible cryptographic algorithms and non-Apple platforms. I just wanted something simple that worked with CryptoKit, so that's what this is.

However, it does abstract the algorithms, so it is possible to use this library with other cryptography systems if you'd like.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/mattmassicotte/Jot", branch: "main")
]
```

## Usage

```swift
import Jot

// Define your custom payload. You can omit fields that you do not need.
struct MyCustomPayload : JSONWebTokenPayload {
    let iss: String?
    let sub: String?
    let aud: JSONWebTokenAudience?
    let jti: String?
    let nbf: Date?
    let iat: Date?
    let exp: Date?

    let customClaim: String
}

// create a token
let token = JSONWebToken<MyCustomPayload>(
    header: JSONWebTokenHeader(algorithm: .ES256),
    payload: MyCustomPayload(iss: nil, sub: nil, aud: nil, jti: nil, nbf: nil, iat: nil, exp: nil, customClaim: "my_claim")
)

import CryptoKit

let key = P256.Signing.PrivateKey()

// encode it
let string = token.encode(with: key)

// decode it
let decodedToken = JSONWebToken<MyCustomPayload>(encodedString: string, key: key)
```

Jot also supports custom signing/verification if CryptoKit is unavailable, or you want to use an algorithm that is does not support.

```swift
// custom signature
let string = token.encode { algorithm, data in
    // custom JSONWebTokenSigner implementation goes here

    return signature
}

// custom verification
let token = try JSONWebToken<MyCustomPayload>(encodedString: tokenString) { algorithm, message, signature in
    // custom JSONWebTokenValidator implementation goes here
}
```

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [the web](https://www.massicotte.org).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/mattmassicotte/Jot/actions
[build status badge]: https://github.com/mattmassicotte/Jot/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/mattmassicotte/Jot
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmattmassicotte%2FJot%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/mattmassicotte/Jot/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
