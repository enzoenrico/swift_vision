import SwiftUI

struct CameraView: View {
    @Binding var image: CGImage?
    var body: some View {
        GeometryReader { geo in
            if let image = image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                ContentUnavailableView("No camera feed :c", systemImage: "xmark.circle.fill")
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
