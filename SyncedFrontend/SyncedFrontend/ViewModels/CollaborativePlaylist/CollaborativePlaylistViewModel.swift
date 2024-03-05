import Foundation
import SwiftUI

class CollaborativePlaylistViewModel: ObservableObject {
    @Published var playlistSongs: [SongMetadata] = []
    @Published var playlistMetadata: PlaylistMetadata?
    @Published var collaborators: [UserMetadata] = []
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var songsToAdd: [SongMetadata] = []
    @Published var playlistOwner = false
    @Published var imagePreview: UIImage?
    var autoDismiss = false
    var appleMusicPlaylistId: String? = nil
    var dismissAction: (() -> Void)?
    var songsToDisplay: [SongMetadata] {
        return playlistSongs + songsToAdd
    }
    let playlistId: String
    
    private let collaborativePlaylistService: CollaborativePlaylistService
    private let imageService: ImageService
    private let authenticationService: AuthenticationServiceProtocol
    private var savedSongs: [SongMetadata] = []
    private var songsToDelete: [SongMetadata] = []
    
    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService, imageService: ImageService,
         authenticationService: AuthenticationServiceProtocol, dismissAction: (() -> Void)? = nil) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
        self.imageService = imageService
        self.authenticationService = authenticationService
        self.dismissAction = dismissAction
        loadCachedPlaylist()
    }
    
    func loadPlaylist() async {
        do {
            let fetchedPlaylist = try await collaborativePlaylistService.getPlaylistById(playlistId: playlistId)
            DispatchQueue.main.async { [weak self] in
                self?.playlistMetadata = fetchedPlaylist.metadata
                self?.playlistSongs = fetchedPlaylist.songs
                self?.collaborators = fetchedPlaylist.collaborators
                self?.appleMusicPlaylistId = fetchedPlaylist.appleMusicPlaylistId
            }
            setPlaylistOwner()
        } catch {
            print("Failed to load playlist: \(playlistId)")
            DispatchQueue.main.async { [weak self] in
                self?.autoDismiss = true
                self?.errorMessage = "Failed to load playlist, please try again later"
            }
        }
    }
    
    func deleteSong(from indexSet: IndexSet) {
        // Ensure there's a valid index
        guard let index = indexSet.first else { return }
        let songToDelete = songsToDisplay[index]
        
        // Check if the song is in songsToAdd
        if let indexInToAdd = songsToAdd.firstIndex(where: { $0.spotifyUri == songToDelete.spotifyUri }) {
            songsToAdd.remove(at: indexInToAdd)
        } else if let indexInPlaylistSongs = playlistSongs.firstIndex(where: { $0.spotifyUri == songToDelete.spotifyUri }) {
            // If not in songsToAdd, it must be in playlistSongs
            songsToDelete.append(songToDelete)
            playlistSongs.remove(at: indexInPlaylistSongs)
        }
    }
    
    func setEditingTrue() {
        self.isEditing = true
        self.savedSongs = self.playlistSongs
    }
    
    func saveChanges() async {
        do {
            try await saveImage()
            try await collaborativePlaylistService.editSongs(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId, songsToDelete: songsToDelete, songsToAdd: songsToAdd, oldSongs: playlistSongs )
            let newSongs = self.songsToAdd
            setEditingFalse()
            DispatchQueue.main.async { [weak self] in
                self?.playlistSongs.append(contentsOf: newSongs)
            }
            await loadPlaylist()
        } catch {
            print("Failed to save changes for playlist \(playlistId): \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.autoDismiss = false
                self?.errorMessage = "Failed to save changes"
            }
        }
    }
    
    func deletePlaylist() async {
        do {
            let deletedPlaylistId = try await collaborativePlaylistService.deletePlaylist(playlistId: playlistId, appleMusicPlaylistId: appleMusicPlaylistId)
            print("Successfully deleted playlist \(deletedPlaylistId)")
            DispatchQueue.main.async { [weak self] in
                self?.dismissAction?()
            }
        } catch {
            print("Failed to delete playlist \(playlistId): \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.autoDismiss = false
                self?.errorMessage = "Failed to delete playlist. Please try again later"
            }
        }
    }
    
    func cancelChanges() {
        playlistSongs = savedSongs
        songsToAdd = []
        songsToDelete = []
        setEditingFalse()
        imagePreview = nil
    }
    
    private func loadCachedPlaylist() {
        if let cachedMetadata: PlaylistMetadata = CachingService.shared.load(forKey: "playlistMetadata_\(playlistId)", type: PlaylistMetadata.self),
           let cachedSongs: [SongMetadata] = CachingService.shared.load(forKey: "playlistSongs_\(playlistId)", type: [SongMetadata].self) {
            DispatchQueue.main.async { [weak self] in
                self?.playlistMetadata = cachedMetadata
                self?.playlistSongs = cachedSongs
            }
            setPlaylistOwner()
        } else {
            Task {
                await loadPlaylist()
            }
        }
    }
    
    private func saveImage() async throws {
        guard let image = imagePreview else {
            return
        }
        
        do {
            try await imageService.saveImage(playlistId: playlistId, image: image, s3Url: playlistMetadata?.coverImageUrl)
        } catch {
            print("Failed to save image: \(error)")
            throw CollaborativePlaylistViewModelError.failedToSaveImage
        }
    }
    
    private func setEditingFalse() {
        self.songsToDelete = []
        DispatchQueue.main.async { [weak self] in
            self?.isEditing = false
            self?.songsToAdd = []
        }
    }
    
    private func setPlaylistOwner() {
        let userId = authenticationService.getUserId()
        let valueToSet = playlistMetadata?.createdBy == userId
        DispatchQueue.main.async { [weak self] in
            self?.playlistOwner = valueToSet
        }
    }
}
