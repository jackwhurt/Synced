import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = true
    private let authenticationService: AuthenticationServiceProtocol
    private let collaborativePlaylistService: CollaborativePlaylistService
    
    init(authenticationService: AuthenticationServiceProtocol, collaborativePlaylistService: CollaborativePlaylistService) {
        self.authenticationService = authenticationService
        self.collaborativePlaylistService = collaborativePlaylistService
    }
    
    func onOpen() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        checkUserSession()
        do {
            try await collaborativePlaylistService.updatePlaylists()
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
