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

        var request = URLRequest(url: url)
        var cachedEtag = ""
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            self.imageData = cachedResponse.data
            self.isLoading = false
            
            if let httpResponse = cachedResponse.response as? HTTPURLResponse {
                if let eTag = httpResponse.allHeaderFields["Etag"] as? String {
                    request.addValue(eTag, forHTTPHeaderField: "If-None-Match")
                    cachedEtag = eTag
                }
            }
        }

        loadImage(url: url, eTag: cachedEtag)
    }
    
    private func loadImage(url: URL, eTag: String) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.addValue("image/jpeg", forHTTPHeaderField: "Accept")
        request.addValue(eTag, forHTTPHeaderField: "If-None-Match")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response, error == nil else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let cachedData = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedData, for: URLRequest(url: url))
                    DispatchQueue.main.async {
                        self.imageData = data
                        self.isLoading = false
                    }
                }
            }
        }.resume()
    }
}
