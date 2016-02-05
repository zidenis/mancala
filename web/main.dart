// Copyright (c) 2016, zidenis (http://dart.blog.br)
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';
import 'dart:async';

import 'mancala.dart';
import 'tree-node.dart';

bool twoPlayers;
String difficult;
Board board;

bool soundEnabled;
AudioElement clickSound;
DivElement msgElement;
DivElement mancalaElement;
DivElement kahala1Element;
DivElement kahala2Element;
DivElement logWindow;
OListElement logElement;
Map<int, DivElement> pitElements;

// Initializes the app
void main() {
  soundEnabled = true;
  logWindow = querySelector('#logwindow');
  logElement = querySelector('#log');
  querySelectorAll('.btn').forEach((btn) => btn.onClick.listen(startGame));
  mancalaElement = querySelector('#mancala');
  msgElement = querySelector('#message');
  clickSound = querySelector('#drops');
  querySelector('#volume').onClick.listen(volumeButton);
  add2log("Ready to play.");
}

/// Starts a new game when the player press "1 player" or "2 players" button
startGame(MouseEvent event) {
  // Creates a new board game registering callback functions that will be called when game state changes
  board = new Board(add2log, nextTurn, true);
  twoPlayers = (event.target as Element).dataset.containsKey('twoPlayers');
  // getting difficult value from radio buttons
  RadioButtonInputElement difficultRadio =
      querySelectorAll('input[name="difficult"]')
          .firstWhere((radio) => (radio as RadioButtonInputElement).checked);
  difficult = difficultRadio.value;
  // remove the setup Element to give space to the board UI
  querySelector('#setup').remove();
  setupBoardUIElements();
}

/// Loads and configs the elements of game board UI
setupBoardUIElements() async {
  await HttpRequest.getString('mancala.html').then((htmlCode) {
    mancalaElement.append(new Element.html(htmlCode));
  });
  // Getting each element of game board for latter reference
  pitElements = {};
  for (DivElement element in querySelectorAll('.pit')) {
    int pitId = int.parse(element.getAttribute('id'));
    pitElements[pitId] = element;
    element.onClick.listen(executePlayersMove);
  }
  kahala1Element = querySelector('#kahala1pit');
  kahala2Element = querySelector('#kahala2pit');
  add2log("${twoPlayers ? '2 players' : '1 player'} $difficult game started.");
  updateBoardUI();
}

/// Updates game board UI with the scores and enable/disable clicks on pits
/// After update the UI, checks if it is an one player game and calls the computer move
/// if it's time to computer play
updateBoardUI() {
  int kahalaSeeds = board.kahala1;
  kahala1Element.setInnerHtml("");
  kahala1Element.appendHtml(kahalaSeeds < 10
      ? '<img class="img-responsive center-block" width="32" src="imgs/$kahalaSeeds.png">'
      : '<img class="img-responsive center-block" width="32" src="imgs/10.png">');
  kahala1Element.appendHtml("<span>$kahalaSeeds</span>");
  kahalaSeeds = board.kahala2;
  kahala2Element.setInnerHtml("");
  kahala2Element.appendHtml(kahalaSeeds < 10
      ? '<img class="img-responsive center-block" width="32" src="imgs/$kahalaSeeds.png">'
      : '<img class="img-responsive center-block" width="32" src="imgs/10.png">');
  kahala2Element.appendHtml("<span>$kahalaSeeds</span>");
  // Updating each pit
  // enable/disable clicks on pits
  for (Pit pit in board.pits) {
    pitElements[pit.pitNumber].setInnerHtml("");
    // Constructs the html that will show the appropriate icon with the num of seeds
    StringBuffer htmlStr = new StringBuffer();
    htmlStr.write('<span class="pitnum">#${pit.pitNumber}</span>');
    int numOfSeeds = pit.numOfSeeds;
    htmlStr.write(numOfSeeds < 10
        ? '<img class="img-responsive center-block" width="32" src="imgs/$numOfSeeds.png">'
        : '<img class="img-responsive center-block" width="32" src="imgs/10.png">');
    htmlStr.write('<span class="seedsnum">$numOfSeeds</span>');
    pitElements[pit.pitNumber].appendHtml(htmlStr.toString());
    if (shouldActivatePit(pit)) {
      pitElements[pit.pitNumber]
          .setAttribute('class', 'col-xs-2 pit activepit');
    } else {
      pitElements[pit.pitNumber].setAttribute('class', 'col-xs-2 pit');
    }
  }
  if (twoPlayers)
    msgElement.text = board.isPlayerOne ? "1st Player Turn" : "2nd Player Turn";
  else {
    msgElement.text = board.isPlayerOne ? "1st Player Turn" : "Computer Turn";
  }
}

/// Checks if a Pit should be enable.
///
/// An enabled pit is able to start seeding when clicked.
/// A pit is disabled if it belongs to the other player or has 0 seeds on it.
bool shouldActivatePit(Pit pit) {
  // pit has 0 seeds on it
  if (pit.numOfSeeds == 0)
    return false;
  else {
    if (board.isPlayerOne) {
      if (pit.pitNumber < 7)
        return true;
      else // belong to the other player
        return false;
    } else {
      if (pit.pitNumber > 6 && twoPlayers)
        return true;
      else // belong to the other player
        return false;
    }
  }
}

