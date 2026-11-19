-- Steal a Snack: the base plots.
-- Four plots ring the plaza. A player who joins claims the first free plot; the
-- rest belong to neighbour bots whose snacks can be stolen. Each plot holds eight
-- snack slots and a lock barrier: while a player's plot is locked, no thief can
-- take a snack from it. Bases keeps the bookkeeping; the snacks live in Creatures.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Creatures = require(script.Parent:WaitForChild("Creatures"))

local Bases = {}

-- The plots World built, and one state record per plot.
local plots = {}
local states = {}

-- Claim the first unclaimed plot for a player, or nil when the plaza is full.
-- The neighbour's snacks already on the plot become the player's starter set:
-- they earn for them now and cannot be stolen from their own base.
function Bases.claimPlot(player)
	for i, plot in ipairs(plots) do
		if not states[i].owner then
			states[i].owner = player
			states[i].isNpc = false
			plot.ownerLabel.Text = player.Name .. "'s Base"
			for _, snack in ipairs(states[i].slots) do
				if snack and snack.Parent then
					snack:SetAttribute("OwnerName", player.Name)
					snack:SetAttribute("State", "base")
					Creatures.setPrompt(snack, "", "", false)
				end
			end
			return states[i]
		end
	end
	return nil
end

-- Give a plot back to the bots when its player leaves. Their snacks stay on it
-- and become stealable, so the base never sits empty.
function Bases.releasePlot(player)
	for i, state in ipairs(states) do
		if state.owner == player then
			state.owner = nil
			state.isNpc = true
			plots[i].ownerLabel.Text = plots[i].npcName .. "'s Base"
			plots[i].barrier.Visible = false
			for _, snack in ipairs(state.snacks) do
				if snack.Parent then
					snack:SetAttribute("OwnerName", plots[i].npcName)
					snack:SetAttribute("State", "npc")
					Creatures.setPrompt(snack, "Steal", snack:GetAttribute("CreatureName"), true)
				end
			end
			return
		end
	end
end

-- The state record of the plot a player owns, or nil.
function Bases.plotOf(player)
	for _, state in ipairs(states) do
		if state.owner == player then
			return state
		end
	end
	return nil
end

-- Every plot's state, for the thief and the stampede to read.
function Bases.allPlots()
	return states
end

-- The first free slot position on a plot, or nil when it is full.
function Bases.freeSlot(state)
	for i, slot in ipairs(state.plot.slots) do
		if not state.slots[i] then
			return slot, i
		end
	end
	return nil, nil
end

-- Park a snack on a plot's free slot. Returns true when it fit.
function Bases.parkSnack(state, snack, ownerName)
	local slot, index = Bases.freeSlot(state)
	if not slot then
		return false
	end
	state.slots[index] = snack
	snack:SetAttribute("OwnerName", ownerName)
	snack:SetAttribute("BaseIndex", state.plot.index)
	snack:SetAttribute("SlotIndex", index)
	Creatures.carryToSlot(snack, slot, function()
		if state.isNpc then
			snack:SetAttribute("State", "npc")
			Creatures.setPrompt(snack, "Steal", snack:GetAttribute("CreatureName"), true)
		else
			snack:SetAttribute("State", "base")
			Creatures.setPrompt(snack, "", "", false)
		end
	end)
	return true
end

-- Take a snack off its plot and hand its slot back. The snack itself is left
-- for the caller to carry, drop or destroy.
function Bases.unparkSnack(snack)
	local baseIndex = snack:GetAttribute("BaseIndex")
	local slotIndex = snack:GetAttribute("SlotIndex")
	if baseIndex and baseIndex >= 1 and states[baseIndex] then
		states[baseIndex].slots[slotIndex] = nil
	end
	snack:SetAttribute("BaseIndex", 0)
	snack:SetAttribute("SlotIndex", 0)
end

-- The snacks currently earning on a plot.
function Bases.snacksOn(state)
	local list = {}
	for _, snack in ipairs(state.slots) do
		if snack and snack.Parent then
			table.insert(list, snack)
		end
	end
	return list
end

-- Lock a plot: thieves turn away while the barrier is up. Returns false when
-- the lock is still recharging.
function Bases.lockPlot(state, now)
	if now < state.lockReadyAt then
		return false
	end
	state.lockUntil = now + Config.LOCK_DURATION
	state.lockReadyAt = now + Config.LOCK_DURATION + Config.LOCK_COOLDOWN
	state.plot.barrier.Visible = true
	return true
end

-- True while a plot's lock is up.
function Bases.isLocked(state, now)
	return now < state.lockUntil
end

-- Hide barriers whose lock has run out.
function Bases.updateLocks(now)
	for _, state in ipairs(states) do
		if state.plot.barrier.Visible and now >= state.lockUntil then
			state.plot.barrier.Visible = false
		end
	end
end

-- Stock a neighbour bot's plot with a few snacks to steal.
function Bases.stockNpcPlot(state, count)
	local made = 0
	for _ = 1, count do
		local creature, rarity, mutation = Config.rollSnack()
		local snack = Creatures.buildSnack(creature, rarity, mutation)
		local slot, index = Bases.freeSlot(state)
		if not slot then
			snack:Destroy()
			break
		end
		state.slots[index] = snack
		snack:SetAttribute("OwnerName", state.plot.npcName)
		snack:SetAttribute("BaseIndex", state.plot.index)
		snack:SetAttribute("SlotIndex", index)
		snack:SetAttribute("State", "npc")
		snack:PivotTo(CFrame.new(slot.X, slot.Y + 0.9, slot.Z))
		snack.Parent = game:GetService("Workspace"):WaitForChild("Snacks")
		Creatures.setPrompt(snack, "Steal", snack:GetAttribute("CreatureName"), true)
		made += 1
	end
	return made
end

-- Build the state records for the plots World handed back.
function Bases.setup(worldPlots)
	plots = worldPlots
	for i, plot in ipairs(plots) do
		states[i] = {
			plot = plot,
			owner = nil,
			isNpc = true,
			slots = {},
			lockUntil = 0,
			lockReadyAt = 0,
			stealReadyAt = 0,
		}
	end
	-- Every neighbour plot starts with snacks worth stealing.
	for _, state in ipairs(states) do
		Bases.stockNpcPlot(state, 4)
	end
end

return Bases
