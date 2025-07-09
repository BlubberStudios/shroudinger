// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EncryptedDNS",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "EncryptedDNS", targets: ["EncryptedDNS"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EncryptedDNS",
            dependencies: [],
            path: "App",
            sources: ["ContentView.swift", "App.swift"]
        ),
        .target(
            name: "DNSProxy",
            dependencies: [],
            path: "DNSProxy"
        ),
        .target(
            name: "Blocklist",
            dependencies: [],
            path: "Blocklist"
        ),
        .target(
            name: "Settings",
            dependencies: [],
            path: "Settings"
        ),
        .target(
            name: "Shared",
            dependencies: [],
            path: "Shared"
        ),
        .testTarget(
            name: "EncryptedDNSTests",
            dependencies: ["EncryptedDNS"],
            path: "Tests",
            sources: ["EncryptedDNSTests.swift"]
        )
    ]
)
