-- Steal a Snack: the game itself.
-- Game wires the world, the snacks, the bases and the thief together and owns
-- the rules: who has money, what a snack costs, what a rebirth gives, when the
-- stampede floods the belt. The client only draws the HUD and asks for rebirths
-- and locks; every decision is made here, on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local World = require(script.Parent:WaitForChild("World"))
local Creatures = require(script.Parent:WaitForChild("Creatures"))
local Bases = require(script.Parent:WaitForChild("Bases"))
local Thieves = require(script.Parent:WaitForChild("Thieves"))

local Game = {}

local remotes = nil
local stampedeUntil = 0
local nextStampedeAt = 0
local connectedPrompts = {}

-- Send a banner to one player, or to everyone when no player is given.
local function announce(text, color, player)
	if player then
		remotes.Announce:FireClient(player, text, color)
	else
		remotes.Announce:FireAllClients(text, color)
	end
end

-- The income multiplier a player earned through rebirths.
local function incomeMultiplier(player)
	return 1 + Config.REBIRTH_BONUS * player:GetAttribute("Rebirths")
end

-- The $/s all of a player's snacks earn together, after their multiplier.
local function playerIncome(player)
	local state = Bases.plotOf(player)
	if not state then
		return 0
	end
	local total = 0
	for _, snack in ipairs(Bases.snacksOn(state)) do
		total += snack:GetAttribute("Income")
	end
	return total * incomeMultiplier(player)
end

-- Refresh the money, income and lock numbers the HUD reads.
local function syncPlayer(player)
	player:SetAttribute("Income", playerIncome(player))
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Snack Cash")
		if cash then
			cash.Value = math.floor(player:GetAttribute("Money"))
		end
	end
end

-- A player buys the snack on the belt: pay, then carry it to a free slot.
local function buySnack(player, snack)
	local state = Bases.plotOf(player)
	if not state then
		announce("The plaza is full — there is no base left to claim.", Color3.fromRGB(255, 80, 80), player)
		return
	end
	local cost = snack:GetAttribute("Cost")
	if player:GetAttribute("Money") < cost then
		announce("You need $" .. cost .. " for " .. snack:GetAttribute("CreatureName") .. ".", Color3.fromRGB(255, 80, 80), player)
		return
	end
	local slot = Bases.freeSlot(state)
	if not slot then
		announce("Your base is full! Rebirth to clear it and earn more.", Color3.fromRGB(255, 200, 40), player)
		return
	end
	player:SetAttribute("Money", player:GetAttribute("Money") - cost)
	-- Take it off the belt's walking list before it is parked.
	for i, walking in ipairs(Creatures.onBelt) do
		if walking == snack then
			table.remove(Creatures.onBelt, i)
			break
		end
	end
	Bases.parkSnack(state, snack, player.Name)
	syncPlayer(player)
end

-- A player steals a snack from a neighbour bot's base, then that base cannot
-- be stolen from again for a while.
local function stealSnack(player, snack)
	local state = Bases.plotOf(player)
	if not state then
		announce("The plaza is full — there is no base left to claim.", Color3.fromRGB(255, 80, 80), player)
		return
	end
	local homeIndex = snack:GetAttribute("BaseIndex")
	local home = homeIndex and Bases.allPlots()[homeIndex]
	if not home then
		return
	end
	local now = os.time()
	if now < home.stealReadyAt then
		announce("That base is watching you. Come back in " .. (home.stealReadyAt - now) .. "s.", Color3.fromRGB(255, 200, 40), player)
		return
	end
	local slot = Bases.freeSlot(state)
	if not slot then
		announce("Your base is full! Rebirth to clear it and earn more.", Color3.fromRGB(255, 200, 40), player)
		return
	end
	home.stealReadyAt = now + Config.STEAL_COOLDOWN
	Bases.unparkSnack(snack)
	Bases.parkSnack(state, snack, player.Name)
	announce(player.Name .. " stole " .. snack:GetAttribute("CreatureName") .. " from " .. home.plot.npcName .. "!", Color3.fromRGB(255, 200, 40))
	syncPlayer(player)
end

-- One prompt trigger: buy from the belt, or steal from a neighbour.
local function onPromptTriggered(player, prompt)
	local body = prompt.Parent
	local snack = body and body.Parent
	if not snack or not snack:IsA("Model") then
		return
	end
	local snackState = snack:GetAttribute("State")
	if snackState == "belt" then
		buySnack(player, snack)
	elseif snackState == "npc" then
		stealSnack(player, snack)
	end
end

-- Watch for every buy/steal prompt the snacks carry, now and later.
local function watchPrompts()
	local folder = Workspace:WaitForChild("Snacks")
	local function watch(prompt)
		if prompt:IsA("ProximityPrompt") and not connectedPrompts[prompt] then
			connectedPrompts[prompt] = true
			prompt.Triggered:Connect(function(player)
				onPromptTriggered(player, prompt)
			end)
		end
	end
	for _, descendant in ipairs(folder:GetDescendants()) do
		watch(descendant)
	end
	folder.DescendantAdded:Connect(watch)
end

-- A rebirth: hand the snacks back, take the money, earn faster forever.
local function onRebirthRequest(player)
	local state = Bases.plotOf(player)
	if not state then
		return
	end
	local rebirths = player:GetAttribute("Rebirths")
	local cost = Config.REBIRTH_BASE_COST * (rebirths + 1)
	if player:GetAttribute("Money") < cost then
		announce("Rebirth costs $" .. cost .. ". You have $" .. math.floor(player:GetAttribute("Money")) .. ".", Color3.fromRGB(255, 80, 80), player)
		return
	end
	for _, snack in ipairs(Bases.snacksOn(state)) do
		Bases.unparkSnack(snack)
		snack:Destroy()
	end
	player:SetAttribute("Money", Config.START_MONEY)
	player:SetAttribute("Rebirths", rebirths + 1)
	announce(player.Name .. " rebirthed! Snacks now earn x" .. incomeMultiplier(player) .. ".", Color3.fromRGB(80, 220, 100))
	syncPlayer(player)
