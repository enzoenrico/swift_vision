import CoreImage
import Foundation
import Observation

@Observable
class ViewModel {
	var currentFrame: CGImage?
	private let cameraManager = CameraManager()

	init() {
		Task {
			await handleCameraPreview()
		}
	}

	func handleCameraPreview() async {
		for await image in cameraManager.previewStream {
			Task { @MainActor in
				currentFrame = image
			}
		}
	}
}
