players = {}

-- Race table

local races = {}

function players:set_race (player, race)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	races[pname] = race
end

function players:get_race (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	return races[pname]
end

-- Ghost stuff

function players:set_ghost (player)
	players:set_race(player, nil)
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
		if not players:get_race(player) then
			local inv = player:get_inventory()
			inv:set_list("main", {})
		end
	end
end)

-- revert any node modified by a ghost
minetest.register_on_dignode(function(pos, oldnode, digger)
	if not players:get_race(digger) then
		minetest.set_node(pos, oldnode)
	end
end)

-- revert any node modified by a ghost
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if not players:get_race(placer) then
		minetest.set_node(pos, oldnode)
	end
end)

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function() players:set_ghost(player) end)
end)
