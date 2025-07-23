// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LlamaCpp",
    // Define the products that this package makes available to other packages.
    products: [
        .library(
            name: "LlamaFramework",
            targets: ["LlamaFramework"]),
    ],
    targets: [
        // This is the binary framework you want to use in your app.
        // Swift Package Manager will download and handle it for you.
        .binaryTarget(
            name: "LlamaFramework",
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b5952/llama-b5952-xcframework.zip",
            checksum: "19336dff34a7a044faffbb217654edb2b156a250e744ccfc40f97249e98e88af"
        )
    ]
)
