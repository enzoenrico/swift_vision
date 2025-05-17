import CoreML
import SwiftUI
import Vision

struct ContentView: View {
	@State private var viewModel = ViewModel()
	@State private var foundDescription: String = ""
	// New state variable for animation
	@State private var rotationAngle: Double = 0

	func classify() {
		foundDescription = ""
		guard let cgImage = viewModel.currentFrame else {
			print("No valid frame available for classification!")
			return
		}
		print("Got image in classify")

		guard
			let visionModel = try? VNCoreMLModel(
				// slower model but better results
				for: SlowVIT(configuration: MLModelConfiguration()).model
			)
		else {
			print("Failed to load FastVIT model")
			return
		}

		// Create a request with a completion handler.
		let request = VNCoreMLRequest(model: visionModel) { request, error in
			if let error = error {
				print("Error during classification: \(error)")
				return
			}
			// Process classification results.
			if let results = request.results as? [VNClassificationObservation],
				let firstObservation = results.first
			{
				DispatchQueue.main.async {
					print(firstObservation)
					foundDescription = firstObservation.identifier
				}
			} else {
				foundDescription = "something went wrong 😔"
			}
		}

		let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
		do {
			try handler.perform([request])
		} catch {
			print("Failed to perform classification: \(error)")
		}
	}

	func findEmoji(description: String) -> String {
		return ""
	}

	var pillOffset: CGFloat {
		foundDescription.isEmpty
			? (-UIScreen.main.bounds.height / 2 + 15)
			: (-UIScreen.main.bounds.height / 2 + 100)
	}

	var body: some View {
		ZStack {
			CameraView(image: $viewModel.currentFrame)
				.ignoresSafeArea()
			Text(foundDescription)
				.padding(.vertical, 8)
				.padding(.horizontal, 16)
				.background(
					Capsule()
						.fill(.regularMaterial)
						.frame(height: 37)
				)
				// Overlay animated rainbow border
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
				.offset(y: pillOffset)
				.animation(.easeInOut(duration: 0.5), value: foundDescription)

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
			// Starts a continuous animation of the rainbow border
			withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
				rotationAngle = 360
			}
		}
	}
}
