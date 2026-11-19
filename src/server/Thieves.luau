-- Steal a Snack: the Snack Snatcher.
-- Every minute or so a hooded thief slips in from the edge of the plaza, walks
-- to a player's base, grabs their most valuable snack and runs for the exit.
-- Touch him (or click him) and he drops the snack and flees. A locked base turns
-- him away before he even starts. He is the game's threat, so he has to work
-- with no other players around: he hunts the richest base he can reach.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Bases = require(script.Parent:WaitForChild("Bases"))
local Creatures = require(script.Parent:WaitForChild("Creatures"))

local Thieves = {}

local nextSpawnAt = 0
local EXIT_POINT = Vector3.new(0, 1, -95)

-- One limb of the thief's rig, joined to the torso by a Motor6D so the walk
-- loop can swing it.
local function limb(model, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = true
	part.Parent = model
	return part
end

-- Build the thief: a hooded figure with a sack, a mask and a red warning tag.
local function buildThief()
	local model = Instance.new("Model")
	model.Name = "Snack Snatcher"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(0, 3, 0)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.Anchored = false
	root.Parent = model

	local torso = limb(model, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), Color3.fromRGB(70, 40, 110))
	local head = limb(model, "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), Color3.fromRGB(230, 190, 150))
	head.Shape = Enum.PartType.Ball
	-- The mask: a black band across the eyes.
	local mask = limb(model, "Mask", Vector3.new(1.25, 0.4, 0.3), Vector3.new(0, 4.7, 0.55), Color3.fromRGB(20, 20, 20))
	mask.CanCollide = false
	-- The sack on his back, where the stolen snack goes.
	local sack = limb(model, "Sack", Vector3.new(1.4, 1.6, 0.8), Vector3.new(0, 3.2, -0.9), Color3.fromRGB(140, 100, 50))
	sack.Material = Enum.Material.SmoothPlastic
	sack.CanCollide = false
	local leftArm = limb(model, "Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), Color3.fromRGB(70, 40, 110))
	local rightArm = limb(model, "Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), Color3.fromRGB(70, 40, 110))
	local leftLeg = limb(model, "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), Color3.fromRGB(30, 30, 35))
	local rightLeg = limb(model, "Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), Color3.fromRGB(30, 30, 35))

	local function joint(name, part0, part1, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.C1 = c1
		motor.Parent = part0
		return motor
	end
	joint("RootJoint", root, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
	joint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	joint("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(0, 1, 0))
	joint("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0, 1, 0))
	local hipRight = joint("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
	local hipLeft = joint("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 13
	humanoid.HipHeight = 2
	humanoid.Health = 100
	humanoid.MaxHealth = 100
	humanoid.Parent = model
	model.PrimaryPart = root

	-- The red warning tag, so a player spots him from across the plaza.
	local tag = Instance.new("BillboardGui")
	tag.Name = "ThiefTag"
	tag.Adornee = head
	tag.Size = UDim2.fromOffset(200, 40)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "SNACK SNATCHER!"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.2
	label.Parent = tag
	tag.Parent = head

	return model, humanoid, hipLeft, hipRight
end

-- Walk a humanoid along a computed path. Returns true when it arrives, false
-- when the walk stalls twice, the humanoid dies, or cancelledFn says stop.
local function walkTo(humanoid, root, target, swing, cancelledFn)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 7,
		AgentMaxSlope = 45,
	})
	path:ComputeAsync(root.Position, target)
	if path.Status ~= Enum.PathStatus.Success then
		return false
	end
	local waypoints = path:GetWaypoints()
	local stalls = 0
	for _, waypoint in ipairs(waypoints) do
		if humanoid.Health <= 0 or (cancelledFn and cancelledFn()) then
			return false
		end
		humanoid:MoveTo(waypoint.Position)
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		-- Wait for arrival, or bail out when stuck.
		local waited = 0
		local lastPos = root.Position
		while (root.Position - waypoint.Position).Magnitude > 3 and waited < 6 do
			task.wait(0.2)
			waited += 0.2
			if cancelledFn and cancelledFn() then
				return false
			end
			if swing then
				swing(os.clock())
			end
			if (root.Position - lastPos).Magnitude < 0.05 and waited > 2 then
				stalls += 1
				humanoid.Jump = true
				lastPos = root.Position
				if stalls >= 2 then
					return false
				end
			elseif (root.Position - lastPos).Magnitude > 0.5 then
				lastPos = root.Position
			end
		end
	end
	return true
end

-- Drop the snack the thief is carrying back onto its own slot, then run away.
-- The snack remembers its home plot and slot in HomeBase/HomeSlot, because
-- unparkSnack already cleared BaseIndex/SlotIndex when it was grabbed.
local function dropSnack(thief, snack)
	if not snack or not snack.Parent then
		return
	end
	local weld = snack:FindFirstChild("ThiefWeld")
	if weld then
		weld:Destroy()
	end
	for _, part in ipairs(snack:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local baseIndex = snack:GetAttribute("HomeBase")
	local slotIndex = snack:GetAttribute("HomeSlot")
	local state = baseIndex and baseIndex >= 1 and Bases.allPlots()[baseIndex]
	if state and slotIndex and slotIndex >= 1 then
		state.slots[slotIndex] = snack
		snack:SetAttribute("BaseIndex", baseIndex)
		snack:SetAttribute("SlotIndex", slotIndex)
		local slot = state.plot.slots[slotIndex]
		Creatures.carryToSlot(snack, slot, function()
			snack:SetAttribute("State", "base")
			Creatures.setPrompt(snack, "", "", false)
		end)
	else
		snack:Destroy()
	end
	thief.carrying = nil
end

-- The whole visit: walk in, grab the richest snack, run for the exit.
local function runVisit(thief, humanoid, root, state, announceFn)
	local player = state.owner
	local snacks = Bases.snacksOn(state)
	if #snacks == 0 then
		return
	end
	-- The richest snack is the prize.
	table.sort(snacks, function(a, b)
		return a:GetAttribute("Income") > b:GetAttribute("Income")
	end)
	local target = snacks[1]
	local targetPos = target:GetPivot().Position
	announceFn("A Snack Snatcher is sneaking to " .. player.Name .. "'s base!", Color3.fromRGB(255, 60, 60))

	local swing = function(t)
		local hipLeft = thief.hipLeft
		local hipRight = thief.hipRight
		if hipLeft and hipRight then
			hipLeft.C0 = CFrame.new(-0.5, -1, 0) * CFrame.Angles(math.sin(t * 8) * 0.6, 0, 0)
			hipRight.C0 = CFrame.new(0.5, -1, 0) * CFrame.Angles(math.sin(t * 8 + math.pi) * 0.6, 0, 0)
		end
	end
	if not walkTo(humanoid, root, targetPos, swing, function()
		return thief.stopped
	end) then
		return
	end
	-- Locked while he walked over? He turns away empty-handed.
	if Bases.isLocked(state, os.time()) then
		announceFn("The Snatcher saw the lock and left empty-handed!", Color3.fromRGB(80, 160, 255))
		return
	end
	if not target.Parent then
		return
	end
	-- Remember home before the grab clears the slot record.
	target:SetAttribute("HomeBase", target:GetAttribute("BaseIndex"))
	target:SetAttribute("HomeSlot", target:GetAttribute("SlotIndex"))
	-- Grab it: lift the snack off its slot and weld it to his back.
	Bases.unparkSnack(target)
	target:SetAttribute("State", "carried")
	for _, part in ipairs(target:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	local body = target:FindFirstChild("Body")
	local torso = thief.model:FindFirstChild("Torso")
	if body and torso then
		local weld = Instance.new("Weld")
		weld.Name = "ThiefWeld"
		weld.Part0 = torso
		weld.Part1 = body
		weld.C0 = CFrame.new(0, 0.5, -1.2)
		weld.Parent = target
	end
	thief.carrying = target
	announceFn("The Snatcher grabbed " .. target:GetAttribute("CreatureName") .. "! Touch him to stop him!", Color3.fromRGB(255, 60, 60))
	-- Run for the exit with the prize.
	if walkTo(humanoid, root, EXIT_POINT, swing, function()
		return thief.stopped
	end) then
		if thief.carrying and thief.carrying.Parent then
			announceFn("The Snatcher escaped with " .. thief.carrying:GetAttribute("CreatureName") .. "!", Color3.fromRGB(255, 60, 60))
			thief.carrying:Destroy()
		end
	end
end

-- Spawn one thief at the plaza's edge and set his visit going.
function Thieves.spawnThief(state, announceFn)
	local model, humanoid, hipLeft, hipRight = buildThief()
	local spawnAt = Vector3.new(math.random(-70, 70), 1, -95)
	model:PivotTo(CFrame.new(spawnAt))
	model.Parent = game:GetService("Workspace")
	local thief = { model = model, humanoid = humanoid, hipLeft = hipLeft, hipRight = hipRight, carrying = nil, stopped = false }
	local root = model:WaitForChild("HumanoidRootPart")

	-- Touch him and he drops the snack and flees; click him and the same happens.
	local torso = model:WaitForChild("Torso")
	local stopped = false
	local function stopHim()
		if stopped or thief.stopped then
			return
		end
		stopped = true
		thief.stopped = true
		dropSnack(thief, thief.carrying)
		announceFn("You stopped the Snatcher! The snack is safe.", Color3.fromRGB(80, 220, 100))
		task.spawn(function()
			walkTo(humanoid, root, EXIT_POINT, nil)
			if model.Parent then
				model:Destroy()
			end
		end)
	end
	torso.Touched:Connect(function(hit)
		local character = hit.Parent
		local hitPlayer = character and Players:GetPlayerFromCharacter(character)
		if hitPlayer then
			stopHim()
		end
	end)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 24
	click.MouseClick:Connect(function()
		stopHim()
	end)
	click.Parent = torso

	task.spawn(function()
		runVisit(thief, humanoid, root, state, announceFn)
		task.wait(0.5)
		if model.Parent then
			model:Destroy()
		end
	end)
	return thief
end

-- Once a second, Game asks whether a thief should visit. He only comes when
-- some player owns snacks on an unlocked base.
function Thieves.tick(now, announceFn)
	if now < nextSpawnAt then
		return
	end
	nextSpawnAt = now + math.random(Config.THIEF_MIN_DELAY, Config.THIEF_MAX_DELAY)
	local candidates = {}
	for _, state in ipairs(Bases.allPlots()) do
		if state.owner and not Bases.isLocked(state, now) then
			local snacks = Bases.snacksOn(state)
			if #snacks >= Config.THIEF_MIN_SNACKS then
				table.insert(candidates, state)
			end
		end
	end
	if #candidates == 0 then
		return
	end
	local state = candidates[math.random(#candidates)]
	Thieves.spawnThief(state, announceFn)
end

-- Start the thief clock: the first visit comes 45 seconds after the server starts.
function Thieves.setup()
	nextSpawnAt = os.time() + 45
end

return Thieves
