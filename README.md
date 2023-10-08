# 🍫 swift-nibbles
![Build](https://img.shields.io/github/actions/workflow/status/connor-ricks/swift-nibbles/pull_request_checks.yaml?logo=GitHub)
![Codecov](https://img.shields.io/codecov/c/github/connor-ricks/swift-nibbles?logo=Codecov&label=codecov)
![License](https://img.shields.io/github/license/connor-ricks/swift-nibbles?color=blue)


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
.product(name: "Stash", package: "swift-nibbles")
```

## Nibbles

### 🗄️ Stash
A simple cache that can be used to store objects.

Use a `Stash` to store objects of a given type in memory using an associated key.
You can then fetch attempt to retrieve from the `Stash` at a later time using the key.

### ⛓️ Extensions
A collection of useful extensions that I freqeuntly implement across multiple projects.

### ⚡️ Fuse
A collection of useful Combine nibbles.

- A variety of helpful sinks that allow for easier less verbose interactions with Combine publishers.
- A variety of helpful sinks that automatically cleanup after themselves by using a `DisposableBag`.
- `BuffableAsyncPublisher` and `BuffableAsyncThrowingPublisher` which both expose a `values(bufferingStrategy:)` on `Publisher`
    - This is a more configurable and powerful version of `values` in Combine that allows converting Combine to an async/await syntax.

### 🛜 Exchange
An HTTP client that creates and manages requests over the network.

The client provides support for sharing common functionality across all requests, but each request can also layer on additional functionality if needed.

Using the concept of plugins, you can customize your client's functionalities to your needs.

- **Adaptors:** Mutate a `URLRequest` before it is dispatched over the network. Useful for adding headers or query parameters to outbound requests.
- **Validators** Validate the `HTTPURLResponse` and `Data` of a `URLRequest` before decoding. Useful for checking status codes and other common validation stratagies. 
- **Retriers** Retry failed requests on your terms.

Generally an ``HTTPClient`` is used to manage the interaction with a single API service. Most APIs
have their own nuance and complexities, and encapsulating all of that in one place can help structure your code in a
more scalable and testable way.

### 🏷️ Identified

A protocol for marking objects as identified and allowing interaction with their identifiers in a type-safe way.

## Contributing

[Learn more](https://github.com/connor-ricks/swift-nibbles/blob/main/CONTRIBUTING.md)

## License

[MIT License](https://github.com/connor-ricks/swift-nibbles/blob/main/LICENSE)
