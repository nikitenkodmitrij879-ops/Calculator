// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CalculatorApp",
    platforms: [
        .iOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "CalculatorApp",
            path: "Sources"
        )
    ]
)