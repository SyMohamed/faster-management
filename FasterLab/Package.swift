// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FasterLab",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "FasterLab",
            dependencies: [
                .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ],
            path: "FasterLab"
        ),
    ]
)
