import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = true
    private let authenticationService: AuthenticationServiceProtocol
    private let appleMusicService: AppleMusicService
    
    init(authenticationService: AuthenticationServiceProtocol, appleMusicService: AppleMusicService) {
        self.authenticationService = authenticationService
        self.appleMusicService = appleMusicService
    }
    
    func onOpen() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        checkUserSession()
        do {
            try await appleMusicService.updatePlaylists()
        } catch{
            print("Update playlists failed")
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    private func checkUserSession() {
        authenticationService.checkSession { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoggedIn = success
            }
        }
    }
}
