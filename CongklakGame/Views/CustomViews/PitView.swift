//
//  PitView.swift
//  CongklakGame
//
//  Created by [Your Name] on 29/01/26.
//

import UIKit

/// Custom view representing a single pit on the game board
class PitView: UIView {
    
    // MARK: - Properties
    
    /// Number of stones in this pit
    var stoneCount: Int = 0 {
        didSet {
            updateStoneLabel()
        }
    }
    
    /// Whether this is a store (large pit)
    var isStore: Bool = false {
        didSet {
            setupAppearance()
        }
    }
    
    /// Whether this pit is highlighted (active for selection)
    var isHighlighted: Bool = false {
        didSet {
            updateHighlight()
        }
    }
    
    /// Callback when pit is tapped
    var onTap: (() -> Void)?
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stoneLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = Constants.Colors.text
        label.font = UIFont.boldSystemFont(ofSize: Constants.Sizes.stoneFontSize)
        return label
    }()
    
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
        addSubview(containerView)
        containerView.addSubview(stoneLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stoneLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stoneLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        setupAppearance()
    }
    
    private func setupAppearance() {
        if isStore {
            containerView.backgroundColor = Constants.Colors.store
            containerView.layer.cornerRadius = Constants.Sizes.storeCornerRadius
            stoneLabel.font = UIFont.boldSystemFont(ofSize: Constants.Sizes.storeFontSize)
        } else {
            containerView.backgroundColor = Constants.Colors.pit
            containerView.layer.cornerRadius = Constants.Sizes.cornerRadius
            stoneLabel.font = UIFont.boldSystemFont(ofSize: Constants.Sizes.stoneFontSize)
        }
        
        containerView.layer.borderWidth = 0
        containerView.layer.borderColor = UIColor.clear.cgColor
    }
    
    private func updateStoneLabel() {
        stoneLabel.text = "\(stoneCount)"
    }
    
    private func updateHighlight() {
        if isHighlighted {
            containerView.layer.borderWidth = Constants.Sizes.highlightBorderWidth
            containerView.layer.borderColor = Constants.Colors.highlight.cgColor
            
            // Subtle scale animation
            UIView.animate(withDuration: Constants.Animation.highlightDuration) {
                self.containerView.transform = CGAffineTransform(scaleX: Constants.Animation.highlightScale, y: Constants.Animation.highlightScale)
            }
        } else {
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
            
            UIView.animate(withDuration: Constants.Animation.highlightDuration) {
                self.containerView.transform = .identity
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        // Tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: Constants.Animation.tapScale, y: Constants.Animation.tapScale)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        onTap?()
    }
    
    // MARK: - Public Methods
    
    /// Configure the pit view
    func configure(stones: Int, isStore: Bool, highlighted: Bool) {
        self.stoneCount = stones
        self.isStore = isStore
        self.isHighlighted = highlighted
    }
    
    /// Animate stone count change
    func animateStoneChange(from oldValue: Int, to newValue: Int) {
        // Fade out old value
        UIView.animate(withDuration: 0.15, animations: {
            self.stoneLabel.alpha = 0
        }) { _ in
            // Update value
            self.stoneCount = newValue
            
            // Fade in new value
            UIView.animate(withDuration: 0.15) {
                self.stoneLabel.alpha = 1
            }
        }
    }
}
