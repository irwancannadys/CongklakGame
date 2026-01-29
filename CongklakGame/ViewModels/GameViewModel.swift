//
//  GameViewModel.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import Foundation
import Combine

/// Game status enumeration
enum GameStatus : Equatable {
    case notStarted
    case inProgress
    case ended(winner: Player?)
    
    var displayMessage: String {
        switch self {
        case .notStarted:
            return "Tap 'Start Game' to begin"
        case .inProgress:
            return "Game in progress"
        case .ended(let winner):
            if let winner = winner {
                return "\(winner.displayName) wins!"
            } else {
                return "It's a tie!"
            }
        }
    }
}

/// ViewModel that manages game state and coordinates with GameEngine
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current game board state
    @Published private(set) var gameBoard: GameBoard
    
    /// Current player's turn
    @Published private(set) var currentPlayer: Player
    
    /// Current game status
    @Published private(set) var gameStatus: GameStatus
    
    /// Message to display to user
    @Published private(set) var statusMessage: String
    
    /// Indices of pits that are currently animating
    @Published private(set) var animatingPitIndices: Set<Int> = []
    
    /// Last move result (for animations)
    @Published private(set) var lastMoveResult: MoveResult?
    
    // MARK: - Private Properties
    
    private let gameEngine: GameEngineProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(gameEngine: GameEngineProtocol = GameEngine()) {
        self.gameEngine = gameEngine
        self.gameBoard = gameEngine.currentBoard
        self.currentPlayer = gameEngine.currentPlayer
        self.gameStatus = .notStarted
        self.statusMessage = "Ready to play Congklak!"
    }
    
    // MARK: - Public Methods
    
    /// Start a new game
    func startNewGame() {
        
        print("\n🎮 ========================================")
        print("🎮 NEW GAME STARTED")
        print("🎮 ========================================\n")
        
        gameEngine.startNewGame()
        updateState()
        gameStatus = .inProgress
        statusMessage = "\(currentPlayer.displayName)'s turn"
    }
    
    /// Handle pit selection by user
    /// - Parameter index: Index of the selected pit
    func selectPit(at index: Int) {
        print("\n========================================")
        print("🎮 PLAYER ACTION: Tap pit at index \(index)")
        
        // Don't allow moves if game is not in progress
        guard gameStatus == .inProgress else {
            statusMessage = "Please start a new game"
            print("❌ Game not in progress")
            print("========================================\n")
            return
        }
        
        // Check if pit can be selected
        guard gameEngine.canSelectPit(at: index) else {
            statusMessage = "Invalid selection. Choose a pit with stones that you own."
            print("❌ Invalid pit selection")
            print("   - Current player: \(currentPlayer.displayName)")
            print("   - Pit owner: \(gameBoard[index].owner.displayName)")
            print("   - Pit stones: \(gameBoard[index].stoneCount)")
            print("   - Is store: \(gameBoard[index].isStore)")
            print("========================================\n")
            return
        }
        
        let stonesBefore = gameBoard[index].stoneCount
        print("✅ Valid selection")
        print("   - Player: \(currentPlayer.displayName)")
        print("   - Pit index: \(index)")
        print("   - Stones to distribute: \(stonesBefore)")
        
        // Perform the move
        guard let result = gameEngine.performMove(from: index) else {
            statusMessage = "Move failed. Please try again."
            print("❌ Move execution failed")
            print("========================================\n")
            return
        }
        
        print("\n📊 MOVE RESULT:")
        print("   - Affected pits: \(result.affectedIndices)")
        print("   - Last stone at: \(result.lastStoneIndex)")
        print("   - Extra turn: \(result.extraTurn ? "YES ✨" : "NO")")
        print("   - Capture occurred: \(result.captureOccurred ? "YES 🎯" : "NO")")
        if result.captureOccurred {
            print("   - Captured stones: \(result.capturedStones)")
        }
        
        // Store result for animations
        lastMoveResult = result
        
        // Update animating indices
        animatingPitIndices = Set(result.affectedIndices)
        
        // Update state
        updateState()
        
        print("\n📋 BOARD STATE:")
        print("   Player 1 Store: \(score(for: .one))")
        print("   Player 2 Store: \(score(for: .two))")
        print("   Next player: \(currentPlayer.displayName)")
        
        // Update status message
        updateStatusMessage(for: result)
        
        // Check if game ended
        if gameEngine.checkGameEnd() {
            print("\n🏁 GAME ENDED!")
            handleGameEnd()
        }
        
        print("========================================\n")
        
        // Clear animations after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.animatingPitIndices.removeAll()
        }
    }
    
    /// Reset the game
    func resetGame() {
        startNewGame()
    }
    
    /// Check if a pit can be selected
    /// - Parameter index: Index of the pit
    /// - Returns: True if pit can be selected by current player
    func canSelectPit(at index: Int) -> Bool {
        guard gameStatus == .inProgress else { return false }
        return gameEngine.canSelectPit(at: index)
    }
    
    /// Get display text for a pit
    /// - Parameter index: Index of the pit
    /// - Returns: String representation of stone count
    func pitDisplayText(at index: Int) -> String {
        return "\(gameBoard[index].stoneCount)"
    }
    
    /// Check if a pit should be highlighted (belongs to current player)
    /// - Parameter index: Index of the pit
    /// - Returns: True if pit should be highlighted
    func shouldHighlightPit(at index: Int) -> Bool {
        guard gameStatus == .inProgress else { return false }
        let pit = gameBoard[index]
        return pit.owner == currentPlayer && !pit.isStore && !pit.isEmpty
    }
    
    /// Get player's current score (stones in store)
    /// - Parameter player: The player
    /// - Returns: Number of stones in player's store
    func score(for player: Player) -> Int {
        return gameBoard.storeCount(for: player)
    }
    
    // MARK: - Private Methods
    
    /// Update view model state from game engine
    private func updateState() {
        gameBoard = gameEngine.currentBoard
        currentPlayer = gameEngine.currentPlayer
    }
    
    /// Update status message based on move result
    private func updateStatusMessage(for result: MoveResult) {
        var messages: [String] = []
        
        if result.captureOccurred {
            messages.append("Captured \(result.capturedStones) stones!")
        }
        
        if result.extraTurn {
            messages.append("\(currentPlayer.displayName) gets an extra turn!")
        } else {
            messages.append("\(currentPlayer.displayName)'s turn")
        }
        
        statusMessage = messages.joined(separator: " ")
    }
    
    /// Handle game end
    private func handleGameEnd() {
        let winner = gameEngine.determineWinner()
        gameStatus = .ended(winner: winner)
        
        // Update board one final time after collecting remaining stones
        updateState()
        
        // Create end game message
        if let winner = winner {
            let player1Score = score(for: .one)
            let player2Score = score(for: .two)
            statusMessage = """
            Game Over!
            \(winner.displayName) wins!
            Score: Player 1: \(player1Score) - Player 2: \(player2Score)
            """
        } else {
            statusMessage = "Game Over! It's a tie!"
        }
    }
}

// MARK: - Computed Properties for UI
extension GameViewModel {
    
    /// Get all pit indices for Player 1 (for UI layout)
    var player1PitIndices: [Int] {
        return Array(gameBoard.pitIndices(for: .one))
    }
    
    /// Get all pit indices for Player 2 (for UI layout)
    var player2PitIndices: [Int] {
        return Array(gameBoard.pitIndices(for: .two)).reversed() // Reversed for visual layout
    }
    
    /// Get Player 1's store index
    var player1StoreIndex: Int {
        return gameBoard.storeIndex(for: .one)
    }
    
    /// Get Player 2's store index
    var player2StoreIndex: Int {
        return gameBoard.storeIndex(for: .two)
    }
    
    /// Check if game is in progress
    var isGameInProgress: Bool {
        if case .inProgress = gameStatus {
            return true
        }
        return false
    }
    
    /// Check if game has ended
    var isGameEnded: Bool {
        if case .ended = gameStatus {
            return true
        }
        return false
    }
}
