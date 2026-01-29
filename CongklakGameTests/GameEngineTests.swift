//
//  GameEngineTests.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

//
//  GameEngineTests.swift
//  CongklakGameTests
//
//  Created by [Your Name] on 29/01/26.
//

import XCTest
@testable import CongklakGame

final class GameEngineTests: XCTestCase {
    
    var sut: GameEngine!
    
    override func setUp() {
        super.setUp()
        sut = GameEngine()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialBoardSetup() {
        // Given: New game engine
        
        // Then: Board should have correct initial state
        XCTAssertEqual(
            sut.currentBoard.pits.count,
            16,
            "Board should have 16 pits"
        )
        
        // Stores should be empty
        XCTAssertEqual(
            sut.currentBoard[0].stoneCount,
            0,
            "Player 1 store should be empty"
        )
        XCTAssertEqual(
            sut.currentBoard[15].stoneCount,
            0,
            "Player 2 store should be empty"
        )
        
        // Small pits should have 7 stones each
        for index in 1...7 {
            XCTAssertEqual(
                sut.currentBoard[index].stoneCount,
                7,
                "Player 1 pit \(index) should have 7 stones"
            )
        }
        
        for index in 8...14 {
            XCTAssertEqual(
                sut.currentBoard[index].stoneCount,
                7,
                "Player 2 pit \(index) should have 7 stones"
            )
        }
        
        // Player 1 should start
        XCTAssertEqual(
            sut.currentPlayer,
            .one,
            "Player 1 should start the game"
        )
    }
    
    func testStoreOwnership() {
        // Given: New game board
        
        // Then: Stores should belong to correct players
        XCTAssertEqual(
            sut.currentBoard[0].owner,
            .one,
            "Store at index 0 should belong to Player 1"
        )
        XCTAssertEqual(
            sut.currentBoard[15].owner,
            .two,
            "Store at index 15 should belong to Player 2"
        )
        
        XCTAssertTrue(sut.currentBoard[0].isStore, "Index 0 should be a store")
        XCTAssertTrue(
            sut.currentBoard[15].isStore,
            "Index 15 should be a store"
        )
    }
    
    func testPitOwnership() {
        // Given: New game board
        
        // Then: Pits should belong to correct players
        for index in 1...7 {
            XCTAssertEqual(
                sut.currentBoard[index].owner,
                .one,
                "Pit \(index) should belong to Player 1"
            )
            XCTAssertFalse(
                sut.currentBoard[index].isStore,
                "Pit \(index) should not be a store"
            )
        }
        
        for index in 8...14 {
            XCTAssertEqual(
                sut.currentBoard[index].owner,
                .two,
                "Pit \(index) should belong to Player 2"
            )
            XCTAssertFalse(
                sut.currentBoard[index].isStore,
                "Pit \(index) should not be a store"
            )
        }
    }
    
    // MARK: - Move Validation Tests
    
    func testCannotSelectEmptyPit() {
        // Given: Empty pit
        sut.currentBoard[1].stoneCount = 0
        
        // When/Then: Should not be able to select
        XCTAssertFalse(
            sut.canSelectPit(at: 1),
            "Should not be able to select empty pit"
        )
    }
    
    func testCannotSelectOpponentPit() {
        // Given: Player 1's turn
        XCTAssertEqual(sut.currentPlayer, .one)
        
        // When/Then: Should not be able to select Player 2's pit
        XCTAssertFalse(
            sut.canSelectPit(at: 8),
            "Should not be able to select opponent's pit"
        )
        XCTAssertFalse(
            sut.canSelectPit(at: 14),
            "Should not be able to select opponent's pit"
        )
    }
    
    func testCannotSelectStore() {
        // Given: Player 1's turn
        XCTAssertEqual(sut.currentPlayer, .one)
        
        // When/Then: Should not be able to select stores
        XCTAssertFalse(
            sut.canSelectPit(at: 0),
            "Should not be able to select own store"
        )
        XCTAssertFalse(
            sut.canSelectPit(at: 15),
            "Should not be able to select opponent's store"
        )
    }
    
    func testCanSelectValidPit() {
        // Given: Player 1's turn with stones in pit
        XCTAssertEqual(sut.currentPlayer, .one)
        
        // When/Then: Should be able to select own non-empty pits
        for index in 1...7 {
            XCTAssertTrue(
                sut.canSelectPit(at: index),
                "Should be able to select pit \(index)"
            )
        }
    }
    
    func testCannotSelectInvalidIndex() {
        // Given: Invalid indices
        
        // When/Then: Should return false
        XCTAssertFalse(
            sut.canSelectPit(at: -1),
            "Should not allow negative index"
        )
        XCTAssertFalse(sut.canSelectPit(at: 16), "Should not allow index >= 16")
        XCTAssertFalse(
            sut.canSelectPit(at: 100),
            "Should not allow large index"
        )
    }
    
    // MARK: - Stone Distribution Tests
    
    func testBasicStoneDistribution() {
        // Given: Player 1 selects pit 1 with 7 stones
        let initialStones = sut.currentBoard[1].stoneCount
        XCTAssertEqual(initialStones, 7)
        
        // When: Perform move
        let result = sut.performMove(from: 1)
        
        // Then: Stones should be distributed
        XCTAssertNotNil(result, "Move should succeed")
        XCTAssertEqual(
            sut.currentBoard[1].stoneCount,
            0,
            "Selected pit should be empty"
        )
        
        // Stones distributed to pits 2-8
        for index in 2...8 {
            XCTAssertEqual(
                sut.currentBoard[index].stoneCount,
                8,
                "Pit \(index) should have 8 stones"
            )
        }
    }
    
    func testDistributionSkipsOpponentStore() {
        // Given: Player 1 selects pit 7 with 7 stones (will reach index 14)
        
        // When: Perform move
        let result = sut.performMove(from: 7)
        
        // Then: Should skip Player 2's store (index 15)
        XCTAssertNotNil(result)
        
        // Stone should have gone to pits 8-14 (not 15)
        XCTAssertEqual(
            sut.currentBoard[15].stoneCount,
            0,
            "Should skip opponent's store"
        )
    }
    
    func testDistributionCounterClockwise() {
        // Given: Player 1 at pit 1 with correct stones to reach store
        // From pit 1, need exactly 15 stones to reach index 0 (wrapping around)
        // But simpler: use pit 7 with 8 stones
        
        // Pit 7 → 8,9,10,11,12,13,14,(skip 15),0
        sut.currentBoard[7].stoneCount = 8
        
        // When: Perform move
        let result = sut.performMove(from: 7)
        
        // Then: Last stone should be in store (index 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(
            result?.lastStoneIndex,
            0,
            "Last stone should land in store"
        )
        XCTAssertGreaterThan(
            sut.currentBoard[0].stoneCount,
            0,
            "Store should have stones"
        )
    }

