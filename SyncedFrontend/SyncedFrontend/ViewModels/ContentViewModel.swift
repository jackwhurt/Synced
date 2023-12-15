import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    private let authenticationService: AuthenticationServiceProtocol
    private let collaborativePlaylistService: CollaborativePlaylistService
    
    init(authenticationService: AuthenticationServiceProtocol, collaborativePlaylistService: CollaborativePlaylistService) {
        self.authenticationService = authenticationService
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    func onOpen() async {
        isLoading = true
        
        checkUserSession()
        await collaborativePlaylistService.updatePlaylists()
        
        isLoading = false
    }
    
    private func checkUserSession() {
        authenticationService.checkSession { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoggedIn = success
            }
        }
    }
}
