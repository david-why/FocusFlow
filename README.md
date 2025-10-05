# FocusFlow

_When you focus, <img src="public/coin.png" style="height: 1em"/> flows!_

## Installation

You can install the app from TestFlight here: (link TBD)

## Usage

You can start a focus timer, which will fail if you leave the page. If you finish your focus session, you'll get coins equal to the number of minutes you focused. Then, you can spend the coins in the shop for buying stuff!

## Todo

- [x] Focus timer
- [x] Gain coins for focusing
- [x] Store
  - [ ] Skip passes _(don't do anything yet)_
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

## Technical details

This app uses SwiftUI as the frontend framework (duh). It stores focus sessions with SwiftData and the coins, purchased items, and some temporary state with UserDefaults.
