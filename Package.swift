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
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    .package(url: "https://github.com/tayloraswift/swift-hash.git", from: "0.7.1"),

    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-navigation.git", from: "2.3.0"),
    
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
    .target(
      name: "AppShared",
      dependencies: [
        "Shared",
        .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
        .product(name: "JavaScriptKit", package: "JavaScriptKit"),
        .product(name: "SwiftNavigation", package: "swift-navigation"),
      ]
    ),
    .executableTarget(
      name: "App",
      dependencies: [
        "AppShared",
        .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
        .product(name: "JavaScriptKit", package: "JavaScriptKit"),
        .product(name: "SwiftNavigation", package: "swift-navigation"),
      ],
      // swiftSettings: [ // requires swift 6.2
      //   .defaultIsolation(MainActor.self),
      // ]
    ),
  ]
)
