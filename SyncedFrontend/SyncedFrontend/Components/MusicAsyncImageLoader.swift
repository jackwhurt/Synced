import SwiftUI

struct MusicAsyncImageLoader: View {
    let urlString: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        if let urlString = urlString, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } placeholder: {
                ProgressView()
            }
            .frame(width: width, height: height)
            .cornerRadius(5)
        } else {
            Rectangle()
                .fill(Color.gray)
                .frame(width: width, height: height)
                .cornerRadius(5)
        }
    }
}

// Preview Provider
struct AsyncImageLoader_Previews: PreviewProvider {
    static var previews: some View {
        MusicAsyncImageLoader(
            urlString: "https://example.com/sample-image.jpg",
            width: 100,
            height: 100
        )
    }
}
