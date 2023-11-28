import SwiftUI

struct Logo: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 150)
    }
}

struct LogoPreview: PreviewProvider {
    static var previews: some View {
        Logo()
    }
}
