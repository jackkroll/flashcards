import SwiftUI
import Combine
import SwiftData

@MainActor
final class Router: ObservableObject {
    @Published var path: [Route] = []

    func push(_ route: Route, allowSelfPush: Bool = false) {
        if path.last == route && !allowSelfPush { return }
        path.append(route)
    }
    func pop() { _ = path.popLast() }
    func popToRoot() { path.removeAll() }
    func replaceStack(with routes: [Route]) { path = routes }

    func pop(to needle: Route) {
        guard let idx = path.lastIndex(of: needle) else { return }
        path.removeSubrange(idx..<path.endIndex)
    }

    func pop(where predicate: (Route) -> Bool) {
        guard let idx = path.lastIndex(where: predicate) else { return }
        path.removeSubrange(idx..<path.endIndex)
    }
    
    func popToLast(case target: RouteCase) -> PersistentIdentifier? {
        guard let destination = path.last(where: { $0.routeCase == target }) else {
            return nil
        }
        pop(to: destination)
        return destination.setID
    }


}
