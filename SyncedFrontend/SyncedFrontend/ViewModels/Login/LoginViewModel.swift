import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showingLoginError = false
    @Published var isLoggedIn: Binding<Bool>

    private let authenticationService: AuthenticationServiceProtocol

    init(isLoggedIn: Binding<Bool>, authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
        self.isLoggedIn = isLoggedIn
        CachingService.shared.clearCache()
    }

    func loginUser() {
        authenticationService.loginUser(email: email, password: password) { [weak self] result in
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
