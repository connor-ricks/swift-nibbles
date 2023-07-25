import Foundation

extension Collection {
    /// Attempts to retrieve the item at the provided index, returning `nil` if the index is beyond the bounds of the collection.
    ///
    /// - Parameter index: The index from which to retrieve an item.
    public subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
