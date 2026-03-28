// swift-tools-version:5.9
import PackageDescription

// NOTE: This file documents the dependencies for the Xcode project.
// In Xcode, add these as Swift Package Manager dependencies:
//
// 1. Firebase iOS SDK:
//    https://github.com/firebase/firebase-ios-sdk
//    Products: FirebaseAuth, FirebaseFirestore, FirebaseStorage
//
// 2. Google Sign-In:
//    https://github.com/google/GoogleSignIn-iOS
//    Product: GoogleSignIn, GoogleSignInSwift
//
// 3. MarkdownUI:
//    https://github.com/gonzalezreal/swift-markdown-ui
//    Product: MarkdownUI

let package = Package(
    name: "KnowledgeOS",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "8.0.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "KnowledgeOS",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "KnowledgeOS"
        ),
    ]
)
