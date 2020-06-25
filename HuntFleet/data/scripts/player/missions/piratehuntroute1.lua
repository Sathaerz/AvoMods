package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local Balancing = include ("galaxy")
local PirateGen = include("pirategenerator")
local AsyncPirateGen = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include ("shiputility")
local SectorSpecifics = include ("sectorspecifics")
MissionUT = include("missionutility")
include("relations")
include("mission")
include("utility")
include("stringutility")
include("callable")

missionData.brief = "Hunt Pirate Fleet"%_t --missionData.brief shows on the left-hand side in the list.
missionData.title = "Hunt Pirate Fleet"%_t --missionData.title shows whenever the mission is accepted / accomplished / abandoned.

local templateBlacklist = {
	"sectors/asteroidshieldboss",
	"sectors/ancientgates",
	"sectors/containerfield",
	"sectors/cultists",
	"sectors/pirateasteroidfield",
	"sectors/piratefight",
	"sectors/piratestation",
	"sectors/resistancecell",
	"sectors/smugglerhideout",
	"sectors/wreckagefield",
	"sectors/xsotanasteroids",
	"sectors/xsotanbreeders",
	"sectors/xsotantransformed"
}

function getUpdateInterval()
    return 3
end

function initialize(giverId, x, y, reward, punishment, dangerValue)

    initMissionCallbacks()

    if onClient() then
        sync()
	else
		Player():registerCallback("onSectorLeft", "onSectorLeft")
    end
	
	if onServer() and not _restoring then
		local station = Entity(giverId)
		local offeringFaction = Faction(station.factionIndex)
		local dAggroValue = offeringFaction:getTrait("aggressive")	

		missionData.giver = station.id
		missionData.factionIndex = station.factionIndex
		missionData.location = {x = x, y = y}
		missionData.dangerValue = dangerValue
		missionData.stationName  = station.name
		missionData.stationTitle = station.translatedTitle
		missionData.reward = reward
		missionData.punishment = punishment
		--Get the description / accomplish + fail messages -- these are initialized here instead of being static values at the start of the script (unlike most other misisons)
		--this is because they depend on the aggressive trait value of the faction (and the random danger value), which is impossible to determine before the script has run.
		local bulletinDescription = fmtMissionDescription(dAggroValue, missionData.dangerValue)
		missionData.accomplishMessage = fmtWinMessage(dAggroValue)
		missionData.failMessage = fmtFailMessage(dAggroValue)
		--Variables used to keep various events from happening twice.
		missionData.firstGroupSpawned = false
		missionData.distressCallSent = false
		missionData.waveTauntSent = false
		--base # of waves.
		missionData.waveNumber = 1
		--wave timers.
		missionData.waveCooldownTimer = 0
		missionData.groupCooldownTimer = 0
		missionData.waveTimeoutTimer = 0
		local maxWaves = 3 + math.floor(dangerValue / 3)
		--base Wave configuration.
		local pirateWaveCt = { low=2, high=3 }
		local marauderWaveCt = { low=1, high=1 }
		local raiderWaveCt = { low=0, high=0 }
		local ravagerWaveCt = { low=0, high=0 }
		--adjust for danger level
		if dangerValue >= 4 then
			pirateWaveCt.low = pirateWaveCt.low + 1 
			pirateWaveCt.high = pirateWaveCt.high + 1 --3-4 Pirates
			marauderWaveCt.high = marauderWaveCt.high + 1 --1-2 Marauder
			raiderWaveCt.high = raiderWaveCt.high + 1 --0-1 Raider
		end
		if dangerValue >= 7 then
			pirateWaveCt.low = pirateWaveCt.low + 1
			pirateWaveCt.high = pirateWaveCt.high + 1 --4-5 Pirates
			marauderWaveCt.high = marauderWaveCt.high + 1 --1-3 Marauder
			raiderWaveCt.high = raiderWaveCt.high + 1 --0-2 Raider
			ravagerWaveCt.high = ravagerWaveCt.high + 1 --0-1 Ravager
		end
		if dangerValue >= 9 then
			pirateWaveCt.low = pirateWaveCt.low + 1
			pirateWaveCt.high = pirateWaveCt.high + 1 --5-6 Pirates
			marauderWaveCt.low = marauderWaveCt.low + 1 --2-3 Marauder
			raiderWaveCt.low = raiderWaveCt.low + 1 --1-2 Raider
		end
		if dangerValue == 10 then
			maxWaves = maxWaves + 1
			ravagerWaveCt.low = ravagerWaveCt.low + 1
			ravagerWaveCt.high = ravagerWaveCt.high + 1 --1-2 Ravager
		end
		--set mission data
		missionData.nextWaveComposition = {}
		missionData.maxWaves = maxWaves
		missionData.pirateWaveCt = pirateWaveCt
		missionData.marauderWaveCt = marauderWaveCt
		missionData.raiderWaveCt = raiderWaveCt
		missionData.ravagerWaveCt = ravagerWaveCt
		missionData.pillagerWaveCt = { low=0, high=0 }
		missionData.conquistadorWaveCt = { low=0, high=0 }
		missionData.extraShipCt = 0
		missionData.factionAttack = 0
		if dangerValue == 10 then
			--50/50 shot of faction attack.
			--TODO: Find faction that hates player -- must actually be a proper faction. No bottan smugglers attacking.
			missionData.factionAttack = random():getInt(0,1)
		end
		
		print("danger value is " .. missionData.dangerValue .. " -- max waves is " .. missionData.maxWaves)
	end
