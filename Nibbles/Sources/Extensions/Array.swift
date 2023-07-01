import Foundation

extension Array {
    /// Splits the array into chunks of the specified size.
    public func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else {
            assertionFailure("Size must not be zero.")
            return []
        }
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
