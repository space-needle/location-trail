import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("Sign in to start tracking your journey.")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            // Sign in with Google Button
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack {
                    // In a real app, you'd use the Google logo image here.
                    Image(systemName: "g.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Sign in with Apple Button
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let appleSignInRequest = authManager.createAppleSignInRequest()
                    request.requestedScopes = appleSignInRequest.requestedScopes
                    request.nonce = appleSignInRequest.nonce
                },
                onCompletion: { result in
                    authManager.handleAppleSignInCompletion(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}
