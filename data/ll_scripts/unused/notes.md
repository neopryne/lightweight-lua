


There are two parts to this.  There is a library for solving arbitrary games to see who wins, given a given setup.

I guess I have to build randomness into it, which gives weights to tree branches.  Without randomness, all branches have weights of 0, 1, or .5 (tie).


Branches that the active player can force into a winning branch are wins. (win ~= 1, becuase of weights).  so I probably need both score and weight, and getWeightedScore
Branches that cause the active player to lose (zugzuang) are losing branches, and to be avoided.  Branches that loop on themselves are marked as tie.  If all choices from a given point have been evaluated, the result of this choice is the best available result for the active player.

(we focus on two player for now, but I should see if it's not hard to build it for more.)






