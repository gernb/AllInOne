// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "AllInOne",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .executable(name: "server", targets: ["Server"]),
    .executable(name: "app", targets: ["App"]),
    .library(name: "Shared", targets: ["Shared"]),
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    .package(url: "https://github.com/tayloraswift/swift-hash.git", from: "0.7.1"),

    .package(url: "https://github.com/sliemeobn/elementary-dom", branch: "main"),
    .package(url: "https://github.com/sliemeobn/elementary-css", branch: "main"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", branch: "main"),
    
    .package(url: "https://github.com/apple/swift-container-plugin", from: "1.0.2"),
  ],
  targets: [
    .target(
      name: "Shared"
    ),
    .executableTarget(
      name: "Server",
      dependencies: [
        "Shared",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "MD5", package: "swift-hash"),
      ],
      swiftSettings: [
        // Enable better optimizations when building in Release configuration. Despite the use of
        // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
        // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
    .executableTarget(
      name: "App",
      dependencies: [
        "Shared",
        .product(name: "ElementaryDOM", package: "elementary-dom"),
        .product(name: "ElementaryCSS", package: "elementary-css"),
        .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
      ],
    ),
  ]
)
