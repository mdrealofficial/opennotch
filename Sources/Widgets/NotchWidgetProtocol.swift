import SwiftUI

public protocol NotchWidget: Identifiable {
    var id: String { get }
    var title: String { get }
    var iconName: String { get }
    var order: Int { get }
    
    associatedtype CompactViewType: View
    associatedtype ExpandedViewType: View
    
    @ViewBuilder func makeCompactView() -> CompactViewType
    @ViewBuilder func makeExpandedView() -> ExpandedViewType
}
