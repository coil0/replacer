
local function inform(name, msg)
	minetest.chat_send_player(name, msg)
	minetest.log("info", "[replacer] "..name..": "..msg)
end

local mode_infos = {
	single = "Replace single node.",
	field = "Left click: Replace field of nodes of a kind where a translucent node is in front of it. Right click: Replace field of air where no translucent node is behind the air.",
	crust = "Left click: Replace nodes which touch another one of its kind and a translucent node, e.g. air. Right click: Replace air nodes which touch the crust",
	chunkborder = "TODO",
}
local mode_colours = {
	single = "#ffffff",
	field = "#54FFAC",
	crust = "#9F6200",
	chunkborder = "#FF5457",
}
local modes = {"single", "field", "crust", "chunkborder"}
for n = 1,#modes do
	modes[modes[n]] = n
end

local function get_data(stack)
	local daten = stack:get_meta():get_string"replacer":split" " or {}
	return {
			name = daten[1] or "default:dirt",
			param1 = tonumber(daten[2]) or 0,
			param2 = tonumber(daten[3]) or 0
		},
		modes[daten[4]] and daten[4] or modes[1]
end

local function set_data(stack, node, mode)
	mode = mode or modes[1]
	local metadata = (node.name or "default:dirt") .. " "
		.. (node.param1 or 0) .. " "
		.. (node.param2 or 0) .. " "
		.. mode
	local meta = stack:get_meta()
	meta:set_string("replacer", metadata)
	meta:set_string("color", mode_colours[mode])
	return metadata
end

local replacer_form_name_modes = "replacer_replacer_mode_change"
local function get_form_modes(current_mode)
	-- TODO: possibly add the info here instead of as
	-- a chat message
	-- TODO: add close button for mobile users who possibly can't esc
	-- need feedback from mobile user to know if this is required
	local formspec = "size[3.9,2]"
		.. "label[0,0;Choose mode]"
		.. "button_exit[0.0,0.6;2,0.5;"
	if current_mode == modes[1] then
		formspec = formspec .. "_;< " .. modes[1] .. " >]"
	else
		formspec = formspec .. "mode;" .. modes[1] .. "]"
	end
	formspec = formspec .. "button_exit[1.9,0.6;2,0.5;"
	if current_mode == modes[2] then
		formspec = formspec .. "_;< " .. modes[2] .. " >]"
	else
		formspec = formspec .. "mode;" .. modes[2] .. "]"
	end
	formspec = formspec .. "button_exit[0.0,1.4;2,0.5;"
	if current_mode == modes[3] then
		formspec = formspec .. "_;< " .. modes[3] .. " >]"
	else
		formspec = formspec .. "mode;" .. modes[3] .. "]"
	end
	-- TODO: enable mode when it is available
	--[[
	formspec = formspec .. "button_exit[1.9,1.4;2,0.5;"
	if current_mode == modes[4] then
		formspec = formspec .. "_;< " .. modes[4] .. " >]"
	else
		formspec = formspec .. "mode;" .. modes[4] .. "]"
	end
	--]]
	return formspec
end

technic.register_power_tool("replacer:replacer", replacer.max_charge)

