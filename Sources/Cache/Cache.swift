// MIT License
//
// Copyright (c) 2023 Connor Ricks
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// MARK: - Cache

/// A simple cache that can be used to store objects.
///
/// Use a cache to store objects of a given type in memory using an associated key.
/// You can then fetch attempt to retrieve from the cache at a later time using the key.
///
/// ```swift
/// // Create a cache of dogs.
/// let cache = Cache<String, Dog>
///
/// // Store a dog inside the cache.
/// let fido = Dog(name: "Fido")
/// cache.insert(fido, forKey: "1")
///
/// // Retrieve a dog from the cache.
/// let cachedDog = cache.value(forKey: "1")
///
/// // Remove a dog from the cache.
/// cache.removeValue(forKey: "1")
///
/// // Interact with the cache using subscripts.
/// cache["2"] = Dog(name: "Spark")
/// let otherCachedDog = cache["2"]
/// ```
///
/// The cache implements a default limetime for which an item is considered valid. If you fetch an object
/// from the cache and it has existed beyond the cache's specified lifetime, the cached object will be removed
/// and the retrievel will fail, returning a null value.
///
/// If both your key and the object you are storing are `Codable`, you can persist
/// your cache to disk and load it at a later point in time.
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
    ///
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
    public func insert(_ value: Value, forKey key: Key) {
        let date = dateProvider().addingTimeInterval(lifetime)
        let entry = Entry(key: key, value: value, lifetime: date)
        insert(entry)
    }

    /// Retrieves the value for the provided key from the cache.
    ///
    /// - Parameter key: The key used to lookup the value in the cache.
    /// - Returns: Returns the value if it exists, otherwise nil.
    public func value(forKey key: Key) -> Value? {
        entry(forKey: key)?.value
    }

    /// Deletes the value in the cache for the provided key.
    ///
    /// - Parameter key: The key used to lookup the value in the cache.
    public func removeValue(forKey key: Key) {
        store.removeObject(forKey: WrappedKey(key))
    }
    
    public subscript(key: Key) -> Value? {
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

    /// Saves the cache to disk for long-term storage.
    ///
    /// - Parameters:
    ///   - name: The name of the cache file.
    ///   - fileManager: The file manager that should store the cache.
    public func saveToDisk(withName name: String, using fileManager: FileManager = .default) throws {
        let folderURLs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }

    /// Loads a cache from disk, initializing it for usage.
    ///
    /// - Parameters:
    ///   - name: The name of the cache file.
    ///   - keyType: The type
    ///   - valueType: The type of item being stored in the cache.
    ///   - fileManager: The file manager that should load the cache from disk.
    /// - Returns: A cache initialized with the stored data.
    public static func loadFromDisk(
        withName name: String,
        keyType: Key.Type,
        valueType: Value.Type,
        using fileManager: FileManager = .default
    ) throws -> Cache<Key, Value> {
        let folderURLs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Cache<Key, Value>.self, from: data)
    }
}
