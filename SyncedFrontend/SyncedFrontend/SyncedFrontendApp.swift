//
//  SyncedFrontendApp.swift
//  SyncedFrontend
//
//  Created by Jack Hurt on 23/11/2023.
//

import SwiftUI
import UserNotifications

@main
struct SyncedFrontendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let appSettings = AppSettings(appleMusicService: DIContainer.shared.provideAppleMusicService(), spotifyService: DIContainer.shared.provideSpotifyService())
    
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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            await DIContainer.shared.provideUserService().registerUserForApns(deviceToken: tokenString)
        }
    }
}
