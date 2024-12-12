//
//  Item.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-04.
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