    // MARK: - Extra Turn Rule Tests

    func testExtraTurnWhenLastStoneInOwnStore() {
        // Given: Setup so last stone lands in Player 1's store
        // Pit 7 with 8 stones will reach index 0 (store)
        // Path: 7 → 8,9,10,11,12,13,14,(skip 15),0
        
        sut.currentBoard[7].stoneCount = 8
        
        // When: Perform move
        let result = sut.performMove(from: 7)
        
        // Then: Should get extra turn
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.extraTurn ?? false, "Should get extra turn")
        XCTAssertEqual(
            sut.currentPlayer,
            .one,
            "Should still be Player 1's turn"
        )
    }
    
    func testNoExtraTurnWhenLastStoneNotInStore() {
        // Given: Pit 1 with 7 stones, last stone at index 8 (not store)
        
        // When: Perform move
        let result = sut.performMove(from: 1)
        
        // Then: Should not get extra turn
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.extraTurn ?? true, "Should not get extra turn")
        XCTAssertEqual(
            sut.currentPlayer,
            .two,
            "Turn should switch to Player 2"
        )
    }
    
    // MARK: - Capture Rule Tests
    
    func testCaptureWhenLastStoneInEmptyOwnPit() {
        // Given: Setup capture scenario
        // Empty pit at index 2, opposite pit (13) has stones
        sut.currentBoard[2].stoneCount = 0
        sut.currentBoard[13].stoneCount = 5
        sut.currentBoard[1].stoneCount = 1 // Will land at index 2
        
        // When: Perform move
        let result = sut.performMove(from: 1)
        
        // Then: Should capture
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.captureOccurred ?? false, "Capture should occur")
        XCTAssertEqual(
            result?.capturedStones,
            6,
            "Should capture 1 + 5 = 6 stones"
        )
        
        // Both pits should be empty
        XCTAssertEqual(
            sut.currentBoard[2].stoneCount,
            0,
            "Landing pit should be empty"
        )
        XCTAssertEqual(
            sut.currentBoard[13].stoneCount,
            0,
            "Opposite pit should be empty"
        )
        
        // Stones should be in store
        XCTAssertEqual(
            sut.currentBoard[0].stoneCount,
            6,
            "Store should have captured stones"
        )
    }
    
    func testNoCaptureWhenOppositePitEmpty() {
        // Given: Empty opposite pit
        sut.currentBoard[2].stoneCount = 0
        sut.currentBoard[13].stoneCount = 0 // Opposite is empty
        sut.currentBoard[1].stoneCount = 1
        
        // When: Perform move
        let result = sut.performMove(from: 1)
        
        // Then: Should not capture
        XCTAssertNotNil(result)
        XCTAssertFalse(
            result?.captureOccurred ?? true,
            "Should not capture when opposite is empty"
        )
    }
    
    func testNoCaptureWhenLandingPitNotEmpty() {
        // Given: Landing pit has stones (not empty)
        sut.currentBoard[2].stoneCount = 3
        sut.currentBoard[13].stoneCount = 5
        sut.currentBoard[1].stoneCount = 1
        
        // When: Perform move
        let result = sut.performMove(from: 1)
        
        // Then: Should not capture
        XCTAssertNotNil(result)
        XCTAssertFalse(
            result?.captureOccurred ?? true,
            "Should not capture when landing pit not empty"
        )
    }
    
    func testNoCaptureWhenLastStoneInStore() {
        // Given: Last stone lands in store
        sut.currentBoard[6].stoneCount = 9 // Will land in store (index 0)
        
        // When: Perform move
        let result = sut.performMove(from: 6)
        
        // Then: Should not capture (store cannot capture)
        XCTAssertNotNil(result)
        XCTAssertFalse(
            result?.captureOccurred ?? true,
            "Store cannot trigger capture"
        )
    }
    
    // MARK: - Opposite Pit Calculation Tests
    
    func testOppositePitCalculation() {
        // Test opposite pit indices
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 1), 14)
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 2), 13)
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 3), 12)
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 7), 8)
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 8), 7)
        XCTAssertEqual(sut.currentBoard.oppositePitIndex(of: 14), 1)
    }
    
    func testStoresHaveNoOpposite() {
        // Stores should not have opposite pits
        XCTAssertNil(sut.currentBoard.oppositePitIndex(of: 0))
        XCTAssertNil(sut.currentBoard.oppositePitIndex(of: 15))
    }
    
    // MARK: - Game End Tests
    
    func testGameNotEndedAtStart() {
        // Given: New game
        
        // Then: Game should not be ended
        XCTAssertFalse(sut.checkGameEnd(), "Game should not be ended at start")
    }
    
    func testGameEndsWhenPlayer1SideEmpty() {
        // Given: Player 1's side is empty
        for index in 1...7 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        // Then: Game should be ended
        XCTAssertTrue(
            sut.checkGameEnd(),
            "Game should end when Player 1's side is empty"
        )
    }
    
    func testGameEndsWhenPlayer2SideEmpty() {
        // Given: Player 2's side is empty
        for index in 8...14 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        // Then: Game should be ended
        XCTAssertTrue(
            sut.checkGameEnd(),
            "Game should end when Player 2's side is empty"
        )
    }
    
    // MARK: - Winner Determination Tests
    
    func testDetermineWinnerPlayer1() {
        // Given: Player 1 has more stones
        sut.currentBoard[0].stoneCount = 50
        sut.currentBoard[15].stoneCount = 48
        
        // Empty all pits to end game
        for index in 1...14 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        // When: Determine winner
        let winner = sut.determineWinner()
        
        // Then: Player 1 should win
        XCTAssertEqual(winner, .one, "Player 1 should win with more stones")
    }
    
    func testDetermineWinnerPlayer2() {
        // Given: Player 2 has more stones
        sut.currentBoard[0].stoneCount = 30
        sut.currentBoard[15].stoneCount = 68
        
        // Empty all pits to end game
        for index in 1...14 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        // When: Determine winner
        let winner = sut.determineWinner()
        
        // Then: Player 2 should win
        XCTAssertEqual(winner, .two, "Player 2 should win with more stones")
    }
    
    func testDetermineWinnerTie() {
        // Given: Both players have same stones
        sut.currentBoard[0].stoneCount = 49
        sut.currentBoard[15].stoneCount = 49
        
        // Empty all pits
        for index in 1...14 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        // When: Determine winner
        let winner = sut.determineWinner()
        
        // Then: Should be a tie
        XCTAssertNil(winner, "Should be a tie when scores are equal")
    }
    
    func testRemainingStonesCollectedToStore() {
        // Given: Game ending with stones remaining
        // Player 1's side empty, Player 2 has remaining stones
        for index in 1...7 {
            sut.currentBoard[index].stoneCount = 0
        }
        
        sut.currentBoard[8].stoneCount = 3
        sut.currentBoard[9].stoneCount = 5
        sut.currentBoard[10].stoneCount = 2
        // Rest are 7 each (11-14)
        
        let player2RemainingStones = 3 + 5 + 2 + 7 + 7 + 7 + 7 // = 38
        
        // When: Determine winner (which collects remaining)
        _ = sut.determineWinner()
        
        // Then: Player 2's remaining stones should be in store
        XCTAssertEqual(
            sut.currentBoard[15].stoneCount,
            player2RemainingStones,
            "Remaining stones should be collected"
        )
        
        // All Player 2 pits should be empty
        for index in 8...14 {
            XCTAssertEqual(
                sut.currentBoard[index].stoneCount,
                0,
                "Pit \(index) should be empty"
            )
        }
    }
    
    // MARK: - New Game Tests
    
    func testStartNewGame() {
        // Given: Modified game state
        _ = sut.performMove(from: 1)
        _ = sut.performMove(from: 8)
        
        // When: Start new game
        sut.startNewGame()
        
        // Then: Should reset to initial state
        XCTAssertEqual(sut.currentPlayer, .one, "Should reset to Player 1")
        XCTAssertEqual(
            sut.currentBoard[0].stoneCount,
            0,
            "Store should be empty"
        )
        XCTAssertEqual(
            sut.currentBoard[15].stoneCount,
            0,
            "Store should be empty"
        )
        
        for index in 1...7 {
            XCTAssertEqual(
                sut.currentBoard[index].stoneCount,
                7,
                "Pit should have 7 stones"
            )
        }
    }
    
    // MARK: - Edge Cases
    
    func testMultipleConsecutiveMoves() {
        // Given: Perform multiple moves
        
        // When: Execute sequence of moves
        let result1 = sut.performMove(from: 1)
        XCTAssertNotNil(result1)
            
        let result2 = sut.performMove(from: 8)
        XCTAssertNotNil(result2)
            
        let result3 = sut.performMove(from: 2)
        XCTAssertNotNil(result3)
        XCTAssertNotNil(result3)
        
        // Then: Game state should be consistent
        // Total stones should remain 98
        var totalStones = 0
        for pit in sut.currentBoard.pits {
            totalStones += pit.stoneCount
        }
        XCTAssertEqual(totalStones, 98, "Total stones should remain constant")
    }
    
    func testStoneConservation() {
        // Given: Any game state
        
        // When: Perform random moves
        if sut.canSelectPit(at: 3) {
            _ = sut.performMove(from: 3)
        }
        
        // Then: Total stones should always be 98
        var totalStones = 0
        for pit in sut.currentBoard.pits {
            totalStones += pit.stoneCount
        }
        XCTAssertEqual(totalStones, 98, "Stones should be conserved")
    }
    
    
        
    func testPerformMoveReturnsNilForInvalidMove() {
        // Given: Invalid pit selection
            
        // When: Try to perform invalid move
        let result = sut.performMove(from: 0) // Store
            
        // Then: Should return nil
        XCTAssertNil(result, "Invalid move should return nil")
    }
        
    func testGameBoardDescription() {
        // Given: Game board
            
        // When: Get description
        let description = sut.currentBoard.description
            
        // Then: Should contain board info
        XCTAssertTrue(
            description.contains("GameBoard"),
            "Description should contain 'GameBoard'"
        )
        XCTAssertTrue(
            description.contains("Player"),
            "Description should contain player info"
        )
    }
        
    func testGameEngineDescription() {
        // Given: Game engine
            
        // When: Get description
        let description = sut.description
            
        // Then: Should contain game info
        XCTAssertTrue(
            description.contains("GameEngine"),
            "Description should contain 'GameEngine'"
        )
        XCTAssertTrue(
            description.contains("Current Player"),
            "Description should contain current player"
        )
        XCTAssertTrue(
            description.contains("Game Ended"),
            "Description should contain game ended status"
        )
    }
        
    func testPitDescription() {
        // Given: A pit
        let pit = sut.currentBoard[1]
            
        // When: Get description
        let description = pit.description
            
        // Then: Should contain pit info
        XCTAssertTrue(
            description.contains("Pit"),
            "Description should contain 'Pit'"
        )
        XCTAssertTrue(
            description.contains("stones"),
            "Description should contain 'stones'"
        )
    }
        
    func testStoreDescription() {
        // Given: A store
        let store = sut.currentBoard[0]
            
        // When: Get description
        let description = store.description
            
        // Then: Should contain store info
        XCTAssertTrue(
            description.contains("Store"),
            "Description should contain 'Store'"
        )
    }
        
    func testPlayerOpponent() {
        // Given: Players
            
        // Then: Opponent should be correct
        XCTAssertEqual(
            Player.one.opponent,
            .two,
            "Player 1's opponent should be Player 2"
        )
        XCTAssertEqual(
            Player.two.opponent,
            .one,
            "Player 2's opponent should be Player 1"
        )
    }
        
    func testPlayerDisplayName() {
        // Given: Players
            
        // Then: Display names should be correct
        XCTAssertEqual(Player.one.displayName, "Player 1")
        XCTAssertEqual(Player.two.displayName, "Player 2")
    }
        
    func testPitIsEmpty() {
        // Given: Empty pit
        sut.currentBoard[1].stoneCount = 0
            
        // Then: Should be empty
        XCTAssertTrue(sut.currentBoard[1].isEmpty, "Pit should be empty")
            
        // Given: Non-empty pit
        sut.currentBoard[2].stoneCount = 5
            
        // Then: Should not be empty
        XCTAssertFalse(sut.currentBoard[2].isEmpty, "Pit should not be empty")
    }
        
    func testIsSideEmptyReturnsFalseWhenPitsHaveStones() {
        // Given: Board with stones
            
        // Then: Both sides should not be empty
        XCTAssertFalse(sut.currentBoard.isSideEmpty(for: .one))
        XCTAssertFalse(sut.currentBoard.isSideEmpty(for: .two))
    }
        
    func testStoreCountReturnsCorrectValue() {
        // Given: Stores with stones
        sut.currentBoard[0].stoneCount = 10
        sut.currentBoard[15].stoneCount = 15
            
        // Then: Store counts should be correct
        XCTAssertEqual(sut.currentBoard.storeCount(for: .one), 10)
        XCTAssertEqual(sut.currentBoard.storeCount(for: .two), 15)
    }
        
    func testPitIndicesForPlayers() {
        // Given: Game board
            
        // Then: Pit indices should be correct
        let player1Indices = sut.currentBoard.pitIndices(for: .one)
        let player2Indices = sut.currentBoard.pitIndices(for: .two)
            
        XCTAssertEqual(
            player1Indices,
            1..<8,
            "Player 1 should have indices 1-7"
        )
        XCTAssertEqual(
            player2Indices,
            8..<15,
            "Player 2 should have indices 8-14"
        )
    }
        
    func testGameBoardSubscript() {
        // Given: Game board
            
        // When: Access via subscript
        let pit = sut.currentBoard[3]
            
        // Then: Should return correct pit
        XCTAssertEqual(pit.stoneCount, 7)
        XCTAssertEqual(pit.owner, .one)
            
        // When: Modify via subscript
        var newPit = pit
        newPit.stoneCount = 10
        sut.currentBoard[3] = newPit
            
        // Then: Should be modified
        XCTAssertEqual(sut.currentBoard[3].stoneCount, 10)
    }
        
    func testCompleteGameScenario() {
        // Given: Play a complete game scenario
        
        // Perform multiple moves
        let result1 = sut.performMove(from: 1)
        XCTAssertNotNil(result1)
        
        // Player 2 turn
        if sut.canSelectPit(at: 8) {
            let result2 = sut.performMove(from: 8)
            XCTAssertNotNil(result2)
        }
        
        // Player 1 turn
        if sut.canSelectPit(at: 2) {
            let result3 = sut.performMove(from: 2)
            XCTAssertNotNil(result3)
        }
        
        // Then: Game state should be valid
        var totalStones = 0
        for pit in sut.currentBoard.pits {
            totalStones += pit.stoneCount
        }
        
        XCTAssertEqual(totalStones, 98, "Stone conservation should hold")
        XCTAssertFalse(sut.checkGameEnd(), "Game should not be ended yet")
    }
        
    func testCaptureWithZeroOppositeStones() {
        // Given: Landing pit empty, opposite pit also empty
        sut.currentBoard[3].stoneCount = 0
        sut.currentBoard[12].stoneCount = 0
        sut.currentBoard[2].stoneCount = 1
            
        // When: Perform move
        let result = sut.performMove(from: 2)
            
        // Then: Should not capture (opposite is empty)
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.captureOccurred ?? true)
    }
        
    func testPlayerAllCases() {
        // Given: Player enum
            
        // Then: Should have 2 cases
        XCTAssertEqual(Player.allCases.count, 2)
        XCTAssertTrue(Player.allCases.contains(.one))
        XCTAssertTrue(Player.allCases.contains(.two))
    }
}
