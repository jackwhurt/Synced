import SwiftUI

// ViewModel for the SignUpView
class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
}

struct SignUpView: View {
    @ObservedObject var viewModel = SignUpViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Spacer(minLength: geometry.size.height * 0.01)
                    
                    Logo()
                        .padding(.bottom, geometry.size.height * 0.05)
                    
                    SignUpInputFields(viewModel: viewModel)
                    SignUpButton(action: {
                        // Add sign up action
                    })
                    AlreadyMemberLink()
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                }
                .padding()
            }
        }
    }
}

struct SignUpButton: View {
    var action: () -> Void

    var body: some View {
        RoundButton(title: "Sign Up", action: action)
    }
}

struct AlreadyMemberLink: View {
    var body: some View {
        TextLink(
            title: "Already a member? Login",
            destination: LoginView()
        )
    }
}

struct SignUpInputFields: View {
    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack {
            LongInputField(placeholder: "Email", text: $viewModel.username)
            LongInputField(placeholder: "Username", text: $viewModel.username)
            LongSecureInputField(placeholder: "Password", text: $viewModel.password)
            LongSecureInputField(placeholder: "Confirm Password", text: $viewModel.password)
        }
    }
}

// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
