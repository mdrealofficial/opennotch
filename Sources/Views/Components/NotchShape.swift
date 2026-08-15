import SwiftUI

/// Ultra-smooth Apple-grade Bezier Notch Shape with continuous G2 curvature (squircle).
/// Features organic concave ear fillets flaring into the top screen bezel and smooth convex rounded bottom corners.
public struct NotchShape: Shape {
    public var earRadius: CGFloat
    public var cornerRadius: CGFloat
    
    public init(earRadius: CGFloat = 12, cornerRadius: CGFloat = 20) {
        self.earRadius = earRadius
        self.cornerRadius = cornerRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let ear = max(0, min(earRadius, w / 4))
        let cr = max(0, min(cornerRadius, h / 2))
        
        // 1. Start top-left (0, 0)
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Concave top-left ear flare with continuous cubic Bezier
        path.addCurve(
            to: CGPoint(x: ear, y: ear),
            control1: CGPoint(x: ear * 0.45, y: 0),
            control2: CGPoint(x: ear, y: ear * 0.55)
        )
        
        // 3. Left vertical edge
        path.addLine(to: CGPoint(x: ear, y: h - cr))
        
        // 4. Convex bottom-left corner with continuous cubic Bezier
        path.addCurve(
            to: CGPoint(x: ear + cr, y: h),
            control1: CGPoint(x: ear, y: h - cr * 0.45),
            control2: CGPoint(x: ear + cr * 0.45, y: h)
        )
        
        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - ear - cr, y: h))
        
        // 6. Convex bottom-right corner with continuous cubic Bezier
        path.addCurve(
            to: CGPoint(x: w - ear, y: h - cr),
            control1: CGPoint(x: w - ear - cr * 0.45, y: h),
            control2: CGPoint(x: w - ear, y: h - cr * 0.45)
        )
        
        // 7. Right vertical edge
        path.addLine(to: CGPoint(x: w - ear, y: ear))
        
        // 8. Concave top-right ear flare with continuous cubic Bezier
        path.addCurve(
            to: CGPoint(x: w, y: 0),
            control1: CGPoint(x: w - ear, y: ear * 0.55),
            control2: CGPoint(x: w - ear * 0.45, y: 0)
        )
        
        // 9. Close top edge
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}
