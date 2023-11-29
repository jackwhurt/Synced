import SwiftUI

class CollaborativePlaylistsViewModel: ObservableObject {
    @Published var isLoggedIn = true
    private var authService: AuthenticationService?

    init() {
        authService = AuthenticationService()
    }

    func logout() {
        authService?.logoutUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isLoggedIn = false
                    // Additional logic after successful logout
                case .failure(let error):
                    print("Logout error: \(error.localizedDescription)")
                    // Handle error scenario
                }
            }
        }
    }
}
