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
