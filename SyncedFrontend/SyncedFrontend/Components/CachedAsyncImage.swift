import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    var content: (Image) -> Content
    var placeholder: () -> Placeholder
    @State private var imageData: Data?
    @State private var isLoading = true
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if isLoading {
                placeholder()
            } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                content(Image(uiImage: uiImage))
                    .clipped()
            } else {
                placeholder()
            }
        }
        .cornerRadius(5)
        .onAppear {
             loadImageFromCacheOrDownload()
        }
    }
    
    private func loadImageFromCacheOrDownload() {
        guard let url = url else {
            self.isLoading = false
            return
        }

        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            self.imageData = cachedResponse.data
            self.isLoading = false
        } else {
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response, error == nil, let _ = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.imageData = data
                    self.isLoading = false
                }
            }.resume()
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    // TODO: Delete
    private func loadImage(url: URL, eTag: String) async {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.addValue("image/jpeg", forHTTPHeaderField: "Accept")
        request.addValue(eTag, forHTTPHeaderField: "If-None-Match")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let cachedData = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedData, for: URLRequest(url: url))
                DispatchQueue.main.async {
                    self.imageData = data
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