minetest.register_tool("replacer:replacer", {
	description = "Node replacement tool",
	inventory_image = "replacer_replacer.png",
	stack_max = 1, -- it has to store information - thus only one can be stacked
	wear_represents = "technic_RE_charge",
	on_refill = technic.refill_RE_charge,
	liquids_pointable = true, -- it is ok to painit in/with water
	--node_placement_prediction = nil,
	metadata = "default:dirt", -- default replacement: common dirt

	on_place = function(itemstack, placer, pt)
		if not placer
		or not pt then
			return
		end

		local keys = placer:get_player_control()
		local name = placer:get_player_name()
		local creative_enabled = creative.is_enabled_for(name)
		local has_give = minetest.check_player_privs(name, "give")

		-- is special-key held? (aka fast-key)
		if keys.aux1 then
			-- fetch current mode
			local node, mode = get_data(itemstack)
			-- increment and roll-over mode
			mode = modes[modes[mode]%#modes+1]
			-- update tool
			set_data(itemstack, node, mode)
			-- spam chat
			inform(name, "Mode changed to: " .. mode .. ": " .. mode_infos[mode])
			-- return changed tool
			return itemstack
		end

		-- If not holding sneak key, place node(s)
		if not keys.sneak then
			return replacer.replace(itemstack, placer, pt, true)
		end

		-- Select new node
		if pt.type ~= "node" then
			inform(name, "Error: No node selected.")
			return
		end

		local node, mode = get_data(itemstack)
		node = minetest.get_node_or_nil(pt.under) or node

		local inv = placer:get_inventory()
		if not (creative_enabled and has_give)
		and not inv:contains_item("main", node.name) then
			if creative_enabled then
				if minetest.get_item_group(node.name,
						"not_in_creative_inventory") > 0 then
					-- search for a drop available in creative inventory
					local found_item = false
					local drops = minetest.get_node_drops(node.name)
					for i = 1,#drops do
						local name = drops[i]
						if minetest.registered_nodes[name]
						and minetest.get_item_group(name,
								"not_in_creative_inventory") == 0 then
							node.name = name
							found_item = true
							break
						end
					end
					if not found_item then
						inform(name, "Node not in creative invenotry: \"" ..
							node.name .. "\".")
						return
					end
				end
			else
				local found_item = false
				-- search for a drop that the player has if possible
				local drops = minetest.get_node_drops(node.name)
				for i = 1,#drops do
					local name = drops[i]
					if minetest.registered_nodes[name]
					and inv:contains_item("main", name) then
						node.name = name
						found_item = true
						break
					end
				end
				if not found_item then
					-- search for a drop available in creative inventory
					-- that first configuring the replacer,
					-- then digging the nodes works
					for i = 1,#drops do
						local name = drops[i]
						if minetest.registered_nodes[name]
						and minetest.get_item_group(name,
								"not_in_creative_inventory") == 0 then
							node.name = name
							found_item = true
							break
						end
					end
				end
				if not found_item
				and not has_give then
					inform(name, "Item not in your inventory: '" .. node.name ..
						"'.")
					return
				end
			end
		end

		local metadata = set_data(itemstack, node, mode)

		inform(name, "Node replacement tool set to: '" .. metadata .. "'.")

		return itemstack --data changed
	end,

--	on_drop = func(itemstack, dropper, pos),

	on_use = function(...)
		-- Replace nodes
		return replacer.replace(...)
	end,
})

local function replacer_register_on_player_receive_fields(player, form_name, fields)
	-- no need to process if it's not expected formspec that triggered call
	if form_name ~= replacer_form_name_modes then return end
	-- no need to process if user closed formspec without changing mode
	if nil == fields.mode then return end

	-- collect some information
	local itemstack = player:get_wielded_item()
	local node, _ = get_data(itemstack)
	local mode = fields.mode
	local name = player:get_player_name()

	-- set metadata and itemstring
	set_data(itemstack, node, mode)
	-- update wielded item
	player:set_wielded_item(itemstack)
	-- spam players chat with information
	inform(name, "Mode changed to: " .. mode .. ": " .. mode_infos[mode])
end
-- listen to submitted fields
minetest.register_on_player_receive_fields(replacer_register_on_player_receive_fields)

local poshash = minetest.hash_node_position

-- cache results of minetest.get_node
local known_nodes = {}
local function get_node(pos)
	local i = poshash(pos)
	local node = known_nodes[i]
	if node then
		return node
	end
	node = minetest.get_node(pos)
	known_nodes[i] = node
	return node
end

-- tests if there's a node at pos which should be replaced
local function replaceable(pos, name, pname)
	return get_node(pos).name == name
		and not minetest.is_protected(pos, pname)
end

local trans_nodes = {}
local function node_translucent(name)
	if trans_nodes[name] ~= nil then
		return trans_nodes[name]
	end
	local data = minetest.registered_nodes[name]
	if data
	and (not data.drawtype or data.drawtype == "normal") then
		trans_nodes[name] = false
		return false
	end
	trans_nodes[name] = true
	return true
end

local function field_position(pos, data)
	return replaceable(pos, data.name, data.pname)
		and node_translucent(
			get_node(vector.add(data.above, pos)).name) ~= data.right_clicked
end

local offsets_touch = {
	{x=-1, y=0, z=0},
	{x=1, y=0, z=0},
	{x=0, y=-1, z=0},
	{x=0, y=1, z=0},
	{x=0, y=0, z=-1},
	{x=0, y=0, z=1},
}

-- 3x3x3 hollow cube
local offsets_hollowcube = {}
for x = -1,1 do
	for y = -1,1 do
		for z = -1,1 do
			local p = {x=x, y=y, z=z}
			if x ~= 0
			or y ~= 0
			or z ~= 0 then
				offsets_hollowcube[#offsets_hollowcube+1] = p
			end
		end
	end
end

-- To get the crust, first nodes near it need to be collected
local function crust_above_position(pos, data)
	-- test if the node at pos is a translucent node and not part of the crust
	local nd = get_node(pos).name
	if nd == data.name
	or not node_translucent(nd) then
		return false
	end
	-- test if a node of the crust is near pos
	for i = 1,26 do
		local p2 = offsets_hollowcube[i]
		if replaceable(vector.add(pos, p2), data.name, data.pname) then
			return true
		end
	end
	return false
end

-- used to get nodes the crust belongs to
local function crust_under_position(pos, data)
	if not replaceable(pos, data.name, data.pname) then
		return false
	end
	for i = 1,26 do
		local p2 = offsets_hollowcube[i]
		if data.aboves[poshash(vector.add(pos, p2))] then
			return true
		end
	end
	return false
end

-- extract the crust from the nodes the crust belongs to
local function reduce_crust_ps(data)
	local newps = {}
	local n = 0
	for i = 1,data.num do
		local p = data.ps[i]
		for i = 1,6 do
			local p2 = offsets_touch[i]
			if data.aboves[poshash(vector.add(p, p2))] then
				n = n+1
				newps[n] = p
				break
			end
		end
	end
	data.ps = newps
	data.num = n
end

-- gets the air nodes touching the crust
local function reduce_crust_above_ps(data)
	local newps = {}
	local n = 0
	for i = 1,data.num do
		local p = data.ps[i]
		if replaceable(p, "air", data.pname) then
			for i = 1,6 do
				local p2 = offsets_touch[i]
				if replaceable(vector.add(p, p2), data.name, data.pname) then
					n = n+1
					newps[n] = p
					break
				end
			end
		end
	end
	data.ps = newps
	data.num = n
end

local function mantle_position(pos, data)
	if not replaceable(pos, data.name, data.pname) then
		return false
	end
	for i = 1,6 do
		if get_node(vector.add(pos, offsets_touch[i])).name ~= data.name then
			return true
		end
	end
	return false
end

-- finds out positions using depth first search
local function get_ps(pos, fdata, adps, max)
	adps = adps or offsets_touch

	local tab = {}
	local num = 0

	local todo = {pos}
	local ti = 1

	local tab_avoid = {}

	while ti ~= 0 do
		local p = todo[ti]
		--~ todo[ti] = nil
		ti = ti-1

		for _,p2 in pairs(adps) do
			p2 = vector.add(p, p2)
			local i = poshash(p2)
			if not tab_avoid[i]
			and fdata.func(p2, fdata) then

				num = num+1
				tab[num] = p2

				ti = ti+1
				todo[ti] = p2

				tab_avoid[i] = true

				if max
				and num >= max then
					return false
				end
			end
		end
	end
	return tab, num, tab_avoid
end

-- replaces one node with another one and returns if it was successful
local function replace_single_node(pos, node, nnd, player, name, inv, creative)
	if minetest.is_protected(pos, name) then
		return false, "Protected at "..minetest.pos_to_string(pos)
	end

	if replacer.blacklist[node.name] then
		return false, "Replacing blocks of the type '" ..
			node.name ..
			"' is not allowed on this server. Replacement failed."
	end

	-- do not replace if there is nothing to be done
	if node.name == nnd.name then
		-- only the orientation was changed
		if node.param1 ~= nnd.param1
		or node.param2 ~= nnd.param2 then
			minetest.swap_node(pos, nnd)
		end
		return true
	end

	-- does the player carry at least one of the desired nodes with him?
	if not creative
	and not inv:contains_item("main", nnd.name) then
		return false, "You have no further '"..(nnd.name or "?")..
			"'. Replacement failed."
	end

	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return false, "Unknown node: "..node.name
	end
	local new_ndef = minetest.registered_nodes[nnd.name]
	if not new_ndef then
		return false, "Unknown node should be placed: "..nnd.name
	end

	-- dig the current node if needed
	if not ndef.buildable_to then
		-- give the player the item by simulating digging if possible
		ndef.on_dig(pos, node, player)
		-- test if digging worked
		local dug_node = minetest.get_node_or_nil(pos)
		if not dug_node
		or not minetest.registered_nodes[dug_node.name].buildable_to then
			return false, "Couldn't dig '".. node.name .."' properly."
		end
	end

	-- place the node similar to how a player does it
	-- (other than the pointed_thing)
	local newitem, succ = new_ndef.on_place(ItemStack(nnd.name), player,
		{type = "node", under = vector.new(pos), above = vector.new(pos)})
	if succ == false then
		return false, "Couldn't place '" .. nnd.name .. "'."
	end

	-- update inventory in survival mode
	if not creative then
		-- consume the item
		inv:remove_item("main", nnd.name.." 1")
		-- if placing the node didn't result in empty stack…
		if newitem:to_string() ~= "" then
			inv:add_item("main", newitem)
		end
	end

	-- test whether the placed node differs from the supposed node
	local placed_node = minetest.get_node(pos)
	if placed_node.name ~= nnd.name then
		-- Sometimes placing doesn't put the node but does something different
		-- e.g. when placing snow on snow with the snow mod
		return true
	end

	-- fix orientation if needed
	if placed_node.param1 ~= nnd.param1
	or placed_node.param2 ~= nnd.param2 then
		minetest.swap_node(pos, nnd)
	end

	return true
end

-- the function which happens when the replacer is used
function replacer.replace(itemstack, user, pt, right_clicked)
	if not user
	or not pt then
		return
	end

	local keys = user:get_player_control()
	local name = user:get_player_name()

	-- is special-key held? (aka fast-key)
	if keys.aux1 then
		-- fetch current mode
		local _, mode = get_data(itemstack)
		-- Show formspec to choose mode
		minetest.show_formspec(name, replacer_form_name_modes, get_form_modes(mode))
		-- return unchanged tool
		return itemstack
	end

	local creative_enabled = creative.is_enabled_for(name)

	if pt.type ~= "node" then
		inform(name, "Error: " .. pt.type .. " is not a node.")
		return
	end

	local pos = minetest.get_pointed_thing_position(pt, right_clicked)
	local node_toreplace = minetest.get_node_or_nil(pos)

	if not node_toreplace then
		inform(name, "Target node not yet loaded. Please wait a " ..
			"moment for the server to catch up.")
		return
	end

	local nnd, mode = get_data(itemstack)
	if node_toreplace.name == nnd.name
	and node_toreplace.param1 == nnd.param1
	and node_toreplace.param2 == nnd.param2 then
		inform(name, "Nothing to replace.")
		return
             end

	if replacer.blacklist[nnd.name] then
		minetest.chat_send_player(name, "Placing blocks of the type '" ..
			nnd.name ..
			"' with the replacer is not allowed on this server. " ..
			"Replacement failed.")
		return
	end

	if mode == "single" then
		local succ,err = replace_single_node(pos, node_toreplace, nnd, user,
			name, user:get_inventory(), creative_enabled)

		if not succ then
			inform(name, err)
		end
		return
	end

	local meta = minetest.deserialize(itemstack:get_metadata())
	if not meta or not meta.charge
	or meta.charge < replacer.charge_per_node then
		inform(name, "Not enough charge to use this mode.")
		return
	end

	local max_charge_to_use = math.min(meta.charge, replacer.max_charge)
	local max_nodes = math.floor(max_charge_to_use / replacer.charge_per_node)
	if max_nodes > replacer.max_nodes then
		max_nodes = replacer.max_nodes
	end

	local ps,num
	if mode == "field" then
		-- get connected positions for plane field replacing
		local pdif = vector.subtract(pt.above, pt.under)
		local adps,n = {},1
		for _,i in pairs{"x", "y", "z"} do
			if pdif[i] == 0 then
				for a = -1,1,2 do
					local p = {x=0, y=0, z=0}
					p[i] = a
					adps[n] = p
					n = n+1
				end
			end
		end
		if right_clicked then
			pdif = vector.multiply(pdif, -1)
		end
		right_clicked = right_clicked and true or false
		ps,num = get_ps(pos, {func=field_position, name=node_toreplace.name,
			pname=name, above=pdif, right_clicked=right_clicked}, adps, max_nodes)
	elseif mode == "crust" then
		local nodename_clicked = get_node(pt.under).name
		local aps,n,aboves = get_ps(pt.above, {func=crust_above_position,
			name=nodename_clicked, pname=name}, nil, max_nodes)
		if aps then
			if right_clicked then
				local data = {ps=aps, num=n, name=nodename_clicked, pname=name}
				reduce_crust_above_ps(data)
				ps,num = data.ps, data.num
			else
				ps,num = get_ps(pt.under, {func=crust_under_position,
					name=node_toreplace.name, pname=name, aboves=aboves},
					offsets_hollowcube, max_nodes)
				if ps then
					local data = {aboves=aboves, ps=ps, num=num}
					reduce_crust_ps(data)
					ps,num = data.ps, data.num
				end
			end
		end
	elseif mode == "chunkborder" then
		ps,num = get_ps(pos, {func=mantle_position, name=node_toreplace.name,
			pname=name}, nil, max_nodes)
	end

	-- reset known nodes table
	known_nodes = {}

	if not ps then
		inform(name, "Aborted, too many nodes detected.")
		return
	end

	local charge_needed = replacer.charge_per_node * num
	if meta.charge < charge_needed then
		inform(name, "Need " .. charge_needed .. " charge to replace " .. num .. " nodes.")
		return
	end

	-- set nodes
	local inv = user:get_inventory()
	for i = 1,num do
		local pos = ps[i]
		local succ,err = replace_single_node(pos, minetest.get_node(pos), nnd,
			user, name, inv, creative_enabled)
		if not succ then
			inform(name, err)
			if not technic.creative_mode then
				meta.charge = meta.charge - replacer.charge_per_node * i
				technic.set_RE_wear(itemstack, meta.charge, replacer.max_charge)
				itemstack:set_metadata(minetest.serialize(meta))
				return itemstack
			end
			return
		end
	end

	if not technic.creative_mode then
		meta.charge = meta.charge - replacer.charge_per_node * num
		technic.set_RE_wear(itemstack, meta.charge, replacer.max_charge)
		itemstack:set_metadata(minetest.serialize(meta))
		return itemstack
	end
	inform(name, num.." nodes replaced.")
end
