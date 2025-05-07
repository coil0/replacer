
if not replacer.hide_recipe_basic then
	minetest.register_craft({
		output = replacer.tool_name_basic,
		recipe = {
			{ 'default:chest', '', 'default:gold_ingot' },
			{ '', 'default:mese_crystal_fragment', '' },
			{ 'default:steel_ingot', '', 'default:chest' },
		}
	})
end


-- only if technic mod is installed
if replacer.has_technic_mod then
	if not replacer.hide_recipe_technic_upgrade then
		minetest.register_craft({
			output = replacer.tool_name_technic,
			recipe = {
				{ replacer.tool_name_basic, 'technic:green_energy_crystal', '' },
				{ '', '', '' },
				{ '', '', '' },
			}
		})
	end
	if not replacer.hide_recipe_technic_direct then
		-- direct upgrade craft
		minetest.register_craft({
			output = replacer.tool_name_technic,
			recipe = {
				{ 'default:chest', 'technic:green_energy_crystal', 'default:gold_ingot' },
				{ '', 'default:mese_crystal_fragment', '' },
				{ 'default:steel_ingot', '', 'default:chest' },
			}
		})
	end
end


minetest.register_craft({
  output = 'replacer:inspect',
  recipe = {
		{ 'default:torch' },
		{ 'default:stick' },
  }
})
