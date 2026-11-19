-- Steal a Snack: the 3D world.
-- Everything the player walks through is built here at runtime, from the plaza
-- and the Snackway conveyor to the four base plots, the trees, the lamps and the
-- big title sign by the spawn. build() returns the plots so Bases can own them.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local World = {}

local workspace = game:GetService("Workspace")

-- A plain anchored box. Every part of the world starts from this one helper.
local function box(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A ball part (tree tops, snack eyes, the pickle's friends).
local function ball(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- A text label that floats above a part and always faces the camera.
local function floatingLabel(name, adornee, text, textColor, size, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	gui.Parent = adornee
	return gui, label
end

-- The Snackway: the belt every snack walks, from the start arch to the chute.
local function buildConveyor(folder)
	-- The belt itself, a long dark slab the snacks walk on.
	box("Belt", Vector3.new(14, 1, 136), Vector3.new(0, 0.5, 0), Color3.fromRGB(70, 70, 80), Enum.Material.Slate, folder)
	-- Yellow rails keep the snacks (and the eye) on the belt.
	box("RailLeft", Vector3.new(0.6, 1.2, 136), Vector3.new(-7.3, 1.1, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, folder)
	box("RailRight", Vector3.new(0.6, 1.2, 136), Vector3.new(7.3, 1.1, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic, folder)
	-- Chevrons down the middle: the belt reads as moving even standing still.
	for z = -64, 64, 8 do
		box("Chevron", Vector3.new(6, 0.15, 1.6), Vector3.new(0, 1.05, z), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, folder)
	end
	-- The start arch: two posts and a board that names the belt.
	box("ArchLeft", Vector3.new(1.5, 10, 1.5), Vector3.new(-8, 5, -70), Color3.fromRGB(255, 150, 60), Enum.Material.SmoothPlastic, folder)
	box("ArchRight", Vector3.new(1.5, 10, 1.5), Vector3.new(8, 5, -70), Color3.fromRGB(255, 150, 60), Enum.Material.SmoothPlastic, folder)
	local archBoard = box("ArchBoard", Vector3.new(18, 3.5, 1), Vector3.new(0, 10.5, -70), Color3.fromRGB(40, 40, 55), Enum.Material.SmoothPlastic, folder)
	floatingLabel("ArchLabel", archBoard, "THE SNACKWAY", Color3.fromRGB(255, 220, 90), Vector2.new(320, 60), 0)
	-- The end chute: a dark pit the snacks tumble into when their walk is done.
	box("ChuteFrame", Vector3.new(16, 1.5, 6), Vector3.new(0, 0.75, 72), Color3.fromRGB(50, 50, 60), Enum.Material.Slate, folder)
	box("ChuteHole", Vector3.new(13, 0.4, 4), Vector3.new(0, 1.2, 72), Color3.fromRGB(5, 5, 10), Enum.Material.SmoothPlastic, folder)
end

-- One base plot: platform, eight snack pads, a sign pole and a lock barrier.
local function buildPlot(folder, plotDef, index)
	local center = plotDef.center
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot" .. index
	plotFolder.Parent = folder

	-- The platform, tinted so each base reads as its own from across the plaza.
	local platform = box("Platform", Vector3.new(26, 1, 26), Vector3.new(center.X, 0.5, center.Z), plotDef.color, Enum.Material.SmoothPlastic, plotFolder)
	platform.CanCollide = true
	-- A pale border so the plot's edge is obvious while running.
	box("Border", Vector3.new(26.6, 0.3, 26.6), Vector3.new(center.X, 0.15, center.Z), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, plotFolder).CanCollide = false

	-- Eight snack pads, two rows of four.
	local slots = {}
	for row = 1, 2 do
		for col = 1, 4 do
			local x = center.X - 9 + (col - 1) * 6
			local z = center.Z - 5 + (row - 1) * 10
			local pad = box("SnackPad", Vector3.new(4.5, 0.3, 4.5), Vector3.new(x, 1.15, z), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, plotFolder)
			pad.CanCollide = false
			table.insert(slots, Vector3.new(x, 1.3, z))
		end
	end

	-- The sign pole at the plot's back corner, with the owner's name floating above it.
	local pole = box("SignPole", Vector3.new(0.8, 9, 0.8), Vector3.new(center.X - 11, 5.5, center.Z - 11), Color3.fromRGB(90, 60, 30), Enum.Material.Wood, plotFolder)
	local _, ownerLabel = floatingLabel("OwnerSign", pole, plotDef.npcName .. "'s Base", Color3.fromRGB(255, 255, 255), Vector2.new(260, 44), 5.5)

	-- The lock barrier: a glowing wall across the plot's front edge, hidden until locked.
	local barrier = box("LockBarrier", Vector3.new(26, 7, 0.6), Vector3.new(center.X, 4.5, center.Z + 13), Color3.fromRGB(80, 160, 255), Enum.Material.Neon, plotFolder)
	barrier.Transparency = 0.75
	barrier.CanCollide = false
	barrier.Visible = false

	return {
		index = index,
		center = center,
		color = plotDef.color,
		npcName = plotDef.npcName,
		platform = platform,
		slots = slots,
		ownerLabel = ownerLabel,
		barrier = barrier,
	}
end

-- Trees, lamps, crates and the title sign: the plaza's dressing.
local function buildDecor(folder)
	-- Trees ring the plaza's edges.
	local treeSpots = {
		{ -30, -80 }, { -15, -82 }, { 15, -82 }, { 30, -80 },
		{ -80, -30 }, { -82, 0 }, { -80, 30 }, { 80, -30 },
		{ 82, 0 }, { 80, 30 }, { -30, 80 }, { 30, 80 },
	}
	for i, spot in ipairs(treeSpots) do
		local x, z = spot[1], spot[2]
		box("Trunk" .. i, Vector3.new(1.6, 6, 1.6), Vector3.new(x, 3, z), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, folder)
		ball("Leaves" .. i, 7, Vector3.new(x, 8.5, z), Color3.fromRGB(60, 170, 80), Enum.Material.SmoothPlastic, folder)
		ball("LeavesTop" .. i, 4.5, Vector3.new(x, 11.5, z), Color3.fromRGB(80, 200, 100), Enum.Material.SmoothPlastic, folder)
	end
	-- Lamp posts light the belt's sides.
	for i, z in ipairs({ -50, -20, 10, 40 }) do
		for _, x in ipairs({ -11, 11 }) do
			box("LampPole" .. i .. x, Vector3.new(0.5, 7, 0.5), Vector3.new(x, 3.5, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, folder)
			box("LampHead" .. i .. x, Vector3.new(1.6, 0.6, 1.6), Vector3.new(x, 7.2, z), Color3.fromRGB(255, 230, 150), Enum.Material.Neon, folder)
		end
	end
	-- Crates stacked by the belt, for the plaza to feel lived in.
	local crateSpots = { { -14, -30, 0 }, { -14, -30, 2.1 }, { 14, 20, 0 }, { 14, 20, 2.1 }, { 12, -55, 0 } }
	for i, spot in ipairs(crateSpots) do
		box("Crate" .. i, Vector3.new(2, 2, 2), Vector3.new(spot[1], spot[3] + 1, spot[2]), Color3.fromRGB(170, 120, 60), Enum.Material.Wood, folder)
	end
	-- The title sign by the spawn, so the game's name is in the first screenshot.
	-- Two posts hold the board up; the board itself carries the name.
	box("TitlePostL", Vector3.new(1, 8, 1), Vector3.new(-9, 4, 78), Color3.fromRGB(90, 60, 30), Enum.Material.Wood, folder)
	box("TitlePostR", Vector3.new(1, 8, 1), Vector3.new(9, 4, 78), Color3.fromRGB(90, 60, 30), Enum.Material.Wood, folder)
	local board = box("TitleBoard", Vector3.new(20, 5, 1), Vector3.new(0, 8.5, 78), Color3.fromRGB(255, 150, 60), Enum.Material.SmoothPlastic, folder)
	floatingLabel("TitleLabel", board, "STEAL A SNACK", Color3.fromRGB(255, 255, 255), Vector2.new(420, 80), 0)
end

-- Build the whole world and hand back the plots.
function World.build()
	local folder = Instance.new("Folder")
	folder.Name = "SnackWorld"
	folder.Parent = workspace

	buildConveyor(folder)
	local plots = {}
	for i, plotDef in ipairs(Config.PLOTS) do
		plots[i] = buildPlot(folder, plotDef, i)
	end
	buildDecor(folder)
	return plots
end

return World