end

--mimics structuredmission.reward, becasue Mission doesn't have a similar function call. Pretty boilerplate but eh, what can you do.
function giveReward()
	if onClient() then return end

	local receiver = Player().craftFaction or Player()
	local r = missionData.reward
	
	if r.credits
		or r.iron
		or r.titanium
		or r.naonite
		or r.trinium
		or r.xanion
		or r.ogonite
		or r.avorion then
		
		receiver:receive(r.paymentMessage or "", r.credits or 0, r.iron or 0, r.titanium or 0, r.naonite or 0, r.trinium or 0, r.xanion or 0, r.ogonite or 0, r.avorion or 0)
	end
	
    if r.relations and missionData.factionIndex then
        local faction = Faction(missionData.factionIndex)
        if faction and faction.isAIFaction then
            changeRelations(receiver, faction, r.relations, r.relationChangeType, true, false)
        end
    end
end

function givePunishment()
	if onClient() then return end

    local punishee = Player().craftFaction or Player()
    local p = missionData.punishment

    if p.credits
        or p.iron
        or p.titanium
        or p.naonite
        or p.trinium
        or p.xanion
        or p.ogonite
        or p.avorion then

        punishee:pay(p.paymentMessage or "", 
					math.abs(p.credits or 0),
					math.abs(p.iron or 0),
					math.abs(p.titanium or 0),
					math.abs(p.naonite or 0),
					math.abs(p.trinium or 0),
					math.abs(p.xanion or 0),
					math.abs(p.ogonite or 0),
					math.abs(p.avorion or 0))
    end

	if p.relations and missionData.factionIndex then
        local faction = Faction(missionData.factionIndex)
        if faction and faction.isAIFaction then
            changeRelations(punishee, faction, -math.abs(p.relations), nil)
        end
    end
end

--Functional calls
function onSectorLeft(player, x, y)
	if missionData.location and missionData.location.x and missionData.location.y then
		if x == missionData.location.x and y == missionData.location.y then
			if onTargetLocationLeft then
				onTargetLocationLeft(x, y)
			end
		end
	end
end

function onTargetLocationEntered(x, y)
	--print("callback worked")
	local specs = SectorSpecifics()
	local serverSeed = Server().seed
	
	specs:initialize(x, y, serverSeed)
	print("sector is a " .. specs.generationTemplate.path .. " -- using.")
	
	if not missionData.firstGroupSpawned then
		createFirstPirateGroup(missionData.dangerValue)
		missionData.firstGroupSpawned = true
	end
end

function onTargetLocationLeft(x, y)
	local sender = missionData.stationTitle
    Player():sendChatMessage(sender, 0, missionData.failMessage)
	fail()
	givePunishment()
end

function onRestore()
	--Re-register necessary callbacks.
end

