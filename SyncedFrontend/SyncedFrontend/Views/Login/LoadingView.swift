import SwiftUI

struct LoadingView: View {
    let animationFrames: [String] = (1...30).map { "Image \($0)" }
    @State private var currentFrameIndex = 0
    @State private var timer: Timer?

    var body: some View {
//        Image(animationFrames[currentFrameIndex])
//            .resizable()
//            .scaledToFit()
//            .onAppear {
//                timer = Timer.scheduledTimer(withTimeInterval: 0.040, repeats: true) { _ in
//                    // Increment frame index and stop the timer if it's the last frame
//                    if currentFrameIndex < animationFrames.count - 1 {
//                        currentFrameIndex += 1
//                    } else {
//                        timer?.invalidate()
//                    }
//                }
//            }
//            .onDisappear {
//                timer?.invalidate()
//            }
        Text("Loading")
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
