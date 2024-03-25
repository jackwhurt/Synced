import XCTest
import MusicKit
@testable import Synced

enum ServiceError: Error {
    case fetchFailed
    case unauthorized
    case unexpectedResponse
}

final class CollaborativePlaylistServiceTests: XCTestCase {
    var service: CollaborativePlaylistService!
    var mockAPIService: MockAPIService!
    var mockAppleMusicService: MockAppleMusicService!
    var mockMusicKitService: MockMusicKitService!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        mockAppleMusicService = MockAppleMusicService()
        mockMusicKitService = MockMusicKitService()
        service = CollaborativePlaylistService(apiService: mockAPIService, appleMusicService: mockAppleMusicService, musicKitService: mockMusicKitService)
    }
    
    // Success scenario setup
    func setupForUpdatePlaylistSuccessScenario() {
        let mockSongUpdate = SongUpdate(playlistId: "1", appleMusicPlaylistId: "AM1", songs: [])
        let mockPlaylistUpdate = PlaylistUpdate(appleMusicPlaylistId: "AM1", playlistId: "1", description: "New Description", title: "New Title", delete: false)
        let mockUpdatePlaylistsResponse = UpdatePlaylistsResponse(songUpdates: [mockSongUpdate], playlistUpdates: [mockPlaylistUpdate])
        
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            return mockUpdatePlaylistsResponse
        }
        
        mockAPIService.makeDeleteRequestHandler = { endpoint, modelType, body in
            return DeleteAppleMusicDeleteFlagsResponse(message: "Success")
        }
    }
    
    // Failure scenario setup
    func setupForUpdatePlaylistFailureScenario() {
        let mockError = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mocked error"])
        
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            throw mockError
        }
    }
    
    func testShouldCallApiGetRequestWhenUpdatingPlaylists() async throws {
        setupForUpdatePlaylistSuccessScenario()
        UserDefaults.standard.set("timestamp1", forKey: "lastUpdatedTimestamp")
        
        try await service.updatePlaylists()
        
        // Verify the API was called with the correct params
        XCTAssertEqual(mockAPIService.makeGetRequestCallCount, 1)
        XCTAssertEqual(mockAPIService.makeGetRequestLastParams?.endpoint, "/songs/apple-music")
        XCTAssertEqual(mockAPIService.makeGetRequestLastParams?.parameters, ["timestamp": "timestamp1"])
    }
    
    func testShouldEditAppleMusicPlaylistWhenUpdatingPlaylistsAndThereExistsSongUpdates() async throws {
        setupForUpdatePlaylistSuccessScenario()
        
        try await service.updatePlaylists()
        
        guard let songsParam = mockMusicKitService.lastEditPlaylistParams?.songs as? [Song] else {
            XCTFail("Failed to cast songs to [Song]")
            return
        }
        XCTAssertTrue(songsParam.isEmpty)
        XCTAssertEqual(mockMusicKitService.editPlaylistCallCount, 1)
    }
    
    func testShouldNotEditAppleMusicPlaylistWhenUpdatingPlaylistsAndThereExistsNoSongUpdates() async throws {
        setupForUpdatePlaylistSuccessScenario()

        let mockUpdatePlaylistsResponse = UpdatePlaylistsResponse(songUpdates: [], playlistUpdates: [])
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            return mockUpdatePlaylistsResponse
        }
        
        try await service.updatePlaylists()
        
        XCTAssertEqual(mockMusicKitService.editPlaylistCallCount, 0)
    }
    
    func testShouldSoftDeletePlaylistWhenUpdatingPlaylistsAndThereExistsADeleteFlag() async throws {
        let testPlaylist = try await mockMusicKitService.getPlaylist(id: "")
        setupForUpdatePlaylistSuccessScenario()
        let mockSongUpdate = SongUpdate(playlistId: "1", appleMusicPlaylistId: "AM1", songs: [])
        let mockPlaylistUpdate = PlaylistUpdate(appleMusicPlaylistId: "AM1", playlistId: "1", description: "New Description", title: "New Title", delete: true)
        let mockUpdatePlaylistsResponse = UpdatePlaylistsResponse(songUpdates: [mockSongUpdate], playlistUpdates: [mockPlaylistUpdate])
        
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            return mockUpdatePlaylistsResponse
        }
        
        try await service.updatePlaylists()
        
        XCTAssertEqual(mockMusicKitService.softDeletePlaylistCallCount, 1)
        XCTAssertEqual(mockMusicKitService.lastSoftDeletePlaylist, testPlaylist)
    }
    
    func testShouldNotSoftDeletePlaylistWhenUpdatingPlaylistsAndThereExistsNoDeleteFlags() async throws {
        setupForUpdatePlaylistSuccessScenario()
        
        try await service.updatePlaylists()
        
        // Verify softDeletePlaylist was called
        XCTAssertEqual(mockMusicKitService.softDeletePlaylistCallCount, 0)
    }
    
    func testShouldUpdateTimestampWhenSuccessfullyUpdatingPlaylists() async throws {
        setupForUpdatePlaylistSuccessScenario()
        UserDefaults.standard.set("timestamp1", forKey: "lastUpdatedTimestamp")
        
        try await service.updatePlaylists()
        
        // Verify softDeletePlaylist was called
        XCTAssertNotEqual(UserDefaults.standard.object(forKey: "lastUpdatedTimestamp") as! String, "timestamp1")
    }
    
    func testShouldNotDeleteAppleMusicFlagsWhenFailedUpdatingPlaylists() async throws {
        setupForUpdatePlaylistSuccessScenario()
        
        try await service.updatePlaylists()
        
        // Verify softDeletePlaylist was called
        XCTAssertEqual(mockAPIService.makeDeleteRequestCallCount, 0)
    }
    
    func testShouldDeleteAppleMusicFlagsWhenFinishedSuccessfullyUpdatingPlaylists() async throws {
        setupForUpdatePlaylistSuccessScenario()
        let testPlaylist = try await mockMusicKitService.getPlaylist(id: "")
        setupForUpdatePlaylistSuccessScenario()
        
        let mockSongUpdate = SongUpdate(playlistId: "1", appleMusicPlaylistId: "AM1", songs: [])
        let mockPlaylistUpdate = PlaylistUpdate(appleMusicPlaylistId: "AM1", playlistId: "1", description: "New Description", title: "New Title", delete: true)
        let mockUpdatePlaylistsResponse = UpdatePlaylistsResponse(songUpdates: [mockSongUpdate], playlistUpdates: [mockPlaylistUpdate])
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            return mockUpdatePlaylistsResponse
        }
        
        let result = DeleteAppleMusicDeleteFlagsRequest(playlistIds: ["1"])
        mockAPIService.makeDeleteRequestHandler = { (_, _, _) async throws -> Any in
            return DeleteAppleMusicDeleteFlagsResponse(message: "Success")
        }
        
        try await service.updatePlaylists()
        
        XCTAssertEqual(mockAPIService.makeDeleteRequestCallCount, 1)
        XCTAssertEqual(mockAPIService.makeDeleteRequestLastParams?.endpoint, "/songs/apple-music")
        XCTAssertEqual(mockAPIService.makeDeleteRequestLastParams?.body as! DeleteAppleMusicDeleteFlagsRequest, result)
    }
    
    func testShouldThrowErrorWhenUpdatingPlaylists() async throws {
        setupForUpdatePlaylistFailureScenario()
        
        do {
            try await service.updatePlaylists()
            XCTFail("Expected `updatePlaylists` to throw an error, but it did not.")
        } catch {
            XCTAssertTrue(true, "Expected failure occurred.")
        }
    }
    
    func testShouldNotUpdateTimestampWhenSuccessfullyUpdatingPlaylists() async throws {
        setupForUpdatePlaylistFailureScenario()
        UserDefaults.standard.set("timestamp1", forKey: "lastUpdatedTimestamp")
        
        do {
            try await service.updatePlaylists()
            XCTFail("Expected `updatePlaylists` to throw an error, but it did not.")
        } catch {
            XCTAssertEqual(UserDefaults.standard.object(forKey: "lastUpdatedTimestamp") as! String, "timestamp1")
        }
    }
    
    // createPlaylist
    
    func setupForCreatePlaylistSuccessScenario() {
        let mockResponse = CreateCollaborativePlaylistResponse(id: "testPlaylistID")
        mockAPIService.makePostRequestWithBodyHandler = { (_, _, _, _) async throws -> Any in
            return mockResponse
        }
    }
    
    func setupForCreatePlaylistFailureScenario() {
        let mockError = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mocked error"])
        
        mockAPIService.makeGetRequestHandler = { (_, _, _) async throws -> Any in
            throw mockError
        }
    }
    
    func testShouldCreateBackendPlaylistWhenCreatingPlaylist() async throws {
        setupForCreatePlaylistSuccessScenario()

        let request = CreateCollaborativePlaylistRequest(playlist: CollaborativePlaylist(title: "Test Playlist", description: "A test playlist", songs: []), collaborators: ["collaboratorId1"], spotifyPlaylist: true, appleMusicPlaylist: true)
        let backendPlaylistId = try await service.createPlaylist(request: request)
        
    
        XCTAssertEqual(mockAPIService.makePostRequestWithBodyCallCount, 1)
        XCTAssertEqual(mockAPIService.makePostRequestWithBodyLastParams?.endpoint, "/collaborative-playlists")
    }
    
    func testShouldCreateAppleMusicPlaylistWhenCreatingPlaylistAndAppleMusicTrue() async throws {
        setupForCreatePlaylistSuccessScenario()

        let request = CreateCollaborativePlaylistRequest(playlist: CollaborativePlaylist(title: "Test Playlist", description: "A test playlist", songs: []), collaborators: ["collaboratorId1"], spotifyPlaylist: true, appleMusicPlaylist: true)
        let backendPlaylistId = try await service.createPlaylist(request: request)
        
        XCTAssertEqual(mockAppleMusicService.createAppleMusicPlaylistCallCount, 1)
        XCTAssertEqual(mockAppleMusicService.lastCreateAppleMusicPlaylistParams?.title, "Test Playlist")
        XCTAssertEqual(mockAppleMusicService.lastCreateAppleMusicPlaylistParams?.description, "A test playlist")
    }
    
    func testShouldNotCallCreateAppleMusicPlaylistWhenCreatingPlaylistAndAppleMusicFalse() async throws {
        setupForCreatePlaylistSuccessScenario()

        let request = CreateCollaborativePlaylistRequest(playlist: CollaborativePlaylist(title: "Test Playlist", description: "A test playlist", songs: []), collaborators: ["collaboratorId1"], spotifyPlaylist: true, appleMusicPlaylist: false)
        let backendPlaylistId = try await service.createPlaylist(request: request)
        
        XCTAssertEqual(mockAppleMusicService.createAppleMusicPlaylistCallCount, 0)
    }
    
    func testShouldReturnBackendPlaylistIdWhenCreatingPlaylist() async throws {
        setupForCreatePlaylistSuccessScenario()

        let request = CreateCollaborativePlaylistRequest(playlist: CollaborativePlaylist(title: "Test Playlist", description: "A test playlist", songs: []), collaborators: ["collaboratorId1"], spotifyPlaylist: true, appleMusicPlaylist: true)
        let backendPlaylistId = try await service.createPlaylist(request: request)
        
        XCTAssertEqual(backendPlaylistId, "testPlaylistID")
    }
    
    func testShouldThrowErrorWhenCreatingPlaylist() async throws {
        setupForUpdatePlaylistFailureScenario()
        
        do {
            try await service.updatePlaylists()
            XCTFail("Expected `updatePlaylists` to throw an error, but it did not.")
        } catch {
            XCTAssertTrue(true, "Expected failure occurred.")
        }
    }
    
    // deletePlaylist
    
    func setupForDeletePlaylistSuccessScenario() {
        mockMusicKitService.softDeletePlaylistHandler = { _ in }
        
        let mockResponse = DeleteCollaborativePlaylistResponse(id: "deletedPlaylistID")
        mockAPIService.makeDeleteRequestHandler = { (_, _, _) async throws -> Any in
            return mockResponse
        }
    }

    func setupForDeletePlaylistFailureScenario() {
        let mockError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mocked deletion error"])
        
        mockAPIService.makeDeleteRequestHandler = { (_, _, _) async throws -> Any in
            throw mockError
        }
    }

    func testShouldSoftDeleteAppleMusicPlaylistWhenDeletingPlaylistWithAppleMusicPlaylistId() async throws {
        setupForDeletePlaylistSuccessScenario()

        let deletedPlaylistId = try await service.deletePlaylist(playlistId: "testPlaylistID", appleMusicPlaylistId: "AMPlaylistID")
        
        XCTAssertEqual(mockMusicKitService.softDeletePlaylistCallCount, 1)
        XCTAssertEqual(deletedPlaylistId, "deletedPlaylistID")
    }

    func testShouldNotSoftDeleteAppleMusicPlaylistWhenAppleMusicPlaylistIdIsNil() async throws {
        setupForDeletePlaylistSuccessScenario()

        let deletedPlaylistId = try await service.deletePlaylist(playlistId: "testPlaylistID", appleMusicPlaylistId: nil)
        
        XCTAssertEqual(mockMusicKitService.softDeletePlaylistCallCount, 0)
        XCTAssertEqual(deletedPlaylistId, "deletedPlaylistID")
    }

    func testShouldDeleteBackendPlaylistWhenDeletingPlaylist() async throws {
        setupForDeletePlaylistSuccessScenario()

        let deletedPlaylistId = try await service.deletePlaylist(playlistId: "testPlaylistID", appleMusicPlaylistId: nil)
        
        XCTAssertEqual(mockAPIService.makeDeleteRequestCallCount, 1)
        XCTAssertEqual(deletedPlaylistId, "deletedPlaylistID")
    }

    func testShouldThrowErrorWhenDeletionFails() async throws {
        setupForDeletePlaylistFailureScenario()

        do {
            _ = try await service.deletePlaylist(playlistId: "testPlaylistID", appleMusicPlaylistId: "AMPlaylistID")
            XCTFail("Expected `deletePlaylist` to throw an error, but it did not.")
        } catch {
            XCTAssertTrue(true, "Expected failure occurred.")
        }
    }

}
