-- Steal a Snack: the HUD.
-- A ScreenGui over the 3D world: snack cash and income up top, the lock and
-- rebirth buttons at the top right, the event banner under the money, and the
-- how-to-play hint at the bottom left. The server owns every number; this
-- script only reads the player's attributes and asks the server for rebirths
-- and locks. Money sits top-centre because Roblox's own menu buttons cover the
-- top-left corner of the play view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local announceEvent = remotes:WaitForChild("Announce")
local rebirthEvent = remotes:WaitForChild("RebirthRequest")
local lockEvent = remotes:WaitForChild("LockRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "SnackHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- $1,234 with commas, so big snack fortunes still read at a glance.
local function formatMoney(amount)
	local whole = math.floor(amount)
	local text = tostring(whole)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

local function makeLabel(name, parent, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	return label
end

local function makeButton(name, parent, position, size, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)
	button.BorderSizePixel = 2
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.Parent = parent
	return button
end

-- Money, top centre: cash, income and rebirths.
local moneyLabel = makeLabel("MoneyLabel", gui, UDim2.new(0.5, -160, 0, 8), UDim2.new(0, 320, 0, 44), 36, Color3.fromRGB(255, 220, 90))
moneyLabel.AnchorPoint = Vector2.new(0.5, 0)
moneyLabel.Text = "$100"
local incomeLabel = makeLabel("IncomeLabel", gui, UDim2.new(0.5, -160, 0, 54), UDim2.new(0, 320, 0, 26), 20, Color3.fromRGB(140, 230, 140))
incomeLabel.AnchorPoint = Vector2.new(0.5, 0)
incomeLabel.Text = "+$0/sec"
local rebirthLabel = makeLabel("RebirthLabel", gui, UDim2.new(0.5, -160, 0, 80), UDim2.new(0, 320, 0, 24), 18, Color3.fromRGB(200, 200, 255))
rebirthLabel.AnchorPoint = Vector2.new(0.5, 0)
rebirthLabel.Text = "Rebirths: 0  •  x1.0"

-- The event banner, under the money, hidden until the server has news.
local banner = makeLabel("Banner", gui, UDim2.new(0.5, -300, 0, 112), UDim2.new(0, 600, 0, 34), 24, Color3.fromRGB(255, 255, 255))
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Visible = false
local bannerUntil = 0
announceEvent.OnClientEvent:Connect(function(text, color)
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	banner.Visible = true
	bannerUntil = os.clock() + 4
end)

-- Lock and rebirth, top right.
local lockButton = makeButton("LockButton", gui, UDim2.new(1, -220, 0, 12), UDim2.new(0, 200, 0, 44), "Lock Base (20s)")
local rebirthButton = makeButton("RebirthButton", gui, UDim2.new(1, -220, 0, 64), UDim2.new(0, 200, 0, 44), "Rebirth")
lockButton.MouseButton1Click:Connect(function()
	lockEvent:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

-- How to play, bottom left.
local hint = makeLabel("Hint", gui, UDim2.new(0, 16, 1, -64), UDim2.new(0, 520, 0, 52), 17, Color3.fromRGB(255, 255, 255))
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.Text = "Hold E on a snack to buy it  •  Steal from neighbour bases\nTouch the Snatcher (or click him) to stop a theft!"
hint.Font = Enum.Font.SourceSans

-- Refresh every quarter second from the player's attributes.
local function refresh()
	local money = player:GetAttribute("Money") or 0
	local income = player:GetAttribute("Income") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	moneyLabel.Text = formatMoney(money)
	incomeLabel.Text = "+$" .. math.floor(income) .. "/sec"
	local multiplier = 1 + 0.5 * rebirths
	rebirthLabel.Text = "Rebirths: " .. rebirths .. "  •  x" .. multiplier
	local rebirthCost = 10000 * (rebirths + 1)
	rebirthButton.Text = "Rebirth — " .. formatMoney(rebirthCost)
	if money < rebirthCost then
		rebirthButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	else
		rebirthButton.TextColor3 = Color3.fromRGB(140, 230, 140)
	end
	local now = os.time()
	local lockUntil = player:GetAttribute("LockUntil") or 0
	local lockReadyAt = player:GetAttribute("LockReadyAt") or 0
	if now < lockUntil then
		lockButton.Text = "Locked! (" .. (lockUntil - now) .. "s)"
		lockButton.TextColor3 = Color3.fromRGB(120, 180, 255)
	elseif now < lockReadyAt then
		lockButton.Text = "Lock recharging (" .. (lockReadyAt - now) .. "s)"
		lockButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	else
		lockButton.Text = "Lock Base (20s)"
		lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	if banner.Visible and os.clock() > bannerUntil then
		banner.Visible = false
	end
end

gui.Parent = player:WaitForChild("PlayerGui")
task.spawn(function()
	while true do
		refresh()
		task.wait(0.25)
	end
end)
