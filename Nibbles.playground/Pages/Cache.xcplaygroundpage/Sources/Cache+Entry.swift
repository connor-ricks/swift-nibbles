import Foundation

// MARK: - Entry

extension Cache {
    /// A wrapper around the `Value` saved to teh cache. This is what gets saved to the `NSCache`.
    final class Entry {
        /// The key that is used to lookup the value in the cache.
        let key: Key
        /// The value that is being cached.
        let value: Value
        /// The expiration date for the entry within the cache.
        let lifetime: Date

        init(key: Key, value: Value, lifetime: Date) {
            self.key = key
            self.value = value
            self.lifetime = lifetime
        }
    }
}

// MARK: Entry + Codable

extension Cache.Entry: Codable where Key: Codable, Value: Codable {}
