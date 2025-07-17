// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "AllInOne",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "server", targets: ["Server"]),
    .executable(name: "app", targets: ["App"]),
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),

    .package(url: "https://github.com/sliemeobn/elementary-dom", branch: "main"),
    .package(url: "https://github.com/sliemeobn/elementary-css", branch: "main"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "Server",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
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
        .product(name: "ElementaryDOM", package: "elementary-dom"),
        .product(name: "ElementaryCSS", package: "elementary-css"),
        .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
      ],
    ),
  ]
)
