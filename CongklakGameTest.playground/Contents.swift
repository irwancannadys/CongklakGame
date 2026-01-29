import Foundation

// MARK: - Player Model
enum Player: Int, CaseIterable {
    case one = 0
    case two = 1
    
    var opponent: Player {
        switch self {
        case .one: return .two
        case .two: return .one
        }
    }
    
    var displayName: String {
        switch self {
        case .one: return "Player 1"
        case .two: return "Player 2"
        }
    }
}

// MARK: - Pit Model
struct Pit {
    var stoneCount: Int
    let isStore: Bool
    let owner: Player
    
    var isEmpty: Bool {
        return stoneCount == 0
    }
    
    func canBeSelected(by player: Player) -> Bool {
        guard !isStore else { return false }
        guard !isEmpty else { return false }
        return owner == player
    }
}

extension Pit: CustomStringConvertible {
    var description: String {
        let type = isStore ? "Store" : "Pit"
        return "\(type)[\(owner.displayName)]: \(stoneCount) stones"
    }
}

// MARK: - GameBoard Model
struct GameBoard {
    static let totalPits = 16
    static let pitsPerPlayer = 7
    static let initialStonesPerPit = 7
    
    var pits: [Pit]
    
    init() {
        var initialPits: [Pit] = []
        
        initialPits.append(Pit(stoneCount: 0, isStore: true, owner: .one))
        
        for _ in 1...GameBoard.pitsPerPlayer {
            initialPits.append(Pit(stoneCount: GameBoard.initialStonesPerPit, isStore: false, owner: .one))
        }
        
        for _ in 1...GameBoard.pitsPerPlayer {
            initialPits.append(Pit(stoneCount: GameBoard.initialStonesPerPit, isStore: false, owner: .two))
        }
        
        initialPits.append(Pit(stoneCount: 0, isStore: true, owner: .two))
        
        self.pits = initialPits
    }
    
    subscript(index: Int) -> Pit {
        get { return pits[index] }
        set { pits[index] = newValue }
    }
    
    func storeIndex(for player: Player) -> Int {
        switch player {
        case .one: return 0
        case .two: return 15
        }
    }
    
    func pitIndices(for player: Player) -> Range<Int> {
        switch player {
        case .one: return 1..<8
        case .two: return 8..<15
        }
    }
    
    func isSideEmpty(for player: Player) -> Bool {
        let range = pitIndices(for: player)
        return range.allSatisfy { pits[$0].isEmpty }
    }
    
    func storeCount(for player: Player) -> Int {
        return pits[storeIndex(for: player)].stoneCount
    }
    
    func oppositePitIndex(of index: Int) -> Int? {
        guard !pits[index].isStore else { return nil }
        let opposite = 15 - index
        guard opposite >= 1 && opposite <= 14 else { return nil }
        return opposite
    }
}

extension GameBoard: CustomStringConvertible {
    var description: String {
        var result = "GameBoard:\n"
        result += "Player 2: "
        
        for i in stride(from: 14, through: 8, by: -1) {
            result += "[\(pits[i].stoneCount)] "
        }
        result += "Store: [\(pits[15].stoneCount)]\n"
        
        result += "Player 1: Store: [\(pits[0].stoneCount)] "
        
        for i in 1...7 {
            result += "[\(pits[i].stoneCount)] "
        }
        
        return result
    }
}

// MARK: - GameEngine
struct MoveResult {
    let board: GameBoard
    let affectedIndices: [Int]
    let extraTurn: Bool
    let captureOccurred: Bool
    let lastStoneIndex: Int
    let capturedStones: Int
}

protocol GameEngineProtocol {
    var currentBoard: GameBoard { get }
    var currentPlayer: Player { get }
    
    func startNewGame()
    func canSelectPit(at index: Int) -> Bool
    func performMove(from index: Int) -> MoveResult?
    func checkGameEnd() -> Bool
    func determineWinner() -> Player?
}

class GameEngine: GameEngineProtocol {
    private(set) var currentBoard: GameBoard
    private(set) var currentPlayer: Player
    
    init() {
        self.currentBoard = GameBoard()
        self.currentPlayer = .one
    }
    
    func startNewGame() {
        currentBoard = GameBoard()
        currentPlayer = .one
    }
    
    func canSelectPit(at index: Int) -> Bool {
        guard index >= 0 && index < GameBoard.totalPits else {
            return false
        }
        let pit = currentBoard[index]
        return pit.canBeSelected(by: currentPlayer)
    }
    
