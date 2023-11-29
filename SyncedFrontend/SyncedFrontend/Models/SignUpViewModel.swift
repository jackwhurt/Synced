import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showingSignUpError = false
    @Published var signUpErrorMessage: String = ""
    @Published var isSignedUp = false
    @Published var passwordValidationMessage: String = ""
    
    private let authService: AuthenticationService

    init(authService: AuthenticationService? = AuthenticationService()) {
        guard let authService = authService else {
            fatalError("Failed to initialize AuthenticationService")
        }
        self.authService = authService
    }

    func signUpUser() {
        if !validatePasswordCriteria() {
            return
        }
            
        authService.signUpUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Sign up successful")
                    self?.isSignedUp = true

                case .failure(let error):
                    print("Sign up error: \(error.localizedDescription)")
                    self?.signUpErrorMessage = error.localizedDescription
                    self?.showingSignUpError = true
                }
            }
        }
    }
    
    func validatePasswordCriteria() -> Bool {
        passwordValidationMessage = ""

        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        if password != confirmPassword {
            passwordValidationMessage = "Passwords do not match."
            return false
        }

        if !hasLowercase || !hasUppercase || !hasNumber {
            passwordValidationMessage = "Password must contain at least one lowercase, one uppercase character, and one number."
            return false
        }
        
        return true
    }
}
