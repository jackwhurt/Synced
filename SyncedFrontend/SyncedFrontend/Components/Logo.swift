import SwiftUI

struct Logo: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(height: 250)
    }
}

struct LogoPreview: PreviewProvider {
    static var previews: some View {
        Logo()
    }
}
