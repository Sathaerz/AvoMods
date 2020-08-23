function AsyncShipGenerator:createHeavyDefender(faction, position)
    position = position or Matrix()

    --You thought the defender was big? These guys are bigger.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 15.0

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_heavy_defender_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onHeavyDefenderPlanFinished(plan, generatorId, position, factionIndex)
    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

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

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end


function AsyncShipGenerator:createHeavyCarrier(faction, position)
    if not carriersPossible() then
        self:createHeavyDefender(faction, position)
        return
    end

    position = position or Matrix()
    fighters = fighters or 12 + random():getInt(6, 12) --at least 18, up to 24 fighters.

    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 25.0

    PlanGenerator.makeAsyncCarrierPlan("_ship_generator_on_heavy_carrier_plan_generated", {self.generatorId, position, faction.index, fighters}, faction, volume)
    self:shipCreationStarted()
end

local function onHeavyCarrierPlanFinished(plan, generatorId, position, factionIndex, fighters)
    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    ShipUtility.addCarrierEquipment(ship, fighters)

    --Add 1 set of military turrets
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.5

    ShipUtility.addArmedTurretsToCraft(ship, turrets)

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", 1)

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end


function AsyncShipGenerator:createAWACS(faction, position)
    position = position or Matrix()
    --About twice as big as a standard blocker ship.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 2

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_awacs_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onAWACSPlanFinished(plan, generatorId, position, factionIndex)
    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 2 + 3
    turrets = turrets + turrets * math.max(0, faction:getTrait("careful") or 0) * 0.25

    --Add a standard armament and blocker equipment
    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ShipUtility.addBlockerEquipment(ship)

    ship.title = "AWACS Ship"%_t

    ship:setValue("is_armed", 1)
    ship:setValue("is_awacs", 1)

    finalizeShip(ship)
    onShipCreated(generatorId, ship)
end


function AsyncShipGenerator:createScout(faction, position)
    position = position or Matrix()
    --Scouts are tiny. Low mass = jump drives recharge quickly.
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation() * 0.5

    PlanGenerator.makeAsyncShipPlan("_ship_generator_on_scout_plan_generated", {self.generatorId, position, faction.index}, faction, volume)
    self:shipCreationStarted()
end

local function onScoutPlanFinished(plan, generatorId, position, factionIndex)
    local self = generators[generatorId] or {}

    local faction = Faction(factionIndex)
    local ship = Sector():createShip(faction, "", plan, position, self.arrivalType)

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

local extraNPCsCore_new = new
local function new(namespace, onGeneratedCallback)
    local instance = extraNPCsCore_new(namespace, onGeneratedCallback)

    if namespace then
        namespace._ship_generator_on_heavy_defender_plan_generated = onHeavyDefenderPlanFinished
        namespace._ship_generator_on_heavy_carrier_plan_generated = onHeavyCarrierPlanFinished
        namespace._ship_generator_on_awacs_plan_generated = onAWACSPlanFinished
        namespace._ship_generator_on_scout_plan_generated = onScoutPlanFinished
    else
        _ship_generator_on_heavy_defender_plan_generated = onHeavyDefenderPlanFinished
        _ship_generator_on_heavy_carrier_plan_generated = onHeavyCarrierPlanFinished
        _ship_generator_on_awacs_plan_generated = onAWACSPlanFinished
        _ship_generator_on_scout_plan_generated = onScoutPlanFinished
    end

    return instance
end