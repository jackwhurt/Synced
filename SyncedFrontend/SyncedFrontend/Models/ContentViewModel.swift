import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var isLoggedIn = false
    private var authenticationService = AuthenticationService()

    init() {
        checkUserSession()
    }

    func checkUserSession() {
        authenticationService?.checkSession { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoggedIn = success
            }
        }
    }

    func recheckSession() {
        checkUserSession()
    }
}
