import UIKit

// MARK: ReusableCell

public protocol ReusableCell {
    static var identifier: String { get }
}

extension ReusableCell {
    public static var identifier: String {
        return "\(type(of: Self.self))"
    }
}

// MARK: - UICollectionView + ReusableCollectionViewCell

extension UICollectionView {
    
    public func dequeueReusableCell<T: UICollectionViewCell & ReusableCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath) as? T else {
            assertionFailure("A cell should always be dequeued.")
            return T()
        }
        
        return cell
    }
    
    func register<T: UICollectionViewCell & ReusableCell>(_ type: T.Type) {
        register(type, forCellWithReuseIdentifier: type.identifier)
    }
}

// MARK: - UITableView + ReusableCell

extension UITableView {
    
    public func dequeueReusableCell<T: UITableViewCell & ReusableCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as? T else {
            assertionFailure("A cell should always be dequeued.")
            return T()
        }
        
        return cell
    }
    
    func register<T: UITableViewCell & ReusableCell>(_ type: T.Type) {
        register(type, forCellReuseIdentifier: type.identifier)
    }
}
