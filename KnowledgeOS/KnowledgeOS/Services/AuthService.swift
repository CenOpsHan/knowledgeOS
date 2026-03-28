import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import os

private let logger = Logger(subsystem: "com.knowledgeos.app", category: "Auth")

@MainActor
class AuthService: ObservableObject {
    @Published var isLoading = true

    private var authUser: User?
    private let fallbackUserId = "local_jonathan_hannestad"
    private var usingFallback = false

    var isSignedIn: Bool { authUser != nil || usingFallback }
    var userId: String? { authUser?.uid ?? (usingFallback ? fallbackUserId : nil) }
    var userEmail: String? { "jonathan@hannestad.co" }

    init() {
        Task {
            do {
                if let currentUser = Auth.auth().currentUser {
                    logger.info("Reusing existing auth user: \(currentUser.uid)")
                    authUser = currentUser
                } else {
                    logger.info("Signing in anonymously...")
                    let result = try await Auth.auth().signInAnonymously()
                    logger.info("Anonymous auth succeeded: \(result.user.uid)")
                    authUser = result.user
                }
            } catch {
                logger.error("Anonymous auth failed: \(error.localizedDescription). Using fallback.")
                usingFallback = true
            }
            isLoading = false
        }
    }

    func signInWithGoogle() async throws {
        // No-op in local dev mode
    }

    func signOut() throws {
        try Auth.auth().signOut()
        authUser = nil
        usingFallback = false
    }
}
