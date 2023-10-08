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

extension Stash {
    /// A wrapper around the `Value` saved to the stash. This is what gets saved to the `NSCache`.
    final class Entry {
        /// The key that is used to lookup the value in the stash.
        let key: Key
        /// The value that is being stashdd.
        let value: Value
        /// The expiration date for the entry within the stash.
        let lifetime: Date

        init(key: Key, value: Value, lifetime: Date) {
            self.key = key
            self.value = value
            self.lifetime = lifetime
        }
    }
}

// MARK: Entry + Codable

extension Stash.Entry: Codable where Key: Codable, Value: Codable {}
