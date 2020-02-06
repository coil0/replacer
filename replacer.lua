replacer.tool_name_basic = "replacer:replacer"
replacer.tool_name_technic = "replacer:replacer_technic"
replacer.tool_default_node = "default:dirt"

local r = replacer
local rb = replacer.blabla
local rp = replacer.patterns

function replacer.inform(name, msg)
	minetest.chat_send_player(name, msg)
	minetest.log("info", rb.log:format(name, msg))
end

replacer.modes = { "single", "field", "crust", "chunkborder" }
for n = 1, #r.modes do
	r.modes[r.modes[n]] = n
end

replacer.mode_infos = {}
replacer.mode_infos[r.modes[1]] = rb.mode_single
replacer.mode_infos[r.modes[2]] = rb.mode_field
replacer.mode_infos[r.modes[3]] = rb.mode_crust
replacer.mode_infos[r.modes[4]] = rb.mode_chunkborder

replacer.mode_colours = {}
replacer.mode_colours[r.modes[1]] = "#ffffff"
replacer.mode_colours[r.modes[2]] = "#54FFAC"
replacer.mode_colours[r.modes[3]] = "#9F6200"
replacer.mode_colours[r.modes[4]] = "#FF5457"

function replacer.get_data(stack)
	local data = stack:get_meta():get_string("replacer"):split(" ") or {}
	local node = {
		name = data[1] or r.tool_default_node,
		param1 = tonumber(data[2]) or 0,
		param2 = tonumber(data[3]) or 0
	}
	local mode = r.modes[1]
	if data[4] and r.modes[data[4]] then
		mode = data[4]
	end
	return node, mode
end

function replacer.set_data(stack, node, mode)
	mode = mode or r.modes[1]
	local metadata = (node.name or replacer.tool_default_node) .. " "
		.. tostring(node.param1 or 0) .. " "
		.. tostring(node.param2 or 0) .. " "
		.. mode
	local meta = stack:get_meta()
	meta:set_string("replacer", metadata)
	meta:set_string("color", r.mode_colours[mode])
	return metadata
end

replacer.form_name_modes = "replacer_replacer_mode_change"
function replacer.get_form_modes(current_mode)
	-- TODO: possibly add the info here instead of as
	-- a chat message
	local formspec = "size[3.9,2]"
		.. "label[0,0;Choose mode]"
		.. "button_exit[0.0,0.6;2,0.5;"
	if r.modes[1] == current_mode then
		formspec = formspec .. "_;< " .. r.modes[1] .. " >]"
	else
		formspec = formspec .. "mode;" .. r.modes[1] .. "]"
	end
	formspec = formspec .. "button_exit[1.9,0.6;2,0.5;"
	if r.modes[2] == current_mode then
		formspec = formspec .. "_;< " .. r.modes[2] .. " >]"
	else
		formspec = formspec .. "mode;" .. r.modes[2] .. "]"
	end
	formspec = formspec .. "button_exit[0.0,1.4;2,0.5;"
	if r.modes[3] == current_mode then
		formspec = formspec .. "_;< " .. r.modes[3] .. " >]"
	else
		formspec = formspec .. "mode;" .. r.modes[3] .. "]"
	end
	-- TODO: enable mode when it is available
	--[[
	formspec = formspec .. "button_exit[1.9,1.4;2,0.5;"
	if r.modes[4] == current_mode then
		formspec = formspec .. "_;< " .. r.modes[4] .. " >]"
	else
		formspec = formspec .. "mode;" .. r.modes[4] .. "]"
	end
	--]]
	return formspec
end -- get_form_modes

