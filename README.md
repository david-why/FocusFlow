# FocusFlow

_When you focus, <img src="public/coin.png" style="height: 1em"/> flows!_

## Installation

You can [install the app from TestFlight](https://testflight.apple.com/join/sAu8hyE2)! (Note: if the link doesn't work, it's because Apple is still approving my build.)

Alternatively, you can clone the repo, open the project in Xcode, and run it yourself by clicking the "run" button.

## Usage

You can start a focus timer, which will fail if you leave the page. If you finish your focus session, you'll get coins equal to the number of minutes you focused. Then, you can spend the coins in the shop for buying stuff!

## Todo

- [x] Focus timer
- [x] Gain coins for focusing
- [x] Store
  - [x] Skip passes
  - [ ] App icons
  - [ ] App themes
  - [ ] Game tickets?
  - [ ] Gambling?
  - [ ] In-app AI credits?
  - [ ] IRL things?
- [ ] Tasks
  - [ ] Reminder integration
- [ ] Coin multipliers
  - [ ] Random daily bonus
  - [ ] Task completion before deadline
- [ ] Shortcuts integration
  - [ ] Start focus sessions in app
  - [ ] Find store items
  - [ ] Purchase store items
  - [ ] Find sessions

## Technical details

This app uses SwiftUI as the frontend framework (duh). It stores focus sessions with SwiftData and the coins, purchased items, and some temporary state with UserDefaults.

To detect when the user leaves the app, a combination of the `.onDisappear` modifier and watching `\.scenePhase` changes is used: the `.onDisappear` monitors switching to another tab, and `\.scenePhase` monitors leaving or killing the app.
