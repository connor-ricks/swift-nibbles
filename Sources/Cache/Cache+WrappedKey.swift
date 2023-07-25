import Foundation

extension Cache {
    /// A wrapper around the `Cache's` `Key` type that makes it compatible with `NSCache`
    class WrappedKey: NSObject {
        
        // MARK: Properties
        
        let key: Key

        // MARK: Initializers
        
        init(_ key: Key) {
            self.key = key
        }
        
        // MARK: NSObject
        
        override var hash: Int {
            return key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
}