end

-- A lock: the barrier goes up and the Snatcher turns away.
local function onLockRequest(player)
	local state = Bases.plotOf(player)
	if not state then
		return
	end
	local now = os.time()
	if Bases.lockPlot(state, now) then
		player:SetAttribute("LockUntil", state.lockUntil)
		player:SetAttribute("LockReadyAt", state.lockReadyAt)
		announce("Base locked for " .. Config.LOCK_DURATION .. "s! No thief can touch it.", Color3.fromRGB(80, 160, 255), player)
	else
		announce("The lock is recharging (" .. (state.lockReadyAt - now) .. "s left).", Color3.fromRGB(255, 200, 40), player)
	end
end

-- The stampede: rare snacks flood the belt for half a minute.
local function startStampede()
	stampedeUntil = os.time() + Config.STAMPEDE_LENGTH
	announce("SNACK STAMPEDE! Rare snacks are flooding the Snackway!", Color3.fromRGB(255, 200, 40))
	-- One guaranteed rare to chase: a Legendary or better, right now.
	local pool = {}
	for _, creature in ipairs(Config.CREATURES) do
		if creature.rarity >= 4 then
			table.insert(pool, creature)
		end
	end
	local creature = pool[math.random(#pool)]
	local rarity = Config.RARITIES[creature.rarity]
	local _, mutation = Config.pickWeighted(Config.MUTATIONS)
	Creatures.spawnSpecific(creature, rarity, mutation)
end

-- One second of game: pay every player's snacks, run the locks, the thief
-- clock and the stampede clock.
local function tick()
	local now = os.time()
	for _, player in ipairs(Players:GetPlayers()) do
		local income = playerIncome(player)
		if income > 0 then
			player:SetAttribute("Money", player:GetAttribute("Money") + income)
		end
		syncPlayer(player)
	end
	Bases.updateLocks(now)
	Thieves.tick(now, announce)
	if now >= nextStampedeAt and now >= stampedeUntil then
		nextStampedeAt = now + Config.STAMPEDE_EVERY
		startStampede()
	end
end

-- A player joins: snack cash, a base, and a leaderboard row.
local function onPlayerAdded(player)
	player:SetAttribute("Money", Config.START_MONEY)
	player:SetAttribute("Income", 0)
	player:SetAttribute("Rebirths", 0)
	player:SetAttribute("LockUntil", 0)
	player:SetAttribute("LockReadyAt", 0)
	local state = Bases.claimPlot(player)
	if state then
		announce("Welcome to Steal a Snack, " .. player.Name .. "! Buy snacks on the Snackway (hold E).", Color3.fromRGB(255, 255, 255), player)
	else
		announce("The plaza is full — you are spectating.", Color3.fromRGB(255, 200, 40), player)
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Snack Cash"
	cash.Value = Config.START_MONEY
	cash.Parent = leaderstats
	leaderstats.Parent = player
end

-- Build the remotes the client talks to.
local function buildRemotes()
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	local announceEvent = Instance.new("RemoteEvent")
	announceEvent.Name = "Announce"
	announceEvent.Parent = remotes
	local rebirthEvent = Instance.new("RemoteEvent")
	rebirthEvent.Name = "RebirthRequest"
	rebirthEvent.Parent = remotes
	local lockEvent = Instance.new("RemoteEvent")
	lockEvent.Name = "LockRequest"
	lockEvent.Parent = remotes
	remotes.Parent = ReplicatedStorage
	rebirthEvent.OnServerEvent:Connect(onRebirthRequest)
	lockEvent.OnServerEvent:Connect(onLockRequest)
end

-- Debug helpers for TOUR.json (and for the reviewer in Studio): start a
-- stampede on demand, and send a thief at the first player who owns a base,
-- giving them a snack first when their base is empty.
function Game.startStampede()
	startStampede()
end

function Game.debugThief()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = Bases.plotOf(player)
		if state then
			if #Bases.snacksOn(state) == 0 then
				local creature, rarity, mutation = Config.rollSnack()
				local snack = Creatures.buildSnack(creature, rarity, mutation)
				snack:PivotTo(CFrame.new(state.plot.center.X, 2.2, state.plot.center.Z))
				snack.Parent = Workspace:WaitForChild("Snacks")
				Bases.parkSnack(state, snack, player.Name)
			end
			Thieves.spawnThief(state, announce)
			return true
		end
	end
	return false
end

-- Start the game.
function Game.init()
	math.randomseed(os.time())
	buildRemotes()
	Creatures.setup()
	watchPrompts()
	local plots = World.build()
	Bases.setup(plots)
	Thieves.setup()
	nextStampedeAt = os.time() + Config.STAMPEDE_EVERY

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		Bases.releasePlot(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- The belt loop: new snacks walk on, faster during a stampede.
	task.spawn(function()
		while true do
			local interval = Config.SPAWN_INTERVAL
			if os.time() < stampedeUntil then
				interval = Config.STAMPEDE_INTERVAL
			end
			task.wait(interval)
			if #Creatures.onBelt < Config.MAX_ON_BELT then
				Creatures.spawnSnack()
			end
		end
	end)

	-- The belt walk loop, every frame.
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		Creatures.updateBelt(dt)
	end)

	-- The one-second loop: money, locks, thief, stampede.
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return Game