-- replaces one node with another one and returns if it was successful
function replacer.replace_single_node(pos, node, nnd, player, name, inv, creative)
	if minetest.is_protected(pos, name) then
		return false, rb.protected_at:format(minetest.pos_to_string(pos))
	end

	if replacer.blacklist[node.name] then
		return false, rb.blacklisted:format(node.name)
	end

	-- do not replace if there is nothing to be done
	if node.name == nnd.name then
		-- only the orientation was changed
		if (node.param1 ~= nnd.param1) or (node.param2 ~= nnd.param2) then
			minetest.swap_node(pos, nnd)
		end
		return true
	end

	-- does the player carry at least one of the desired nodes with him?
	if (not creative) and (not inv:contains_item("main", nnd.name)) then
		return false, rb.run_out:format(nnd.name or "?")
	end

	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return false, rb.attempt_unknown_replace:format(node.name)
	end
	local new_ndef = minetest.registered_nodes[nnd.name]
	if not new_ndef then
		return false, rb.attempt_unknown_place:format(nnd.name)
	end

	-- dig the current node if needed
	if not ndef.buildable_to then
		-- give the player the item by simulating digging if possible
		ndef.on_dig(pos, node, player)
		-- test if digging worked
		local dug_node = minetest.get_node_or_nil(pos)
		if (not dug_node) or
			(not minetest.registered_nodes[dug_node.name].buildable_to) then
			return false, rb.can_not_dig:format(node.name)
		end
	end

	-- place the node similar to how a player does it
	-- (other than the pointed_thing)
	local newitem, succ = new_ndef.on_place(ItemStack(nnd.name), player,
		{ type = "node", under = vector.new(pos), above = vector.new(pos) })
	if false == succ then
		return false, rb.can_not_place:format(nnd.name)
	end

	-- update inventory in survival mode
	if not creative then
		-- consume the item
		inv:remove_item("main", nnd.name .. " 1")
		-- if placing the node didn't result in empty stack…
		if "" ~= newitem:to_string() then
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
end -- replace_single_node