function updateServer(timeStep)
    updateMission(timeStep)

	local pirateCt = 0
	for _, ship in pairs({Sector():getEntitiesByFaction(PirateGen:getPirateFaction().index)}) do
		if ship.isShip then
			pirateCt = pirateCt + 1
		end
	end
	--print("pirate count is ... " .. pirateCt)
	
	--If we haven't yet sent the distress call, send it once there's only one ship left.
	if not missionData.distressCallSent and pirateCt == 1 then
		sendDistressCall()
		missionData.distressCallSent = true
	end
	
	--Tick down timers.
	if missionData.distressCallSent and missionData.waveNumber <= missionData.maxWaves then
		missionData.waveCooldownTimer = missionData.waveCooldownTimer - timeStep
	end
	if next(missionData.nextWaveComposition) ~= nil then
		missionData.groupCooldownTimer = missionData.groupCooldownTimer - timeStep
	end
	
	--I guess I could use a vanquish check / wave manager to do this, but I don't think the wave manager spawns in the sheer # of ships I want... so let's just custom-build it.
	if missionData.distressCallSent and pirateCt == 0 and missionData.waveCooldownTimer <= 0 and missionData.waveNumber <= missionData.maxWaves then
		missionData.waveTauntSent = false
		scheduleNextWave(missionData.dangerValue)
		print("scheduled wave " .. missionData.waveNumber .. " of " .. missionData.maxWaves .. " -- " .. #missionData.nextWaveComposition .. " ships in table")
		missionData.waveCooldownTimer = 15
		missionData.waveNumber = missionData.waveNumber + 1
	end
	if next(missionData.nextWaveComposition) ~= nil and missionData.groupCooldownTimer <= 0 then
		createNextGroup()
		missionData.groupCooldownTimer = 5
	end
end

--Custom callbacks.
function onCreateWave(generated)
	SpawnUtility.addEnemyBuffs(generated)
	local lastShipName = missionData.lastShipName
	for _, ship in pairs(generated) do
		if not missionData.waveTauntSent then
			local waveTaunts = {
				"Vengeance!",
				"You killed our friends! Now... we'll kill you!",
				"We'll tear you to pieces!",
				"Two wrongs probably won't be enough...",
				"Die! Die! Die!",
				"This is the end of the line for you!",
				"Blood for blood!",
				"Go down, you murderer!",
				"Remember the " .. lastShipName .. "!",
				"You'll pay for what you did to the " .. lastShipName .. "!"
			}
			Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, waveTaunts[random():getInt(1, #waveTaunts)])
			missionData.waveTauntSent = true
		end
		ship:addScript("deleteonplayersleft.lua")
	end
end

--Custom (but still 'functional') calls.
function HuntPirates_getEnemyPosition()
	local pos = random():getVector(-1000,1000)
	return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

function createFirstPirateGroup(dangerValue)
	--This prevents the first group of pirates from being different from the subsequent groups.
	PirateGen.pirateLevel = Balancing_GetPirateLevel(missionData.location.x, missionData.location.y)
	
	local outlawMin = 2
	local outlawMax = 3
	local banditMin = 1
	local banditMax = 2
	local pirateMin = 0
	local pirateMax = 0
	local pirateHPMin = .2
	local pirateHPMax = .5
	
	if dangerValue >= 6 then
		outlawMin = outlawMin + 1
		outlawMax = outlawMax + 2
		banditMin = banditMin + 1
		banditMax = banditMax + 1
		pirateHPMin = pirateHPMin + .1
		pirateHPMax = pirateHPMax + .1
	end
	if dangerValue == 10 then
		outlawMin = outlawMin + 1
		outlawMax = outlawMax + 2
		banditMax = banditMax + 1
		pirateMin = pirateMin + 1
		pirateMax = pirateMax + 2
		pirateHPMin = pirateHPMin + .1
		pirateHPMax = pirateHPMax + .1
	end
	
	local pirates = {}
	
	local outlawCt = random():getInt(outlawMin, outlawMax)
	for oidx=1,outlawCt,1 do
		outlaw = PirateGen.createScaledOutlaw(HuntPirates_getEnemyPosition())
		outlaw:addScript("deleteonplayersleft.lua")
		local duraFactor = random():getFloat(pirateHPMin, pirateHPMax)
		outlaw.durability = outlaw.maxDurability * duraFactor
		table.insert(pirates, outlaw)
	end
	
	local banditCt = random():getInt(banditMin, banditMax)
	for bidx=1,banditCt,1 do
		bandit = PirateGen.createScaledBandit(HuntPirates_getEnemyPosition())
		bandit:addScript("deleteonplayersleft.lua")
		local duraFactor = random():getFloat(pirateHPMin, pirateHPMax)
		bandit.durability = bandit.maxDurability * duraFactor
		table.insert(pirates, bandit)
	end
	
	if pirateMin > 0 then
		local pirateCt = random():getInt(pirateMin, pirateMax)
		for pidx=1,pirateCt,1 do
			pirate = PirateGen.createScaledPirate(HuntPirates_getEnemyPosition())
			pirate:addScript("deleteonplayersleft.lua")
			local duraFactor = random():getFloat(pirateHPMin, pirateHPMax)
			pirate.durability = pirate.maxDurability * duraFactor
			table.insert(pirates, pirate)
		end
	end
	
	if dangerLevel == 10 then
		SpawnUtility.addEnemyBuffs(pirates)
	end
end

function sendDistressCall()
	--print("sending distress call")
	local lastShip
	for _, ship in pairs({Sector():getEntitiesByFaction(PirateGen:getPirateFaction().index)}) do
		if ship.isShip then
			lastShip = ship
			missionData.lastShipName = ship.name
		end
	end
	local x, y = Sector():getCoordinates()
	local lastShipName = missionData.lastShipName
	
	local helpCalls = {
		"We're being slaughtered! Help us! HELP US!!!",
		"This is the " .. lastShipName .. "! Everyone else is dead! Send help!",
		"This is a distress call! Our position is (" .. x .. ":" .. y .. ")! We're under attack!",
		"Mayday! All other ships are destroyed and we're critically damaged! Mayday!",
		"Save us! Save us! Hurt them! Hurt them!",
		"Get the fleet on red alert! They'll kill us all!",
		"No!!! NO!!! Not like this! Not like this!"
	}
	Sector():broadcastChatMessage(lastShip, ChatMessageType.Chatter, helpCalls[random():getInt(1, #helpCalls)])
end

function scheduleNextWave(dangerValue)
	--Create the new wave using asyncPirateGen, then bump the # of each ship that appears. Consider spawning in 2 or 3 groups if there are too many enemies.
	local pirateCount = random():getInt(missionData.pirateWaveCt.low, missionData.pirateWaveCt.high)
	local marauderCount = random():getInt(missionData.marauderWaveCt.low, missionData.marauderWaveCt.high)
	local raiderCount = random():getInt(missionData.raiderWaveCt.low, missionData.raiderWaveCt.high)
	local ravagerCount = random():getInt(missionData.ravagerWaveCt.low, missionData.ravagerWaveCt.high)
	
	--make a table of ships to schedule, then shuffle it. Marauder / pirate count should always be above 0.
	local nextWaveComposition = {}
	
	for idx=1,pirateCount,1 do
		table.insert(nextWaveComposition, "pirate")
	end
	
	for idx=1,marauderCount,1 do
		table.insert(nextWaveComposition, "marauder")
	end
	
	if raiderCount > 0 then
		for idx=1,raiderCount,1 do
			table.insert(nextWaveComposition, "raider")
		end
	end

	if ravagerCount > 0 then
		for idx=1,ravagerCount,1 do
			table.insert(nextWaveComposition, "ravager")
		end
	end

	--Get randomly generated ships.
	if missionData.extraShipCt > 0 then
		local extraShipTable = {
			"pirate",
			"pirate",
			"pirate",
			"pirate",
			"marauder",
			"marauder",
			"raider",
			"raider",
			"ravager"
		}
		if dangerValue >= 7 then
			table.insert(extraShipTable, "marauder")
			table.insert(extraShipTable, "raider")
		end
		if dangerValue == 10 then
			table.insert(extraShipTable, "marauder")
			table.insert(extraShipTable, "raider")
			table.insert(extraShipTable, "ravager")
		end
		
		for idx=1,missionData.extraShipCt,1 do
			table.insert(nextWaveComposition, extraShipTable[random():getInt(1, #extraShipTable)])
		end
	end
	
	local pillagerCt = 2
	local pillagerWave = missionData.maxWaves - 2
	if dangerValue == 10 then
		pillagerCt = 3
		pillagerWave = missionData.maxWaves - 3
	end
	
	if dangerValue >= 8 and missionData.waveNumber >= pillagerWave then
		print("adding pillagers to table")
		for pidx=1,pillagerCt,1 do
			--This doesn't guarantee 2-3 pillagers, but that's okay.
			nextWaveComposition[random():getInt(1, #nextWaveComposition)] = "pillager"
		end
	end
	
	if dangerValue == 10 and missionData.waveNumber == missionData.maxWaves then
		print("adding conquistador to tables")
		table.insert(nextWaveComposition, "conquistador")
		table.insert(nextWaveComposition, "conquistador")
	end

	shuffle(random(), nextWaveComposition)
	
	missionData.nextWaveComposition = nextWaveComposition
	
	missionData.extraShipCt = missionData.extraShipCt + 1
end

function createNextGroup()
	--Get values for matrix.
	local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500
    local distance = 200
	local enemiesInGroup = random():getInt(3,4)
	
	local nWaveGen = AsyncPirateGen(nil, onCreateWave)
	nWaveGen:startBatch()
	print("nWaveGen pirateLevel is " .. Balancing_GetPirateLevel(missionData.location.x, missionData.location.y))
	
	local counter = 0
	
	for idx=1,enemiesInGroup,1 do
		if next(missionData.nextWaveComposition) ~= nil then
			local nextPirate = table.remove(missionData.nextWaveComposition)
			if nextPirate == "pirate" then
				nWaveGen:createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			elseif nextPirate == "marauder" then
				nWaveGen:createScaledMarauder(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			elseif nextPirate == "raider" then
				nWaveGen:createScaledRaider(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			elseif nextPirate == "ravager" then
				nWaveGen:createScaledRavager(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			elseif nextPirate == "pillager" then
				print("spawning pillager")
				nWaveGen:createScaledPillager(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			elseif nextPirate == "conquistador" then
				print("spawning conquistador")
				nWaveGen:createScaledConquistador(MatrixLookUpPosition(-dir, up, pos + right * distance * counter))
			end
			counter = counter + 1
		end
	end
	
	nWaveGen:endBatch()
end

--getBulletin and getBulletin related values / calls, including messages, etc.
--No real need to allow these to be acessible outside this mod -- they are just mission descriptions that vary by the aggressive value of the faction and the danger value of the mission.
--Peaceful description
local psDesc1 = [[]]
local psDesc2 = [[]]
local psDesc3 = [[]]

--Aggressive description
local asDesc1 = [[]]
local asDesc2 = [[]]
local asDesc3 = [[]]

--Moderate description
local msDesc1 = [[]]
local msDesc2 = [[]]
local msDesc3 = [[]]

--Accomplish messages.
local winMsg = {
	[[Moderate value win.]], --Moderate
	[[Aggressive value win.]], --Aggressive
	[[Peaceful value win.]] --Peaceful
}

--Failure messages.
local failMsg = {
	[[Moderate value lose.]], --Moderate
	[[Aggressive value lose.]], --Aggressive
	[[Peaceful value lose.]] --Peaceful
}

function fmtMissionDescription(aggroVal, dangerValue)
	local descriptionType = 1 --Moderate
	if aggroVal >= 0.5 then
		descriptionType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		descriptionType = 3 --Peaceful
	end
	
	local description = ""
	if descriptionType == 1 then
		description = msDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. msDesc2
		end
		description = description .. "\n\n" .. msDesc3
	elseif descriptionType == 2 then
		description = asDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. asDesc2
		end
		description = description .. "\n\n" .. asDesc3
	elseif descriptionType == 3 then
		description = psDesc1
		if dangerValue >= 6 then
			description = description .. "\n\n" .. psDesc2
		end
		description = description .. "\n\n" .. psDesc3
	end

	return description
end

function fmtFailMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		msgType = 3 --Peaceful
	end

	return failMsg[msgType]
end

function fmtWinMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	elseif aggroVal <= -0.5 then
		msgType = 3 --Peaceful
	end
	
	return winMsg[msgType]
end

--Add this mission to bulletin boards of stations.
function getBulletin(station)
	--This is not offered from player / alliance stations. There's too much stuff that either breaks or doesn't make sense.
	local offeringFaction = Faction(station.factionIndex)
	if offeringFaction and (offeringFaction.isPlayer or offeringFaction.isAlliance) then return end
	--[[Script: Mission always starts with a number of damaged pirate ships that the player can easily clean up. 50% chance to add a light asteroid field if one isn't already present.
				Mass waves of pirates jump in to avenge their fallen comrades once the player cleans them up.
	]]
	--print("running getBulletin")
	--Get coordinates first.
	local specs = SectorSpecifics()
	local x, y = Sector():getCoordinates()
	local giverInsideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
	local coords = specs.getShuffledCoordinates(random(), x, y, 8, 22)
	local serverSeed = Server().seed
	local target = nil

	for _, coord in pairs(coords) do
		local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)
		
		if offgrid and not blocked and giverInsideBarrier == MissionUT.checkSectorInsideBarrier(coord.x, coord.y) then
			specs:initialize(coord.x, coord.y, serverSeed) --This will actually add a template to the sector! Very handy.
			--There's a fairly long list of templates that we don't want to hit, but a large # are perfectly acceptable.
			local avoid = false
			for k, v in pairs(templateBlacklist) do
				if specs.generationTemplate.path == v then
					avoid = true
					break
				end
			end
			if not avoid then
				if not Galaxy():sectorExists(coord.x, coord.y) then
					target = coord
					break
				end
			end
		end
	end

	if not target then return end

	local fFaction = Faction(station.factionIndex)
	local dAggroValue = fFaction:getTrait("aggressive")	

    reward = {credits = 40000 * Balancing.GetSectorRichnessFactor(Sector():getCoordinates()), relations = 2000, paymentMessage = "Earned %1% for hunting down pirates."}
	punishment = {relations = reward.relations}
	--I don't like how formulaic most Avorion missions are, so we'll throw in a hidden "danger value" to spice things up a bit.
	--[[Danger value effects:
		Please note that these effects are cumulative -- i.e. the mission listed difficulty / description will change at danger level 6-7, but also at 8+ as well.
		- Danger Level 1-2:
			2-3 outlaws + 1-2 bandit in very first group (2-3 outlaw, 1-2 bandit -- 3-5 ships total), initial pirates have 20-50% HP
			3 Waves after initial pirate ships are destroyed.
			Base wave consists of 2-3 pirates, 1 marauder, 0 raiders, 0 ravagers. Subsequent waves consist of +1 randomly chosen class of ship per wave.
			Random ship spawn table is pirate x4, raider x2, marauder x2, ravager x1
			Waves spawn after previous wave is destroyed.
		- Danger Level 3:
			+1 Wave (4 total)
		- Danager Level 4-5:
			Initial wave consists of +1-1 (3-4) pirates, +0-1 (1-2) marauders, +0-1 (0-1) raiders.
		- Danger Level 6:
			+1-2 outlaw, + 1 bandit in very first group (3-5 outlaw, 2-3 bandit -- 5-8 ships total), initial pirates have 30-60% HP
			+1 Wave (5 total)
			Waves spawn after previous wave is destroyed OR maximum time elapses.
			Mission listed difficulty / description changed slightly to hint that this one is harder.
		- Danager Level 7:
			Base wave consists of +1-1 (4-5) pirates, +0-1 (1-3) marauders, +0-1 (0-2) raiders, +0-1 (0-1) ravagers.
			Random ship spawn table gains +1 raider / marauder entry.
		- Danger Level 8:
			Last 2 waves include Pillagers -- replace 2 ships in the table with pillagers.
		- Danger Level 9:
			+1 Wave (6 total)
			Base wave consists of +1-0 (2-3) marauders, +1-0 (1-2) raiders
			Random ship spawn table gains +1 ravager entry.
		- Danger Level 10:
			+1-2 outlaw, +0-1 bandit, +1-2 pirate in very first group (4-7 outlaw, 2-4 bandit, 1-2 pirate -- 7-13 ships total), initial pirates have 40-70% HP & Buffs
			+1 Wave (7 total)
			Base wave consists of +1-1 (1-2) ravagers.
			Random ship spawn table gains +1 raider / marauder / ravager entry.
			50% chance -- after defeating final wave, powerful faction ships appear if there is a faction nearby that hates you (bad or worse relations)
				If this happens, have a scout that vanishes after 40 seconds show up with the second to last wave.
				Include an AWACS (hyperspace jammer) with insurgents.
				Add a dialogue when the faction ships jump in. Provoking insurgents causes a 2nd group of them to spawn.
			Maximum time between wave spawn is shorter.
			Last 3 waves include Pillagers. (Including the final wave -- see above note)
			Last wave includes 2 Conquistadors. -- These are added to the table -- they do not replace a random ship.
		Danger Level [Any]
			Higher danger level = larger pirate classes included in waves + more pirate ships in general.
	]]
	--local dangerValue = random():getInt(1, 10)
	local dangerValue = 10
	
	local description = fmtMissionDescription(dAggroValue, dangerValue)
	local sDifficulty = "Medium /*difficulty*/"%_t
	if dangerValue >= 6 then
		sDifficulty = "Difficult /*difficulty*/"%_t
	end

    local bulletin =
    {
        brief = "Hunt Pirate Fleet"%_t,
        description = description,
        difficulty = sDifficulty,
        reward = "$${reward}",
        script = "missions/piratehuntroute1.lua",
        arguments = {station.index, target.x, target.y, reward, punishment, dangerValue},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward.credits)},
        msg = "Thank you. We have tracked the fleet to \\s(%i:%i). Please hunt them down.",
        entityTitle = station.title,
        entityTitleArgs = station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin
end