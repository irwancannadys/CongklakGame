//
//  Pit.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import Foundation

/// Represents a single pit on the game board
struct Pit {
    /// Number of stones in this pit
    var stoneCount: Int
    
    /// Indicates if this is a store (large pit)
    let isStore: Bool
    
    /// The player who owns this pit
    let owner: Player
    
    /// Check if the pit is empty
    var isEmpty: Bool {
        return stoneCount == 0
    }
    
    /// Check if this pit can be selected by the given player
    func canBeSelected(by player: Player) -> Bool {
        // Can't select if it's a store
        guard !isStore else { return false }
        
        // Can't select if it's empty
        guard !isEmpty else { return false }
        
        // Can only select own pits
        return owner == player
    }
}

// MARK: - CustomStringConvertible
extension Pit: CustomStringConvertible {
    var description: String {
        let type = isStore ? "Store" : "Pit"
        return "\(type)[\(owner.displayName)]: \(stoneCount) stones"
    }
}
