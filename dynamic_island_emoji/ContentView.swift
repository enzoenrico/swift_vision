import CoreML
import SwiftUI
import Vision

// A simple struct for detected objects.
struct DetectedObject: Identifiable {
	let id = UUID()
	let label: String
	// Normalized bounding box (x, y, width, height) with values in 0...1.
	let boundingBox: CGRect
}

struct ContentView: View {
	@State private var viewModel = ViewModel()
	// When using an object detection model, store an array of detections.
	@State private var detectedObjects: [DetectedObject] = []
	// For the animated rainbow border (if still needed)
	@State private var rotationAngle: Double = 0

	func classify() {
		// Clear previous detections.
		detectedObjects = []

		// Your currentFrame is assumed to be a CGImage.
		guard let cgImage = viewModel.currentFrame else {
			print("No valid frame available for classification!")
			return
		}
		print("Got image in classify")

		// IMPORTANT: Use your object detection model here.
		// For example, if you have a model that returns VNRecognizedObjectObservation:
		guard
			let visionModel = try? VNCoreMLModel(
				for: FastVIT(configuration: MLModelConfiguration()).model)
		else {
			print("Failed to load FastVIT model")
			return
		}

		// Create a VNCoreMLRequest. We assume the model returns VNRecognizedObjectObservation.
		let request = VNCoreMLRequest(model: visionModel) { request, error in
			if let error = error {
				print("Error during classification: \(error)")
				return
			}

			// Process object detection results.
			if let results = request.results as? [VNRecognizedObjectObservation] {
				let objects = results.map { observation -> DetectedObject in
					// Use the top label from each observation.
					let label = observation.labels.first?.identifier ?? "Unknown"
					return DetectedObject(label: label, boundingBox: observation.boundingBox)
				}
				// Update UI on the main thread.
				DispatchQueue.main.async {
					detectedObjects = objects
				}
			} else {
				print("No objects detected")
			}
		}
		// Optionally set crop and scale option.
		request.imageCropAndScaleOption = .scaleFill

		// Create an image request handler and perform the request.
		let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
		do {
			try handler.perform([request])
		} catch {
			print("Failed to perform classification: \(error)")
		}
	}

	var body: some View {
		ZStack {
			CameraView(image: $viewModel.currentFrame)
				.ignoresSafeArea()

			// Overlay the detected objects.
			GeometryReader { geometry in
				ForEach(detectedObjects) { object in
					// Convert normalized bounding box to view coordinates.
					let rect = VNImageRectForNormalizedRect(
						object.boundingBox,
						Int(geometry.size.width),
						Int(geometry.size.height))

					// Draw a rectangle and label.
					ZStack(alignment: .topLeading) {
						Rectangle()
							.strokeBorder(Color.red, lineWidth: 2)
							.frame(width: rect.width, height: rect.height)
						Text(object.label)
							.font(.caption)
							.padding(4)
							.background(Color.red.opacity(0.7))
							.foregroundColor(.white)
					}
					.position(x: rect.midX, y: rect.midY)
				}
			}
			// Optionally, if you still want the animated pill (for something else)
			Text("")
				.padding(.vertical, 8)
				.padding(.horizontal, 16)
				.background(
					Capsule()
						.fill(.ultraThinMaterial)
						.frame(height: 37)
				)
				.overlay(
					Capsule()
						.stroke(
							AngularGradient(
								gradient: Gradient(colors: [
									.red, .orange, .yellow, .green, .blue, .indigo, .purple, .red,
								]),
								center: .center,
								startAngle: .degrees(rotationAngle),
								endAngle: .degrees(rotationAngle + 360)
							),
							lineWidth: 2
						)
						.blur(radius: 2.5)
				)
				.offset(y: -UIScreen.main.bounds.height / 2 + 15)

			VStack {
				Spacer()
				HStack {
					Button(
						action: {
							classify()
						},
						label: {
							Text("What's that?")
								.font(.headline)
								.padding(.vertical, 8)
								.padding(.horizontal, 16)
								.background(
									Capsule()
										.fill(.ultraThinMaterial)
										.frame(width: 120, height: 37)
								)
						})
				}
				.padding(.bottom, 20)
			}
		}
		.onAppear {
			// Starts the continuous animation for the rainbow border.
			withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
				rotationAngle = 360
			}
		}
	}
}
