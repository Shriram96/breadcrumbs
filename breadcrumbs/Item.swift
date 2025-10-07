//
//  Item.swift
//  breadcrumbs
//
//  Created by Shriram R on 10/5/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    // MARK: Lifecycle

    init(timestamp: Date) {
        self.timestamp = timestamp
    }

    // MARK: Internal

    var timestamp: Date
}
