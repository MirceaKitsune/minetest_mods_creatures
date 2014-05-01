-- Race table

creatures.races = {}

function creatures:set_race (player, race)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	creatures.races[pname] = race
end

function creatures:get_race (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	return creatures.races[pname]
end

-- Creature registration - Players

creatures.players = {}

function creatures:register_player(name, def)
	creatures.players[name] = {}
	creatures.players[name].hp_max = def.hp_max
	creatures.players[name].armor = def.armor
	creatures.players[name].collisionbox = def.collisionbox
	creatures.players[name].visual = def.visual
	creatures.players[name].mesh = def.mesh
	creatures.players[name].textures = def.textures
	creatures.players[name].visual_size = def.visual_size
	creatures.players[name].drawtype = def.drawtype
	creatures.players[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.players[name].physics_speed = def.physics_speed
	creatures.players[name].physics_jump = def.physics_jump
	creatures.players[name].physics_gravity = def.physics_gravity
	creatures.players[name].inventory_main = def.inventory_main
	creatures.players[name].inventory_craft = def.inventory_craft
end

-- Ghost stuff

function creatures:set_ghost (player)
	creatures:set_race(player, nil)
	-- configure inventory
	local inv = player:get_inventory()
	inv:set_list("main", {})
	inv:set_list("craft", {})
	inv:set_size("main", 1)
	inv:set_size("craft", 1)
	player:set_inventory_formspec("size[1,1]")
	player:hud_set_hotbar_itemcount(1)
	player:hud_set_flags({hotbar = false, wielditem = false})
	-- configure properties
	player:set_hp(20)
	player:set_physics_override({gravity = 0.5})
	player:set_properties({
		collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
		textures = { "clear.png", "clear.png", },
		visual = "upright_sprite",
		is_visible = false,
		makes_footstep_sound = false,
	})
	-- configure visuals
	player:override_day_night_ratio(0.15)
	player:set_sky({r = 64, g = 0, b = 128}, "plain", {})
	player:hud_add({hud_elem_type = "image",
		text = "hud_ghost.png",
		name = "hud_ghost",
		scale = {x=-100, y=-100},
		position = {x=0, y=0},
		alignment = {x=1, y=1},
	})
end

-- prevent ghosts from having any items
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		if not creatures:get_race(player) then
			local inv = player:get_inventory()
			inv:set_list("main", {})
		end
	end
end)

-- revert any node modified by a ghost
minetest.register_on_dignode(function(pos, oldnode, digger)
	if not creatures:get_race(digger) then
		minetest.set_node(pos, oldnode)
	end
end)

-- revert any node modified by a ghost
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if not creatures:get_race(placer) then
		minetest.set_node(pos, oldnode)
	end
end)

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function() creatures:set_ghost(player) end)
end)
