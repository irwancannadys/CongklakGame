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
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13) // Smaller
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
        setupAnimationObservers()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Congklak"
        view.backgroundColor = .white
        
        // Score labels
        let player1ScoreLabel = UILabel()
        player1ScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        player1ScoreLabel.textAlignment = .left
        player1ScoreLabel.font = UIFont.boldSystemFont(ofSize: 16)
        player1ScoreLabel.textColor = .systemBlue
        player1ScoreLabel.text = "P1: 0"
        
        let player2ScoreLabel = UILabel()
        player2ScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        player2ScoreLabel.textAlignment = .left
        player2ScoreLabel.font = UIFont.boldSystemFont(ofSize: 16)
        player2ScoreLabel.textColor = .systemRed
        player2ScoreLabel.text = "P2: 0"
        
        // Update current player label for center display
        currentPlayerLabel.font = UIFont.boldSystemFont(ofSize: 14)
        currentPlayerLabel.numberOfLines = 2
        
        // Update button styles
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        restartButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        // Add subviews
        view.addSubview(player1ScoreLabel)
        view.addSubview(player2ScoreLabel)
        view.addSubview(boardView)
        view.addSubview(currentPlayerLabel) // Will be on top of board
        view.addSubview(startButton)
        view.addSubview(restartButton)
        
        // Set delegate
        boardView.delegate = self
        
        // Layout
        NSLayoutConstraint.activate([
            // Player 1 score - top left
            player1ScoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            player1ScoreLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            // Player 2 score - below P1
            player2ScoreLabel.topAnchor.constraint(equalTo: player1ScoreLabel.bottomAnchor, constant: 4),
            player2ScoreLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            // Restart button - top right
            restartButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            restartButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            restartButton.widthAnchor.constraint(equalToConstant: 80),
            restartButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Start button (same position)
            startButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            startButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            startButton.widthAnchor.constraint(equalToConstant: 100),
            startButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Board - fills remaining space
            boardView.topAnchor.constraint(equalTo: player2ScoreLabel.bottomAnchor, constant: 12),
            boardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            boardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            boardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            
            // Current player label - CENTERED ON TOP OF BOARD
            currentPlayerLabel.centerXAnchor.constraint(equalTo: boardView.centerXAnchor),
            currentPlayerLabel.centerYAnchor.constraint(equalTo: boardView.centerYAnchor),
            currentPlayerLabel.widthAnchor.constraint(lessThanOrEqualTo: boardView.widthAnchor, multiplier: 0.4)
        ])
        
        // Bind scores
        viewModel.$gameBoard
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                player1ScoreLabel.text = "P1: \(self.viewModel.score(for: .one))"
                player2ScoreLabel.text = "P2: \(self.viewModel.score(for: .two))"
            }
            .store(in: &cancellables)
        
        // Update score label emphasis based on current player
        viewModel.$currentPlayer
            .receive(on: DispatchQueue.main)
            .sink { player in
                player1ScoreLabel.font = player == .one ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 16)
                player2ScoreLabel.font = player == .two ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 16)
            }
            .store(in: &cancellables)
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
                guard let self = self else { return }
                // Animate pits that are currently active
                for index in indices {
                    self.boardView.animatePit(at: index)
                }
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
            guard let self = self else { return }
            self.viewModel.resetGame()
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
    
    private func setupAnimationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePulsePit(_:)),
            name: NSNotification.Name("PulsePit"),
            object: nil
        )
    }

    @objc private func handlePulsePit(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let index = userInfo["index"] as? Int else {
            return
        }
        
        boardView.animatePit(at: index)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - GameBoardViewDelegate

extension GameViewController: GameBoardViewDelegate {
    func didTapPit(at index: Int) {
        viewModel.selectPit(at: index)
    }
}