-- the function which happens when the replacer is used
function replacer.replace(itemstack, user, pt, right_clicked)
	if (not user) or (not pt) then
		return
	end
	
	local keys = user:get_player_control()
	local name = user:get_player_name()
	local creative_enabled = creative.is_enabled_for(name)
	local has_give = minetest.check_player_privs(name, "give")
	local is_technic = itemstack:get_name() == replacer.tool_name_technic
	local modes_are_available = is_technic or has_give or creative_enabled
	
	-- is special-key held? (aka fast-key)
	if keys.aux1 then
		if not modes_are_available then return itemstack end
		-- fetch current mode
		local _, mode = r.get_data(itemstack)
		-- Show formspec to choose mode
		minetest.show_formspec(name, r.form_name_modes, r.get_form_modes(mode))
		-- return unchanged tool
		return itemstack
	end

	if "node" ~= pt.type then
		r.inform(name, rb.not_a_node:format(pt.type))
		return
	end

	local pos = minetest.get_pointed_thing_position(pt, right_clicked)
	local node_toreplace = minetest.get_node_or_nil(pos)

	if not node_toreplace then
		r.inform(name, rb.wait_for_load)
		return
	end

	local nnd, mode = r.get_data(itemstack)
	if (node_toreplace.name == nnd.name)
		and (node_toreplace.param1 == nnd.param1)
		and (node_toreplace.param2 == nnd.param2) then
		r.inform(name, rb.nothing_to_replace)
		return
	end

	if replacer.blacklist[nnd.name] then
		minetest.chat_send_player(name, rb.blacklisted:format(nnd.name))
		return
	end

	if not modes_are_available then
		mode = r.modes[1]
	end
	
	if r.modes[1] == mode then
		-- single
		local succ, err = replacer.replace_single_node(pos, node_toreplace, nnd, user,
			name, user:get_inventory(), creative_enabled)
		if not succ then
			r.inform(name, err)
		end
		return
	end

	local max_nodes = replacer.max_nodes
	local meta = minetest.deserialize(itemstack:get_metadata())
	if replacer.has_technic_mod and (not (creative_enabled or has_give)) then
		if (not meta) or (not meta.charge) or (meta.charge < replacer.charge_per_node) then
			r.inform(name, rb.need_more_charge)
			return
		end

		local max_charge_to_use = math.min(meta.charge, replacer.max_charge)
		max_nodes = math.floor(max_charge_to_use / replacer.charge_per_node)
		if max_nodes > replacer.max_nodes then
			max_nodes = replacer.max_nodes
		end
	end

	local ps, num
	if r.modes[2] == mode then
		-- field
		-- get connected positions for plane field replacing
		local pdif = vector.subtract(pt.above, pt.under)
		local adps, n = {}, 1
		local p
		for _, i in pairs{ "x", "y", "z" } do
			if 0 == pdif[i] then
				for a = -1, 1, 2 do
					p = { x = 0, y = 0, z = 0 }
					p[i] = a
					adps[n] = p
					n = n + 1
				end
			end
		end
		if right_clicked then
			pdif = vector.multiply(pdif, -1)
		end
		right_clicked = (right_clicked and true) or false
		ps, num = rp.get_ps(pos, { func = rp.field_position, name = node_toreplace.name,
			pname = name, above = pdif, right_clicked = right_clicked }, adps, max_nodes)
	elseif r.modes[3] == mode then
		-- crust
		local nodename_clicked = rp.get_node(pt.under).name
		local aps, n, aboves = rp.get_ps(pt.above, { func = rp.crust_above_position,
			name = nodename_clicked, pname = name }, nil, max_nodes)
		if aps then
			if right_clicked then
				local data = { ps = aps, num = n, name = nodename_clicked, pname = name }
				rp.reduce_crust_above_ps(data)
				ps, num = data.ps, data.num
			else
				ps, num = rp.get_ps(pt.under, { func = rp.crust_under_position,
					name = node_toreplace.name, pname = name, aboves = aboves },
					rp.offsets_hollowcube, max_nodes)
				if ps then
					local data = { aboves = aboves, ps = ps, num = num }
					rp.reduce_crust_ps(data)
					ps, num = data.ps, data.num
				end
			end
		end
	elseif r.modes[4] == mode then
		-- chunkborder
		ps, num = rp.get_ps(pos, { func = rp.mantle_position, name = node_toreplace.name,
			pname = name }, nil, max_nodes)
	end

	-- reset known nodes table
	replacer.patterns.known_nodes = {}

	if not ps then
		r.inform(name, rb.too_many_nodes_detected)
		return
	end

	if 0 == num then
		local succ, err = r.replace_single_node(pos, node_toreplace, nnd, user,
			name, user:get_inventory(), creative_enabled)
		if not succ then
			r.inform(name, err)
		end
		return
	end

	local charge_needed = replacer.charge_per_node * num
	if replacer.has_technic_mod and (not (creative_enabled or has_give)) then
		if (meta.charge < charge_needed) then
			r.inform(name, rb.charge_required:format(charge_needed, num))
			return
		end
	end

	-- set nodes
	local inv = user:get_inventory()
	for i = 1, num do
		local pos = ps[i]
		local succ, err = r.replace_single_node(pos, minetest.get_node(pos), nnd,
			user, name, inv, creative_enabled)
		if not succ then
			r.inform(name, err)
			if replacer.has_technic_mod and (not technic.creative_mode) then
				if not (creative_enabled or has_give) then
					meta.charge = meta.charge - replacer.charge_per_node * i
					technic.set_RE_wear(itemstack, meta.charge, replacer.max_charge)
					itemstack:set_metadata(minetest.serialize(meta))
					return itemstack
				end
			end
			return
		end
	end

	if replacer.has_technic_mod and (not technic.creative_mode) then
		if not (creative_enabled or has_give) then
			meta.charge = meta.charge - charge_needed
			technic.set_RE_wear(itemstack, meta.charge, replacer.max_charge)
			itemstack:set_metadata(minetest.serialize(meta))
			return itemstack
		end
	end
	r.inform(name, rb.count_replaced:format(num))
end -- replacer.replace

