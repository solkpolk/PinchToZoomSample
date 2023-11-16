import SwiftUI
import UIKit


@main
struct PinchToZoomApp: App {
    var body: some Scene {
        WindowGroup {
			NavigationStack {
				VStack {
					
					// Zoomable content
					AsyncImage(url: URL(string: "https://picsum.photos/id/6/500/500"))
						.frame(width: 300, height: 300)
						.cornerRadius(15)
						.addPinchToZoom()
				}
				
				.navigationTitle("HELLO WORLD")
			}
        }
    }
}



extension View {
	func addPinchToZoom() -> some View {
		return PinchZoomContext {
			self
		}
	}
}

struct PinchZoomContext<Content: View>: View {
	
	var content: Content
	var fullScreen: Bool
	
	init(fullscreen: Bool = false,  @ViewBuilder content: @escaping () -> Content) {
		self.content = content()
		self.fullScreen = fullscreen
	}
	
	@State var offset: CGPoint = .zero
	@State var scale: CGFloat = 0
	@State var scalePosition: CGPoint = .zero
	
	var body: some View {
		if fullScreen {
			content
				.offset(x: offset.x, y: offset.y)
				.overlay {
					GeometryReader { proxy in
						let size = proxy.size
						ZoomGesture(size: size, scale: $scale, offset: $offset, scalePosition: $scalePosition)
					}
				}
				.scaleEffect(1 + scale, anchor: .init(x: scalePosition.x, y: scalePosition.y))
		} else {
			ZStack {
				content
					.offset(x: offset.x, y: offset.y)
					.scaleEffect(1 + scale, anchor: .init(x: scalePosition.x, y: scalePosition.y))
					.clipped()
				
				Rectangle()
					.fill(.clear)
					.offset(x: offset.x, y: offset.y)
					.overlay {
						GeometryReader { proxy in
							let size = proxy.size
							ZoomGesture(size: size, scale: $scale, offset: $offset, scalePosition: $scalePosition)
						}
					}
					.scaleEffect(1 + scale, anchor: .init(x: scalePosition.x, y: scalePosition.y))
			}
		}
	}
}

struct ZoomGesture: UIViewRepresentable {
	
	var size: CGSize
	@Binding var scale: CGFloat
	@Binding var offset: CGPoint
	@Binding var scalePosition: CGPoint
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}
	
	func makeUIView(context: Context) -> some UIView {
		let view = UIView()
		view.backgroundColor = .clear
		
		// add pinch gestures
		let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(sender:)))
		view.addGestureRecognizer(pinchGesture)
		
		// add pan gestures
		let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(sender:)))
		panGesture.delegate = context.coordinator
		view.addGestureRecognizer(panGesture)
		
		return view
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) {
		
	}
	
	class Coordinator: NSObject, UIGestureRecognizerDelegate {
		
		var parent: ZoomGesture
		
		init(parent: ZoomGesture) {
			self.parent = parent
		}
		
		// making pan to recognise simultanous
		func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
			return true
		}
		
		@objc func handlePan(sender: UIPanGestureRecognizer) {
			
			sender.maximumNumberOfTouches = 2
			
			// min scale is 1...
			if sender.state == .began || sender.state == .changed && parent.scale > 0 {
				if let view = sender.view {
					let transition = sender.translation(in: view)
					parent.offset = transition
				}
			} else {
				withAnimation {
					parent.offset = .zero
					parent.scalePosition = .zero
				}
			}
		}
		
		@objc func handlePinch(sender: UIPinchGestureRecognizer) {
			// calc scale
			if sender.state == .began || sender.state == .changed {
				parent.scale = (sender.scale - 1) // -1 for removing the added 1
				
				// getting the position where the user pinched and applied scale at that position and normalizing it between (0...1)
				let scalePoint = CGPoint(x: sender.location(in: sender.view).x / sender.view!.frame.size.width, y: sender.location(in: sender.view).y / sender.view!.frame.size.height)
				parent.scalePosition = (parent.scalePosition == .zero ? scalePoint : parent.scalePosition)
				
				
			} else {
				// setting scale to 0
				withAnimation(.easeInOut(duration: 0.35)) {
					parent.scale = 0
					parent.scalePosition = .zero
				}
			}
			
		}
	}
}

extension View {
	func getRect() -> CGRect {
		return UIScreen.main.bounds
	}
}
