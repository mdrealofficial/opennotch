import SwiftUI

/// A squircle-inspired notch shape with smooth top "ears" that fluidly blend into the display bezel.
public struct NotchShape: Shape {
    public var earRadius: CGFloat
    public var cornerRadius: CGFloat
    
    public init(earRadius: CGFloat = 10, cornerRadius: CGFloat = 14) {
        self.earRadius = earRadius
        self.cornerRadius = cornerRadius
    }
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(earRadius, cornerRadius)
        }
        set {
            earRadius = newValue.first
            cornerRadius = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Clamp radii so they never exceed geometry limits
        let effectiveEar = max(0, min(earRadius, min(width / 4, height)))
        let effectiveCorner = max(0, min(cornerRadius, min(width / 4, height / 2)))
        
        // Start top-left outside ear
        path.move(to: CGPoint(x: 0, y: 0))
        
        if effectiveEar > 0.001 {
            // Left ear fillet with G2-continuous cubic bezier curve
            path.addCurve(
                to: CGPoint(x: effectiveEar, y: effectiveEar),
                control1: CGPoint(x: effectiveEar * 0.45, y: 0),
                control2: CGPoint(x: effectiveEar, y: effectiveEar * 0.55)
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        // Left vertical edge down to bottom-left corner
        let leftCornerStartY = max(effectiveEar, height - effectiveCorner)
        path.addLine(to: CGPoint(x: effectiveEar, y: leftCornerStartY))
        
        if effectiveCorner > 0.001 {
            // Bottom-left rounded corner
            path.addQuadCurve(
                to: CGPoint(x: effectiveEar + effectiveCorner, y: height),
                control: CGPoint(x: effectiveEar, y: height)
            )
        }
        
        // Bottom horizontal edge
        let rightCornerStartX = max(effectiveEar + effectiveCorner, width - effectiveEar - effectiveCorner)
        path.addLine(to: CGPoint(x: rightCornerStartX, y: height))
        
        if effectiveCorner > 0.001 {
            // Bottom-right rounded corner
            path.addQuadCurve(
                to: CGPoint(x: width - effectiveEar, y: height - effectiveCorner),
                control: CGPoint(x: width - effectiveEar, y: height)
            )
        }
        
        // Right vertical edge up to top-right ear
        path.addLine(to: CGPoint(x: width - effectiveEar, y: effectiveEar))
        
        if effectiveEar > 0.001 {
            // Right ear fillet with G2-continuous cubic bezier curve
            path.addCurve(
                to: CGPoint(x: width, y: 0),
                control1: CGPoint(x: width - effectiveEar, y: effectiveEar * 0.55),
                control2: CGPoint(x: width - (effectiveEar * 0.45), y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Top edge closing
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}
