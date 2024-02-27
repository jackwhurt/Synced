import Foundation
import SwiftUI

class EditCollaboratorsViewModel: ObservableObject {
    @Published var collaborators: [UserMetadata] = []
    @Published var errorMessage: String? = nil
    @Published var playlistId: String
    
    private let collaborativePlaylistService: CollaborativePlaylistService
    
    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
    }
    
    func loadCollaborators() {
        Task {
            do {
                //self.collaborators = collaborativePlaylistService.getCollaborators(playlistId: playlistId)
            } catch {
                // error
            }
        }
    }
    
    private func loadCachedCollaborators() {
        if let cachedCollaborators: [UserMetadata] = CachingService.shared.load(forKey: "playlistCollaborators_\(playlistId)", type: [UserMetadata].self) {
            DispatchQueue.main.async { [weak self] in
                self?.collaborators = cachedCollaborators
            }
        }
    }
}
