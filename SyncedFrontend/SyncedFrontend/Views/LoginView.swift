import SwiftUI

// ViewModel for the LoginView
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var showingLoginError = false
    @Published var isAuthenticated = false

    private let authService: AuthenticationService

    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
    }

    func loginUser() {
        authService.loginUser(username: username, password: password) { [weak self] result in
            switch result {
            case .success():
                print("Login successful")
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                }
            case .failure(let error):
                print("Login error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showingLoginError = true
                }
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Spacer(minLength: geometry.size.height * 0.01)
                                
                    LogoView()
                        .padding(.bottom, geometry.size.height * 0.05)
                    
                    InputFields(viewModel: viewModel)
                    LoginButton(action: viewModel.loginUser)
                    ForgotPasswordAndSignUpLinks()
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    if viewModel.isAuthenticated {
                        NavigationLink("Collaborative Playlists", destination: CollaborativePlaylistsView())
                    }
                }
                .padding()
                .alert(isPresented: $viewModel.showingLoginError) {
                    Alert(title: Text("Login Error"), message: Text("Failed to login. Please check your username and password and try again."), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
}

struct LogoView: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 150)
    }
}

struct InputFields: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack {
            LongInputField(placeholder: "Username", text: $viewModel.username)
            LongSecureInputField(placeholder: "Password", text: $viewModel.password)
        }
    }
}

struct LoginButton: View {
    var action: () -> Void

    var body: some View {
        RoundButton(title: "Log In", action: action)
    }
}

struct ForgotPasswordAndSignUpLinks: View {
    var body: some View {
        HStack {
            Spacer()
            
            TextLink(
                title: "Forgot Password?",
                destination: LoginView() // Placeholder
            )

            Spacer()
            
            TextLink(
                title: "Sign Up Here",
                destination: SignUpView()
            )
            
            Spacer()
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
