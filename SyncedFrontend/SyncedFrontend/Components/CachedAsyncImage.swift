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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response, error == nil else {
                return
            }
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                if httpResponse.allHeaderFields["Etag"] as? String != cachedEtag {
                    let cachedData = CachedURLResponse(response: response, data: data)
                    if let url = request.url {
                        let requestUrlOnly = URLRequest(url: url)
                        URLCache.shared.storeCachedResponse(cachedData, for: requestUrlOnly)
                        DispatchQueue.main.async {
                            self.imageData = data
                            self.isLoading = false
                        }
                    }
                }
            }
        }.resume()
    }
}
