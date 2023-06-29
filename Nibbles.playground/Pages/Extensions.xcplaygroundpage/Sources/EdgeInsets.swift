import SwiftUI

extension EdgeInsets {
    /// A value that represents an `EdgeInsets` with zero around all edges.
    public static let zero: EdgeInsets = .init(padding: 0)

    /// Creates `EdgeInsets` using the provided `padding` for all edges.
    /// - Parameter padding: The value to be used for each edge.
    public init(padding: CGFloat) {
        self.init(
            top: padding,
            leading: padding,
            bottom: padding,
            trailing: padding
        )
    }

    /// Creates `EdgeInsets` using the provided `vertical` and `horizontal` values.
    /// - Parameters:
    ///   - vertical: The value to be used for both the `top` and `bottom` edges.
    ///   - horizontal: The value to be used for both the `leading` and `trailing` edges.
    public init(vertical: CGFloat, horizontal: CGFloat) {
        self.init(
            top: vertical,
            leading: horizontal,
            bottom: vertical,
            trailing: horizontal
        )
    }
}
