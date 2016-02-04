// Copyright (c) 2016, zidenis (http://dart.blog.br)
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

// Callback Function that will be called to notify UI for log messages
typedef void NotifyCallback(String message);

// Callback Function that will be called to inform that the board state has changed
typedef void EndOfMoveCallback();

/// A game board of mancala
class Board {
  List<Pit> pits;
  int kahala1;
  int kahala2;

  bool isPlayerOne;
  bool playAgain;
  bool gameOver;

  NotifyCallback notify;
  EndOfMoveCallback endOfMove;

  // Creates a new board game and register the callback functions that will be called when game state changes
  Board(NotifyCallback this.notify, EndOfMoveCallback this.endOfMove) {
    pits = [];
    for (int i = 1; i <= 12; i++) {
      pits.add(new Pit(i));
    }
    kahala1 = 0;
    kahala2 = 0;
    isPlayerOne = true;
    playAgain = false;
    gameOver = false;
  }

  /// Gets the Pit identified by [pitNumber].
  Pit getPit(int pitNumber) => pits[pitNumber - 1];

  /// Begins the seeding. Starts on [pitNumber] and apply game rules.
  startSeeding(int pitNumber) {
    Pit pit = getPit(pitNumber);
    int seeds = pit.numOfSeeds; // colects seeds from the pit
    pit.numOfSeeds = 0; // the pit is now empty
    notify(
        "Player ${isPlayerOne ? "1" : "2"} collected $seeds seeds on  pit #${pitNumber} and start seeding.")??null;
    while (seeds > 0) {
      // gets the number of the next pit
      pitNumber = (pitNumber == 12) ? 1 : pitNumber + 1;
      if (pitNumber == 1 || pitNumber == 7) {
        seeds--;
        pitNumber == 1 ? kahala2++ : kahala1++;
        if (seeds == 0) { // Last seed on one of kahalas
          if (pitNumber == 7) {
            if (isPlayerOne) {
              playAgain = true;
              notify("Last seed on Player's Kahala. Player 1 moves again.")??null;
            }
            break;
          }
          if (pitNumber == 1) {
            if (!isPlayerOne) {
              playAgain = true;
              notify("Last seed on Player's Kahala. Player 2 moves again.")??null;
            }
            break;
          }
        }
      }
      seeds--;
      if (seeds == 0) {
        // Checking if the last seed will be put on an empty pit.
        if (getPit(pitNumber).numOfSeeds == 0) {
          // Catching the opposite pit.
          Pit oppositePit = pits[getPit(pitNumber).opposite() - 1];
          if (oppositePit.numOfSeeds > 0)
            notify(
                "Last seed on empty pit #${pitNumber}. Player ${isPlayerOne ? "1" : "2"} collected ${oppositePit.numOfSeeds} seeds from pit #${oppositePit.pitNumber}")??null;
          if (isPlayerOne)
            kahala1 += oppositePit.numOfSeeds;
          else
            kahala2 += oppositePit.numOfSeeds;
          oppositePit.numOfSeeds = 0;
        }
      }
      getPit(pitNumber).numOfSeeds++; // puts one seed on pit
    }
    // defines who should play the next move
    if (!playAgain)
      isPlayerOne = !isPlayerOne;
    else
      playAgain = false;
    // checks if game has ended (no more possible moves)
    if (_hasEnded()) _finish();
    endOfMove()??null;
  }

  /// Checks if the game has ended.
  ///
  /// Game ends when one of the players doesn't have seeds on theirs pits.
  bool _hasEnded() {
    int i = 1;
    int sum;
    for (sum = 0; i <= 6; i++) {
      sum += getPit(i).numOfSeeds;
    }
    if (sum == 0) {
      notify(
          "1st Player's board does not have more seeds. Finishing the game. ")??null;
      return true;
    }
    for (sum = 0; i <= 12; i++) {
      sum += getPit(i).numOfSeeds;
    }
    if (sum == 0) {
      notify(
          "2nd Player's board does not have more seeds. Finishing the game. ")??null;
      return true;
    }
    return false;
  }

  /// Finishes the game by putting the remaining seeds on respective player's kahala
  void _finish() {
    int i = 1;
    for (; i <= 6; i++) {
      int lastSeeds = getPit(i).numOfSeeds;
      if (lastSeeds > 0) {
        notify(
            "Moving $lastSeeds seeds from pit #${i+1} to 1st Player's Kahala")??null;
        kahala1 += lastSeeds;
        getPit(i).numOfSeeds = 0;
      }
    }
    for (; i <= 12; i++) {
      int lastSeeds = getPit(i).numOfSeeds;
      if (lastSeeds > 0) {
        notify(
            "Moving $lastSeeds seeds from pit #${i+1} to 2nd Player's Kahala")??null;
        kahala2 += lastSeeds;
        getPit(i).numOfSeeds = 0;
      }
    }
    if (kahala1 > kahala2) {
      notify("Game Over. 1st player won.")??null;
    } else if (kahala2 > kahala1) {
      notify("Game Over. 2nd player won.")??null;
    } else {
      notify("Game Over. Tie game.")??null;
    }
    gameOver = true;
  }
}

/// A pit of seeds in the mancala game board
class Pit {
  int numOfSeeds;
  final int pitNumber;

  Pit(this.pitNumber) {
    numOfSeeds = 6;
  }

  int opposite() => 13 - pitNumber;
}
