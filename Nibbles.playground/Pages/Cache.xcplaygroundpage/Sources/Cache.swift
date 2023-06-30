import Foundation

// MARK: - Cache

/// A simple cache that can be used to store objects.
public final class Cache<Key: Hashable, Value> {

    // MARK: Properties
    
    /// The provider used to create dates for cache entries.
    let dateProvider: () -> Date
    
    /// The max lifetime that a value should exist in the cache.
    let lifetime: TimeInterval
    
    /// The actual cache store.
    let store = NSCache<WrappedKey, Entry>()
    
    /// An observer of the store.
    let keyTracker = KeyTracker()

    /// The keys that currently exist within the cache.
    public var keys: Set<Key> {
        return keyTracker.keys
    }

    // MARK: Initializers

    /// Creates a cache with the provided configuration.
    /// - Parameters:
    ///   - dateProvider: The provider used to create dates for cache entries.
    ///   - lifetime: The max lifetime that a value should exist in the cache.
    ///   - limit: The max number of items that should exist in the cache.
    public init(
        dateProvider: @escaping () -> Date = Date.init,
        lifetime: TimeInterval = 12 * 60 * 60,
        limit: Int = 0
    ) {
        self.dateProvider = dateProvider
        self.lifetime = lifetime
        self.store.countLimit = limit
        self.store.delegate = keyTracker
    }

    // MARK: Actions

    /// Inserts the provided value into the cache.
    ///
    /// - Parameters:
    ///   - value: The value to be inserted.
    ///   - key: The key that identifies the item.
    func insert(_ value: Value, forKey key: Key) {
        let date = dateProvider().addingTimeInterval(lifetime)
        let entry = Entry(key: key, value: value, lifetime: date)
        insert(entry)
    }

    /// Retrieves the value for the provided key from the cache.
    ///
    /// - Parameter key: The key used to lookup the value in the cache.
    /// - Returns: Returns the value if it exists, otherwise nil.
    func value(forKey key: Key) -> Value? {
        entry(forKey: key)?.value
    }

    /// Deletes the value in the cache for the provided key.
    ///
    /// - Parameter key: The key used to lookup the value in the cache.
    func removeValue(forKey key: Key) {
        store.removeObject(forKey: WrappedKey(key))
    }
    
    subscript(key: Key) -> Value? {
        get {
            value(forKey: key)
        }
        set {
            if let value = newValue {
                insert(value, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    // MARK: Private Actions
    
    /// Inserts the provided entry into the cache.
    ///
    /// - Parameters:
    ///   - entry: The entry to be inserted.
    private func insert(_ entry: Entry) {
        store.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
    
    /// Gets the cache entry for the provided key.
    ///
    /// - Parameter key: The key used to lookup the entry.
    /// - Returns: The entry, if it exists, otherwise nil.
    private func entry(forKey key: Key) -> Entry? {
        guard let entry = store.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard dateProvider() < entry.lifetime else {
            removeValue(forKey: key)
            return nil
        }

        return entry
    }
}

// MARK: - Cache + Codable

extension Cache: Codable where Key: Codable, Value: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }

    public func saveToDisk(withName name: String, using fileManager: FileManager = .default) throws {
        let folderURLs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }

    public static func loadFromDisk(
        withName name: String,
        keyType: Key.Type,
        valueType: Value.Type,
        using fileManager: FileManager = .default
    ) throws -> Cache {
        let folderURLs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Cache.self, from: data)
    }
}
