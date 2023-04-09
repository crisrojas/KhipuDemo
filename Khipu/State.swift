//
//  State.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 08/04/2023.
//

import Foundation
import Models
import SwiftUI

public struct AppState {
    let todos: [ToDo]
    let editing: Bool
}

public final class ViewState: ObservableObject {
    @Published public var todos = [ToDo]()
    @Published public var editing = false
    
    public init(store: DefaultStore) {
        
        process(store.state())
        
        store.onChange { [weak self] in
            self?.process(store.state())
        }
    }
    
    private func process(_ state: AppState) {
        todos = state.todos
            .sorted(by: { $0.title < $1.title })
            .sorted(by: { !$0.done && $1.done })
        editing = state.editing
    }
}

public extension AppState {
    init() {todos = [] ; editing = false}
    
    init(_ todos: [ToDo], _ editing: Bool) {
        self.todos = todos
        self.editing = editing
    }
    
    enum Change {
        case add(ToDo)
        case delete(ToDo)
        case change(ToDo, with: ToDo.Change)
        case editing(Bool)
    }
    
    func apply(_ change: Change) -> Self {
        switch change {
        case .add(let todo): return .init(todos + [todo], editing)
        case .delete(let todo): return .init(todos.filter { $0.id != todo.id }, editing)
        case .change(let todo, let change):
            let todos = todos
                .filter { $0.id != todo.id }
                + [todo.apply(change)]
            return .init(todos, editing)
        case .editing(let editing): return .init(todos, editing)
        }
    }
}

extension AppState: Codable {}
extension AppState.Change: Codable {}

public typealias Access<S> = (               ) -> S
public typealias Change<C> = (C              ) -> ()
public typealias Observe   = (@escaping()->()) -> ()
public typealias Inject<S> = (S              ) -> ()
public typealias DefaultStore = StateStore<AppState, AppState.Change>

public typealias StateStore<S,C> = (
    state: Access<S>,
    change: Change<C>,
    onChange: Observe,
    inject: Inject<S>
)


public func createRamStore() -> DefaultStore {
    var s = AppState(){didSet{c.forEach{$0()}}}
    var c = [()->()]()
    return (
        state: { s },
        change: { s = s.apply($0) },
        onChange: { c = c + [$0] },
        inject: { s = $0 }
    )
}