/// Adds messages to UI
add2log(String message) {
  DateTime dt = new DateTime.now();
  String hour = dt.hour.toString().padLeft(2, '0');
  String minute = dt.minute.toString().padLeft(2, '0');
  String second = dt.second.toString().padLeft(2, '0');
  logElement.append(new LIElement()..text = '$hour:$minute:$second - $message');
  logWindow.scrollTop = logWindow.scrollHeight;
}

/// Execute the move of the player when he clicks on one of his pits
///
/// The move is performed when the player clicks on a pit that is located
/// on his side of the board and that has one or more seeds.
executePlayersMove(MouseEvent event) {
  playClickSound();
  DivElement element = event.target;
  int pitNumber;
  // the [pitNumber] is an attribute of the Div element clicked
  // if the user clicked on an chield element (inside div), get the id from the parent
  if (event.target is DivElement) {
    pitNumber = int.parse(element.getAttribute('id'));
  } else {
    pitNumber = int.parse(element.parent.getAttribute('id'));
  }
  //does nothing if pit has no seed
  if (board.getPit(pitNumber).numOfSeeds == 0) return;
  //does nothing if a player is clicking in a pit that not belongs to him
  if (pitNumber > 6 && pitNumber < 13) {
    if (board.isPlayerOne) return;
    if (!twoPlayers) return;
  }
  if (!board.isPlayerOne && pitNumber > 0 && pitNumber < 7) return;
  board.startSeeding(pitNumber);
}

// Sets up the next turn, calling the computer move if it is the Computer's turn
void nextTurn() {
  updateBoardUI();
  if (board.gameOver) {
    if (board.kahala1 > board.kahala2)
      msgElement.text =
          "Finished. ${twoPlayers ? "1st Player" : "YOU"}  Won!!!";
    else if (board.kahala1 < board.kahala2)
      msgElement.text =
          "Finished. ${twoPlayers ? "2nd Player" : "Computer"} Won!!!";
    else
      msgElement.text = "Finished. Tie game";
  }
  //calls computer move if the type of game is Player vs Computer
  //and it is the computer time to play
  else if (!twoPlayers && !board.isPlayerOne) chooseComputerMove();
}

/// Chooses the computer move according to selected game difficult
chooseComputerMove() async {
  switch (difficult) {
    case "easy":
      new Future.delayed(new Duration(seconds: 1), computerRandomMove);
      break;
    case "normal":
      new Future.delayed(new Duration(seconds: 1), () {
        board.startSeeding(chooseBestMove(buildDecisionTree(4, [new TreeNode.root(new Board.clone(board))])));});
      break;
    case "hard":
      new Future.delayed(new Duration(seconds: 1), () {
        board.startSeeding(chooseBestMove(buildDecisionTree(6, [new TreeNode.root(new Board.clone(board))])));});
      break;
  }
}

/// Random move for computer in easy games
computerRandomMove() {
  Random rndGen = new Random();
  int pitNumber = rndGen.nextInt(6) + 7;
  if (board.getPit(pitNumber).numOfSeeds == 0)
    computerRandomMove();
  else {
    board.startSeeding(pitNumber);
  }
}

/// Builds a decision tree with nodes, returning the leaf nodes in a List.
///
/// Each Node will have a game board representing the game state in the future.
///
List<TreeNode> buildDecisionTree(int decisionTreeHeight, List<TreeNode> decisionTree) {
  if (decisionTreeHeight == 0)
    return decisionTree;
  else {
    for (TreeNode node in new List.from(decisionTree)) {
      if (node.board.isPlayerOne) {
        for (int pitNumber = 1; pitNumber < 7; pitNumber++) {
          if (node.board.getPit(pitNumber).numOfSeeds > 0) {
            decisionTree.add(new TreeNode(node, pitNumber, true));
          }
        }
      } else {
        for (int pitNumber = 7; pitNumber < 13; pitNumber++) {
          if (node.board.getPit(pitNumber).numOfSeeds > 0) {
            TreeNode tmpNode = new TreeNode(node, pitNumber, false);
            decisionTree.add(tmpNode);
          }
        }
      }
      if (decisionTree.length == 1)
        decisionTreeHeight = 1;
      else {
        decisionTree.remove(node);
      }
    }
    return buildDecisionTree(decisionTreeHeight - 1, decisionTree);
  }
}

/// Evaluates the leaf nodes of the decision tree to determine the best move for computer
int chooseBestMove(List<TreeNode> boardList) {
  return boardList
      .reduce((nodeA, nodeB) =>
          (nodeA.boardScore >= nodeB.boardScore) ? nodeA : nodeB)
      .originalPitNumber;
}

/// Plays a sound on user click
playClickSound() {
  if (soundEnabled) clickSound.play();
}

/// Toggles the volume between on and off
volumeButton(MouseEvent event) {
  if (soundEnabled) {
    (event.target as SpanElement)
        .setAttribute('class', 'logo-text glyphicon glyphicon-volume-off');
  } else {
    (event.target as SpanElement)
        .setAttribute('class', 'logo-text glyphicon glyphicon-volume-up');
  }
  soundEnabled = !soundEnabled;
}
