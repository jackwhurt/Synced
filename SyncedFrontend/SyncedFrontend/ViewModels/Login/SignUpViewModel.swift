import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var confirmPassword: String = ""
    @Published var showingSignUpError = false
    @Published var signUpErrorMessage: String = ""
    @Published var signUpSuccessMessage: String = ""
    @Published var passwordValidationMessage: String = ""
    @Published var usernameValidationMessage: String = ""
    @Published var isLoggedIn: Binding<Bool>
    @Published var alert: SignUpAlertType?
    
    private let authenticationService: AuthenticationServiceProtocol

    init(isLoggedIn: Binding<Bool>, authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
        self.isLoggedIn = isLoggedIn
    }

    func signUpUser() {
        if !validatePasswordCriteria() || !validateUsernameCriteria() {
            return
        }
        self.showingSignUpError = true

        let trimmedLowercaseUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        authenticationService.signUpUser(email: email, password: password, username: trimmedLowercaseUsername) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Sign up successful")
                    self?.signUpSuccessMessage = "Successfully signed up. Please log in"
                    self?.alert = .success
                case .failure(let error):
                    print("Sign up error: \(error.localizedDescription)")
                    
                    if let cognitoError = error as NSError? {
                        let userInfo = cognitoError.userInfo
  
                        if let errorMessage = userInfo["message"] as? String {
                            if errorMessage == "PreSignUp failed with error Username already exists." {
                                self?.signUpErrorMessage = "Username already exists, please try again."
                            } else {
                                self?.signUpErrorMessage = "Failed to sign up, please try again later."
                            }
                        } else {
                            self?.signUpErrorMessage = "An unexpected error occurred, please try again."
                        }
                    } else {
                        self?.signUpErrorMessage = "Failed to sign up, please try again later."
                    }
                    self?.alert = .error
                }
            }
        }
    }
    
    func validatePasswordCriteria() -> Bool {
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
        
        passwordValidationMessage = ""
        
        return true
    }
    
    func validateUsernameCriteria() -> Bool {
        let regex = "^[a-zA-Z0-9_-]{3,16}$"
        let regexTest = NSPredicate(format:"SELF MATCHES %@", regex)
        
        if !regexTest.evaluate(with: username) {
            usernameValidationMessage = "Usernames must be between 3 and 16 characters long, containing only alphanumeric characters, underscores, or dashes."
            return false
        }
        
        usernameValidationMessage = ""
        
        return true
    }
}
