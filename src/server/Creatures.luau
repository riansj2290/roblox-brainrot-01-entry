-- Steal a Snack: the snacks themselves.
-- A snack is an anchored Model built from parts: a body, a head, two eyes, one
-- accessory that makes it recognisable, and a floating tag with its name, rarity
-- and $/s. Snacks walk the Snackway on their own, wait to be bought, then sit on
-- a base slot and earn. This module builds them, walks them and parks them; the
-- money, the buying and the stealing live in Game.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Creatures = {}

local snacksFolder = nil

-- One anchored part of a snack model.
local function snackPart(name, size, offset, color, material, model)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- The little extra that tells one snack from another at a glance.
local function addAccessory(model, kind)
	if kind == "sword" then
		local blade = snackPart("Sword", Vector3.new(0.25, 2.6, 0.6), Vector3.new(1.9, 0.4, 0.6), Color3.fromRGB(220, 220, 230), Enum.Material.Metal, model)
		blade.CFrame = CFrame.new(1.9, 0.4, 0.6) * CFrame.Angles(0, 0, math.rad(-25))
		snackPart("SwordHilt", Vector3.new(0.8, 0.3, 0.3), Vector3.new(1.75, -0.6, 0.6), Color3.fromRGB(120, 80, 30), Enum.Material.Wood, model)
	elseif kind == "tophat" then
		snackPart("TopHat", Vector3.new(1.8, 1.4, 1.8), Vector3.new(0, 3.3, 0), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic, model)
		snackPart("TopHatBrim", Vector3.new(2.8, 0.25, 2.8), Vector3.new(0, 2.65, 0), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic, model)
	elseif kind == "cape" then
		local cape = snackPart("Cape", Vector3.new(2.6, 2.4, 0.25), Vector3.new(0, 0.2, -1.6), Color3.fromRGB(180, 30, 40), Enum.Material.SmoothPlastic, model)
		cape.CFrame = CFrame.new(0, 0.2, -1.6) * CFrame.Angles(math.rad(10), 0, 0)
	elseif kind == "crown" then
		snackPart("Crown", Vector3.new(1.6, 0.7, 1.6), Vector3.new(0, 3, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, model)
	elseif kind == "skewer" then
		local skewer = snackPart("Skewer", Vector3.new(0.2, 0.2, 4.4), Vector3.new(0, 0.6, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal, model)
		skewer.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(35), 0, 0)
	elseif kind == "halo" then
		snackPart("Halo", Vector3.new(2.4, 0.25, 2.4), Vector3.new(0, 3.9, 0), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, model)
	elseif kind == "glasses" then
		snackPart("LensLeft", Vector3.new(0.7, 0.7, 0.2), Vector3.new(-0.55, 2, 1.2), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
		snackPart("LensRight", Vector3.new(0.7, 0.7, 0.2), Vector3.new(0.55, 2, 1.2), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
		snackPart("GlassesBridge", Vector3.new(0.5, 0.15, 0.15), Vector3.new(0, 2, 1.2), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
	elseif kind == "pepperoni" then
		snackPart("Pepperoni1", Vector3.new(0.8, 0.2, 0.8), Vector3.new(-0.7, 0.3, 1.5), Color3.fromRGB(180, 30, 30), Enum.Material.SmoothPlastic, model)
		snackPart("Pepperoni2", Vector3.new(0.8, 0.2, 0.8), Vector3.new(0.7, -0.4, 1.5), Color3.fromRGB(180, 30, 30), Enum.Material.SmoothPlastic, model)
		snackPart("Pepperoni3", Vector3.new(0.8, 0.2, 0.8), Vector3.new(0, 0.9, 1.5), Color3.fromRGB(180, 30, 30), Enum.Material.SmoothPlastic, model)
	end
end

-- The floating tag: name, rarity and $/s, readable from across the plaza.
local function addTag(model, creature, rarity, mutation)
	local body = model:WaitForChild("Body")
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(170, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (mutation.name ~= "" and mutation.name .. " " or "") .. creature.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = gui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = rarity.name .. "  •  $" .. Config.earnRate(creature, mutation) .. "/s"
	rateLabel.TextColor3 = rarity.color
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextStrokeTransparency = 0.3
	rateLabel.Parent = gui
	gui.Parent = body
end

-- Build one snack model from a creature definition and a mutation.
function Creatures.buildSnack(creature, rarity, mutation)
	local model = Instance.new("Model")
	model.Name = creature.name

	local tint = mutation.tint or creature.body
	local material = Enum.Material.SmoothPlastic
	if mutation.name == "Diamond" then
		material = Enum.Material.Neon
	elseif mutation.name == "Rainbow" then
		material = Enum.Material.Neon
	end

	local body = snackPart("Body", Vector3.new(3, 2.2, 3), Vector3.new(0, 0, 0), tint, material, model)
	-- A slightly lighter head so the face reads from the front.
	local headColor = Color3.new(
		math.min(1, tint.R + 0.12),
		math.min(1, tint.G + 0.12),
		math.min(1, tint.B + 0.12)
	)
	snackPart("Head", Vector3.new(2.2, 1.6, 2.2), Vector3.new(0, 1.9, 0), headColor, material, model)
	-- Two eyes on the front (+Z is the way the snack walks).
	local eye = snackPart("EyeLeft", Vector3.new(0.45, 0.45, 0.45), Vector3.new(-0.55, 2, 1.15), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
	eye.Shape = Enum.PartType.Ball
	local eye2 = snackPart("EyeRight", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0.55, 2, 1.15), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
	eye2.Shape = Enum.PartType.Ball
	addAccessory(model, creature.accessory)

	model.PrimaryPart = body
	addTag(model, creature, rarity, mutation)

	model:SetAttribute("CreatureName", creature.name)
	model:SetAttribute("Rarity", rarity.name)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Cost", Config.buyPrice(creature, mutation))
	model:SetAttribute("Income", Config.earnRate(creature, mutation))
	model:SetAttribute("State", "belt")
	model:SetAttribute("OwnerName", "")
	model:SetAttribute("RarityIndex", creature.rarity)
	model:SetAttribute("Speed", Config.BELT_SPEED_BASE + Config.BELT_SPEED_PER_RARITY * (creature.rarity - 1) + rarity.speedBonus)
	model:SetAttribute("Phase", math.random() * math.pi * 2)

	-- The buy prompt lives on the body, so a player walks up and holds E.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = creature.name .. "  •  $" .. model:GetAttribute("Cost")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	return model
end

-- Where the belt snacks live, and the list of snacks still walking it.
function Creatures.setup()
	snacksFolder = Instance.new("Folder")
	snacksFolder.Name = "Snacks"
	snacksFolder.Parent = game:GetService("Workspace")
	Creatures.onBelt = {}
end

-- Roll a snack and put it at the start of the belt.
function Creatures.spawnSnack()
	local creature, rarity, mutation = Config.rollSnack()
	local snack = Creatures.buildSnack(creature, rarity, mutation)
	snack:PivotTo(CFrame.new(0, 2.2, Config.BELT_START_Z))
	snack.Parent = snacksFolder
	table.insert(Creatures.onBelt, snack)
	return snack
end

-- Put a specific snack on the belt (used for the guaranteed stampede rares).
function Creatures.spawnSpecific(creature, rarity, mutation)
	local snack = Creatures.buildSnack(creature, rarity, mutation)
	snack:PivotTo(CFrame.new(0, 2.2, Config.BELT_START_Z))
	snack.Parent = snacksFolder
	table.insert(Creatures.onBelt, snack)
	return snack
end

-- Walk every belt snack one step. Call from a Heartbeat loop with dt.
-- Snacks that reach the chute are destroyed.
function Creatures.updateBelt(dt)
	local now = os.clock()
	for i = #Creatures.onBelt, 1, -1 do
		local snack = Creatures.onBelt[i]
		if not snack.Parent then
			table.remove(Creatures.onBelt, i)
		else
			local speed = snack:GetAttribute("Speed")
			local pivot = snack:GetPivot()
			local z = pivot.Position.Z + speed * dt
			if z >= Config.BELT_END_Z then
				table.remove(Creatures.onBelt, i)
				snack:Destroy()
			else
				-- A gentle bob as it walks, and a rainbow snack cycles its hue.
				local phase = snack:GetAttribute("Phase")
				local y = 2.2 + math.sin(now * 4 + phase) * 0.15
				snack:PivotTo(CFrame.new(0, y, z))
				if snack:GetAttribute("Mutation") == "Rainbow" then
					local body = snack:FindFirstChild("Body")
					local head = snack:FindFirstChild("Head")
					if body and head then
						local hue = (now * 0.15 + phase) % 1
						body.Color = Color3.fromHSV(hue, 0.85, 1)
						head.Color = Color3.fromHSV(hue, 0.7, 1)
					end
				end
			end
		end
	end
end

-- Carry a snack from wherever it is to a base slot, with a little hop.
-- Calls done() once it lands.
function Creatures.carryToSlot(snack, slotPosition, done)
	snack:SetAttribute("State", "carried")
	local prompt = snack:FindFirstChild("Body") and snack.Body:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Enabled = false
	end
	local start = snack:GetPivot()
	local target = CFrame.new(slotPosition.X, slotPosition.Y + 0.9, slotPosition.Z)
	local steps = 24
	local step = 0
	task.spawn(function()
		while step < steps do
			step += 1
			local t = step / steps
			local pos = start.Position:Lerp(target.Position, t)
			pos = Vector3.new(pos.X, pos.Y + math.sin(t * math.pi) * 4, pos.Z)
			if snack.Parent then
				snack:PivotTo(CFrame.new(pos))
			else
				return
			end
			task.wait(0.05)
		end
		if snack.Parent then
			snack:PivotTo(target)
			snack:SetAttribute("State", "base")
		end
		if done then
			done()
		end
	end)
end

-- The buy prompt of a snack, if it has one.
function Creatures.getPrompt(snack)
	local body = snack:FindFirstChild("Body")
	if body then
		return body:FindFirstChild("BuyPrompt")
	end
	return nil
end

-- Reword a snack's prompt (buy, steal, or nothing at all).
function Creatures.setPrompt(snack, actionText, objectText, enabled)
	local prompt = Creatures.getPrompt(snack)
	if prompt then
		prompt.ActionText = actionText
		prompt.ObjectText = objectText
		prompt.Enabled = enabled
	end
end

return Creatures
