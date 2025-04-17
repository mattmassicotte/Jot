// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "Jot",
	platforms: [
		.macOS(.v10_15),
		.macCatalyst(.v13),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v7),
		.visionOS(.v1),
	],
	products: [
		.library(name: "Jot", targets: ["Jot"]),
	],
	targets: [
		.target(name: "Jot"),
		.testTarget(
			name: "JotTests",
			dependencies: ["Jot"]
		),
	]
)
