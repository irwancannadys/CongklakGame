# 🎮 Congklak - Traditional Indonesian Board Game

An interactive iOS application that brings the traditional Indonesian mancala-style board game (Congklak) to iPhone. Built with UIKit, MVVM architecture, and Combine framework.

![iOS](https://img.shields.io/badge/iOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-green)
![Tests](https://img.shields.io/badge/Tests-124%20Passed-success)
![Coverage](https://img.shields.io/badge/Coverage-93%25-brightgreen)

## 📱 Screenshots

<table>
  <tr>
    <td><img src="screenshots/game-start.png" width="200"/></td>
    <td><img src="screenshots/gameplay.png" width="200"/></td>
    <td><img src="screenshots/game-end.png" width="200"/></td>
  </tr>
  <tr>
    <td align="center">Game Start</td>
    <td align="center">Gameplay</td>
    <td align="center">Game End</td>
  </tr>
</table>

## 🎯 Game Rules Summary

Congklak is a traditional Indonesian two-player board game played on a board with 16 pits.

### Board Setup
- **16 pits**: 7 small pits per player + 1 store per player
- **Starting stones**: Each small pit starts with 7 stones (98 total)

### Objective
Collect the most stones in your store to win.

### How to Play

1. **Taking a Turn**
   - Select one of your pits that contains stones
   - Pick up all stones from that pit
   - Distribute stones counter-clockwise, one per pit

2. **Distribution Rules**
   - Place stones in your own pits and your store
   - **Skip opponent's store** (never place stones there)
   - Continue until all stones are distributed

3. **Extra Turn Rule** ⭐
   - If your last stone lands in **your own store**
   - You get an **extra turn**
   - Continue playing without switching players

4. **Capture Rule** 🎯
   - If your last stone lands in an **empty pit on your side**
   - AND the **opposite opponent's pit has stones**
   - Capture both your stone and all opponent's stones from opposite pit
   - All captured stones go to **your store**

5. **Game End**
   - Game ends when **all pits on one side are empty**
   - Remaining stones on the other side go to that player's store
   - **Player with most stones in store wins!**

### Example Turn

```
Initial:
Player 2: [0] ← [7] [7] [7] [7] [7] [7] [7]
Player 1: [7] [7] [7] [7] [7] [7] [7] → [0]

Player 1 selects pit with 7 stones:
Distributes to next 7 pits counter-clockwise

Result:
Player 2: [0] ← [8] [7] [7] [7] [7] [7] [7]
Player 1: [0] [8] [8] [8] [8] [8] [8] → [0]

Turn switches to Player 2
```

## 🏗️ Architecture Explanation

### MVVM Pattern

This project implements the **Model-View-ViewModel (MVVM)** architecture with Combine framework for reactive data binding.

```
┌──────────────────────────────────────────┐
│              View Layer                   │
│  ┌────────────────────────────────────┐  │
│  │     GameViewController              │  │
│  │  - Manages UI lifecycle             │  │
│  │  - Observes ViewModel via Combine   │  │
│  │  - Handles user interactions        │  │
│  └────────────────────────────────────┘  │
│          │                    ▲           │
│          │ Commands           │ Updates   │
│          ▼                    │           │
│  ┌────────────────────────────────────┐  │
│  │  Custom Views                      │  │
│  │  - PitView (individual pit)        │  │
│  │  - GameBoardView (complete board)  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
                │                  ▲
          Commands          @Published State
                ▼                  │
┌──────────────────────────────────────────┐
│           ViewModel Layer                 │
│  ┌────────────────────────────────────┐  │
│  │      GameViewModel                  │  │
│  │  - Business logic coordination      │  │
│  │  - State management (Combine)       │  │
│  │  - @Published properties            │  │
│  │  - Transforms data for UI           │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
                │                  ▲
          Delegates           Returns
                ▼                  │
┌──────────────────────────────────────────┐
│            Service Layer                  │
│  ┌────────────────────────────────────┐  │
│  │        GameEngine                   │  │
│  │  - Pure game logic                  │  │
│  │  - Rule implementation              │  │
│  │  - No UI dependencies               │  │
│  │  - Protocol-based (testable)        │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
                │                  ▲
          Modifies            Reads
                ▼                  │
┌──────────────────────────────────────────┐
│             Model Layer                   │
│  ┌────────────────────────────────────┐  │
│  │  GameBoard │ Pit │ Player          │  │
│  │  - Data structures                  │  │
│  │  - Business entities                │  │
│  │  - Value types (structs/enums)      │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

## 📦 Project Structure

```
CongklakGame/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
│
├── Models/
│   ├── Player.swift              # Player enum with opponent logic
│   ├── Pit.swift                 # Pit struct with validation
│   └── GameBoard.swift           # Board with 16 pits
│
├── Services/
│   └── GameEngine.swift          # Core game logic (93% tested)
│
├── ViewModels/
│   └── GameViewModel.swift       # Presentation logic + Combine
│
├── Views/
│   ├── Controllers/
│   │   └── GameViewController.swift
│   ├── CustomViews/
│   │   ├── PitView.swift         # Individual pit UI
│   │   └── GameBoardView.swift   # Complete board UI
│   └── Base.lproj/
│       └── Main.storyboard
│
├── Utils/
│   └── Constants.swift           # Colors, sizes, animations
│
└── Resources/
    ├── Assets.xcassets
    └── LaunchScreen.storyboard

Tests/
└── GameEngineTests.swift         # 46 unit tests, 93% coverage
```

### Components

- **Models**: `Player`, `Pit`, `GameBoard` - Pure data structures
- **Services**: `GameEngine` - Core game logic (93% test coverage)
- **ViewModels**: `GameViewModel` - State management with Combine
- **Views**: `GameViewController`, `GameBoardView`, `PitView` - UIKit components

### Key Features
- ✅ MVVM architecture with clear separation of concerns
- ✅ Protocol-based design for testability (`GameEngineProtocol`)
- ✅ Reactive state management using Combine framework
- ✅ Sequential stone distribution animations
- ✅ Haptic feedback for enhanced UX

## ⚠️ Known Limitations

1. **Single Device Only** - Pass-and-play mode only, no online multiplayer
2. **No Persistence** - Game state not saved between app launches
3. **Landscape Mode** - Optimized for landscape, portrait not fully supported
4. **No Undo** - Cannot undo moves once made
5. **No AI** - Two human players required
6. **No Accessibility** - VoiceOver and Dynamic Type not implemented
7. **No Audio** - Silent gameplay, no sound effects

### Potential Improvements
- Game state persistence (UserDefaults/Core Data)
- AI opponent with difficulty levels
- Full accessibility support
- Sound effects and background music
- Online multiplayer via Game Center
- Move history and undo functionality

## 🚀 Installation

```bash
# Clone repository
git clone https://github.com/irwancannadys/CongklakGame.git
cd CongklakGame

# Open in Xcode
open CongklakGame.xcodeproj

# Build and run
# Press Cmd + R or click Play button
# Recommended: iPhone 15 simulator in Landscape
```

### Requirements
- macOS 12.0+
- Xcode 14.0+
- iOS 15.0+
- Swift 5.0+

## 📄 License

Created for educational purposes as part of an iOS Engineer.

## 👤 Author

**Irwan Cannadys**
- GitHub: [@irwancannadys](https://github.com/irwancannadys)

---

**Built with ❤️ using Swift and UIKit**
