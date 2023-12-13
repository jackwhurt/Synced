import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var isLoggedIn = false
    private let authenticationService: AuthenticationServiceProtocol
    
    init(authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
        checkUserSession()
    }

    func checkUserSession() {
        authenticationService.checkSession { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoggedIn = success
            }
        }
    }

    func recheckSession() {
        checkUserSession()
    }
}
