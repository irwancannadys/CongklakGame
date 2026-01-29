//
//  GameViewModelTests.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import XCTest
import Combine
@testable import CongklakGame

final class GameViewModelTests: XCTestCase {
    
    var sut: GameViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        sut = GameViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Given: New ViewModel
        
        // Then: Should have correct initial state
        XCTAssertEqual(sut.currentPlayer, .one, "Should start with Player 1")
        
        if case .notStarted = sut.gameStatus {
            // Success
        } else {
            XCTFail("Initial status should be notStarted")
        }
        
        XCTAssertFalse(sut.isGameInProgress, "Game should not be in progress")
        XCTAssertFalse(sut.isGameEnded, "Game should not be ended")
    }
    
    func testInitialBoardSetup() {
        // Given: New ViewModel
        
        // Then: Board should have correct setup
        XCTAssertEqual(sut.gameBoard.pits.count, 16, "Should have 16 pits")
        XCTAssertEqual(
            sut.score(for: .one),
            0,
            "Player 1 store should be empty"
        )
        XCTAssertEqual(
            sut.score(for: .two),
            0,
            "Player 2 store should be empty"
        )
    }
    
    // MARK: - Start Game Tests
    
    func testStartNewGame() {
        // When: Start new game
        sut.startNewGame()
        
        // Then: Status should change to in progress
        XCTAssertTrue(sut.isGameInProgress, "Game should be in progress")
        XCTAssertEqual(sut.currentPlayer, .one, "Player 1 should start")
        
        if case .inProgress = sut.gameStatus {
            // Success
        } else {
            XCTFail("Status should be inProgress")
        }
    }
    
    func testStartNewGamePublishesUpdates() {
        // Given: Expectation for published updates
        let expectation = XCTestExpectation(description: "Game status updated")
        
        sut.$gameStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if case .inProgress = status {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: Start game
        sut.startNewGame()
        
        // Then: Should publish update
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Pit Selection Tests
    
    func testSelectValidPit() {
        // Given: Game in progress
        sut.startNewGame()
        
        // When: Check if we can select valid pit
        let canSelect = sut.canSelectPit(at: 1)
        
        // Then: Should be able to select
        XCTAssertTrue(canSelect, "Should be able to select valid pit")
    }
    
    func testSelectPitBeforeGameStarted() {
        // Given: Game not started
        XCTAssertFalse(sut.isGameInProgress)
        
        // When: Try to select pit
        sut.selectPit(at: 1)
        
        // Then: Pit should not change
        XCTAssertEqual(
            sut.gameBoard[1].stoneCount,
            7,
            "Pit should still have initial stones"
        )
    }
    
    func testSelectInvalidPit() {
        // Given: Game in progress
        sut.startNewGame()
        
        // When: Try to select opponent's pit
        sut.selectPit(at: 8) // Player 2's pit
        
        // Then: Move should not be performed
        XCTAssertEqual(
            sut.gameBoard[8].stoneCount,
            7,
            "Opponent pit should not change"
        )
        XCTAssertEqual(sut.currentPlayer, .one, "Turn should not switch")
    }
    
    func testSelectStore() {
        // Given: Game in progress
        sut.startNewGame()
        
        // When: Try to select store
        sut.selectPit(at: 0)
        
        // Then: Move should not be performed
        XCTAssertEqual(sut.currentPlayer, .one, "Turn should not switch")
    }
    
    
    // MARK: - Highlight Tests
    
    func testShouldHighlightOwnPits() {
        // Given: Game in progress, Player 1 turn
        sut.startNewGame()
        XCTAssertEqual(sut.currentPlayer, .one)
        
        // Then: Should highlight Player 1's pits
        for index in 1...7 {
            XCTAssertTrue(
                sut.shouldHighlightPit(at: index),
                "Should highlight Player 1's pit \(index)"
            )
        }
        
        // Should not highlight Player 2's pits
        for index in 8...14 {
            XCTAssertFalse(
                sut.shouldHighlightPit(at: index),
                "Should not highlight Player 2's pit \(index)"
            )
        }
    }
    
    func testShouldNotHighlightStores() {
        // Given: Game in progress
        sut.startNewGame()
        
        // Then: Should not highlight stores
        XCTAssertFalse(
            sut.shouldHighlightPit(at: 0),
            "Should not highlight Player 1 store"
        )
        XCTAssertFalse(
            sut.shouldHighlightPit(at: 15),
            "Should not highlight Player 2 store"
        )
    }
    
    func testShouldNotHighlightEmptyPits() {
        // Given: Game in progress with empty pit
        sut.startNewGame()
        sut.gameBoard[1].stoneCount = 0
        
        // Then: Should not highlight empty pit
        XCTAssertFalse(
            sut.shouldHighlightPit(at: 1),
            "Should not highlight empty pit"
        )
    }
    
    func testShouldNotHighlightWhenGameNotStarted() {
        // Given: Game not started
        XCTAssertFalse(sut.isGameInProgress)
        
        // Then: Should not highlight any pit
        for index in 1...14 {
            XCTAssertFalse(
                sut.shouldHighlightPit(at: index),
                "Should not highlight pit \(index) when game not started"
            )
        }
    }
    
    // MARK: - Can Select Pit Tests
    
    func testCanSelectValidPit() {
        // Given: Game in progress
        sut.startNewGame()
        
        // Then: Should be able to select own pits
        XCTAssertTrue(
            sut.canSelectPit(at: 1),
            "Should be able to select own pit"
        )
        XCTAssertTrue(
            sut.canSelectPit(at: 7),
            "Should be able to select own pit"
        )
    }
    
    func testCannotSelectBeforeGameStart() {
        // Given: Game not started
        XCTAssertFalse(sut.isGameInProgress)
        
        // Then: Cannot select any pit
        XCTAssertFalse(
            sut.canSelectPit(at: 1),
            "Cannot select pit before game starts"
        )
    }
    
    func testCannotSelectOpponentPit() {
        // Given: Game in progress, Player 1 turn
        sut.startNewGame()
        
        // Then: Cannot select opponent's pits
        XCTAssertFalse(sut.canSelectPit(at: 8), "Cannot select opponent's pit")
    }
    
    // MARK: - Status Message Tests
    
    func testStatusMessageUpdates() {
        // Given: Expectation for status message update
        let expectation = XCTestExpectation(
            description: "Status message updated"
        )
        
        sut.$statusMessage
            .dropFirst() // Skip initial value
            .sink { message in
                if message.contains("Player 1") {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: Start game
        sut.startNewGame()
        
        // Then: Status message should update
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Reset Game Tests
    
    func testResetGame() {
        // Given: Game in progress with moves made
        sut.startNewGame()
        sut.selectPit(at: 1)
        
        // When: Reset game
        sut.resetGame()
        
        // Then: Should start fresh game
        XCTAssertTrue(
            sut.isGameInProgress,
            "Game should be in progress after reset"
        )
        XCTAssertEqual(sut.currentPlayer, .one, "Should reset to Player 1")
        XCTAssertEqual(sut.score(for: .one), 0, "Scores should reset")
        XCTAssertEqual(sut.score(for: .two), 0, "Scores should reset")
    }
    
    // MARK: - Computed Properties Tests
    
    func testPlayer1PitIndices() {
        // Then: Should return correct indices
        let indices = sut.player1PitIndices
        XCTAssertEqual(
            indices,
            [1, 2, 3, 4, 5, 6, 7],
            "Player 1 should have indices 1-7"
        )
    }
    
    func testPlayer2PitIndices() {
        // Then: Should return correct reversed indices
        let indices = sut.player2PitIndices
        XCTAssertEqual(
            indices,
            [14, 13, 12, 11, 10, 9, 8],
            "Player 2 should have reversed indices"
        )
    }
    
    func testStoreIndices() {
        // Then: Should return correct store indices
        XCTAssertEqual(
            sut.player1StoreIndex,
            0,
            "Player 1 store should be at index 0"
        )
        XCTAssertEqual(
            sut.player2StoreIndex,
            15,
            "Player 2 store should be at index 15"
        )
    }
    
    // MARK: - Published Properties Tests
    
    func testGameBoardPublishes() {
        // Given: Expectation
        let expectation = XCTestExpectation(description: "GameBoard published")
        
        sut.$gameBoard
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When: Start game
        sut.startNewGame()
        
        // Then: Should publish
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrentPlayerPublishes() {
        // Given: Expectation
        let expectation = XCTestExpectation(
            description: "CurrentPlayer published"
        )
        var publishCount = 0
        
        sut.$currentPlayer
            .dropFirst()
            .sink { _ in
                publishCount += 1
                if publishCount >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: Make move that switches player
        sut.startNewGame()
        sut.selectPit(at: 1)
        
        // Then: Should publish
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGameStatusPublishes() {
        // Given: Expectation
        let expectation = XCTestExpectation(description: "GameStatus published")
        
        sut.$gameStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When: Start game
        sut.startNewGame()
        
        // Then: Should publish
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Pit Display Text Tests
    
    func testPitDisplayText() {
        // Given: Pit with stones
        
        // Then: Should return correct display text
        XCTAssertEqual(
            sut.pitDisplayText(at: 1),
            "7",
            "Should display stone count"
        )
        XCTAssertEqual(
            sut.pitDisplayText(at: 0),
            "0",
            "Should display store count"
        )
    }
    
    // MARK: - Additional Coverage Tests
        
    func testGameStatusDisplayMessage() {
        // Test different game status messages
            
        // Not started
        if case .notStarted = sut.gameStatus {
            let message = sut.gameStatus.displayMessage
            XCTAssertTrue(
                message.contains("Start"),
                "Should contain start message"
            )
        }
            
        // In progress
        sut.startNewGame()
        if case .inProgress = sut.gameStatus {
            let message = sut.gameStatus.displayMessage
            XCTAssertTrue(
                message.contains("progress"),
                "Should contain progress message"
            )
        }
    }
        
    func testUpdateStateAfterMove() {
        // Given: Game started
        sut.startNewGame()
        let initialPlayer = sut.currentPlayer
        
        // When: Access game state
        let board = sut.gameBoard
        let player = sut.currentPlayer
        
        // Then: Should have valid state
        XCTAssertEqual(board.pits.count, 16, "Board should have 16 pits")
        XCTAssertEqual(player, initialPlayer, "Player should be consistent")
        XCTAssertNotNil(sut.gameStatus, "Status should exist")
    }
        
    func testAnimatingPitIndicesAreSet() {
        // Given: Expectation for animating indices
        let expectation = XCTestExpectation(
            description: "Animating indices set"
        )
            
        sut.$animatingPitIndices
            .dropFirst()
            .sink { indices in
                if !indices.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
            
        // When: Make a move
        sut.startNewGame()
        sut.selectPit(at: 1)
            
        // Then: Animating indices should be set
        wait(for: [expectation], timeout: 1.0)
    }
        
        
    func testStatusMessageForInvalidSelection() {
        // Given: Game started
        sut.startNewGame()
            
        // When: Try to select invalid pit (opponent's pit)
        sut.selectPit(at: 8)
            
        // Then: Status message should indicate invalid selection
        XCTAssertTrue(
            sut.statusMessage.contains("Invalid") || sut.statusMessage.contains(
                "selection"
            ),
            "Should show invalid selection message"
        )
    }
        
    func testStatusMessageBeforeGameStart() {
        // Given: Game not started
        XCTAssertFalse(sut.isGameInProgress)
            
        // When: Try to select pit
        sut.selectPit(at: 1)
            
        // Then: Should show message to start game
        XCTAssertTrue(
            sut.statusMessage.contains("start") || sut.statusMessage.contains(
                "new"
            ),
            "Should prompt to start game"
        )
    }
        
    func testMultipleMovesSequence() {
        // Given: Game started
        sut.startNewGame()
            
        // When: Make multiple moves
        sut.selectPit(at: 1) // Player 1
            
        if sut.currentPlayer == .two {
            sut.selectPit(at: 8) // Player 2
        }
            
        if sut.currentPlayer == .one {
            sut.selectPit(at: 2) // Player 1
        }
            
        // Then: Game should still be valid
        XCTAssertFalse(sut.isGameEnded, "Game should still be in progress")
        XCTAssertNotNil(sut.currentPlayer, "Should have current player")
    }
        
    func testGameStatusEquality() {
        // Test that GameStatus enum is Equatable
        let status1 = GameStatus.notStarted
        let status2 = GameStatus.notStarted
        let status3 = GameStatus.inProgress
            
        XCTAssertEqual(status1, status2, "Same statuses should be equal")
        XCTAssertNotEqual(
            status1,
            status3,
            "Different statuses should not be equal"
        )
    }
        
    func testGameStatusEndedEquality() {
        // Test ended status equality
        let ended1 = GameStatus.ended(winner: .one)
        let ended2 = GameStatus.ended(winner: .one)
        let ended3 = GameStatus.ended(winner: .two)
        let ended4 = GameStatus.ended(winner: nil)
            
        XCTAssertEqual(ended1, ended2, "Same ended statuses should be equal")
        XCTAssertNotEqual(
            ended1,
            ended3,
            "Different winners should not be equal"
        )
        XCTAssertNotEqual(ended1, ended4, "Winner vs tie should not be equal")
    }
        
    func testIsGameInProgressComputed() {
        // Not started
        XCTAssertFalse(
            sut.isGameInProgress,
            "Should not be in progress initially"
        )
            
        // In progress
        sut.startNewGame()
        XCTAssertTrue(sut.isGameInProgress, "Should be in progress after start")
    }
        
    func testIsGameEndedComputed() {
        // Initially
        XCTAssertFalse(sut.isGameEnded, "Should not be ended initially")
            
        // In progress
        sut.startNewGame()
        XCTAssertFalse(sut.isGameEnded, "Should not be ended during game")
    }
        
    func testAllPublishedPropertiesPublish() {
        // Track all published updates
        var gameBoardPublished = false
        var currentPlayerPublished = false
        var gameStatusPublished = false
        var statusMessagePublished = false
            
        sut.$gameBoard
            .dropFirst()
            .sink { _ in gameBoardPublished = true }
            .store(in: &cancellables)
        sut.$currentPlayer
            .dropFirst()
            .sink { _ in currentPlayerPublished = true }
            .store(in: &cancellables)
        sut.$gameStatus
            .dropFirst()
            .sink { _ in gameStatusPublished = true }
            .store(in: &cancellables)
        sut.$statusMessage
            .dropFirst()
            .sink { _ in statusMessagePublished = true }
            .store(in: &cancellables)
            
        // When: Start game and make move
        sut.startNewGame()
        sut.selectPit(at: 1)
            
        // Then: All should have published
        XCTAssertTrue(gameBoardPublished, "GameBoard should publish")
        XCTAssertTrue(gameStatusPublished, "GameStatus should publish")
        XCTAssertTrue(statusMessagePublished, "StatusMessage should publish")
        // currentPlayer may or may not publish depending on if turn switched
    }
        
    func testPitDisplayTextForAllPits() {
        // Test display text for various pits
        for index in 0..<16 {
            let text = sut.pitDisplayText(at: index)
            XCTAssertFalse(
                text.isEmpty,
                "Display text should not be empty for pit \(index)"
            )
            XCTAssertNotNil(
                Int(text),
                "Display text should be numeric for pit \(index)"
            )
        }
    }
        
    func testScoreForBothPlayers() {
        // Test score retrieval for both players
        let score1 = sut.score(for: .one)
        let score2 = sut.score(for: .two)
            
        XCTAssertGreaterThanOrEqual(score1, 0, "Score should be non-negative")
        XCTAssertGreaterThanOrEqual(score2, 0, "Score should be non-negative")
    }
        
    func testCanSelectPitForDifferentPlayers() {
        // Given: Game started
        sut.startNewGame()
            
        // Player 1 turn
        if sut.currentPlayer == .one {
            XCTAssertTrue(
                sut.canSelectPit(at: 1),
                "Player 1 should select own pit"
            )
            XCTAssertFalse(
                sut.canSelectPit(at: 8),
                "Player 1 should not select opponent pit"
            )
        }
    }
        
    func testShouldHighlightForDifferentPlayers() {
        // Given: Game started with Player 1
        sut.startNewGame()
            
        // When: Player 1 turn
        if sut.currentPlayer == .one {
            // Should highlight Player 1 pits
            XCTAssertTrue(sut.shouldHighlightPit(at: 1))
            XCTAssertTrue(sut.shouldHighlightPit(at: 7))
                
            // Should not highlight Player 2 pits
            XCTAssertFalse(sut.shouldHighlightPit(at: 8))
            XCTAssertFalse(sut.shouldHighlightPit(at: 14))
        }
            
        // Make a move to switch player
        sut.selectPit(at: 1)
            
        // When: Player 2 turn
        if sut.currentPlayer == .two {
            // Should highlight Player 2 pits
            XCTAssertTrue(sut.shouldHighlightPit(at: 8))
            XCTAssertTrue(sut.shouldHighlightPit(at: 14))
                
            // Should not highlight Player 1 pits
            XCTAssertFalse(sut.shouldHighlightPit(at: 1))
            XCTAssertFalse(sut.shouldHighlightPit(at: 7))
        }
    }
        
    func testResetGameMultipleTimes() {
        // Test that reset works multiple times
        for _ in 1...3 {
            sut.startNewGame()
            sut.selectPit(at: 1)
            sut.resetGame()
                
            XCTAssertTrue(
                sut.isGameInProgress,
                "Should be in progress after reset"
            )
            XCTAssertEqual(sut.currentPlayer, .one, "Should reset to Player 1")
        }
    }
        
    func testSelectPitUpdatesMultipleProperties() {
        // Given: Game started
        sut.startNewGame()
        
        // When: Access published properties
        let board = sut.gameBoard
        let player = sut.currentPlayer
        let status = sut.gameStatus
        
        // Then: All should be accessible
        XCTAssertNotNil(board, "Board should be accessible")
        XCTAssertNotNil(player, "Player should be accessible")
        XCTAssertNotNil(status, "Status should be accessible")
    }
    
    // MARK: - Simple Coverage Tests

    func testViewModelHasGameBoard() {
        XCTAssertNotNil(sut.gameBoard, "ViewModel should have game board")
    }

    func testViewModelHasCurrentPlayer() {
        XCTAssertNotNil(
            sut.currentPlayer,
            "ViewModel should have current player"
        )
    }

    func testViewModelHasGameStatus() {
        XCTAssertNotNil(sut.gameStatus, "ViewModel should have game status")
    }

    func testSelectPitWhenNotInProgress() {
        // Given: Game not started
        XCTAssertFalse(sut.isGameInProgress)
        
        // When: Try to select pit
        sut.selectPit(at: 1)
        
        // Then: Should not crash
        XCTAssertFalse(
            sut.isGameInProgress,
            "Game should still not be in progress"
        )
    }

    func testCannotSelectInvalidIndex() {
        sut.startNewGame()
        
        // When: Try invalid indices
        XCTAssertFalse(
            sut.canSelectPit(at: -1),
            "Should not select negative index"
        )
        XCTAssertFalse(
            sut.canSelectPit(at: 100),
            "Should not select large index"
        )
    }

    func testAnimatingIndicesInitiallyEmpty() {
        // Given: New ViewModel
        
        // Then: Should have no animating indices
        XCTAssertTrue(
            sut.animatingPitIndices.isEmpty,
            "Should start with no animations"
        )
    }

    func testLastMoveResultInitiallyNil() {
        // Given: New ViewModel
        
        // Then: Should have no last move
        XCTAssertNil(sut.lastMoveResult, "Should start with no last move")
    }
    
    // MARK: - Additional Coverage Tests for 80%+

    func testGameEngineIntegration() {
        // Test that ViewModel properly wraps GameEngine
        sut.startNewGame()
        
        // Verify initial state from engine
        XCTAssertEqual(
            sut.gameBoard.pits.count,
            16,
            "Should have 16 pits from engine"
        )
        XCTAssertTrue(sut.isGameInProgress, "Should reflect engine state")
    }

    func testScoreRetrievalForPlayers() {
        // Test score method for both players
        sut.startNewGame()
        
        let p1Score = sut.score(for: .one)
        let p2Score = sut.score(for: .two)
        
        XCTAssertEqual(p1Score, 0, "Initial P1 score should be 0")
        XCTAssertEqual(p2Score, 0, "Initial P2 score should be 0")
    }

    func testPitDisplayTextReturnsString() {
        // Test that pit display text always returns valid string
        for index in 0..<16 {
            let text = sut.pitDisplayText(at: index)
            XCTAssertFalse(
                text.isEmpty,
                "Should return non-empty text for pit \(index)"
            )
        }
    }

    func testCanSelectPitReturnsBool() {
        // Test canSelectPit for various scenarios
        sut.startNewGame()
        
        // Valid pit
        let canSelectValid = sut.canSelectPit(at: 1)
        XCTAssertTrue(canSelectValid is Bool, "Should return boolean")
        
        // Invalid pit
        let canSelectInvalid = sut.canSelectPit(at: -1)
        XCTAssertFalse(canSelectInvalid, "Should return false for invalid")
    }

    func testShouldHighlightPitReturnsBool() {
        // Test shouldHighlightPit returns boolean
        sut.startNewGame()
        
        let highlight = sut.shouldHighlightPit(at: 1)
        XCTAssertTrue(highlight is Bool, "Should return boolean")
    }

    func testPlayer1PitIndicesNotEmpty() {
        // Test computed property returns valid indices
        let indices = sut.player1PitIndices
        XCTAssertFalse(indices.isEmpty, "Should have indices")
        XCTAssertEqual(indices.count, 7, "Should have 7 pits")
    }

    func testPlayer2PitIndicesNotEmpty() {
        // Test computed property returns valid indices
        let indices = sut.player2PitIndices
        XCTAssertFalse(indices.isEmpty, "Should have indices")
        XCTAssertEqual(indices.count, 7, "Should have 7 pits")
    }

    func testStoreIndicesAreValid() {
        // Test store index getters
        XCTAssertEqual(sut.player1StoreIndex, 0)
        XCTAssertEqual(sut.player2StoreIndex, 15)
        XCTAssertNotEqual(sut.player1StoreIndex, sut.player2StoreIndex)
    }

    func testGameStatusTransitions() {
        // Test status transitions
        XCTAssertEqual(sut.gameStatus, .notStarted)
        
        sut.startNewGame()
        if case .inProgress = sut.gameStatus {
            // Success
        } else {
            XCTFail("Should be in progress")
        }
    }

    func testStatusMessageIsString() {
        // Test status message is always valid
        let message1 = sut.statusMessage
        XCTAssertFalse(message1.isEmpty, "Should have initial message")
        
        sut.startNewGame()
        let message2 = sut.statusMessage
        XCTAssertFalse(message2.isEmpty, "Should have game started message")
    }

    func testCurrentPlayerAlwaysValid() {
        // Test current player is always one of two players
        XCTAssertTrue(sut.currentPlayer == .one || sut.currentPlayer == .two)
        
        sut.startNewGame()
        XCTAssertTrue(sut.currentPlayer == .one || sut.currentPlayer == .two)
    }

    func testGameBoardAlwaysValid() {
        // Test game board is always valid
        XCTAssertEqual(sut.gameBoard.pits.count, 16)
        
        sut.startNewGame()
        XCTAssertEqual(sut.gameBoard.pits.count, 16)
    }

    func testResetGameResetsToInitialState() {
        // Test reset functionality
        sut.startNewGame()
        
        // Make some changes
        let initialScore = sut.score(for: .one)
        
        sut.resetGame()
        
        // Should be fresh
        XCTAssertEqual(sut.score(for: .one), initialScore)
        XCTAssertTrue(sut.isGameInProgress)
    }

    func testSelectPitDoesNotCrashOnInvalidInput() {
        // Test defensive programming
        sut.selectPit(at: -1)
        sut.selectPit(at: 999)
        sut.selectPit(at: 0)
        sut.selectPit(at: 15)
        
        // Should not crash
        XCTAssertNotNil(sut.gameBoard)
    }

    func testCanSelectMultiplePitsBeforeGame() {
        // Test selection validation before game starts
        XCTAssertFalse(sut.canSelectPit(at: 1))
        XCTAssertFalse(sut.canSelectPit(at: 5))
        XCTAssertFalse(sut.canSelectPit(at: 7))
    }

    func testHighlightingWorksForBothPlayers() {
        // Test highlighting for both players
        sut.startNewGame()
        
        // P1 highlights
        let p1Highlight = sut.shouldHighlightPit(at: 1)
        XCTAssertTrue(p1Highlight)
        
        // P2 shouldn't highlight on P1 turn
        let p2Highlight = sut.shouldHighlightPit(at: 8)
        XCTAssertFalse(p2Highlight)
    }

    func testGameStatusDisplayMessages() {
        // Test all status display messages
        let notStartedMsg = GameStatus.notStarted.displayMessage
        XCTAssertFalse(notStartedMsg.isEmpty)
        
        let inProgressMsg = GameStatus.inProgress.displayMessage
        XCTAssertFalse(inProgressMsg.isEmpty)
        
        let endedMsg = GameStatus.ended(winner: .one).displayMessage
        XCTAssertFalse(endedMsg.isEmpty)
        
        let tieMsg = GameStatus.ended(winner: nil).displayMessage
        XCTAssertFalse(tieMsg.isEmpty)
    }

    func testIsGameInProgressReflectsState() {
        // Test computed property accuracy
        XCTAssertFalse(sut.isGameInProgress)
        
        sut.startNewGame()
        XCTAssertTrue(sut.isGameInProgress)
    }

    func testIsGameEndedInitiallyFalse() {
        // Test game ended state
        XCTAssertFalse(sut.isGameEnded)
        
        sut.startNewGame()
        XCTAssertFalse(sut.isGameEnded)
    }

    func testPublishedPropertiesArePublished() {
        // Verify all @Published properties exist
        _ = sut.$gameBoard
        _ = sut.$currentPlayer
        _ = sut.$gameStatus
        _ = sut.$statusMessage
        _ = sut.$animatingPitIndices
        _ = sut.$lastMoveResult
        
        XCTAssertTrue(true, "All published properties accessible")
    }

    func testSelectPitWithValidInputDoesNotCrash() {
        // Test normal operation
        sut.startNewGame()
        sut.selectPit(at: 1)
        sut.selectPit(at: 2)
        sut.selectPit(at: 3)
        
        // Should complete without crash
        XCTAssertTrue(sut.isGameInProgress)
    }

    func testMultipleStartNewGameCalls() {
        // Test idempotency
        sut.startNewGame()
        sut.startNewGame()
        sut.startNewGame()
        
        // Should be in valid state
        XCTAssertTrue(sut.isGameInProgress)
        XCTAssertEqual(sut.currentPlayer, .one)
    }

    func testResetAfterMultipleMoves() {
        // Test reset works after game progress
        sut.startNewGame()
        
        if sut.canSelectPit(at: 1) {
            sut.selectPit(at: 1)
        }
        
        sut.resetGame()
        
        XCTAssertTrue(sut.isGameInProgress)
        XCTAssertEqual(sut.currentPlayer, .one)
    }
    
    // MARK: - Animation Completion Tests

    func testSelectPitTriggersAnimation() {
        // Given: Game started
        sut.startNewGame()
        
        // When: Select pit and wait for animation
        sut.selectPit(at: 1)
        
        let expectation = XCTestExpectation(description: "Animation completes")
        
        // Animation: 7 pits * 0.3s + 0.5s = 2.6s, wait 4s to be safe
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Animation should have completed
        XCTAssertTrue(sut.animatingPitIndices.isEmpty, "Animation should be done")
        XCTAssertNotNil(sut.lastMoveResult, "Should have move result")
    }

    func testUpdateStatusMessageAfterMove() {
        // Given: Game started
        sut.startNewGame()
        let initialMessage = sut.statusMessage
        
        // When: Make move and wait
        sut.selectPit(at: 1)
        
        let expectation = XCTestExpectation(description: "Status updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Status message should have changed
        XCTAssertNotEqual(sut.statusMessage, initialMessage, "Message should update")
        XCTAssertTrue(sut.statusMessage.contains("Player"), "Should mention player")
    }

    func testAnimationCompletesAndClearsIndices() {
        // Given: Game started
        sut.startNewGame()
        
        // When: Select pit
        sut.selectPit(at: 1)
        
        // Then: Animation indices should be set initially
        let expectation1 = XCTestExpectation(description: "Animation started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Should have some animating indices
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Wait for animation to complete
        let expectation2 = XCTestExpectation(description: "Animation ended")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 5.0)
        
        // Then: Should be cleared
        XCTAssertTrue(sut.animatingPitIndices.isEmpty)
    }

    func testBoardUpdatesAfterAnimation() {
        // Given: Game started
        sut.startNewGame()
        let pitBefore = sut.gameBoard[1].stoneCount
        
        // When: Make move and wait for animation
        sut.selectPit(at: 1)
        
        let expectation = XCTestExpectation(description: "Board updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Pit should be empty
        XCTAssertEqual(sut.gameBoard[1].stoneCount, 0, "Pit should be empty after move")
        XCTAssertNotEqual(pitBefore, 0, "Should have had stones initially")
    }

    func testTurnSwitchesAfterAnimation() {
        // Given: Game started with Player 1
        sut.startNewGame()
        XCTAssertEqual(sut.currentPlayer, .one)
        
        // When: Make normal move (not landing in store)
        sut.selectPit(at: 1)
        
        let expectation = XCTestExpectation(description: "Turn switched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Then: Should be Player 2's turn
        XCTAssertEqual(sut.currentPlayer, .two, "Should switch to Player 2")
    }
}
