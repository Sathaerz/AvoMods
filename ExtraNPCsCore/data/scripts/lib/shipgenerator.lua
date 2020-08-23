function ShipGenerator.createHeavyDefender(faction, position)
    --You thought the defender was big? These guys are bigger.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 15.0

    local ship = ShipGenerator.createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    --Add two sets of turrets and give them x3 damage. This should result in roughly 50% more damage than a standard defender.
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)
    ship.damageMultiplier = ship.damageMultiplier * 3

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")
    ship:setValue("is_armed", 1)
    ship:setValue("is_defender", 1)
    ship:setValue("npc_chatter", true)

    ship:addScript("icon.lua", "data/textures/icons/pixel/defender.png")

    return ship
end

function ShipGenerator.createHeavyCarrier(faction, position)
    position = position or Matrix()
    fighters = fighters or 12 + random():getInt(6, 12) --at least 18, up to 24 fighters.

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 25.0

    local plan = PlanGenerator.makeCarrierPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.shieldDurability = ship.shieldMaxDurability
    --Add fighters.
    local hangar = Hangar(ship.index)
    hangar:addSquad("Alpha")
    hangar:addSquad("Beta")
    hangar:addSquad("Gamma")

    local numFighters = 0
    local generator = SectorFighterGenerator()
    generator.factionIndex = faction.index

    for squad = 0, 2 do
        local fighter = generator:generateArmed(faction:getHomeSectorCoordinates())
        for i = 1, 7 do
            hangar:addFighter(squad, fighter)

            numFighters = numFighters + 1
            if numFighters >= fighters then break end
        end

        if numFighters >= fighters then break end
    end

    ship.crew = ship.minCrew

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.minCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", 1)

    ship:addScript("icon.lua", "data/textures/icons/pixel/carrier.png")

    return ship
end

function ShipGenerator.createAWACS(faction, position)
    position = position or Matrix()
    --About twice as big as a standard blocker ship.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 2

    local ship = Sector():createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    --Add a standard armament and blocker equipment
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addBlockerEquipment(ship)

    ship.title = "AWACS Ship"%_t

    ship:setValue("is_armed", 1)
    ship:setValue("is_awacs", 1)
end

function ShipGenerator.createScout(faction, position)
    position = position or Matrix()
    --Scouts are tiny. Low mass = jump drives recharge quickly.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 0.5

    local ship = Sector():createShip(faction, position, volume)

    --Don't give scouts many turrets, or a damage multiplier.
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.title = "Scout Ship"%_t

    ship:setValue("is_armed", 1)
    ship:setValue("is_scout", 1)

    ship:addScript("icon.lua", "data/textures/icons/pixel/fighter.png")

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end