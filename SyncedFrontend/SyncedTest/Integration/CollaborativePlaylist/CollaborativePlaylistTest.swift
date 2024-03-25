import XCTest
@testable import Synced

class CollaborativePlaylistIntegrationTest: XCTestCase {
    let testPlaylistId = "a6dcc1c8-d368-482a-b493-c3dd08fa8753"
    let testPlaylistIdUnauthorised = "5868d36f-f7e8-4294-89ba-206945ff043e"
    let testAppleMusicPlaylistId = "p.EP80cV3KQqg"
    
    var service: CollaborativePlaylistService!
    
    override func setUpWithError() throws {
        super.setUp()
        
        service = DIContainer.shared.provideCollaborativePlaylistService()
    }
    
    override func tearDownWithError() throws {
        service = nil
        super.tearDown()
    }
    
    func testShouldGetPlaylists() async throws {
        do {
            let playlists = try await service.getPlaylists()
            XCTAssertNotEqual(playlists.count, 0, "Should retrieve at least one playlist")
            // Further assertions can be made based on expected test data
        } catch {
            XCTFail("Integration test for getting playlists failed with error: \(error)")
        }
    }
    
    func testShouldGetPlaylistById() async throws {
        do {
            let playlists = try await service.getPlaylistById(playlistId: testPlaylistId)
            XCTAssertEqual(playlists.playlistId, testPlaylistId)
        } catch {
            XCTFail("Integration test for getting playlists failed with error: \(error)")
        }
    }
    
    func testShouldThrowErrorWhenIdInvalid() async throws {
        do {
            let _ = try await service.getPlaylistById(playlistId: "invalidId")
            XCTFail("Returned playlist")
        } catch {
            XCTAssertTrue(true, "Invalid ID")
        }
    }
    
    func testShouldCreateAndDeletePlaylist() async throws {
        let request = CreateCollaborativePlaylistRequest(
            playlist: CollaborativePlaylist(title: "Test Playlist", description: "", songs: []),
            collaborators: [],
            spotifyPlaylist: true,
            appleMusicPlaylist: true
        )
        
        do {
            let playlistId = try await service.createPlaylist(request: request)
            XCTAssertNotNil(playlistId, "Playlist ID should not be nil after creation")
            
            let deletedPlaylistId = try await service.deletePlaylist(playlistId: playlistId, appleMusicPlaylistId: nil)
            XCTAssertEqual(deletedPlaylistId, playlistId)
        } catch {
            XCTFail("Integration test for creating and deleting a playlist failed with error: \(error)")
        }
    }
    
    func testShouldFailToDeletePlaylistWhenIdInvalid() async throws {
        do {
            let _ = try await service.deletePlaylist(playlistId: "playlistId", appleMusicPlaylistId: nil)
            XCTFail("Successfully deleted playlist")
        } catch {
            XCTAssertTrue(true, "Failed to delete playlist with invalid id")
        }
    }
    
    func testShouldFailToDeletePlaylistWhenUnauthorised() async throws {
        do {
            let _ = try await service.deletePlaylist(playlistId: testPlaylistIdUnauthorised, appleMusicPlaylistId: nil)
            XCTFail("Successfully deleted playlist")
        } catch {
            XCTAssertTrue(true, "Failed to delete playlist created by a different user")
        }
    }

    func testShouldEditSongsInPlaylist() async throws {
        let songsToAdd = [SongMetadata(songId: "newSong", title: "New Song 1", album: "Album 1", artist: "Artist 1", spotifyUri: nil, appleMusicUrl: "/v1/catalog/gb/songs/1440906589", appleMusicId: "1440906589", coverImageUrl: nil)]
        let oldSongs = [SongMetadata(songId: "oldSong1", title: "Old Song 1", album: "Album 1", artist: "Artist 1", spotifyUri: nil, appleMusicUrl: "/v1/catalog/gb/songs/1440891494", appleMusicId: "1440891494", coverImageUrl: nil)]

        do {
            try await service.editSongs(appleMusicPlaylistId: testAppleMusicPlaylistId, playlistId: testPlaylistId, songsToDelete: [], songsToAdd: songsToAdd, oldSongs: oldSongs)
    
            XCTAssertTrue(true, "Successfully edited songs in playlist")
        } catch {
            XCTFail("Integration test for editing songs in a playlist failed with error: \(error)")
        }
    }
 
    func testShouldManageCollaborator() async throws {
        let collaboratorIds = ["693a4785-23a8-46d7-b273-e2023ee0c409"]
        
        do {
            let additionResult = try await service.addCollaborators(playlistId: testPlaylistId, collaboratorIds: collaboratorIds)
            let deletionResult = try await service.deleteCollaborators(playlistId: testPlaylistId, collaboratorIds: collaboratorIds)
            
            XCTAssertEqual(additionResult.first, deletionResult.first)
        } catch {
            XCTFail("Integration test for managing collaborators failed with error: \(error)")
        }
    }
    
    func testShouldFailToAddCollaboratorWhenIdInvalid() async throws {
        let collaboratorIdInvalid = ["testUserId"]
        
        do {
            _ = try await service.addCollaborators(playlistId: testPlaylistId, collaboratorIds: collaboratorIdInvalid)
            XCTFail("Integration test for adding invalid Collaborator didn't throw error")
        } catch {
            XCTAssertTrue(true, "Failed to add collaborator with invalid ID")
        }
    }
    
    func testShouldFailToAddCollaboratorWhenIdAlreadyAdded() async throws {
        let collaboratorIdAlreadyAdded = ["13a8cc73-aa90-42c1-9598-ea84ab3e4863"]
        
        do {
            _ = try await service.addCollaborators(playlistId: testPlaylistId, collaboratorIds: collaboratorIdAlreadyAdded)
            XCTFail("Integration test for adding invalid Collaborator didn't throw error")
        } catch {
            XCTAssertTrue(true, "Failed to add collaborator with invalid ID")
        }
    }
    
    func testShouldFailToAddCollaboratorWhenUnauthorised() async throws {
        let collaboratorIdAlreadyAdded = ["13a8cc73-aa90-42c1-9598-ea84ab3e4863"]
        
        do {
            _ = try await service.addCollaborators(playlistId: testPlaylistIdUnauthorised, collaboratorIds: collaboratorIdAlreadyAdded)
            XCTFail("Integration test for adding invalid Collaborator didn't throw error")
        } catch {
            XCTAssertTrue(true, "Failed to add collaborator with invalid ID")
        }
    }
    
    func testShouldFailToDeleteCollaboratorWhenIdInvalid() async throws {
        let collaboratorIdsToAdd = ["testUserId"]
        
        do {
            _ = try await service.deleteCollaborators(playlistId: testPlaylistId, collaboratorIds: collaboratorIdsToAdd)
            XCTFail("Integration test for adding invalid Collaborator didn't throw error")
        } catch {
            XCTAssertTrue(true, "Failed to add collaborator with invalid ID")
        }
    }
}
