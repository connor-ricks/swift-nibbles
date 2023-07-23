# 🍫 swift-nibbles
[![🚨 Checks](https://github.com/connor-ricks/swift-exploration-nibbles/actions/workflows/pull_request_checks.yaml/badge.svg)](https://github.com/connor-ricks/swift-exploration-nibbles/actions/workflows/pull_request_checks.yaml)
[![codecov](https://codecov.io/gh/connor-ricks/swift-nibbles/branch/main/graph/badge.svg?token=2521H59VKB)](https://codecov.io/gh/connor-ricks/swift-nibbles)

Nibbles of useful swift code that I regularaly use across various proejcts.

## Getting Started

To add `swift-nibbles` to your project, first add it as a dependency.

```swift
.package(url: "https://github.com/connor-ricks/swift-nibbles/", branch: "main")
```

Nibbles are all broken down into their own targets, so you can choose which nibbles are relevant to your project.

```swift
.product(name: "HTTPNetworking", package: "swift-nibbles")
// or
.product(name: "Cache", package: "swift-nibbles")
```

## Nibbles

### 🗄️ Cache
A simple cache that can be used to store objects.

Use a cache to store objects of a given type in memory using an associated key.
You can then fetch attempt to retrieve from the cache at a later time using the key.

### ⛓️ Extensions
A collection of useful extensions that I freqeuntly implement across multiple projects.

### 🕸️ HTTPNetworking
A client that creates and manages requests over the network.

The client provides common functionality for all requests, including encoding and decoding strategies, as well as request adaptation, response validation and retry stratagies.

Generally an ``HTTPClient`` is used to manage the interaction with a single API service. Most APIs
have their own nuance and complexities, and encapsulating all of that in one place can help structure your code in a
more scalable and testable way.

### 🏷️ Identified

A protocol for marking objects as identified and allowing interaction with their identifiers in a type-safe way.

## License

[MIT License](https://github.com/connor-ricks/swift-nibbles/blob/main/LICENSE)
