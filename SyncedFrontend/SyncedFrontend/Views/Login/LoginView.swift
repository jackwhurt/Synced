import SwiftUI

struct LoginView: View {
    @ObservedObject private var loginViewModel: LoginViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _loginViewModel = ObservedObject(initialValue: LoginViewModel(isLoggedIn: isLoggedIn, authenticationService: DIContainer.shared.provideAuthenticationService()))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Logo()
                        .padding(.top, geometry.size.height * 0.08)
                    
                    LoginInputFields(loginViewModel: loginViewModel)
                    LoginButton(action: loginViewModel.loginUser)
                    ForgotPasswordAndSignUpLinks(loginViewModel: loginViewModel)
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                }
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .alert(isPresented: $loginViewModel.showingLoginError) {
                    Alert(title: Text("Login Error"), message: Text("Failed to login. Please check your username and password and try again."), dismissButton: .default(Text("OK")))
                }
            }
            .background(Color("SyncedBackground"))
        }
        .accentColor(Color("SyncedBlue"))
    }
}

struct LoginInputFields: View {
    @ObservedObject var loginViewModel: LoginViewModel

    var body: some View {
        VStack {
            LongInputField(placeholder: "Email", text: $loginViewModel.email, inputType: .email)
            LongSecureInputField(placeholder: "Password", text: $loginViewModel.password, inputType: .password)
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
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        HStack {
//            Spacer()
            
            // TODO: Implement
//            TextLink(
//                title: "Forgot Password?",
//                // Placeholder
//                destination: LoginView(isLoggedIn: .constant(false))
//            )

            Spacer()
            
            TextLink(
                title: "Sign Up Here",
                destination: SignUpView(isLoggedIn: loginViewModel.isLoggedIn)
            )
            
            Spacer()
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
