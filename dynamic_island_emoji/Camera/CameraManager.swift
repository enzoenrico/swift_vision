import AVFoundation
import Foundation

class CameraManager: NSObject {
	private let captureSession = AVCaptureSession()
	private var deviceInput: AVCaptureDeviceInput?
	private var videoOutput: AVCaptureVideoDataOutput?
	private let defaultCamera = AVCaptureDevice.default(for: .video)

	private var sessionQueue = DispatchQueue(label: "video.preview.session")

	private var isAuthorized: Bool {
		get async {
			let status = AVCaptureDevice.authorizationStatus(for: .video)
			var auth = status == .authorized
			if status == .notDetermined {
				auth = await AVCaptureDevice.requestAccess(for: .video)
			}
			return auth
		}
	}

	private var addToPreviewStream: ((CGImage) -> Void)?

	lazy var previewStream: AsyncStream<CGImage> = {
		AsyncStream { stream in
			addToPreviewStream =
				{ cg in
					stream.yield(cg)
				}

		}
	}()

	override init() {
		super.init()

		Task {
			await configureSession()
			await startSession()
		}
	}
	private func configureSession() async {
		guard await isAuthorized,
			let defaultCamera,
			let deviceInput = try? AVCaptureDeviceInput(device: defaultCamera)
		else {
			return
		}

		captureSession.beginConfiguration()

		defer {
			self.captureSession.commitConfiguration()
		}

		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

		guard captureSession.canAddInput(deviceInput) else {
			print("Can't add device input to capture sesison")
			return
		}

		guard captureSession.canAddOutput(videoOutput) else {
			print("Can't add video output to capture sesison")
			return
		}
		captureSession.addInput(deviceInput)
		captureSession.addOutput(videoOutput)

		let videoConnection = videoOutput.connection(with: .video)
		videoConnection?.videoRotationAngle = 90

	}
	private func startSession() async {
		guard await isAuthorized else { return }
		captureSession.startRunning()
	}

}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(
		_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
		from connection: AVCaptureConnection
	) {
		guard let currentFrame = sampleBuffer.cgImage else { return }
		addToPreviewStream?(currentFrame)
	}
}
