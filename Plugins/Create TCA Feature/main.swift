import Foundation
import PackagePlugin

@main
struct CreateTCAFeature: CommandPlugin {
    
    // MARK: Error
    
    struct Error: Swift.Error {
        let description: String
    }
    
    // MARK: CommandPlugin
    
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
    
        let features = extractor.extractOption(named: "create")
        guard !features.isEmpty else {
            throw Error(description: "Must provide a feature to create using --create <feature>")
        }
        
        for feature in features {
            let featureDirectory = context.package.directory.appending(["Sources", feature])
            try createTCAFeatureDirectory(featureDirectory)
            try createTCAFeatureFile(for: feature, directory: featureDirectory)
            try createTCAFeatureActionFile(for: feature, directory: featureDirectory)
            try createTCAFeatureStateFile(for: feature, directory: featureDirectory)
            try createTCAFeaturePathFile(for: feature, directory: featureDirectory)
            try createTCAFeatureViewFile(for: feature, directory: featureDirectory)
            
        }
    }
}

// MARK: - Create TCA Feature Folder

extension CreateTCAFeature {
    func createTCAFeatureDirectory(_ directory: Path) throws {
        try FileManager.default.createDirectory(at: URL(filePath: directory.string), withIntermediateDirectories: true)
    }
}

// MARK: - Create TCA Feature

extension CreateTCAFeature {
    func createTCAFeatureFile(for feature: String, directory: Path) throws {
        let content = """
        import SwiftUI
        import ComposableArchitecture

        public struct \(feature): Reducer {
            
            // MARK: Initializers
            
            public init() {}
            
            // MARK: Body
            
            public var body: some ReducerOf<Self> {
                BindingReducer()
                
                Reduce<State, Action> { state, action in
                    switch action {
                    case .binding:
                        return .none
                    case .delegate:
                        return .none
                    }
                }
            }
        }
        """
        
        return try content.write(
            to: URL(filePath: directory.appending(subpath: "\(feature).swift").string),
            atomically: false,
            encoding: .utf8
        )
    }
}

// MARK: - Create TCA Feature Action

extension CreateTCAFeature {
    func createTCAFeatureActionFile(for feature: String, directory: Path) throws {
        let content = """
        import SwiftUI
        import ComposableArchitecture

        extension \(feature) {
            public enum Action: Equatable, BindableAction {
                case binding(BindingAction<State>)
                case delegate(Delegate)
                
                // MARK: Delegate
                
                public enum Delegate: Equatable {
                    
                }
            }
        }
        """
        
        return try content.write(
            to: URL(filePath: directory.appending(subpath: "\(feature)+Action.swift").string),
            atomically: false,
            encoding: .utf8
        )
    }
}

// MARK: - Create TCA Feature State

extension CreateTCAFeature {
    func createTCAFeatureStateFile(for feature: String, directory: Path) throws {
        let content = """
        import SwiftUI
        import ComposableArchitecture
        
        extension \(feature) {
            public struct State: Equatable {
                
                // MARK: Properties
                
                // MARK: Initializers
                
                public init() {
                    
                }
            }
        }
        """

        return try content.write(
            to: URL(filePath: directory.appending(subpath: "\(feature)+State.swift").string),
            atomically: false,
            encoding: .utf8
        )
    }
}

// MARK: - Create TCA Feature Path

extension CreateTCAFeature {
    func createTCAFeaturePathFile(for feature: String, directory: Path) throws {
        let content = """
        import Foundation
        import ComposableArchitecture

        extension \(feature) {
            public struct Path: Reducer {
                
                // MARK: State
                
                public enum State: Equatable {
                    case child
                }
                
                // MARK: Action
                
                public enum Action: Equatable {
                    case child
                }
                
                // MARK: Body
                
                public var body: some ReducerOf<Self> {
                    Scope(state: /State.child, action: /Action.child) {
                        ChildFeature()
                    }
                }
            }
        }
        """
        
        return try content.write(
            to: URL(filePath: directory.appending(subpath: "\(feature)+Path.swift").string),
            atomically: false,
            encoding: .utf8
        )
    }
}

// MARK: - Create TCA Feature View

extension CreateTCAFeature {
    func createTCAFeatureViewFile(for feature: String, directory: Path) throws {
        let name = feature.replacingOccurrences(of: "Feature", with: "")
        let content = """
        import SwiftUI
        import ComposableArchitecture

        // MARK: - \(name)View

        public struct \(name)View: View {
            
            // MARK: Properties
            
            let store: StoreOf<\(feature)>
            
            // MARK: Initializers
            
            public init(store: StoreOf<\(feature)>) {
                self.store = store
            }
            
            // MARK: Body
            
            public var body: some View {
                WithViewStore(store, observe: { $0 }) { viewStore in
                    
                }
            }
        }

        // MARK: - \(name)View + Previews

        #Preview {
            \(name)View(store: .init(
                initialState: \(feature).State(),
                reducer: { \(feature)() }
            ))
        }
        """
        
        return try content.write(
            to: URL(filePath: directory.appending(subpath: "\(name)View.swift").string),
            atomically: true,
            encoding: .utf8
        )
    }
}
