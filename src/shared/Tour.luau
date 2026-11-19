-- Steal a Snack: the tour helpers.
-- TOUR.json names these functions so make.fun's reviewers can bring the game
-- to each screenshot's screen from Studio. They only ever run on the server:
-- each one reaches into the server's Game module when it is called, never at
-- require time, so requiring this module from the client stays harmless.

local Tour = {}

-- Give the first player in the game this much snack cash (arg: an integer).
function Tour.grantMoney(arg)
	local players = game:GetService("Players"):GetPlayers()
	if #players == 0 then
		return false
	end
	local amount = tonumber(arg) or 0
	local player = players[1]
	player:SetAttribute("Money", (player:GetAttribute("Money") or 0) + amount)
	return true
end

-- Send the Snack Snatcher after the first player's base (arg: ignored).
function Tour.spawnThief(_arg)
	local gameModule = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Game"))
	return gameModule.debugThief()
end

-- Start a Snack Stampede right now (arg: ignored).
function Tour.stampede(_arg)
	local gameModule = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Game"))
	gameModule.startStampede()
	return true
end

return Tour
