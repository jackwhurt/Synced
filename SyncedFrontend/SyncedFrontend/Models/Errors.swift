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

