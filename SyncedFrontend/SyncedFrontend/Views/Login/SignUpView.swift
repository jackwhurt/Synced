import SwiftUI

// TODO: Loading circle
struct SignUpView: View {
    @ObservedObject private var signUpViewModel: SignUpViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(isLoggedIn: Binding<Bool>) {
        _signUpViewModel = ObservedObject(initialValue: SignUpViewModel(isLoggedIn: isLoggedIn, authenticationService: DIContainer.shared.provideAuthenticationService()))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Logo()
                        .padding(.top, geometry.size.height * 0.04)
                    SignUpInputFields(signUpViewModel: signUpViewModel)
                    SignUpButton(action: signUpViewModel.signUpUser)
                    Spacer(minLength: geometry.size.height * 0.1)
                }
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .alert(item: $signUpViewModel.alert) { alert in
                    switch alert {
                    case .error:
                        Alert(title: Text("Sign Up Error"), message: Text(signUpViewModel.signUpErrorMessage), dismissButton: .default(Text("OK")))
                    case .success:
                        Alert(
                            title: Text("Sign Up Success"),
                            message: Text(signUpViewModel.signUpSuccessMessage),
                            dismissButton: .default(Text("OK"), action: {
                                presentationMode.wrappedValue.dismiss()
                                signUpViewModel.email = ""
                                signUpViewModel.password = ""
                                signUpViewModel.username = ""
                                signUpViewModel.confirmPassword = ""
                            }))
                    }
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
    @ObservedObject var signUpViewModel: SignUpViewModel

    var body: some View {
        VStack {
            LongInputField(placeholder: "Email", text: $signUpViewModel.email)
            LongInputField(placeholder: "Username", text: $signUpViewModel.username)
                .onChange(of: signUpViewModel.username) {
                    _ = signUpViewModel.validateUsernameCriteria()
                }
            LongSecureInputField(placeholder: "Password", text: $signUpViewModel.password)
                .onChange(of: signUpViewModel.password) {
                    _ = signUpViewModel.validatePasswordCriteria()
                }
            LongSecureInputField(placeholder: "Confirm Password", text: $signUpViewModel.confirmPassword)
                .onChange(of: signUpViewModel.confirmPassword) {
                    _ = signUpViewModel.validatePasswordCriteria()
                }
            if(signUpViewModel.passwordValidationMessage != "") {
                Text(signUpViewModel.passwordValidationMessage)
                    .foregroundColor(Color("SyncedErrorRed"))
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }
            if(signUpViewModel.usernameValidationMessage != "") {
                Text(signUpViewModel.usernameValidationMessage)
                    .foregroundColor(Color("SyncedErrorRed"))
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }
        }
    }
}

// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(isLoggedIn: .constant(false))
    }
}
