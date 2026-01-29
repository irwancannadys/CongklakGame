//
//  GameEngine.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import Foundation

/// Result of a move operation
struct MoveResult {
    /// The updated game board after the move
    let board: GameBoard
    
    /// Indices of pits that were affected (for animation)
    let affectedIndices: [Int]
    
    /// Whether the current player gets an extra turn
    let extraTurn: Bool
    
    /// Whether a capture occurred
    let captureOccurred: Bool
    
    /// Index where the last stone landed
    let lastStoneIndex: Int
    
    /// Captured stones count (if capture occurred)
    let capturedStones: Int
}

/// Protocol for game engine to allow testing
protocol GameEngineProtocol {
    var currentBoard: GameBoard { get }
    var currentPlayer: Player { get }
    
    func startNewGame()
    func canSelectPit(at index: Int) -> Bool
    func performMove(from index: Int) -> MoveResult?
    func checkGameEnd() -> Bool
    func determineWinner() -> Player?
}

/// Game engine that handles all game logic
class GameEngine: GameEngineProtocol {
    
    // MARK: - Properties
    
    /// Current state of the game board
    var currentBoard: GameBoard
    
    /// Current player's turn
    var currentPlayer: Player
    
    // MARK: - Initialization
    
    init() {
        self.currentBoard = GameBoard()
        self.currentPlayer = .one
    }
    
    // MARK: - Public Methods
    
    /// Start a new game with fresh board
    func startNewGame() {
        currentBoard = GameBoard()
        currentPlayer = .one
    }
    
    /// Check if a pit can be selected by current player
    func canSelectPit(at index: Int) -> Bool {
        // Validate index
        guard index >= 0 && index < GameBoard.totalPits else {
            return false
        }
        
        let pit = currentBoard[index]
        return pit.canBeSelected(by: currentPlayer)
    }
    
    /// Perform a move from the selected pit
    /// Returns MoveResult if move is valid, nil otherwise
    func performMove(from index: Int) -> MoveResult? {
        // Validate move
        guard canSelectPit(at: index) else {
            return nil
        }
        
        // Get stones from selected pit
        var stones = currentBoard[index].stoneCount
        currentBoard[index].stoneCount = 0
        
        var affectedIndices: [Int] = [index]
        var currentIndex = index
        
        // Distribute stones counter-clockwise
        while stones > 0 {
            currentIndex = nextIndex(from: currentIndex)
            
            // Skip opponent's store
            if currentIndex == currentBoard.storeIndex(for: currentPlayer.opponent) {
                continue
            }
            
            currentBoard[currentIndex].stoneCount += 1
            affectedIndices.append(currentIndex)
            stones -= 1
        }
        
        let lastStoneIndex = currentIndex
        var extraTurn = false
        var captureOccurred = false
        var capturedStones = 0
        
        // Check for extra turn (last stone in own store)
        if lastStoneIndex == currentBoard.storeIndex(for: currentPlayer) {
            extraTurn = true
        }
        // Check for capture rule
        else if shouldCapture(at: lastStoneIndex) {
            capturedStones = performCapture(at: lastStoneIndex)
            captureOccurred = true
            
            if let oppositeIndex = currentBoard.oppositePitIndex(of: lastStoneIndex) {
                affectedIndices.append(oppositeIndex)
                affectedIndices.append(currentBoard.storeIndex(for: currentPlayer))
            }
        }
        
        // Switch turn if no extra turn
        if !extraTurn {
            currentPlayer = currentPlayer.opponent
        }
        
        return MoveResult(
            board: currentBoard,
            affectedIndices: affectedIndices,
            extraTurn: extraTurn,
            captureOccurred: captureOccurred,
            lastStoneIndex: lastStoneIndex,
            capturedStones: capturedStones
        )
    }
    
    /// Check if the game has ended
    func checkGameEnd() -> Bool {
        return currentBoard.isSideEmpty(for: .one) ||
               currentBoard.isSideEmpty(for: .two)
    }
    
    /// Determine the winner (call after game ends)
    /// Returns nil if it's a tie
    func determineWinner() -> Player? {
        // Collect remaining stones
        collectRemainingStones()
        
        let player1Score = currentBoard.storeCount(for: .one)
        let player2Score = currentBoard.storeCount(for: .two)
        
        if player1Score > player2Score {
            return .one
        } else if player2Score > player1Score {
            return .two
        } else {
            return nil // Tie
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Get the next pit index in counter-clockwise direction
    private func nextIndex(from index: Int) -> Int {
        return (index + 1) % GameBoard.totalPits
    }
    
    /// Check if capture should occur at the given index
    private func shouldCapture(at index: Int) -> Bool {
        let pit = currentBoard[index]
        
        // Must be current player's pit
        guard pit.owner == currentPlayer else {
            return false
        }
        
        // Must not be a store
        guard !pit.isStore else {
            return false
        }
        
        // Last stone must have landed in empty pit (now has 1 stone)
        guard pit.stoneCount == 1 else {
            return false
        }
        
        // Opposite pit must have stones
        guard let oppositeIndex = currentBoard.oppositePitIndex(of: index),
              currentBoard[oppositeIndex].stoneCount > 0 else {
            return false
        }
        
        return true
    }
    
    /// Perform capture from the given index
    /// Returns the total number of stones captured
    private func performCapture(at index: Int) -> Int {
        guard let oppositeIndex = currentBoard.oppositePitIndex(of: index) else {
            return 0
        }
        
        // Get stones from both pits
        let ownStones = currentBoard[index].stoneCount
        let oppositeStones = currentBoard[oppositeIndex].stoneCount
        let totalCaptured = ownStones + oppositeStones
        
        // Clear both pits
        currentBoard[index].stoneCount = 0
        currentBoard[oppositeIndex].stoneCount = 0
        
        // Add to current player's store
        let storeIndex = currentBoard.storeIndex(for: currentPlayer)
        currentBoard[storeIndex].stoneCount += totalCaptured
        
        return totalCaptured
    }
    
    /// Collect remaining stones to respective stores (at end of game)
    private func collectRemainingStones() {
        // Collect Player 1's remaining stones
        for index in currentBoard.pitIndices(for: .one) {
            let stones = currentBoard[index].stoneCount
            if stones > 0 {
                currentBoard[index].stoneCount = 0
                let storeIndex = currentBoard.storeIndex(for: .one)
                currentBoard[storeIndex].stoneCount += stones
            }
        }
        
        // Collect Player 2's remaining stones
        for index in currentBoard.pitIndices(for: .two) {
            let stones = currentBoard[index].stoneCount
            if stones > 0 {
                currentBoard[index].stoneCount = 0
                let storeIndex = currentBoard.storeIndex(for: .two)
                currentBoard[storeIndex].stoneCount += stones
            }
        }
    }
    
#if DEBUG
  /// For testing purposes only - allows direct board manipulation
  func setBoard(_ board: GameBoard) {
      self.currentBoard = board
  }
  
  /// For testing purposes only - allows direct player setting
  func setCurrentPlayer(_ player: Player) {
      self.currentPlayer = player
  }
  #endif
}

// MARK: - CustomStringConvertible
extension GameEngine: CustomStringConvertible {
    var description: String {
        return """
        GameEngine:
        Current Player: \(currentPlayer.displayName)
        \(currentBoard.description)
        Game Ended: \(checkGameEnd())
        """
    }
}