-- right-click with tool -> place set node
-- special+right-click -> cycle mode (if tool/privs permit)
-- sneak+right-click -> set node
function replacer.common_on_place(itemstack, placer, pt)
	if (not placer)	or (not pt) then
		return
	end

	local keys = placer:get_player_control()
	local name = placer:get_player_name()
	local creative_enabled = creative.is_enabled_for(name)
	local has_give = minetest.check_player_privs(name, "give")
	local is_technic = itemstack:get_name() == replacer.tool_name_technic
	local modes_are_available = is_technic or has_give or creative_enabled

	-- is special-key held? (aka fast-key)
	if keys.aux1 then
		-- don't want anybody to think that special+rc = place
		if not modes_are_available then return end
		-- fetch current mode
		local node, mode = r.get_data(itemstack)
		-- increment and roll-over mode
		mode = r.modes[r.modes[mode] % #r.modes + 1]
		-- update tool
		r.set_data(itemstack, node, mode)
		-- spam chat
		r.inform(name, rb.mode_changed:format(mode, r.mode_infos[mode]))
		-- return changed tool
		return itemstack
	end

	-- If not holding sneak key, place node(s)
	if not keys.sneak then
		return replacer.replace(itemstack, placer, pt, true)
	end

	-- Select new node
	if pt.type ~= "node" then
		r.inform(name, rb.none_selected)
		return
	end

	local node, mode = r.get_data(itemstack)
	node = minetest.get_node_or_nil(pt.under) or node
	
	if not modes_are_available then
		mode = r.modes[1]
	end

	local inv = placer:get_inventory()
	if (not (creative_enabled and has_give))
		and (not inv:contains_item("main", node.name)) then
		-- not in inv and not (creative and give)
		local found_item = false
		local drops = minetest.get_node_drops(node.name)
		if creative_enabled then
			if minetest.get_item_group(node.name,
					"not_in_creative_inventory") > 0 then
				-- search for a drop available in creative inventory
				for i = 1, #drops do
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
					r.inform(name, rb.not_in_creative:format(node.name))
					return
				end
			end
		else
			-- search for a drop that the player has if possible
			for i = 1, #drops do
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
				for i = 1, #drops do
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
			if (not found_item) and (not has_give) then
				inform(name, rb.not_in_inventory:format(node.name))
				return
			end
		end
	end

	local metadata = r.set_data(itemstack, node, mode)

	r.inform(name, rb.set_to:format(metadata))

	return itemstack --data changed
end -- common_on_place

function replacer.tool_def_basic()
	return {
		description = rb.description_basic,
		inventory_image = "replacer_replacer.png",
		stack_max = 1, -- it has to store information - thus only one can be stacked
		liquids_pointable = true, -- it is ok to painit in/with water
		--node_placement_prediction = nil,
		--metadata = "default:dirt", -- default replacement: common dirt

		--	on_drop = func(itemstack, dropper, pos),
		
		-- place node(s)
		on_place = replacer.common_on_place, --function(...) return common_on_place(...) end,

		-- Replace node(s)
		on_use = replacer.replace --function(...) return replacer.replace(...)	end,
	}
end

minetest.register_tool(replacer.tool_name_basic, replacer.tool_def_basic())

if replacer.has_technic_mod then
	function replacer.tool_def_technic()
		local def = replacer.tool_def_basic()
		def.description = rb.description_technic
		def.wear_represents = "technic_RE_charge"
		def.on_refill = technic.refill_RE_charge
		return def
	end
	technic.register_power_tool(replacer.tool_name_technic, replacer.max_charge)
	minetest.register_tool(replacer.tool_name_technic, replacer.tool_def_technic())
end

function replacer.register_on_player_receive_fields(player, form_name, fields)
	-- no need to process if it's not expected formspec that triggered call
	if form_name ~= replacer.form_name_modes then return end
	-- no need to process if user closed formspec without changing mode
	if nil == fields.mode then return end

	-- collect some information
	local itemstack = player:get_wielded_item()
	local node, _ = r.get_data(itemstack)
	local mode = fields.mode
	local name = player:get_player_name()

	-- set metadata and itemstring
	r.set_data(itemstack, node, mode)
	-- update wielded item
	player:set_wielded_item(itemstack)
	--[[ NOTE: for now I leave this code here in case we later make this a setting in
				some way that does not mute all messages of tool
	-- spam players chat with information
	r.inform(name, rb.set_to:format(mode, r.mode_infos[mode]))
	--]]
end
-- listen to submitted fields
minetest.register_on_player_receive_fields(replacer.register_on_player_receive_fields)
