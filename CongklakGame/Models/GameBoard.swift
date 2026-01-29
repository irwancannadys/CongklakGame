//
//  GameBoard.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import Foundation

/// Represents the complete game board with all pits
struct GameBoard {
    /// Total number of pits on the board (including stores)
    static let totalPits = 16
    
    /// Number of small pits per player
    static let pitsPerPlayer = 7
    
    /// Initial number of stones in each small pit
    static let initialStonesPerPit = 7
    
    /// Array of all pits on the board
    /// Layout: [P1_Store, P1_Pit1-7, P2_Pit1-7, P2_Store]
    var pits: [Pit]
    
    // MARK: - Initialization
    
    /// Initialize a new game board with starting configuration
    init() {
        var initialPits: [Pit] = []
        
        // Player 1's store (index 0)
        initialPits.append(Pit(stoneCount: 0, isStore: true, owner: .one))
        
        // Player 1's small pits (index 1-7)
        for _ in 1...GameBoard.pitsPerPlayer {
            initialPits.append(Pit(
                stoneCount: GameBoard.initialStonesPerPit,
                isStore: false,
                owner: .one
            ))
        }
        
        // Player 2's small pits (index 8-14)
        for _ in 1...GameBoard.pitsPerPlayer {
            initialPits.append(Pit(
                stoneCount: GameBoard.initialStonesPerPit,
                isStore: false,
                owner: .two
            ))
        }
        
        // Player 2's store (index 15)
        initialPits.append(Pit(stoneCount: 0, isStore: true, owner: .two))
        
        self.pits = initialPits
    }
    
    // MARK: - Helper Methods
    
    /// Get pit at specific index
    subscript(index: Int) -> Pit {
        get {
            return pits[index]
        }
        set {
            pits[index] = newValue
        }
    }
    
    /// Get store index for a player
    func storeIndex(for player: Player) -> Int {
        switch player {
        case .one: return 0
        case .two: return 15
        }
    }
    
    /// Get the range of pit indices owned by a player (excluding store)
    func pitIndices(for player: Player) -> Range<Int> {
        switch player {
        case .one: return 1..<8    // indices 1-7
        case .two: return 8..<15   // indices 8-14
        }
    }
    
    /// Check if all pits on one side are empty
    func isSideEmpty(for player: Player) -> Bool {
        let range = pitIndices(for: player)
        return range.allSatisfy { pits[$0].isEmpty }
    }
    
    /// Get total stones in a player's store
    func storeCount(for player: Player) -> Int {
        return pits[storeIndex(for: player)].stoneCount
    }
    
    /// Calculate opposite pit index
    /// For player 1's pit at index i (1-7), opposite is at 15-i
    /// For player 2's pit at index i (8-14), opposite is at 15-i
    func oppositePitIndex(of index: Int) -> Int? {
        // Only small pits have opposites
        guard !pits[index].isStore else { return nil }
        
        // Calculate opposite
        let opposite = 15 - index
        
        // Validate
        guard opposite >= 1 && opposite <= 14 else { return nil }
        
        return opposite
    }
}

// MARK: - CustomStringConvertible
extension GameBoard: CustomStringConvertible {
    var description: String {
        var result = "GameBoard:\n"
        result += "Player 2: "
        
        // Player 2's pits (reversed for display)
        for i in stride(from: 14, through: 8, by: -1) {
            result += "[\(pits[i].stoneCount)] "
        }
        result += "Store: [\(pits[15].stoneCount)]\n"
        
        result += "Player 1: Store: [\(pits[0].stoneCount)] "
        
        // Player 1's pits
        for i in 1...7 {
            result += "[\(pits[i].stoneCount)] "
        }
        
        return result
    }
}
