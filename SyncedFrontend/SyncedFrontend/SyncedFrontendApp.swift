//
//  SyncedFrontendApp.swift
//  SyncedFrontend
//
//  Created by Jack Hurt on 23/11/2023.
//

import SwiftUI

@main
struct SyncedFrontendApp: App {
    let appSettings = AppSettings(appleMusicService: DIContainer.shared.provideAppleMusicService())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .onOpenURL { url in
                    Task {
                        let result = await DIContainer.shared.provideSpotifyService().handleAuthCallback(url: url)
                        if result {
                            appSettings.isSpotifyConnected = true
                        }
                    }
                }
        }
    }
}
