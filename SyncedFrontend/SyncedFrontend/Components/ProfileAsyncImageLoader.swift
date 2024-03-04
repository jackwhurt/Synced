import SwiftUI

struct ProfileAsyncImageLoader: View {
    let urlString: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        if let imageURL = urlString, let url = URL(string: imageURL) {
            CachedAsyncImage(url: url, reloadAfterCacheHit: true) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        }
    }
}

// Preview Provider
struct ProfileImageLoader_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAsyncImageLoader(
            urlString: "https://example.com/sample-image.jpg",
            width: 100,
            height: 100
        )
    }
}
