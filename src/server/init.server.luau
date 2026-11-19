-- Steal a Snack: the server entrypoint.
-- One line starts the whole game: Game.init builds the world, stocks the
-- neighbour bases, starts the belt, the money tick, the thief clock and the
-- stampede clock. Everything else lives in the modules it requires.

local Game = require(script.Parent:WaitForChild("Game"))

Game.init()
print("Steal a Snack is running: buy snacks on the Snackway, guard your base.")
