package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local Balancing = include ("galaxy")
local PirateGen = include("pirategenerator")
local AsyncPirateGen = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include ("shiputility")
MissionUT = include("missionutility")
include("relations")
include("mission")
include("utility")
include("stringutility")
include("callable")

missionData.brief = "Hunt Pirate Fleet"%_t --missionData.brief shows on the left-hand side in the list.
missionData.title = "Hunt Pirate Fleet"%_t --missionData.title shows whenever the mission is accepted / accomplished / abandoned.

function getUpdateInterval()
    return 2
end

function initialize(giverId, x, y, reward, dangerValue)

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
	end
end

--Functional calls -- No reward / punishment needed here, since it is handled slightly differently.
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

end

function onTargetLocationLeft(x, y)
	local sender = missionData.stationTitle
    Player():sendChatMessage(sender, 0, missionData.failMessage)
	fail()
end

function onRestore()
	--Re-register necessary callbacks.
end

function updateServer(timeStep)
    updateMission(timeStep)

end

--Custom callbacks.

--Custom (but still 'functional') calls.

--getBulletin and getBulletin related values / calls, including messages, etc.
--No real need to allow these to be acessible outside this mod -- they are just mission descriptions that vary by the aggressive value of the faction and the danger value of the mission.
--Peaceful factions do not offer this particular mission.
--Aggressive description
local asDesc1 = [[]]
local asDesc3 = [[]]

--Moderate description
local msDesc1 = [[]]
local msDesc3 = [[]]

--Accomplish messages.
local winMsg = {
	[[]], --Moderate
	[[]], --Aggressive
}

--Failure messages.
local failMsg = {
	[[]], --Moderate
	[[]], --Aggressive
}

function fmtMissionDescription(aggroVal, dangerValue)
	local descriptionType = 1 --Moderate
	if aggroVal >= 0.5 then
		descriptionType = 2 --Aggressive
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
	end

	return description
end

function fmtFailMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	end

	return failMsg[msgType]
end

function fmtWinMessage(aggroVal)
	local msgType = 1 --Moderate
	if aggroVal >= 0.5 then
		msgType = 2 --Aggressive
	end
	
	return winMsg[msgType]
end

--Add this mission to bulletin boards of stations.
function getBulletin(station)
	--This is not offered from player / alliance stations. There's too much stuff that either breaks or doesn't make sense.
	local offeringFaction = Faction(station.factionIndex)
	if offeringFaction and (offeringFaction.isPlayer or offeringFaction.isAlliance) then return end
	--[[Script: Mission always starts with a number of damaged pirate ships that the player can easily clean up. 50% chance to add a light asteroid field if one isn't already present.
				Insurgents jump in after the initial wave of pirates are killed. 
	]]
	--print("running getBulletin")
	--Get coordinates first.
	local target = {}
	local x, y = Sector():getCoordinates()
	local giverInsideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
	target.x, target.y = MissionUT.getSector(x, y, 8, 22, false, false, false, false)
	
	if not target.x or not target.y or giverInsideBarrier ~= MissionUT.checkSectorInsideBarrier(target.x, target.y) then return end

	local fFaction = Faction(station.factionIndex)
	local dAggroValue = fFaction:getTrait("aggressive")	

    reward = {credits = 40000 * Balancing.GetSectorRichnessFactor(Sector():getCoordinates()), relations = 2000, paymentMessage = "Earned %1% for ...."}
	--I don't like how formulaic most Avorion missions are, so we'll throw in a hidden "danger value" to spice things up a bit.
	--[[Danger value effects:
		Please note that these effects are cumulative -- i.e. the mission listed difficulty / description will chdsange at danger level 6-7, but also at 8+ as well.
		- Danger Level 1-2:
			3 Waves after initial pirate wave + initial insurgent wave.
			Waves spawn after previous wave is destroyed.
			Provoking the insurgents adds 1 to the initial number of ships in the first wave.
		- Danger Level 3-5:
			+1 Wave (4 total)
		- Danger Level 6-7:
			+1 Wave (5 total)
			Waves spawn after previous wave is destroyed OR maximum time elapses.
			2nd wave of insurgents includes AWACS.
			Provoking the insurgents adds 1-2 to the initial number of ships in the first wave.
		- Danger Level 8:
			Last 2 waves include "defender" (*7 scale ships)
		- Danger Level 9:
			+1 Wave (6 total)
		- Danger Level 10:
			+1 Wave (7 total)
			Maximum time between wave spawn is shorter.
			Last 3 waves include Defenders. (Including the final wave -- see above note)
			All waves of insurgents includes AWACS. (Path 2 ONLY)
			Provoking the insurgents adds 2-3 to the initial number of ships in the first wave.
		- Danger Level [Any]
			Higher danger level = larger pirate classes included in waves + more pirate ships in general.
	]]
	local dangerValue = random():getInt(1, 10)
	
	--Notably, this one does NOT get a difficulty hint. They are trying to kill you. Why would they warn you?
	local description = fmtMissionDescription(dAggroValue, dangerValue)
	local sDifficulty = "Medium /*difficulty*/"%_t

    local bulletin =
    {
        brief = "..."%_t,
        description = description,
        difficulty = sDifficulty,
        reward = "$${reward}",
        script = "missions/piratehuntroute2.lua",
        arguments = {station.index, target.x, target.y, reward, dangerValue},
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