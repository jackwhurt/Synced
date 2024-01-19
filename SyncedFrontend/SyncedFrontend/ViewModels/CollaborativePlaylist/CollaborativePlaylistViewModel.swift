import Foundation

class CollaborativePlaylistViewModel: ObservableObject {
    @Published var playlistSongs: [SongMetadata] = []
    @Published var playlistMetadata: PlaylistMetadata?
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var songsToAdd: [SongMetadata] = []
    @Published var playlistOwner = false
    var autoDismiss = false
    var appleMusicPlaylistId: String? = nil
    var dismissAction: (() -> Void)?
    var songsToDisplay: [SongMetadata] {
        return playlistSongs + songsToAdd
    }
    
    private let playlistId: String
    private let collaborativePlaylistService: CollaborativePlaylistService
    private let authenticationService: AuthenticationServiceProtocol
    private var savedSongs: [SongMetadata] = []
    private var songsToDelete: [SongMetadata] = []

    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService, authenticationService: AuthenticationServiceProtocol, dismissAction: (() -> Void)? = nil) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
        self.authenticationService = authenticationService
        self.dismissAction = dismissAction
    }

    func loadPlaylist() async {
        do {
            let fetchedPlaylist = try await collaborativePlaylistService.getPlaylistById(playlistId: playlistId)
            DispatchQueue.main.async { [weak self] in
                self?.playlistMetadata = fetchedPlaylist.metadata
                self?.playlistSongs = fetchedPlaylist.songs
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
    
    func deleteSong(song: SongMetadata) {
        songsToDelete.append(song)
        
        if let index = playlistSongs.firstIndex(of: song) {
            playlistSongs.remove(at: index)
        }
    }
    
    func setEditingTrue() {
        self.isEditing = true
        self.savedSongs = self.playlistSongs
    }
    
    func saveChanges() async {
        do {
            try await collaborativePlaylistService.editSongs(appleMusicPlaylistId: appleMusicPlaylistId, playlistId: playlistId, songsToDelete: songsToDelete, songsToAdd: songsToAdd, newSongs: playlistSongs )
            let newSongs = self.songsToAdd
            setEditingFalse()
            DispatchQueue.main.async { [weak self] in
                self?.playlistSongs.append(contentsOf: newSongs)
            }
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
            let deletedPlaylistId = try await collaborativePlaylistService.deletePlaylist(playlistId: playlistId)
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
        setEditingFalse()
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
