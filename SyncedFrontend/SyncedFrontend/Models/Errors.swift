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
