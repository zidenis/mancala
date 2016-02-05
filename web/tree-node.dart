// Copyright (c) 2016, zidenis (http://dart.blog.br)
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'mancala.dart';

class TreeNode {
  Board board; // Game state for this node
  TreeNode parent;
  List<TreeNode> children;

  // Indicates the quality of the game to the computer. Higher the better.
  int _boardScore;
  // Indicates if it is the computer who should play next
  bool computerMove;
  int treeHeight;
  int originalPitNumber;

  /// Builds a tree node.
  ///
  /// The node should have a [parent] node,
  /// a [pitNumber] indicating which move the player will play and
  /// an indication [isPlayerOne] of which player is the one who is playing
  TreeNode(TreeNode this.parent, int pitNumber, bool isPlayerOne) {
    board = new Board(null, null, isPlayerOne);
    children = [];
    treeHeight = parent.treeHeight + 1;
    board.kahala1 = parent.board.kahala1;
    board.kahala2 = parent.board.kahala2;
    for (Pit pit in board.pits) {
      pit.numOfSeeds = parent.board.getPit(pit.pitNumber).numOfSeeds;
    }
    board.startSeeding(pitNumber);
    _boardScore = board.kahala2 - board.kahala1;
    if (parent.originalPitNumber == null) originalPitNumber = pitNumber;
    else originalPitNumber = parent.originalPitNumber;
    computerMove = board.isPlayerOne;
    parent.children.add(this);
  }

  /// Special builder for the root of the decision tree
  TreeNode.root(Board this.board) {
    children = [];
    treeHeight = 0;
  }

  /// Gets the scoring that classifies the game board.
  int get boardScore {
    if (board.kahala2 > 36) _boardScore+=100;
    return _boardScore;
  }

}