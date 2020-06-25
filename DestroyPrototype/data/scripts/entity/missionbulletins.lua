local getPossibleMissions_destroyproto = MissionBulletins.getPossibleMissions
function MissionBulletins.getPossibleMissions()
	--print("getting possible missions")
	local station = Entity()
    local stationTitle = station.title
	
	local scripts = getPossibleMissions_destroyproto()
	
	if stationTitle == "Research Station" or stationTitle == "Military Outpost" or stationTitle == "Shipyard" then
		--print("adding 'destroy prototype' to table")
		table.insert(scripts, {path = "data/scripts/player/missions/destroyprototype.lua", prob = 0.1})
	end

	return scripts
end