    func performMove(from index: Int) -> MoveResult? {
        guard canSelectPit(at: index) else {
            return nil
        }
        
        var stones = currentBoard[index].stoneCount
        currentBoard[index].stoneCount = 0
        
        var affectedIndices: [Int] = [index]
        var currentIndex = index
        
        while stones > 0 {
            currentIndex = nextIndex(from: currentIndex)
            
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
        
        if lastStoneIndex == currentBoard.storeIndex(for: currentPlayer) {
            extraTurn = true
        } else if shouldCapture(at: lastStoneIndex) {
            capturedStones = performCapture(at: lastStoneIndex)
            captureOccurred = true
            
            if let oppositeIndex = currentBoard.oppositePitIndex(of: lastStoneIndex) {
                affectedIndices.append(oppositeIndex)
                affectedIndices.append(currentBoard.storeIndex(for: currentPlayer))
            }
        }
        
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
    
    func checkGameEnd() -> Bool {
        return currentBoard.isSideEmpty(for: .one) || currentBoard.isSideEmpty(for: .two)
    }
    
    func determineWinner() -> Player? {
        collectRemainingStones()
        
        let player1Score = currentBoard.storeCount(for: .one)
        let player2Score = currentBoard.storeCount(for: .two)
        
        if player1Score > player2Score {
            return .one
        } else if player2Score > player1Score {
            return .two
        } else {
            return nil
        }
    }
    
    private func nextIndex(from index: Int) -> Int {
        return (index + 1) % GameBoard.totalPits
    }
    
    private func shouldCapture(at index: Int) -> Bool {
        let pit = currentBoard[index]
        
        guard pit.owner == currentPlayer else { return false }
        guard !pit.isStore else { return false }
        guard pit.stoneCount == 1 else { return false }
        
        guard let oppositeIndex = currentBoard.oppositePitIndex(of: index),
              currentBoard[oppositeIndex].stoneCount > 0 else {
            return false
        }
        
        return true
    }
    
    private func performCapture(at index: Int) -> Int {
        guard let oppositeIndex = currentBoard.oppositePitIndex(of: index) else {
            return 0
        }
        
        let ownStones = currentBoard[index].stoneCount
        let oppositeStones = currentBoard[oppositeIndex].stoneCount
        let totalCaptured = ownStones + oppositeStones
        
        currentBoard[index].stoneCount = 0
        currentBoard[oppositeIndex].stoneCount = 0
        
        let storeIndex = currentBoard.storeIndex(for: currentPlayer)
        currentBoard[storeIndex].stoneCount += totalCaptured
        
        return totalCaptured
    }
    
    private func collectRemainingStones() {
        for index in currentBoard.pitIndices(for: .one) {
            let stones = currentBoard[index].stoneCount
            if stones > 0 {
                currentBoard[index].stoneCount = 0
                let storeIndex = currentBoard.storeIndex(for: .one)
                currentBoard[storeIndex].stoneCount += stones
            }
        }
        
        for index in currentBoard.pitIndices(for: .two) {
            let stones = currentBoard[index].stoneCount
            if stones > 0 {
                currentBoard[index].stoneCount = 0
                let storeIndex = currentBoard.storeIndex(for: .two)
                currentBoard[storeIndex].stoneCount += stones
            }
        }
    }
}

// MARK: - TESTING
print("=== CONGKLAK GAME ENGINE TEST ===\n")

let engine = GameEngine()

print("Initial Board:")
print(engine.currentBoard)
print("\nCurrent Player: \(engine.currentPlayer.displayName)")
print("---")

// Test Move 1: Player 1 selects pit 1 (7 stones)
print("\n📍 Player 1 selects pit 1 (has 7 stones)")
if let result = engine.performMove(from: 1) {
    print("✅ Move successful!")
    print("Extra turn: \(result.extraTurn)")
    print("Capture: \(result.captureOccurred)")
    print("Last stone landed at: \(result.lastStoneIndex)")
    print("\nBoard after move:")
    print(engine.currentBoard)
    print("Current Player: \(engine.currentPlayer.displayName)")
} else {
    print("❌ Invalid move")
}

print("\n---")

// Test Move 2
print("\n📍 Player 2 selects pit 8 (has 7 stones)")
if let result = engine.performMove(from: 8) {
    print("✅ Move successful!")
    print("Extra turn: \(result.extraTurn)")
    print("Capture: \(result.captureOccurred)")
    print("\nBoard after move:")
    print(engine.currentBoard)
    print("Current Player: \(engine.currentPlayer.displayName)")
} else {
    print("❌ Invalid move")
}

print("\n---")
print("\n✅ TEST COMPLETED!")
