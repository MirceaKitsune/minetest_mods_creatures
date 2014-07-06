creatures = {}

-- Determines whether two players or mobs are allies
function creatures:alliance(creature1, creature2)
	local creature1_teams = {}
	if creature1:get_luaentity() then
		creature1_teams = creature1:get_luaentity().teams
	elseif creature1:is_player() then
		local race = creatures:player_get(creature1)
		creature1_teams = creatures.player_def[race].teams
	end

	local creature2_teams = {}
	if creature2:get_luaentity() then
		creature2_teams = creature2:get_luaentity().teams
	elseif creature2:is_player() then
		local race = creatures:player_get(creature2)
		creature2_teams = creatures.player_def[race].teams
	end

	local common = 0
	for i, element1 in pairs(creature1_teams) do
		local element2 = creature2_teams[i]
		if element2 then
			common = common + (element1 * element2)
		end
	end
	common = math.min(1, math.max(-1, common))

	return common
end

-- Pipe the creature registration function into the player and mob api
function creatures:register_creature(name, def)
	creatures:register_mob(name, def)
	creatures:register_player(name, def)
end

-- Load files
dofile(minetest.get_modpath("creatures").."/api_players.lua")
dofile(minetest.get_modpath("creatures").."/api_mobs.lua")
dofile(minetest.get_modpath("creatures").."/logic_players.lua")
dofile(minetest.get_modpath("creatures").."/logic_mobs.lua")

-- Log mod
if minetest.setting_get("log_mods") then
	minetest.log("action", "creatures loaded")
end
