// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UDFKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "UDFKit", targets: ["UDFKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    ],
    targets: [
        .target(
            name: "UDFKit",
            dependencies: ["ZIPFoundation"]
        ),
    ]
)
