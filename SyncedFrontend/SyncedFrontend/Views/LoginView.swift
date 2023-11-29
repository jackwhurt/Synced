import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: LoginViewModel(isLoggedIn: isLoggedIn))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Logo()
                        .padding(.top, geometry.size.height * 0.08)
                    
                    LoginInputFields(viewModel: viewModel)
                    LoginButton(action: viewModel.loginUser)
                    ForgotPasswordAndSignUpLinks()
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                }
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .alert(isPresented: $viewModel.showingLoginError) {
                    Alert(title: Text("Login Error"), message: Text("Failed to login. Please check your username and password and try again."), dismissButton: .default(Text("OK")))
                }
            }
            .background(Color("SyncedBackground"))
        }
        .accentColor(Color("SyncedBlue"))
    }
}

struct LoginInputFields: View {
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
                destination: SignUpView() // Placeholder
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
        LoginView(isLoggedIn: .constant(false))
    }
}
