import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

@MainActor
class AuthService: ObservableObject {
    @Published var isLoading = false

    // Local dev mode: skip Google Sign-In, use a fixed identity
    private let localEmail = "jonathan@hannestad.co"
    private let localUserId = "local_jonathan_hannestad"

    var isSignedIn: Bool { true }
    var userId: String? { localUserId }
    var userEmail: String? { localEmail }

    func signInWithGoogle() async throws {
        // No-op in local dev mode
    }

    func signOut() throws {
        // No-op in local dev mode
    }
}
