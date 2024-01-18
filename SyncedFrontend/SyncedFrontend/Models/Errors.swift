enum AuthenticationServiceError: Error {
    case cognitoIdsNotSet
    case cognitoUserPoolFailedToInitialise
    case failedToRetrieveTokens
    case failedToRefreshTokens
    case failedToLogin
    case noCurrentUserFound
    case noRefreshTokenFound
    case failedToClearTokens
    case failedToSaveTokens
}

enum FallbackAuthenticationError: Error {
    case loginNotAvailable
    case logoutNotAvailable
    case signupNotAvailable
    case tokenRefreshNotAvailable
}

enum MusicKitError: Error {
    case failedToCreatePlaylist
    case failedToEditPlaylist
    case failedToRetrievePlaylist
    case playlistNotInLibrary
}

enum APIServiceError: Error {
    case tokenRetrievalFailed
    case invalidURL
    case failedToDecodeResponse
}

enum AppleMusicServiceError: Error {
    case developerTokenRetrievalFailed
    case userTokenRequestFailed(Error?)
    case authorizationRequestFailed
    case songUpdatesRetrievalFailed
    case playlistUpdateFailed
    case playlistReplacementFailed
    case playlistCreationFailed
    case failedToFormatTimestamp
    case playlistEditFailed
    case songConversionFailed
}

enum CollaborativePlaylistServiceError: Error {
    case playlistRetrievalFailed
    case playlistCreationFailed
    case playlistDeletionFailed
    case backendPlaylistCreationFailed
    case failedToDeleteSongs
    case failedToEditSongs
    case backendPlaylistDeletionFailed
}

enum SongServiceError: Error {
    case spotifySearchFailed
    case songConversionFailed
}

