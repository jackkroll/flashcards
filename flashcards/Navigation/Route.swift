import SwiftUI
import SwiftData

// Typed routes for the app's navigation stack
// Prefer routing by PersistentIdentifier for SwiftData models
// to keep the stack light and stable.
enum Route: Hashable {
    case set(setID: PersistentIdentifier)
    case stats(setID: PersistentIdentifier)
    case proCompare
    case storeView
    case settings
    case generator
    case addCard(setID: PersistentIdentifier, cardID: PersistentIdentifier?)
    case playSelectionView(setID: PersistentIdentifier)
    case study(studySet: PersistentIdentifier,
               shuffle: Bool,
               subsetSize: Int?,
               focusOnWeakCards: Bool,
               includeStrongCards: Bool)
}
enum RouteCase {
    case set
    case stats
    case proCompare
    case storeView
    case settings
    case generator
    case addCard
    case playSelectionView
    case study
}

extension Route {
    var routeCase: RouteCase {
        switch self {
        case .set: return .set
        case .stats: return .stats
        case .proCompare: return .proCompare
        case .storeView: return .storeView
        case .settings: return .settings
        case .generator: return .generator
        case .addCard: return .addCard
        case .playSelectionView: return .playSelectionView
        case .study: return .study
        }
    }
}

extension Route {
    var setID: PersistentIdentifier? {
        if case .set(let id) = self { return id }
        if case .stats(let id) = self { return id }
        if case .addCard(let id, _) = self { return id }
        if case .playSelectionView(let id) = self { return id }
        if case .study(let id, _, _, _, _) = self { return id }
        return nil
    }
}



struct RouterViewDestination: View {
    @Environment(\.modelContext) var modelContext
    let route: Route
    var body: some View {
        switch route {
        case .set(let id):
            if let set = modelContext.model(for: id) as? StudySet {
                SetView(set: set)
            } else {
                SetNotFoundView()
            }
        case .stats(let id):
            if let set = modelContext.model(for: id) as? StudySet {
                StatsView(viewingSet: set)
            } else {
                SetNotFoundView()
            }
        case .settings:
            SettingsView()
        case .generator:
            GenerateSetView()
        case .proCompare:
            ProFeatureComparison()
        case .storeView:
            StoreView()
        case .addCard(let setID, let cardID):
            if let set = modelContext.model(for: setID) as? StudySet {
                if let card = set.cards.first(where: { $0.id == cardID }) {
                    AddCardView(parentSet: set, parentCard: card)
                }
                else {
                    AddCardView(parentSet: set)
                }
            } else {
                SetNotFoundView()
            }
        case .playSelectionView(let id):
            if let set = modelContext.model(for: id) as? StudySet {
                PlaySelectionView(parentSet: set)
            } else {
                SetNotFoundView()
            }
        case .study(studySet: let setID,
                    shuffle: let shuffle,
                    subsetSize: let subsetSize,
                    focusOnWeakCards: let focusOnWeakCards,
                    includeStrongCards: let includeStrongCards):
            if let set = modelContext.model(for: setID) as? StudySet {
                StudyView(
                    studySet: set,
                    shouldShuffle: shuffle,
                    subsetSize: subsetSize,
                    shouldFocusOnWeakCards: focusOnWeakCards,
                    includeStrongCards: includeStrongCards
                )
            }
            else {
                SetNotFoundView()
            }
        }
    }
    
}

struct SetNotFoundView: View {
    var body: some View {
        ContentUnavailableView("Set not found", systemImage: "exclamationmark.triangle")
    }
}
