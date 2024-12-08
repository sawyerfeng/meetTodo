//
//  Item.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
