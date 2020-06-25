function PirateGenerator.createScaledPillager(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 18.0 * scaling, "Pillager"%_T)
end

function PirateGenerator.createScaledConquistador(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 28.0 * scaling, "Conquistador"%_T)
end

function PirateGenerator.createPillager(position)
    return PirateGenerator.create(position, 18.0, "Pillager"%_T)
end

function PirateGenerator.createConquistador(position)
    return PirateGenerator.create(position, 28.0, "Conquistador"%_T)
end

local huntPirateFleet_addPirateEquipment = PirateGenerator.addPirateEquipment
function PirateGenerator.addPirateEquipment(craft, title)
	if title == "Pillager" or title == "Conquistador" then
		local turretDrops = 0

		local x, y = Sector():getCoordinates()
		local turretGenerator = SectorTurretGenerator()
		local rarities = turretGenerator:getSectorRarityDistribution(x, y)
		
		if title == "Pillager" then
			local type = random():getInt(1, 3)
			if type == 1 then
				ShipUtility.addDisruptorEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			elseif type == 3 then
				ShipUtility.addTorpedoBoatEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1, 0)
		
			turretDrops = 3
			rarities[-1] = 0 -- no petty turrets
			rarities[0] = 0 -- no common turrets
			rarities[1] = 0 -- no uncommon turrets
		elseif title == "Conquistador" then
			local type = random():getInt(1, 2)
			if type == 1 then
				ShipUtility.addArtilleryEquipment(craft)
			elseif type == 2 then
				ShipUtility.addPersecutorEquipment(craft)
			end
			ShipUtility.addMilitaryEquipment(craft, 1.5, 0)
			ShipUtility.addMilitaryEquipment(craft, 1.5, 0)
		
			turretDrops = 3
			rarities[-1] = 0 -- no petty turrets
			rarities[0] = 0 -- no common turrets
			rarities[1] = 0 -- no uncommon turrets
			rarities[2] = rarities[2] * 0.5 -- reduce rates for rare turrets to have higher chance for the others
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
		huntPirateFleet_addPirateEquipment(craft, title)
	end
end