--Get a number of positions for spawning pirates in the standard positions they spawn in for attacks, so we don't need to do it in our missions / events.
function PirateGenerator.getStandardPositions(positionCT, distance)
	--Just in case some joker passes us 5.25 positions.
	positionCT = math.floor(positionCT)
	distance = distance or 100

	local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
	local up = vec3(0, 1, 0)
	local right = normalize(cross(dir, up))
	local pos = dir * 1000

	local positionTable = {}

	for idx = 1, positionCT do
		local posMult
		if idx % 2 == 1 then
			posMult = (idx - 1) / 2 * -1
		else
			posMult = idx / 2
		end

		local posValue = pos
		if posMult ~= 0 then
			posValue = pos + right * distance * posMult
		end

		table.insert(positionTable, MatrixLookUpPosition(-dir, up, posValue))
	end

	return positionTable
end

function PirateGenerator.createScaledJammer(position)
	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 1.0 * scaling, "Jammer"%_T)
end

function PirateGenerator.createScaledScorcher(position)
	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 6.0 * scaling, "Scorcher"%_T)
end

function PirateGenerator.createScaledSinner(position)
	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 10.0 * scaling, "Sinner"%_T)
end

function PirateGenerator.createScaledProwler(position)
	local scaling = PirateGenerator.getScaling()
	return PirateGenerator.create(position, 12.0 * scaling, "Prowler"%_T)
end

function PirateGenerator.createScaledPillager(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 18.0 * scaling, "Pillager"%_T)
end

function PirateGenerator.createScaledDemolisher(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 28.0 * scaling, "Demolisher"%_T)
end

--Adds a very easy way to spawn any scaled pirate
function PirateGenerator.createScaledPirateByName(name, position)
	return PirateGenerator["createScaled" .. name](position)
end

function PirateGenerator.createJammer(position)
	return PirateGenerator.create(position, 1.0, "Jammer"%_T)
end

function PirateGenerator.createScorcher(position)
	return PirateGenerator.create(position, 6.0, "Scorcher"%_T)
end

function PirateGenerator.createSinner(position)
	return PirateGenerator.create(position, 10.0, "Sinner"%_T)
end

function PirateGenerator.createProwler(position)
	return PirateGenerator.create(position, 12.0, "Prowler"%_T)
end

function PirateGenerator.createPillager(position)
    return PirateGenerator.create(position, 18.0, "Pillager"%_T)
end

function PirateGenerator.createDemolisher(position)
    return PirateGenerator.create(position, 28.0, "Demolisher"%_T)
end

--Adds a very easy way to spawn any pirate
function PirateGenerator.createPirateByName(name, position)
	return PirateGenerator["create" .. name](position)
end

--[[
Adds custom equipment / loot for our custom NPC ships.
This will still add the standard equipment for other pirates (Outlaw, Bandit, Marauder, etc.)
]]
local extraNPCsCore_addPirateEquipment = PirateGenerator.addPirateEquipment
function PirateGenerator.addPirateEquipment(craft, title)
	local IsExtraNPC = false
	local ExtraNPCTitles = {
		"Pillager",
		"Demolisher",
		"Scorcher",
		"Prowler",
		"Sinner",
		"Jammer"
	}
	for _, p in pairs(ExtraNPCTitles) do
		if title == p then
			IsExtraNPC = true
		end
	end

	if IsExtraNPC then
		local turretDrops = 0

		local x, y = Sector():getCoordinates()
		local turretGenerator = SectorTurretGenerator()
		local rarities = turretGenerator:getSectorRarityDistribution(x, y)

		if title == "Jammer" then
			--A tiny ship that focuses on disrupting the player. Blocks hyperspace + anti-shield
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addBlockerEquipment(craft)

			craft:setValue("is_jammer", 1)
		elseif title == "Scorcher" then
			--A small ship that focuses on shield damage.
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addDisruptorEquipment(craft)

			craft:setValue("is_scorcher", 1)
		elseif title == "Sinner" then
			--A mid-sized ship with an odd / eclectic group of equipment + quantum jumps.
			ShipUtility.addDisruptorEquipment(craft)
			ShipUtility.addMilitaryEquipment(craft, 1, 0)
			ShipUtility.addTorpedoBoatEquipment(craft)

			craft:addScriptOnce("enemies/blinker.lua")

			Boarding(craft).boardable = false
			craft:setValue("is_sinner", 1)
		elseif title == "Prowler" then
			--A mid-sized combat ship armed similarly to a Marauder (no CIWS) - no special loot.
			local type = random():getInt(1, 2)

			if type == 1 then
				ShipUtility.addDisruptorEquipment(craft)
			elseif type == 2 then
				ShipUtility.addArtilleryEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1.25, 0)

			craft:setValue("is_prowler", 1)
		elseif title == "Pillager" then
			--A heavy combat ship armed similarly to a Raider - special loot similar to a raider.
			local type = random():getInt(1, 3)
			if type == 1 then
				ShipUtility.addDisruptorEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			elseif type == 3 then
				ShipUtility.addTorpedoBoatEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1.5, 0)

			turretDrops = 3
			rarities[-1] = 0 -- no petty turrets
			rarities[0] = 0 -- no common turrets
			rarities[1] = 0 -- no uncommon turrets

			craft:setValue("is_pillager", 1)
		elseif title == "Demolisher" then
			--An ultraheavy combat ship armed similarly to a Ravager - special loot similar to a ravager.
			local type = random():getInt(1, 2)
			if type == 1 then
				ShipUtility.addArtilleryEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1.75, 0)
			ShipUtility.addMilitaryEquipment(craft, 1.75, 0)

			--Yeah I don't think these guys are threatening enough even with all of that, so they also get a damage bonus.
			craft.damageMultiplier = 1.2

			turretDrops = 3
			rarities[-1] = 0 -- no petty turrets
			rarities[0] = 0 -- no common turrets
			rarities[1] = 0 -- no uncommon turrets
			rarities[2] = rarities[2] * 0.75 -- reduce rates for rare turrets slightly to have higher chance for the others
			craft:setValue("is_demolisher", 1)
		end

		if craft.numTurrets == 0 then
			ShipUtility.addMilitaryEquipment(craft, 1, 0)
		end

		turretGenerator.rarities = rarities
		for i = 1, turretDrops do
			Loot(craft):insert(InventoryTurret(turretGenerator:generate(x, y)))
		end

		ShipAI(craft.index):setAggressive()
		craft:setTitle("${toughness}"..title, {toughness = ""})
		craft.shieldDurability = craft.shieldMaxDurability

		craft:setValue("is_pirate", 1)
	else
		extraNPCsCore_addPirateEquipment(craft, title)
	end
end