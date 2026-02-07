
--[[
A game with two players.  The players have perfect information, and are playing perfectly.  This means that 



This requires a very simplified MTG AI to be able to play.


However, it creates lots of creatures, and you have to check _every_ line of play, with all possible combinations of blocks and attacks.



Very simply, for any action, for each player, it can either be an action that forces a win, an action that forces a tie, or an action that looses.



Another issue that this intruduces is looping.  You have to be able to recognize when you get into the same state.  Luckilly, since MTG states are unique, we can hash these.
This is big/costly, but means we won't run into loops.


When a loop is reached, the actions from the loop point to the loop point are marked as a tie for both players. (so they will no longer be evaluated.)

Players traverse their action tree until they find the most favorable outcome (a win) or run out of actions, at which point they return whatever the most favorable outcome they found is.
Some actions pass priority, and some do not.




For the initial test of this, it will be simpler to not model all the magic rules, and do manual validation of the results to check they are a legal game.
Otherwise we would have to model steps and phases, which would make it much more intensive to run.

And, of course, you want a visualizer to model your state once you've computed it.  
You might have to save these results to disk for use as memory due to how large the problem space is.
Also, we want to save every state so that we can reuse computation if we get to it again.  This can happen without loops.

A much simpler simulation is hangarback walker math.  What are the projected damage lines that you can get out of different sizes of hangarback walker given different numbers?
Specifically, we are interested in the largest number you can hit before your opponent hits a larger number of damage to you.
Which player deals that damage is the sign of that number.

This is a special case of the algorithm where the goal is not _winning_, but finding the most damage a given line can deal to your opponent before they deal that much damage to you.
If there is no limit, then you strictly beat them for all possible starting life totals.
Note that you don't care how much damage they deal to you first.  This is about fast growing functions.

Furthermore, the list of possible amounts of damage you can deal to each other, in how many turns, 

This system falls apart when you have two identical vanilla creatures hitting back and forth, and one burn spell.  Each damage total will be a new one, and it will never return.
We need a different way to talk about this.  In such a scenario, one player can be said to be "up life/tempo" by n points.  That is, 
their relative life totals will not change, but the one that attacks first will win.  In order to avoid going "down tempo", with no other options, you block.
This restores the board to neutral state, with no objects anywhere.  The empty state is a tie.  To be clearer, the state with no actions is a tie.
To be clearer, the state with no actions is a trivial loop that counts as a tie.



Tempo is difficult to model, because it breaks the idea that there is a single amount of damage that you will outrace.


Burn is constant damage.
Creatures are linear damage.
Armies in a can are geometric damage.
Doublers are exponential damage.



There are undecidable problems, but it's very hard to know what they are.
]]














