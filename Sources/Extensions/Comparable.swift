import Foundation

extension Comparable {
    /// Clamps the value to the provided range.
    ///
    /// - Parameter limits: The range to clamp the value to.
    /// - Returns: The value clamped to the provided range.
    public func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
