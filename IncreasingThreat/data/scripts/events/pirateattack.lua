local piratefaction = nil
local shipscalevalue = 0
local mostHatedPlayer = nil
local mostNotoriousPlayer = nil
local pirate_reserves = {}
local hateCountdownTimer = 0
local notorietyCountdownTimer = 0
--Some consts.
local pirate_taunts = {
    "Kill 'em all, let their god sort them out!",
    "HahahahAHAHAHAHAHA!",
    "Looks like a soft target. Let's take them out quickly.",
    "Maybe next time, you'll pay our generous fee for protection.",
    "Don't save any ammo! The salvage will pay for it.",
    "Surrender or be destroyed!",
    "Is this really worth our time? It doesn't matter, we'd be idiots to pass up on free loot."
}
local hatred_pirate_taunts = {
    "This is the end of the line for you, {Player}!",
    "We're going to kill you, {Player}!",
    "Hope you're ready to die, {Player}.",
    "There's {Player}! Die die die!",
    "You'll pay for what you did to our friends!",
    "You killed our comrades! Now, we'll kill you!",
    "You're dead! Your pathetic begging won't save you!"
}
local notorious_pirate_taunts = {
    "Look, it's {Player}! If we kill them, we'll be legends!",
    "{Player} has a huge bounty! Take them down now!",
    "{Player} doesn't look anything like the rumors! Let's vaporize them and we'll pretend we killed a monster!",
    "Well, well, well, it's {Player}! We'll bring your head to our boss and get a huge reward!",
    "We're missing one last skull to decorate our ship. Yours will do nicely.",
    "I've never understood why we have such a bad reputation with the likes of you out there."
}
local pirate_attackTypes = {
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 15, reward = 1.0, strength = 3.5, shipTable = {"Pirate", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 25, reward = 1.5, strength = 4.5, shipTable = {"Pirate", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 35, reward = 1.5, strength = 4.5, shipTable = {"Bandit", "Bandit", "Bandit", "Outlaw", "Outlaw"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 0, maxChallenge = 45, reward = 2.0, strength = 6, shipTable = {"Raider", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 10, maxChallenge = 55, reward = 2.0, strength = 7.5, shipTable = {"Pirate", "Pirate", "Pirate", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 20, maxChallenge = 65, reward = 2.5, strength = 7.5, shipTable = {"Raider", "Bandit", "Bandit", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 30, maxChallenge = 75, reward = 2.5, strength = 9, shipTable = {"Raider", "Bandit", "Bandit", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 40, maxChallenge = 85, reward = 3.0, strength = 10.5, shipTable = {"Raider", "Raider", "Bandit", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 50, maxChallenge = 95, reward = 3.0, strength = 10.5, shipTable = {"Ravager", "Bandit", "Pirate"}}, --end of +0.5 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 60, maxChallenge = 105, reward = 3.4, strength = 12, shipTable = {"Raider", "Marauder", "Disruptor", "Marauder", "Marauder"}}, --start of +0.4 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 70, maxChallenge = 115, reward = 3.4, strength = 12, shipTable = {"Ravager", "Marauder", "Disruptor"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 80, maxChallenge = 125, reward = 3.8, strength = 14, shipTable = {"Prowler", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 90, maxChallenge = 135, reward = 3.8, strength = 16, shipTable = {"Raider", "Raider", "Raider", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 100, maxChallenge = 145, reward = 4.2, strength = 16, shipTable = {"Prowler", "Marauder", "Disruptor"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 110, maxChallenge = 155, reward = 4.2, strength = 18, shipTable = {"Prowler", "Pirate", "Pirate", "Pirate", "Pirate"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 120, maxChallenge = 165, reward = 4.6, strength = 20, shipTable = {"Prowler", "Marauder", "Disruptor", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 130, maxChallenge = 175, reward = 4.6, strength = 20, shipTable = {"Ravager", "Ravager", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 140, maxChallenge = 185, reward = 5.0, strength = 22, shipTable = {"Prowler", "Ravager", "Bandit", "Bandit"}}, --end of +0.4 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 150, maxChallenge = 195, reward = 5.3, strength = 24, shipTable = {"Pillager", "Disruptor", "Marauder", "Marauder"}, dist = 150}, --start of +0.3 tier
    {minHatred = 0, minNotoriety = 0, minChallenge = 160, maxChallenge = 205, reward = 5.3, strength = 26, shipTable = {"Pillager", "Disruptor", "Marauder", "Raider"}, dist = 150},
    {minHatred = 0, minNotoriety = 0, minChallenge = 170, maxChallenge = 215, reward = 5.6, strength = 26, shipTable = {"Prowler", "Prowler", "Bandit", "Bandit"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 180, maxChallenge = -1, reward = 5.6, strength = 28, shipTable = {"Pillager", "Ravager", "Raider"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 190, maxChallenge = -1, reward = 5.9, strength = 30, shipTable = {"Ravager", "Ravager", "Ravager", "Disruptor", "Raider"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 200, maxChallenge = -1, reward = 5.9, strength = 30, shipTable = {"Prowler", "Prowler", "Marauder", "Marauder", "Marauder"}},
    {minHatred = 0, minNotoriety = 0, minChallenge = 210, maxChallenge = -1, reward = 6.2, strength = 32, shipTable = {"Demolisher", "Marauder", "Disruptor"}, dist = 150}
    --{type = "spcatk1", minHatred = 100, minNotoriety = 0, minChallenge = 50, maxChallenge = -1, reward = 0.1, strength = 40, specialFlags = {"multiplyRewardByHatred"}}
}
local hatred_attackTypes = {
    { maxHatred = 400, spawnTable = { "Marauder", "Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Raider", "Ravager", "Ravager" } },
    { maxHatred = 500, spawnTable = { "Marauder", "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Raider", "Ravager", "Ravager", "Ravager" } },
    { maxHatred = 600, spawnTable = { "Marauder", "Marauder", "Disruptor", "Disruptor", "Raider", "Scorcher", "Ravager", "Ravager", "Ravager", "Ravager" } },
    { maxHatred = 700, spawnTable = { "Disruptor", "Disruptor", "Raider", "Raider", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler" } },
    { maxHatred = 800, spawnTable = { "Disruptor", "Raider", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler", "Prowler", "Pillager" } },
    { maxHatred = 900, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Ravager", "Ravager", "Prowler", "Prowler", "Pillager", "Demolisher" } },
    { maxHatred = 1000, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Ravager", "Prowler", "Prowler", "Pillager", "Pillager", "Demolisher" } },
    { maxHatred = 1100, spawnTable = { "Scorcher", "Scorcher", "Scorcher", "Ravager", "Prowler", "Prowler", "Pillager", "Pillager", "Demolisher", "Demolisher" } },
    { maxHatred = -1, spawnTable = { "Scorcher", "Scorcher", "Prowler", "Prowler", "Pillager", "Pillager", "Pillager", "Demolisher", "Demolisher", "Demolisher" } }
}

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PirateAttack

if onServer() then
    local secure_IncreasingThreat = PirateAttack.secure
    function PirateAttack.secure()
        local secureResults = secure_IncreasingThreat()

        secureResults.piratefaction = piratefaction
        secureResults.shipscalevalue = shipscalevalue
        secureResults.mostHatedPlayer = mostHatedPlayer
        secureResults.mostNotoriousPlayer = mostNotoriousPlayer
        secureResults.hateCountdownTimer = hateCountdownTimer
        secureResults.notorietyCountdownTimer = notorietyCountdownTimer
        secureResults.pirate_reserves = pirate_reserves

        return secureResults
    end

    local restore_IncreasingThreat = PirateAttack.restore
    function PirateAttack.restore(data)
        restore_IncreasingThreat()

	    piratefaction = data.piratefaction
        shipscalevalue = data.shipscalevalue
        mostHatedPlayer = data.mostHatedPlayer
        mostNotoriousPlayer = data.mostNotoriousPlayer
        hateCountdownTimer = data.mostHatedPlayer
        notorietyCountdownTimer = data.notorietyCountdownTimer
        pirate_reserves = data.pirate_reserves
    end

    --This is the one section of the mod that I can't figure out how to retain compatibility with!
    local initialize_IncreasingThreat = PirateAttack.initialize
    function PirateAttack.initialize()
        print("intializing increasing threat pirate attack")
        local sector = Sector()

        -- no pirate attacks at the very edge of the galaxy
        local x, y = sector:getCoordinates()
        if length(vec2(x, y)) > 560 then
            print ("Too far out for pirate attacks.")
            terminate()
            return
        end

        if not EventUT.attackEventAllowed() then
            print("Attack event not allowed. Terminating event.")
            terminate()
            return
        end

        ships = {}
        participants = {}
        reward = 0
        reputation = 0

        local generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onPiratesGenerated)
        piratefaction = generator:getPirateFaction()
        local controller = Galaxy():getControllingFaction(x, y)
        if controller and controller.index == piratefaction.index then
            print("sector controlled by pirate faction. Terminating event.")
            terminate()
            return
        end

        --Get challenge rating of attack
        --Challenge rating of attack is calculated by adding notoriety + hatred of all players, then averaging it.
        local totalNotoriety = 0
        local totalHatred = 0
        local highestNotoriety = 0
        local highestHatred = 0
        local players = {Sector():getPlayers()}
        for _, p in pairs(players) do
            print("getting hatred / notoriety for player " .. p.name)
            local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index

            local xnotoriety = p:getValue("_increasingthreat_notoriety")
            local xhatred = p:getValue(hatredindex)
            if xnotoriety then
                totalNotoriety = totalNotoriety + xnotoriety
                if xnotoriety > highestNotoriety then
                    mostNotoriousPlayer = p
                    highestNotoriety = xnotoriety
                end
            end
            if xhatred then
                totalHatred = totalHatred + xhatred
                if xhatred > highestHatred then
                    mostHatedPlayer = p
                    highestHatred = xhatred
                end
            end
        end
        local challengeRating = (totalNotoriety + totalHatred) / (#players * 2)
        print("challenge rating of attack is " .. challengeRating)
        print("building attack pattern table")

        local possible_attackTypes = {}
        for _, at in pairs(pirate_attackTypes) do
            --all conditions have to be met.
            if challengeRating >= at.minChallenge and (challengeRating < at.maxChallenge or at.maxChallenge == -1) and highestHatred >= at.minHatred and highestNotoriety >= at.minNotoriety then
                table.insert(possible_attackTypes, at)
            end
        end
        --trigger a possible hatred / notoriety event based on hatred / notoriety. This will be based on the maximum hatred / notoriety value between all players.
        local hatredCooldown = piratefaction:getValue("_increasingthreat_hatred_cooldown") or 0
        local notorietyCooldown = piratefaction:getValue("_increasingthreat_notoriety_cooldown") or 0

        if highestHatred >= 300 and hatredCooldown <= 0 then
            print("cacluating hatred attack chance based on " .. highestHatred .. " hatred.")
            local chance = 20 + math.min(30, (highestHatred - 300) / 13.3) --Start @ 20% chance at 300. Caps at 50% chance @ 700.
            if math.random(100) < chance then
                print("execute hatred attack.")
                hatredCooldown = 2 --math.floor((math.min(1000, highestHatred) / 166) + math.min(1, math.random((highestHatred - 1000) / 400, (highestHatred - 1000) / 200)))
                print("setting hatred cooldown to " .. hatredCooldown)
                local hatredShips = (math.min(1000, highestHatred) / 50) + ((highestHatred - 1000) / 100)
                local hatredTable = PirateAttack.getHatredTable(highestHatred)
                for _ = 1, hatredShips do
                    table.insert(pirate_reserves, {ship = hatredTable[math.random(1, #hatredTable)], reason = "hate"})
                    print("added " .. #pirate_reserves .. " ships to reserve")
                end
            end
        else
            print("hatred attack has happened. decrementing cooldown from " .. hatredCooldown)
            hatredCooldown = hatredCooldown - 1
        end
        if highestNotoriety >= 60 and notorietyCooldown <= 0 then
            print("calculating notoriety attack chance based on " .. highestNotoriety .. " notoriety.")
            local chance = 20 + math.min(30, (highestNotoriety - 60) / 2.6) --Start @ 20% chance at 60. Caps at 50% chance @ 140.
            if math.random(100) < chance then
                print("execute notoriety attack.")
            end
        else
            print("notoriety attack has happened. decrementing cooldown from " .. notorietyCooldown)
            notorietyCooldown = notorietyCooldown - 1
        end

        piratefaction:setValue("_increasingthreat_hatred_cooldown", hatredCooldown)
        piratefaction:setValue("_increasingthreat_notoriety_cooldown", notorietyCooldown)

        local attackType = possible_attackTypes[math.random(#possible_attackTypes)]
        -- create attacking ships
        local distance = attackType.dist or 100

        generator:startBatch()

        local posCounter = 1
        local pirate_positions = generator:getStandardPositions(#attackType.shipTable, distance)
        for _, p in pairs(attackType.shipTable) do
            generator:createScaledPirateByName(p, pirate_positions[posCounter])
            posCounter = posCounter + 1
        end

        generator:endBatch()
        reward = attackType.reward
        shipscalevalue = attackType.strength
        if attackType.specialFlags then
            for _, p in pairs(attackType.specialFlags) do
                if p == "multiplyRewardByHatred" then
                    reward = attackType.reward * highestHatred
                end
            end
        end

        reputation = reward * 2000
        reward = reward * 10000 * Balancing_GetSectorRichnessFactor(sector:getCoordinates())

        sector:broadcastChatMessage("Server"%_t, 2, "Pirates are attacking the sector!"%_t)
        AlertAbsentPlayers(2, "Pirates are attacking sector \\s(%1%:%2%)!"%_t, sector:getCoordinates())
    end

    --Created callbacks.
    local onPiratesGenerated_IncreasingThreat = PirateAttack.onPiratesGenerated
    function PirateAttack.onPiratesGenerated(generated)
        onPiratesGenerated_IncreasingThreat(generated)

        local chance = math.random(100)
        if #generated > 1 or chance < 25 then
            Sector():broadcastChatMessage(leadShip, ChatMessageType.Chatter, pirate_taunts[math.random(#pirate_taunts)])
        end
    end

    function PirateAttack.onHatredPiratesGenerated(generated)
        onPiratesGenerated_IncreasingThreat(generated)

        local chance = math.random(100)
        if #generated > 1 or chance < 25 then
            Sector():broadcastChatMessage(leadShip, ChatMessageType.Chatter, hatred_pirate_taunts[math.random(#hatred_pirate_taunts)])
        end
    end

    function PirateAttack.onNotorietyPiratesGenerated(generated)
        onPiratesGenerated_IncreasingThreat(generated)

        local chance = math.random(100)
        if #generated > 1 or chance < 25 then
            Sector():broadcastChatMessage(leadShip, ChatMessageType.Chatter, notorious_pirate_taunts[math.random(#notorious_pirate_taunts)])
        end
    end

    --Update function.
    local update_IncreasingThreat = PirateAttack.update
    function PirateAttack.update(timeStep)
        if not PirateAttack.attackersGenerated then return end

        --Tick down both the hatred + notoriety timers if applicable.
        if hateCountdownTimer > 0 then
            hateCountdownTimer = hateCountdownTimer - timeStep
        end
        if notorietyCountdownTimer > 0 then
            notorietyCountdownTimer = notorietyCountdownTimer - timeStep
        end

        if tablelength(pirate_reserves) > 0 then
            if #ships < 20 then
                --start spawning in more ships. Don't spawn them more than 4-5 at a time.
                local shipsToSpawn = 20 - #ships
                if shipsToSpawn > 4 then
                    shipsToSpawn = math.random(4,5)
                end
                print("spawning" ..  shipsToSpawn .. "additional ships.")
                local generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onPiratesGenerated)
                piratefaction = generator:getPirateFaction()
                generator:startBatch()

                local pirate_positions = generator:getStandardPositions(shipsToSpawn, 150)
                for posidx = 1, shipsToSpawn do
                    if next(pirate_reserves) ~= nil then
                        local nextReserveShip = table.remove(pirate_reserves)
                        generator:createScaledPirateByName(nextReserveShip.ship, pirate_positions[posidx])
                        if ship then
                            print("ship made")
                        end
                        --
                        --if nextReserveShip.reason == "hate" then
                        --    ship:setValue("_increasingthreat_hatred_spawn", 1)
                        --else
                        --    ship:setValue("_increasingthreat_notoriety_spawn", 1)
                        --end
                    end
                end

                generator:endBatch()
            end
            return
        end

        update_IncreasingThreat(timeStep)
    end

    --Can't retain compatibility here, unfortunately. If we let the damage check run we will have to let the end check run
    --We don't necessarily want that due to the delay on hatred / notoriety-based events.
    local onShipDestroyed_IncreasingThreat = PirateAttack.onShipDestroyed
    function PirateAttack.onShipDestroyed(shipIndex)
        ships[shipIndex.string] = nil

        local ship = Entity(shipIndex)
        local damagers = {ship:getDamageContributors()}
        for _, damager in pairs(damagers) do
            local faction = Faction(damager)
            if faction and (faction.isPlayer or faction.isAlliance) then
                participants[damager] = damager
            end
        end

        -- if they're all destroyed, the event ends
        if tablelength(ships) == 0 and tablelength(pirate_reserves) == 0 then
            PirateAttack.endEvent()
        end
    end

    local endEvent_IncreasingThreat = PirateAttack.endEvent
    function PirateAttack.endEvent()
        --print("running increasing threat endEvent")
        --increase notoriety and hatred for all participants
        for _, participant in pairs(participants) do
            local participantFaction = Faction(participant)

            if participantFaction and participantFaction.isPlayer then
                --print("increasing notoriety / hatred for player " .. participantFaction.name)
                local notoriety = participantFaction:getValue("_increasingthreat_notoriety")
                if notoriety then
                    --print("notoriety value is " .. notoriety)
                    notoriety = notoriety + 1
                else
                    --print("notoriety is 0")
                    notoriety = 1
                end
                --print("new notoriety value is " .. notoriety)
                notoriety = math.min(notoriety, 200) --Notoriety is capped at 200.
                participantFaction:setValue("_increasingthreat_notoriety", notoriety)

                local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index
                local hatred = participantFaction:getValue(hatredindex)
                local hatredincrement = math.max((shipscalevalue / 3.5), 1.5)
                if hatred then
                    --print("hatred value is " .. hatred)
                    hatred = hatred + hatredincrement
                else
                    --print("hatred value is 0")
                    hatred = hatredincrement
                end
                --print("new hatred value is " .. hatred)
                participantFaction:setValue(hatredindex, hatred)

            end
        end

        --run vanilla endEvent
        --print("running vanilla endEvent")
        endEvent_IncreasingThreat()
    end

    function PirateAttack.getHatredTable(hatred)
        for _, p in pairs(hatred_attackTypes) do
            if hatred <= p.maxHatred then
                print("returning table of " .. p.maxHatred)
                return p.spawnTable
            end
        end
    end
end
