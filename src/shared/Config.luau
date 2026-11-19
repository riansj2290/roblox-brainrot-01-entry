-- Steal a Snack: shared game data.
-- Every creature, rarity and mutation the Snackway can spawn lives here, so the
-- server (spawning, prices, income) and the client (HUD colours and labels) read
-- the same numbers. Nothing here touches the network or the filesystem.

local Config = {}

-- The game hands every player this much snack cash when they join.
Config.START_MONEY = 100
-- How many snack slots one base holds.
Config.MAX_SLOTS = 8
-- How often a new snack walks onto the Snackway, in seconds.
Config.SPAWN_INTERVAL = 6
-- How many snacks may walk the Snackway at once.
Config.MAX_ON_BELT = 14
-- A stampede floods the belt this often, and lasts this long (seconds).
Config.STAMPEDE_EVERY = 150
Config.STAMPEDE_LENGTH = 30
Config.STAMPEDE_INTERVAL = 1.5
-- A thief only comes for a base that holds at least this many snacks.
Config.THIEF_MIN_SNACKS = 1
-- Seconds between one thief visit and the next (rolled fresh each time).
Config.THIEF_MIN_DELAY = 50
Config.THIEF_MAX_DELAY = 80
-- A locked base cannot be robbed for this long; then the lock needs this long to recharge.
Config.LOCK_DURATION = 20
Config.LOCK_COOLDOWN = 60
-- Rebirth cost: base times (rebirths + 1). Each rebirth adds this to the income multiplier.
Config.REBIRTH_BASE_COST = 10000
Config.REBIRTH_BONUS = 0.5
-- A snack stolen from a neighbour's base cannot be stolen again from that base for this long.
Config.STEAL_COOLDOWN = 30
-- How fast snacks walk the belt, studs per second, by rarity index.
Config.BELT_SPEED_BASE = 3
Config.BELT_SPEED_PER_RARITY = 0.5
-- The belt runs along Z from this end to that end.
Config.BELT_START_Z = -66
Config.BELT_END_Z = 66

-- Rarities, weakest first. weight is the share of spawns; color tints the snack's
-- name label; speedBonus is added to the belt speed.
Config.RARITIES = {
	{ name = "Common", weight = 45, color = Color3.fromRGB(220, 220, 220), speedBonus = 0 },
	{ name = "Rare", weight = 28, color = Color3.fromRGB(80, 160, 255), speedBonus = 0.5 },
	{ name = "Epic", weight = 15, color = Color3.fromRGB(180, 90, 255), speedBonus = 1 },
	{ name = "Legendary", weight = 8, color = Color3.fromRGB(255, 200, 40), speedBonus = 1.5 },
	{ name = "Mythic", weight = 3, color = Color3.fromRGB(255, 80, 120), speedBonus = 2 },
	{ name = "Secret", weight = 1, color = Color3.fromRGB(40, 40, 40), speedBonus = 2.5 },
}

-- Mutations roll on top of a spawn. incomeMult multiplies the snack's $/s,
-- costMult multiplies its buy price, and tint recolours its body.
Config.MUTATIONS = {
	{ name = "", weight = 80, incomeMult = 1, costMult = 1, tint = nil },
	{ name = "Golden", weight = 12, incomeMult = 2, costMult = 1.5, tint = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 6, incomeMult = 4, costMult = 2.5, tint = Color3.fromRGB(120, 230, 255) },
	{ name = "Rainbow", weight = 2, incomeMult = 8, costMult = 5, tint = nil },
}

-- The snack cast. cost is the buy price, income the $/s it earns on a base.
-- accessory picks the little part that makes each snack recognisable at a glance.
Config.CREATURES = {
	{ name = "Sir Fry", title = "a fry knight", rarity = 1, cost = 50, income = 2, body = Color3.fromRGB(255, 200, 60), accessory = "sword" },
	{ name = "Baron Bagel", title = "a bagel baron", rarity = 1, cost = 75, income = 3, body = Color3.fromRGB(210, 170, 110), accessory = "tophat" },
	{ name = "Count Croissant", title = "a croissant count", rarity = 2, cost = 300, income = 8, body = Color3.fromRGB(220, 160, 70), accessory = "cape" },
	{ name = "Duchess Donut", title = "a donut duchess", rarity = 2, cost = 450, income = 12, body = Color3.fromRGB(255, 150, 200), accessory = "crown" },
	{ name = "King Kebab", title = "a kebab king", rarity = 3, cost = 900, income = 25, body = Color3.fromRGB(180, 90, 50), accessory = "skewer" },
	{ name = "Queen Queso", title = "a cheese queen", rarity = 3, cost = 1200, income = 35, body = Color3.fromRGB(255, 230, 90), accessory = "crown" },
	{ name = "Emperor Espresso", title = "an espresso emperor", rarity = 4, cost = 3000, income = 90, body = Color3.fromRGB(90, 55, 30), accessory = "cape" },
	{ name = "The Forbidden Pickle", title = "a pickle you must not eat", rarity = 4, cost = 4500, income = 130, body = Color3.fromRGB(90, 180, 70), accessory = "halo" },
	{ name = "Grandma's Lasagna", title = "a sentient lasagna", rarity = 5, cost = 10000, income = 300, body = Color3.fromRGB(230, 110, 50), accessory = "glasses" },
	{ name = "The Last Slice", title = "the final pizza slice", rarity = 6, cost = 30000, income = 1000, body = Color3.fromRGB(255, 90, 60), accessory = "pepperoni" },
}

-- The four base plots around the plaza: centre, size, pad colour, and the name
-- the sign above it shows while nobody owns it.
Config.PLOTS = {
	{ center = Vector3.new(-45, 0, 45), color = Color3.fromRGB(80, 170, 255), npcName = "Baker Bot" },
	{ center = Vector3.new(45, 0, 45), color = Color3.fromRGB(255, 150, 80), npcName = "Chef Circuit" },
	{ center = Vector3.new(-45, 0, -45), color = Color3.fromRGB(150, 220, 90), npcName = "Auntie Algorithm" },
	{ center = Vector3.new(45, 0, -45), color = Color3.fromRGB(220, 120, 220), npcName = "Sir Simmer" },
}

-- Pick one entry from a weighted table (each entry carries a weight field).
-- Returns the entry and its index.
function Config.pickWeighted(entries)
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.weight
	end
	local roll = math.random() * total
	for i, entry in ipairs(entries) do
		roll -= entry.weight
		if roll <= 0 then
			return entry, i
		end
	end
	return entries[#entries], #entries
end

-- Roll a snack: a creature of a random rarity, plus a mutation.
function Config.rollSnack()
	local rarity, rarityIndex = Config.pickWeighted(Config.RARITIES)
	local pool = {}
	for _, creature in ipairs(Config.CREATURES) do
		if creature.rarity == rarityIndex then
			table.insert(pool, creature)
		end
	end
	local creature = pool[math.random(#pool)]
	local mutation = Config.pickWeighted(Config.MUTATIONS)
	return creature, rarity, mutation
end

-- The buy price of a creature with a mutation.
function Config.buyPrice(creature, mutation)
	return math.floor(creature.cost * mutation.costMult + 0.5)
end

-- The $/s a creature earns on a base, with a mutation.
function Config.earnRate(creature, mutation)
	return creature.income * mutation.incomeMult
end

-- The rarity record for a creature definition.
function Config.rarityOf(creature)
	return Config.RARITIES[creature.rarity]
end

return Config
