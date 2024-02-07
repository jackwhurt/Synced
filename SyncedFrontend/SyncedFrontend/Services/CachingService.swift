import Foundation
import UIKit


// TODO: Move saving caching to services. duh
class CachingService {
    // Provides a single instance that can be accessed throughout the app, ensuring storage logic is centralised
    static let shared = CachingService()
    
    private let cache = NSCache<NSString, UIImage>()
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let filePath = getFilePath(forKey: key)
            let data = try JSONEncoder().encode(object)
            try data.write(to: filePath, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Could not save object: \(error)")
        }
    }
    
    func load<T: Codable>(forKey key: String, type: T.Type) -> T? {
        let filePath = getFilePath(forKey: key)
        do {
            let data = try Data(contentsOf: filePath)
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            print("Could not load object for key \(key): \(error)")
            return nil
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        let directory = getDocumentsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Could not clear documents directory: \(error)")
        }
    }
    
    private func getFilePath(forKey key: String) -> URL {
        let fileName = "\(key).json"
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
