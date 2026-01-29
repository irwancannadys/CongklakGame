//
//  GameBoardView.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import UIKit

/// Protocol for handling pit tap events
protocol GameBoardViewDelegate: AnyObject {
    func didTapPit(at index: Int)
}

/// Custom view representing the complete game board
class GameBoardView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: GameBoardViewDelegate?
    
    private var pitViews: [PitView] = []
    
    // MARK: - UI Components
    
    private let boardContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.Colors.background
        view.layer.cornerRadius = 20
        return view
    }()
    
    // Player 2 (top)
    private let player2StackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Constants.Sizes.spacing
        return stack
    }()
    
    // Player 1 (bottom)
    private let player1StackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Constants.Sizes.spacing
        return stack
    }()
    
    // Stores
    private var player1StoreView: PitView!
    private var player2StoreView: PitView!
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(boardContainerView)
        
        // Create 16 pit views
        for index in 0..<16 {
            let pitView = PitView()
            pitView.translatesAutoresizingMaskIntoConstraints = false
            pitView.onTap = { [weak self] in
                self?.delegate?.didTapPit(at: index)
            }
            pitViews.append(pitView)
        }
        
        // Setup stores
        player1StoreView = pitViews[0]
        player1StoreView.isStore = true
        
        player2StoreView = pitViews[15]
        player2StoreView.isStore = true
        
        setupLayout()
    }
    
    private func setupLayout() {
        // Add player 1's small pits to stack (1-7)
        for index in 1...7 {
            player1StackView.addArrangedSubview(pitViews[index])
        }
        
        // Add player 2's small pits to stack (8-14, reversed for display)
        for index in stride(from: 14, through: 8, by: -1) {
            player2StackView.addArrangedSubview(pitViews[index])
        }
        
        // Add stacks and stores to board
        boardContainerView.addSubview(player1StoreView)
        boardContainerView.addSubview(player2StoreView)
        boardContainerView.addSubview(player1StackView)
        boardContainerView.addSubview(player2StackView)
        
        NSLayoutConstraint.activate([
            // Board container
            boardContainerView.topAnchor.constraint(equalTo: topAnchor),
            boardContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            boardContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            boardContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Player 1 Store (left side)
            player1StoreView.leadingAnchor.constraint(equalTo: boardContainerView.leadingAnchor, constant: Constants.Layout.boardPadding),
            player1StoreView.centerYAnchor.constraint(equalTo: boardContainerView.centerYAnchor),
            player1StoreView.widthAnchor.constraint(equalToConstant: Constants.Sizes.storeWidth),
            player1StoreView.heightAnchor.constraint(equalToConstant: Constants.Sizes.storeHeight),
            
            // Player 2 Store (right side)
            player2StoreView.trailingAnchor.constraint(equalTo: boardContainerView.trailingAnchor, constant: -Constants.Layout.boardPadding),
            player2StoreView.centerYAnchor.constraint(equalTo: boardContainerView.centerYAnchor),
            player2StoreView.widthAnchor.constraint(equalToConstant: Constants.Sizes.storeWidth),
            player2StoreView.heightAnchor.constraint(equalToConstant: Constants.Sizes.storeHeight),
            
            // Player 2 Stack (top)
            player2StackView.topAnchor.constraint(equalTo: boardContainerView.topAnchor, constant: Constants.Layout.boardPadding),
            player2StackView.leadingAnchor.constraint(equalTo: player1StoreView.trailingAnchor, constant: Constants.Sizes.spacing),
            player2StackView.trailingAnchor.constraint(equalTo: player2StoreView.leadingAnchor, constant: -Constants.Sizes.spacing),
            player2StackView.heightAnchor.constraint(equalToConstant: Constants.Sizes.pitSize),
            
            // Player 1 Stack (bottom)
            player1StackView.bottomAnchor.constraint(equalTo: boardContainerView.bottomAnchor, constant: -Constants.Layout.boardPadding),
            player1StackView.leadingAnchor.constraint(equalTo: player1StoreView.trailingAnchor, constant: Constants.Sizes.spacing),
            player1StackView.trailingAnchor.constraint(equalTo: player2StoreView.leadingAnchor, constant: -Constants.Sizes.spacing),
            player1StackView.heightAnchor.constraint(equalToConstant: Constants.Sizes.pitSize)
        ])
        
        // Set pit size constraints
        for pitView in pitViews where !pitView.isStore {
            NSLayoutConstraint.activate([
                pitView.widthAnchor.constraint(equalToConstant: Constants.Sizes.pitSize),
                pitView.heightAnchor.constraint(equalToConstant: Constants.Sizes.pitSize)
            ])
        }
    }
    
    // MARK: - Public Methods
    
    /// Update the board with new game state
    func updateBoard(with gameBoard: GameBoard, highlightIndices: Set<Int> = []) {
        for (index, pitView) in pitViews.enumerated() {
            let pit = gameBoard[index]
            let shouldHighlight = highlightIndices.contains(index)
            pitView.configure(stones: pit.stoneCount, isStore: pit.isStore, highlighted: shouldHighlight)
        }
    }
    
    /// Animate stone count change for a specific pit
    func animatePitChange(at index: Int, from oldValue: Int, to newValue: Int) {
        guard index < pitViews.count else { return }
        pitViews[index].animateStoneChange(from: oldValue, to: newValue)
    }
    
    func animatePit(at index: Int) {
        guard index < pitViews.count else { return }
        pitViews[index].pulseAnimation()
    }
    
    /// Update board and trigger animations for changed pits
    func updateBoardAnimated(with gameBoard: GameBoard, changedIndices: [Int]) {
        // Update all pits
        for (index, pitView) in pitViews.enumerated() {
            let pit = gameBoard[index]
            let oldCount = pitView.stoneCount
            let newCount = pit.stoneCount
            
            // If this pit changed and is in the changed indices
            if changedIndices.contains(index) && oldCount != newCount {
                pitView.animateStoneChange(from: oldCount, to: newCount)
            } else {
                pitView.configure(stones: pit.stoneCount, isStore: pit.isStore, highlighted: false)
            }
        }
    }
}
