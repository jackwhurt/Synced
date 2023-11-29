import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel = SignUpViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Logo()
                        .padding(.top, geometry.size.height * 0.04)
                    
                    SignUpInputFields(viewModel: viewModel)
                    SignUpButton(action: viewModel.signUpUser)
                    
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
            .background(Color("SyncedBackground"))
        }
    }
}

struct SignUpButton: View {
    var action: () -> Void

    var body: some View {
        RoundButton(title: "Sign Up", action: action)
    }
}

struct SignUpInputFields: View {
    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack {
            LongInputField(placeholder: "Email", text: $viewModel.email)
            LongSecureInputField(placeholder: "Password", text: $viewModel.password)
                .onChange(of: viewModel.password) { _ in
                    viewModel.validatePasswordCriteria()
                }
            LongSecureInputField(placeholder: "Confirm Password", text: $viewModel.confirmPassword)
                .onChange(of: viewModel.confirmPassword) { _ in
                    viewModel.validatePasswordCriteria()
                }
            if(viewModel.passwordValidationMessage != "") {
                Text(viewModel.passwordValidationMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
