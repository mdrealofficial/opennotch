import SwiftUI

public struct VisualizerBarView: View {
    let levels: [CGFloat]
    let barColor: Color
    
    public init(levels: [CGFloat], barColor: Color = Color.green) {
        self.levels = levels
        self.barColor = barColor
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<levels.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 3, height: max(4, levels[idx] * 18))
                    .animation(.easeInOut(duration: 0.12), value: levels[idx])
            }
        }
        .frame(height: 20)
    }
}
