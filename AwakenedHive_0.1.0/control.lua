--control.lua

global.ANGER = 0
global.EXHAUSTION = 0
global.STAGE = 0
global.WAVES = 0
global.AIACTIVE = nil
global.GRACEPERIOD = 3600
global.REDUCEEVOAMOUNT = 0.00025
global.BASES = {}
global.CYCLELENGTH = 54000
global.MAXGROUPS = 40
global.MIGRATIONCHANCE = 0.0

--Init
script.on_init(function()
    global.CYCLELENGTH = settings.global["AwakenedHive-CycleLength"].value * 60 * 60
    global.GRACEPERIOD = settings.global["AwakenedHive-GracePeriod"].value * 60 * 60
    global.REDUCEEVOAMOUNT = (settings.global["AwakenedHive-ReduceEvolutionAmount"].value / 100) + game.forces.enemy.evolution_factor_by_killing_spawners
    if (settings.global["AwakenedHive-Difficulty"].value == "Easy") then global.MAXGROUPS = 5
    elseif (settings.global["AwakenedHive-Difficulty"].value == "Normal") then global.MAXGROUPS = 15
    elseif (settings.global["AwakenedHive-Difficulty"].value == "Hard") then global.MAXGROUPS = 25
    elseif (settings.global["AwakenedHive-Difficulty"].value == "Extreme") then global.MAXGROUPS = 50 end
end)

--"Sub-Cycle" function
script.on_nth_tick(3600, function()
    if (global.AIACTIVE ~= nil and global.AIACTIVE == true) then
        --Launch Attack
        FormGroups()
        --Point Increases/Decreases
        if (global.EXHAUSTION ~= 100) then
            global.EXHAUSTION = global.EXHAUSTION + 5
            if (global.EXHAUSTION > 100) then 
                global.EXHAUSTION = 100
                Notification(3)
            end
        end
        if (global.ANGER ~= 0) then
            global.ANGER = global.ANGER - 5
            if (global.ANGER < 0) then 
                global.ANGER = 0 
                Notification(2)
            end
        end
        --Reduce Wave Count
        global.WAVES = global.WAVES - 1
        --Reset the AIACTIVE bool
        if (global.WAVES == 0) then 
            global.AIACTIVE = false 
        end
    end
end)

--"Cycle" function
script.on_nth_tick(global.CYCLELENGTH, function()
    --GRACE PERIOD checker
    if (game.tick > 1 and game.tick > global.GRACEPERIOD and global.AIACTIVE == nil) then 
        global.AIACTIVE = false 
        game.surfaces[1].print("The Hive has Awakened!")
    end
    if (global.AIACTIVE ~= nil and global.AIACTIVE == false) then
        --BEFORE ATTACK ROLL
        CheckStage()
        --ATTACK ROLL
        local attackChance = (0.4 + (global.STAGE / 10) + (global.ANGER / 200) - (global.EXHAUSTION / 200))
        local attackRoll = math.random()
        --Case: Attack roll Success
        if (attackRoll < attackChance) then
            global.WAVES = math.ceil((math.random(1, 3)) + (global.STAGE) * ((global.ANGER / 100) + 1) * (1 - (global.EXHAUSTION / 200)))
            global.AIACTIVE = true
            Notification(5)
        --Case: Attack Roll Failed
        else
            if (global.EXHAUSTION ~= 0) then 
                global.EXHAUSTION = global.EXHAUSTION - (25 + (global.STAGE * 5))
                if (global.EXHAUSTION < 0) then 
                    global.EXHAUSTION = 0 
                    Notification(4)
                end
            end
        end
        --AFTER Attack Roll
        if (global.ANGER ~= 100) then
            global.ANGER = global.ANGER + (5 * global.STAGE)
            if (global.ANGER > 100) then 
                global.ANGER = 100 
                Notification(1)
            end
        end
    end
end)

--1Hour Function
script.on_nth_tick(216000, function()
    if (game.tick > 1 and settings.global["AwakenedHive-BiterCleanup"].value == true) then 
        game.forces["enemy"].kill_all_units()
        Notification(6)
    end
end)

--Function to run every time a spawner dies
script.on_event(defines.events.on_entity_died, function(event)
    if (event.entity.force == "enemy" and event.entity.type == "unit-spawner") then
        global.ANGER = global.ANGER + 2
        if (global.ANGER > 100) then 
            global.ANGER = 100 
            Notification(1)
        end
        --Reduce Evolution when spawner dies (Can be disabled by config)
        if (settings.global["AwakenedHive-ReduceEvolution"].value == true) then 
            game.forces.enemy.evolution_factor = game.forces.enemy.evolution_factor - global.REDUCEEVOAMOUNT
        end
        --Remove BASE from global if there are no more spawners in area
        local ThisZone = ZoneFromPos(event.entity.position)
        if (BaseExists(ThisZone) == true and game.surfaces[1].count_entities_filtered{area = {{ThisZone.x, ThisZone.y}, {ThisZone.x + 159, ThisZone.y + 159}}, type = "unit-spawner"} < 1) then 
            RemoveFromTable(global.BASES, ThisZone)
        end
    end
end)

--Function to run every time a spawner is created
script.on_event(defines.events.on_biter_base_built, function(event)
    local ThisZone = ZoneFromPos(event.entity.position)
    if (BaseExists(ThisZone) == false and game.surfaces[1].count_entities_filtered{area = {{ThisZone.x, ThisZone.y}, {ThisZone.x + 159, ThisZone.y + 159}}, type = "unit-spawner"} > 0) then
        table.insert(global.BASES, ThisZone)
    end
end)

