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
        
        authenticationService.checkSession { success in
            DispatchQueue.main.async {
                self.isLoggedIn = success
            }
            
            if success {
                Task {
                    do {
                        try await self.collaborativePlaylistService.updatePlaylists()
                    } catch {
                        print("Update playlists failed")
                    }
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
