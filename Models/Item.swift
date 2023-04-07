//
//  Item.swift
//  Models
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import Foundation

public struct ToDo {
    public let id: UUID
    public let title: String
    public let done: Bool
}

public extension ToDo {
    
    init() {
        id = UUID()
        title = ""
        done = false
    }
    
    init(_ id: UUID, _ title: String, _ done: Bool) {
        self.id = id
        self.title = title
        self.done = done
    }
    
    enum Change {
        case title(String)
        case complete
        case uncomplete
    }
    
    func apply(_ change: Change) -> Self {
        switch change {
        case .title(let title): return .init(id, title, done)
        case .complete  : return .init(id, title, true)
        case .uncomplete: return .init(id, title, false)
        }
    }
}

extension ToDo: Codable, Identifiable {}
extension ToDo.Change: Codable {}