--Function to run every time a chunk is generated
script.on_event(defines.events.on_chunk_generated, function(event)
    if (event.surface == game.surfaces[1]) then 
        local ThisZone = ZoneFromChunkPos(event.position)
        if (BaseExists(ThisZone) == false and game.surfaces[1].count_entities_filtered{area = {{ThisZone.x, ThisZone.y}, {ThisZone.x + 159, ThisZone.y + 159}}, type = "unit-spawner"} > 0) then
            table.insert(global.BASES, ThisZone)
        end
    end
end)

--Function for checking Stage
function CheckStage()
    local evoFactor = game.forces.enemy.evolution_factor
    if (evoFactor < 0.1) then global.STAGE = 0
    elseif (evoFactor >= 0.1 and evoFactor < 0.3) then global.STAGE = 1
    elseif (evoFactor >= 0.3 and evoFactor < 0.5) then global.STAGE = 2
    elseif (evoFactor >= 0.5 and evoFactor < 0.7) then global.STAGE = 3
    elseif (evoFactor >= 0.7 and evoFactor < 0.9) then global.Stage = 4
    elseif (evoFactor >= 0.9) then global.STAGE = 5
    end
end

--Function pertained to sending notifications
function Notification(type) 
    if (type ~= nil) then 
        local message = ""
        -- 1: AngerMax, 2: AngerMin, 3: ExhaustionMax, 4: ExhaustionMin, 5: AttackStart, 6: Cleanup
        if (type == 1) then message = "The Hive is Enraged!"
        elseif (type == 2) then message = "The Hive is Calming down!"
        elseif (type == 3) then message = "The Hive is Exhausted!"
        elseif (type == 4) then message = "The Hive is Invigorated!"
        elseif (type == 5) then message = "The Hive is Attacking!"
        elseif (type == 6) then message = "Cleanup Done!"
        end
        if (#game.players == 1) then 
            if (settings.get_player_settings(game.players[1])["AwakenedHive-Notifications"].value == true) then
                game.players[1].print(message)
            end
        elseif (#game.players > 1) then 
            for _,player in pairs(game.players) do
                if (settings.get_player_settings(player)["AwakenedHive-Notifications"].value == true) then 
                    player.print(message)
                end
            end
        end
    end
end

--Zone Position from Position
function ZoneFromPos(pos)
    if (pos ~= nil) then 
        local Zone = {x = math.floor(pos.x / 32), y = math.floor(pos.x / 32)}
        Zone.x = math.floor(Zone.x / 5)
        Zone.y = math.floor(Zone.y / 5)
        Zone.x = Zone.x * 160
        Zone.y = Zone.y * 160
        return Zone
    end
end

--Zone Position from from ChunkPosition
function ZoneFromChunkPos(pos)
    if (pos ~= nil) then
        local Zone = {x = pos.x, y = pos.y}
        Zone.x = math.floor(Zone.x / 5)
        Zone.y = math.floor(Zone.y / 5)
        Zone.x = Zone.x * 160
        Zone.y = Zone.y * 160
        return Zone
    end
end

--Function for checking if a Zone already is in BASES
function BaseExists(Zone)
    if (Zone ~= nil) then
        for i = 1, #global.BASES do 
            if (global.BASES[i].x == Zone.x and global.BASES[i].y == Zone.y) then 
                return true
            end
        end
        return false
    end
end

--Function for removing an element from a Table
function RemoveFromTable(tab, ele)
    if (tab ~= nil and ele ~= nil) then 
        local NewTab = tab
        if (TableContains(tab, ele)) then 
            for i = 1, #newTab do
                if (newTab[i] == ele) then
                    table.remove(newTab[i])
                    global.BASES = NewTab
                    break
                end
            end
        end
    end
end

--Function for Forming and sending Groups
function FormGroups()
    if (global.BASES ~= nil and #global.BASES > 1) then 
        local MaxGroups = global.MAXGROUPS
        if (MaxGroups > #global.BASES) then MaxGroups = #global.BASES end
        for i = 1, MaxGroups do 
            local ThisZone = global.BASES[i]
            local Units = game.surfaces[1].find_entities_filtered{area = {{ThisZone.x, ThisZone.y}, {ThisZone.x + 159, ThisZone.y + 159}}, force = "enemy", type = "unit"}
            if (Units ~= nil and #Units > 0) then 
                local GroupPos = Units[1].position
                local Group = game.surfaces[1].create_unit_group{position = GroupPos}
                for _, biter in ipairs(Units) do 
                    if (biter.valid == true and Group.valid == true) then Group.add_member(biter) end
                end
                if (Group.valid == true) then 
                    if (#game.players == 1) then 
                        local Target = game.surfaces[1].find_nearest_enemy{position = GroupPos, max_distance = 1000, force = "enemy"}
                        if (Target ~= nil) then 
                            Group.set_command{type=defines.command.attack_area, destination = Target, radius= 16, distraction=defines.distraction.by_anything} 
                        else
                            Group.set_command{type=defines.command.attack_area, destination = game.players[1].position, radius= 16, distraction=defines.distraction.by_anything} 
                        end
                    else
                        local Target = game.surfaces[1].find_nearest_enemy{position = GroupPos, max_distance = 1000, force = "enemy"}
                        if (Target ~= nil) then 
                            Group.set_command{type=defines.command.attack_area, destination = Target, radius= 16, distraction=defines.distraction.by_anything}
                        else
                            Target = math.random(1, #game.players)
                            Group.set_command{type=defines.command.attack_area, destination = game.players[Target].position, radius= 16, distraction=defines.distraction.by_anything} 
                        end
                    end
                end
            end
        end
    end
end