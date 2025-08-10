import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class AuthManager: NSObject, ObservableObject {

    @Published var currentUser: User?
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    override init() {
        super.init()
        // Listen for authentication state changes from Firebase
        self.authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.currentUser = user
        }
    }

    deinit {
        // Detach the listener when the object is deallocated
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Sign In with Google

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase client ID not found. Make sure you have the GoogleService-Info.plist in your project.")
            return
        }

        // Find the presenting view controller
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            print("Error: Could not find a presenting view controller for Google Sign In.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingViewController) { [weak self] user, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                return
            }

            guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                print("Google Sign In Error: Missing authentication token.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: authentication.accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Sign In Error: \(error.localizedDescription)")
                    return
                }
                print("Successfully signed in with Google: \(authResult?.user.uid ?? "No UID")")
            }
        }
    }

    // MARK: - Sign In with Apple

    func createAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        UserDefaults.standard.set(nonce, forKey: "appleSignInNonce")

        return request
    }

    func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("Apple Sign In Error: Unable to retrieve Apple ID credential.")
                return
            }

            guard let nonce = UserDefaults.standard.string(forKey: "appleSignInNonce") else {
                fatalError("Apple Sign In Error: Invalid state, nonce not found.")
            }

            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Apple Sign In Error: Unable to fetch or serialize identity token.")
                return
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                             rawNonce: nonce,
                                                             fullName: appleIDCredential.fullName)

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Firebase Apple Sign In Error: \(error.localizedDescription)")
                    return
                }
                print("Successfully signed in with Apple: \(authResult?.user.uid ?? "No UID")")
                UserDefaults.standard.removeObject(forKey: "appleSignInNonce")
            }

        case .failure(let error):
            print("Apple Sign In Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("User signed out successfully.")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// MARK: - Nonce Helper functions for Apple Sign In
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate random bytes. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }

        for random in randoms {
            if remainingLength == 0 {
                break
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()

    return hashString
}

// Helper extension to create an Apple credential for Firebase
extension OAuthProvider {
    static func appleCredential(withIDToken idToken: String, rawNonce: String, fullName: PersonNameComponents?) -> OAuthCredential {
        let credential = self.credential(withProviderID: "apple.com",
                                         idToken: idToken,
                                         rawNonce: rawNonce)
        credential.fullName = fullName
        return credential
    }
}
