// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LiquidGlassCalculator",
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
