//
//  GameViewController.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//


import UIKit
import Combine

class GameViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel = GameViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private let boardView: GameBoardView = {
        let view = GameBoardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let currentPlayerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Game", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = Constants.Colors.activePlayer
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Restart", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = Constants.Colors.inactive
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Congklak"
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(currentPlayerLabel)
        view.addSubview(statusLabel)
        view.addSubview(boardView)
        view.addSubview(startButton)
        view.addSubview(restartButton)
        
        // Set delegate
        boardView.delegate = self
        
        // Layout
        NSLayoutConstraint.activate([
            // Current player label
            currentPlayerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            currentPlayerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentPlayerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: currentPlayerLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Board view
            boardView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: Constants.Layout.verticalSpacing),
            boardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            boardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            boardView.heightAnchor.constraint(equalToConstant: 300),
            
            // Start button
            startButton.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: Constants.Layout.verticalSpacing),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            startButton.heightAnchor.constraint(equalToConstant: Constants.Layout.buttonHeight),
            
            // Restart button (same position as start button)
            restartButton.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: Constants.Layout.verticalSpacing),
            restartButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            restartButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            restartButton.heightAnchor.constraint(equalToConstant: Constants.Layout.buttonHeight)
        ])
    }
    
    private func setupBindings() {
        // Observe game board changes
        viewModel.$gameBoard
            .receive(on: DispatchQueue.main)
            .sink { [weak self] board in
                self?.updateBoardUI(board)
            }
            .store(in: &cancellables)
        
        // Observe current player changes
        viewModel.$currentPlayer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] player in
                self?.updateCurrentPlayerUI(player)
            }
            .store(in: &cancellables)
        
        // Observe game status changes
        viewModel.$gameStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateGameStatusUI(status)
            }
            .store(in: &cancellables)
        
        // Observe status message changes
        viewModel.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.statusLabel.text = message
            }
            .store(in: &cancellables)
        
        // Observe animating pit indices
        viewModel.$animatingPitIndices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indices in
                // Animations handled by PitView
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        restartButton.addTarget(self, action: #selector(restartButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    
    private func updateBoardUI(_ board: GameBoard) {
        // Get highlighted pits
        var highlightedIndices: Set<Int> = []
        
        if viewModel.isGameInProgress {
            // Highlight pits that can be selected by current player
            for index in 0..<16 {
                if viewModel.shouldHighlightPit(at: index) {
                    highlightedIndices.insert(index)
                }
            }
        }
        
        boardView.updateBoard(with: board, highlightIndices: highlightedIndices)
    }
    
    private func updateCurrentPlayerUI(_ player: Player) {
        currentPlayerLabel.text = "Current Player: \(player.displayName)"
        
        // Change label color based on player
        switch player {
        case .one:
            currentPlayerLabel.textColor = .systemBlue
        case .two:
            currentPlayerLabel.textColor = .systemRed
        }
    }
    
    private func updateGameStatusUI(_ status: GameStatus) {
        switch status {
        case .notStarted:
            startButton.isHidden = false
            restartButton.isHidden = true
            currentPlayerLabel.text = "Congklak"
            
        case .inProgress:
            startButton.isHidden = true
            restartButton.isHidden = false
            
        case .ended(let winner):
            showGameEndAlert(winner: winner)
        }
    }
    
    // MARK: - Actions
    
    @objc private func startButtonTapped() {
        viewModel.startNewGame()
    }
    
    @objc private func restartButtonTapped() {
        let alert = UIAlertController(
            title: "Restart Game",
            message: "Are you sure you want to restart?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Restart", style: .destructive) { [weak self] _ in
            self?.viewModel.resetGame()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Game End
    
    private func showGameEndAlert(winner: Player?) {
        let title = winner != nil ? "\(winner!.displayName) Wins! 🎉" : "It's a Tie! 🤝"
        
        let player1Score = viewModel.score(for: .one)
        let player2Score = viewModel.score(for: .two)
        
        let message = """
        Final Score:
        Player 1: \(player1Score)
        Player 2: \(player2Score)
        """
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Play Again", style: .default) { [weak self] _ in
            self?.viewModel.resetGame()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - GameBoardViewDelegate

extension GameViewController: GameBoardViewDelegate {
    func didTapPit(at index: Int) {
        viewModel.selectPit(at: index)
    }
}
