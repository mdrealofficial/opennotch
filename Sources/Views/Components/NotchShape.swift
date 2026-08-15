import SwiftUI

/// Custom Bezier Notch Shape that features top concave ears (flaring outward to connect with the macOS menu bar)
/// and smooth continuous convex bottom corners matching MacBook hardware.
public struct NotchShape: Shape {
    public var earRadius: CGFloat = 10
    public var cornerRadius: CGFloat = 20
    
    public init(earRadius: CGFloat = 10, cornerRadius: CGFloat = 20) {
        self.earRadius = earRadius
        self.cornerRadius = cornerRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let ear = max(0, min(earRadius, 16))
        let cr = max(0, min(cornerRadius, h / 2))
        
        // 1. Start top-left corner
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Concave top-left ear fillet (curving inward and down)
        path.addQuadCurve(
            to: CGPoint(x: ear, y: ear),
            control: CGPoint(x: 0, y: ear)
        )
        
        // 3. Left vertical drop
        path.addLine(to: CGPoint(x: ear, y: h - cr))
        
        // 4. Convex bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: ear + cr, y: h),
            control: CGPoint(x: ear, y: h)
        )
        
        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - ear - cr, y: h))
        
        // 6. Convex bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: w - ear, y: h - cr),
            control: CGPoint(x: w - ear, y: h)
        )
        
        // 7. Right vertical rise
        path.addLine(to: CGPoint(x: w - ear, y: ear))
        
        // 8. Concave top-right ear fillet (curving outward to top edge)
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w, y: ear)
        )
        
        // 9. Close top edge
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}
