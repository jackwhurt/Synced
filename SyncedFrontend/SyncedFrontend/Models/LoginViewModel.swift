import SwiftUI

// ViewModel for the LoginView
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var showingLoginError = false
    @Published var isLoggedIn: Binding<Bool>

    private let authService: AuthenticationService

    init(isLoggedIn: Binding<Bool>, authService: AuthenticationService? = AuthenticationService()) {
        guard let authService = authService else {
            fatalError("Failed to initialize AuthenticationService")
        }
        self.authService = authService
        self.isLoggedIn = isLoggedIn
    }

    func loginUser() {
        authService.loginUser(username: username, password: password) { [weak self] result in
            switch result {
            case .success():
                print("Login successful")
                DispatchQueue.main.async {
                    self?.isLoggedIn.wrappedValue = true
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
