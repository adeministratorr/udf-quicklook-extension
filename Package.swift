// swift-tools-version: 5.9
import PackageDescription

// App-extension executables must use NSExtensionMain as their entry point instead
// of the normal main(); force it via the linker. This is what lets the .appex be
// built with plain SwiftPM (Command Line Tools only) — no full Xcode required.
let nsExtensionEntry: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])
]

let package = Package(
    name: "UDFViewer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "UDFKit"),
    ],
    targets: [
        // Shared parse+render island (vendored render files + UDFRenderer facade).
        .target(
            name: "UDFRender",
            dependencies: [.product(name: "UDFKit", package: "UDFKit")],
            path: "Shared"
        ),
        // Read-only host viewer app (normal main()).
        .executableTarget(
            name: "UDFViewer",
            dependencies: ["UDFRender"],
            path: "HostApp",
            exclude: ["Info.plist"]
        ),
        // QuickLook Preview extension (.appex; NSExtensionMain entry).
        .executableTarget(
            name: "QuickLookPreview",
            dependencies: ["UDFRender"],
            path: "QuickLookPreview",
            exclude: ["Info.plist", "QuickLookPreview.entitlements"],
            linkerSettings: nsExtensionEntry
        ),
        // QuickLook Thumbnail extension (.appex; NSExtensionMain entry).
        .executableTarget(
            name: "QuickLookThumbnail",
            dependencies: ["UDFRender"],
            path: "QuickLookThumbnail",
            exclude: ["Info.plist", "QuickLookThumbnail.entitlements"],
            linkerSettings: nsExtensionEntry
        ),
    ]
)
