--[[
local getPossibleMissions_destroyproto = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions")
	local station = Entity()
    local stationTitle = station.title
	
	local scripts = getPossibleMissions_destroyproto()
	
	if stationTitle == "${faction} Headquarters" or stationTitle == "Military Outpost" then
		--print("adding 'destroy prototype' to table")
		table.insert(scripts, {path = "data/scripts/player/missions/piratehuntroute1.lua", prob = 0.8})
	end

	return scripts
end
]]

--Use this for debugging. It will guarantee that the bulletin generates on every station.
MissionBulletins.persistentBulletins = {"data/scripts/player/missions/piratehuntroute1.lua"}
function MissionBulletins.addPersistentBulletins()
	local entity = Entity()
	for _, v in pairs(MissionBulletins.persistentBulletins) do
		local ok, bulletin = run(v, "getBulletin", entity)
		if ok == 0 and bulletin then
			entity:invokeFunction("bulletinboard", "postBulletin", bulletin)
		end
	end
end

function MissionBulletins.updateServer(timeStep)
	MissionBulletins.updateBulletins(timeStep)
	MissionBulletins.addPersistentBulletins()
end