import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Binding var isLoggedIn: Bool
    @Published var imagePreview: UIImage?
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var user: UserMetadata? {
        didSet {
            CachingService.shared.save(user, forKey: "UserMetadata")
        }
    }
    var isAppleMusicConnected = false
    
    private let appleMusicService: AppleMusicService
    private let spotifyService: SpotifyService
    private let authenticationService: AuthenticationServiceProtocol
    private let userService: UserService
    private let imageService: ImageService
    
    init(isLoggedIn: Binding<Bool>, appleMusicService: AppleMusicService, spotifyService: SpotifyService,
         authenticationService: AuthenticationServiceProtocol, userService: UserService, imageService: ImageService) {
        _isLoggedIn = isLoggedIn
        self.appleMusicService = appleMusicService
        self.spotifyService = spotifyService
        self.authenticationService = authenticationService
        self.userService = userService
        self.imageService = imageService
        self.isAppleMusicConnected = appleMusicService.checkCurrentAuthorizationStatus()
        self.loadUserMetadataFromCache()
    }
    
    func loadUser() {
        Task {
            do {
                guard let userId = authenticationService.getUserId() else { throw ProfileViewModelError.failedToGetUserId }
                let response = try await userService.getUserById(userId: userId)
                DispatchQueue.main.async {
                    self.user = response
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to load profile, please try again later."
                }
                print("Failed to retrieve user: \(error)")
            }
        }
    }
    
    func requestAuthentication() async -> Bool {
        let status = await appleMusicService.requestAuthorization()
        
        switch status {
        case .authorized:
            print("Successfully requested authorisation")
            return true
        case .denied, .notDetermined, .restricted:
            print("Authorization status: \(status)")
        @unknown default:
            print("Unexpected authorization status")
        }
        
        return false
    }
    
    func getSpotifyAuthURL() async -> URL? {
        do {
            let url = try await spotifyService.getSpotifyAuthURL()
            print("Successfully retrieved Spotify auth url: \(url)")
            
            return url
        } catch {
            print("Failed to get Spotify auth url: \(error)")
        }
        
        return nil
    }
    
    func saveChanges() {
        Task {
            do {
                try await saveImage()
                loadUser()
                DispatchQueue.main.async {
                    self.imagePreview = nil
                }
            } catch {
                print("Failed to save changes: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to save changes, please try again later."
                }
            }
            
        }
    }
    
    func logout() {
        CachingService.shared.clearCache()
        authenticationService.logoutUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isLoggedIn = false
                case .failure(let error):
                    print("Logout error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveImage() async throws {
        guard let image = imagePreview else {
            return
        }
        do {
            try await imageService.saveImage(userIdBool: "true", image: image, s3Url: user?.photoUrl)
        } catch {
            print("Failed to save changes: \(error)")
            throw CollaborativePlaylistViewModelError.failedToSaveImage
        }
    }
    
    private func loadUserMetadataFromCache() {
        if let cachedUserMetadata: UserMetadata = CachingService.shared.load(forKey: "UserMetadata", type: UserMetadata.self) {
            self.user = cachedUserMetadata
        }
    }
}
