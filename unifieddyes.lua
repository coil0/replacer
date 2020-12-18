if not replacer.has_unifieddyes_mod then
	function replacer.colourName(param2, nodeDef) return '' end
	function replacer.addUnifieddyesRecipe(nodeName, recipes) return recipes end
	return
end


function replacer.addUnifieddyesRecipe(nodeName, recipes)
	local nodeDef = minetest.registered_items[nodeName]
print(dump(nodeDef))
	return recipes
end


function replacer.colourName(param2, nodeDef)
	param2 = tonumber(param2)
	if param2 and nodeDef and nodeDef.palette
		and nodeDef.groups and nodeDef.groups.ud_param2_colorable
		and 0 < nodeDef.groups.ud_param2_colorable
	then
		-- TODO: check if is coloured at all, some nodes have neutral states
		local s = unifieddyes.make_readable_color(
			unifieddyes.color_to_name(param2, nodeDef))
		return ' ' .. s
	else
		return ''
	end
end

