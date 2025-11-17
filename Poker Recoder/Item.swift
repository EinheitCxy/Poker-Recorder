//
//  Item.swift
//  Poker Recoder
//
//  Created by cxy on 2025/11/17.
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
