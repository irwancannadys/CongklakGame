//
//  Constants.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import UIKit

/// Global constants for the app
enum Constants {
    
    // MARK: - Colors
    enum Colors {
        /// Background color for the game board
        static let background = UIColor(red: 0.96, green: 0.90, blue: 0.83, alpha: 1.0) // #F5E6D3
        
        /// Color for small pits
        static let pit = UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0) // #8B4513
        
        /// Color for stores (large pits)
        static let store = UIColor(red: 0.40, green: 0.26, blue: 0.13, alpha: 1.0) // #654321
        
        /// Highlight color for active pits
        static let highlight = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // #FFD700
        
        /// Text color for stone count
        static let text = UIColor.white
        
        /// Color for current player indicator
        static let activePlayer = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0) // #4CAF50
        
        /// Disabled/inactive color
        static let inactive = UIColor.lightGray
    }
    
    // MARK: - Sizes
    enum Sizes {
        /// Width and height for small pits
        static let pitSize: CGFloat = 60
        
        /// Width for stores
        static let storeWidth: CGFloat = 70
        
        /// Height for stores
        static let storeHeight: CGFloat = 200
        
        /// Spacing between pits
        static let spacing: CGFloat = 8
        
        /// Corner radius for pits
        static let cornerRadius: CGFloat = 30
        
        /// Corner radius for stores
        static let storeCornerRadius: CGFloat = 15
        
        /// Border width for highlighted pits
        static let highlightBorderWidth: CGFloat = 3
        
        /// Font size for stone count
        static let stoneFontSize: CGFloat = 20
        
        /// Font size for store count
        static let storeFontSize: CGFloat = 24
    }
    
    // MARK: - Animation
    enum Animation {
        /// Duration for most animations
        static let defaultDuration: TimeInterval = 0.3
        
        /// Duration for highlight pulse
        static let highlightDuration: TimeInterval = 0.2
        
        /// Scale transform for tap animation
        static let tapScale: CGFloat = 0.95
        
        /// Scale transform for highlight
        static let highlightScale: CGFloat = 1.05
    }
    
    // MARK: - Layout
    enum Layout {
        /// Padding around the board
        static let boardPadding: CGFloat = 16
        
        /// Spacing between board and controls
        static let verticalSpacing: CGFloat = 20
        
        /// Height for status label
        static let statusLabelHeight: CGFloat = 60
        
        /// Height for buttons
        static let buttonHeight: CGFloat = 50
    }
}
