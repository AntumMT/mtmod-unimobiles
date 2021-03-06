--MCmobs v0.5
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes


--maikerumines throwing code
--arrow (weapon)
minetest.register_craftitem(":mobs:arrow", {
	description = "Arrow",
	inventory_image = "arrow.png",
})

minetest.register_node(":mobs:arrow_box", {
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- Shaft
			{-6.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
			--Spitze
			{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
			{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
			--Federn
			{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
			{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
			{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
			{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},

			{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
			{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
			{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
			{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17},
		}
	},
	tiles = {"throwing_arrow.png", "throwing_arrow.png", "throwing_arrow_back.png", "throwing_arrow_front.png", "throwing_arrow_2.png", "throwing_arrow.png"},
	groups = {not_in_creative_inventory=1},
})



local THROWING_ARROW_ENTITY={
	physical = false,
	timer=0,
	visual = "wielditem",
	visual_size = {x=0.1, y=0.1},
	textures = {"mobs:arrow_box"},
	--textures = {"esmobs:arrow.png"},
	velocity = 10,
	lastpos={},
	collisionbox = {0,0,0,0,0,0},
}


--ARROW CODE
THROWING_ARROW_ENTITY.on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

minetest.add_particle({
    pos = pos,
    vel = {x=0, y=0, z=0},
    acc = {x=0, y=0, z=0},
    expirationtime = .3,
    size = 1,
    collisiondetection = false,
    vertical = false,
    texture = "arrow_particle.png",
})

	if self.timer>0.2 then
		local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1.5)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "mobs:arrow_entity" and obj:get_luaentity().name ~= "__builtin:item" then
					local damage = 3
					minetest.sound_play("damage", {pos = pos})
					obj:punch(self.object, 1.0, {
						full_punch_interval=1.0,
						damage_groups={fleshy=damage},
					}, nil)
					self.object:remove()
				end
			else
				local damage = 3
				minetest.sound_play("damage", {pos = pos})
				obj:punch(self.object, 1.0, {
					full_punch_interval=1.0,
					damage_groups={fleshy=damage},
				}, nil)
				self.object:remove()
			end
		end
	end

	if self.lastpos.x~=nil then
		if node.name ~= "air" then
			minetest.sound_play("bowhit1", {pos = pos})
			--minetest.punch_node(pos)  --this crash game when bones for mobs used
			--minetest.add_item(self.lastpos, 'mobs:arrow')
			minetest.add_item(self.lastpos, 'throwing:arrow')--make for throwing compatibility
			self.object:remove()
		end
	end
	self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end


minetest.register_entity(":mobs:arrow_entity", THROWING_ARROW_ENTITY)


minetest.register_craft({
	output = 'mobs:arrow 4',
	recipe = {
		{'default:flint'},
		{'default:stick'},
		{'mobs:feather'},
	}
})


arrows = {
	{"mobs:arrow", "mobs:arrow_entity" },
}

local throwing_shoot_arrow = function(itemstack, player)
	for _,arrow in ipairs(arrows) do
		if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow[1] then
			if not minetest.settings:get_bool("creative_mode") then
				player:get_inventory():remove_item("main", arrow[1])
			end
			local playerpos = player:getpos()
			--local obj = minetest.env:add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow[2]) --current
			local obj = minetest.add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow[2])  --mc
			local dir = player:get_look_dir()
			obj:setvelocity({x=dir.x*22, y=dir.y*22, z=dir.z*22})
			obj:setacceleration({x=dir.x*-3, y=-10, z=dir.z*-3})
			obj:setyaw(player:get_look_yaw()+math.pi)
			minetest.sound_play("throwing_sound", {pos=playerpos})
			if obj:get_luaentity().player == "" then
				obj:get_luaentity().player = player
			end
			obj:get_luaentity().node = player:get_inventory():get_stack("main", 1):get_name()
			return true
		end
	end
	return false
end

minetest.register_tool(":mobs:bow_wood", {
	description = "Bow",
	inventory_image = "bow_standby.png",
    stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		if throwing_shoot_arrow(itemstack, user, pointed_thing) then
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:add_wear(65535/50)
			end
		end
		return itemstack
	end,
})

minetest.register_craft({
	output = 'mobs:bow_wood',
	recipe = {
		{'farming:cotton', 'default:stick', ''},
		{'farming:cotton', '',              'default:stick'},
		{'farming:cotton', 'default:stick', ''},
	}
})
--end maikerumine code

-- leather, feathers, etc.
minetest.register_craftitem(":mobs:feather", {
	description = "Feather",
	inventory_image = "mobs_feather.png",
})

if minetest.settings:get_bool("log_mods") then
	minetest.log("action", "MC mobs loaded")
end