import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel = SignUpViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: 30) {
                    Logo()
                        .padding(.bottom, geometry.size.height * 0.03)
                        .padding(.top, geometry.size.height * 0.1)
                    
                    SignUpInputFields(viewModel: viewModel)
                    SignUpButton(action: viewModel.signUpUser)
                    AlreadyMemberLink()
                    
                    Spacer(minLength: geometry.size.height * 0.1)
                    
                    if viewModel.isSignedUp {
                        NavigationLink("", destination: CollaborativePlaylistsView())
                    }
                }
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .alert(isPresented: $viewModel.showingSignUpError) {
                    Alert(title: Text("Sign Up Error"), message: Text(viewModel.signUpErrorMessage), dismissButton: .default(Text("OK")))
                }
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
            LongInputField(placeholder: "Email", text: $viewModel.email)
            LongSecureInputField(placeholder: "Password", text: $viewModel.password)
            LongSecureInputField(placeholder: "Confirm Password", text: $viewModel.confirmPassword)
        }
    }
}

// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
