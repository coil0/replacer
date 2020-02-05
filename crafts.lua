
minetest.register_craft({
	output = replacer.tool_name_basic,
	recipe = {
		{ 'default:chest', 'default:gold_ingot', '' },
		{ '', 'default:mese_crystal_fragment', '' },
		{ 'default:steel_ingot', '', 'default:chest' },
	}
})


-- only if technic mod is installed
if replacer.has_technic_mod then
	minetest.register_craft({
		output = replacer.tool_name_technic,
		recipe = {
			{ replacer.tool_name_basic, '', '' },
			{ '', 'technic:green_energy_crystal', '' },
			{ '', '', '' },
		}
	})
	-- direct upgrade craft, is this any good?
	minetest.register_craft({
		output = replacer.tool_name_technic,
		recipe = {
			{ 'default:chest', '', 'default:gold_ingot' },
			{ '', 'default:mese_crystal_fragment', 'technic:green_energy_crystal' },
			{ 'default:steel_ingot', '', 'default:chest' },
		}
	})
end


minetest.register_craft({
  output = 'replacer:inspect',
  recipe = {
		{ 'default:torch' },
		{ 'default:stick' },
  }
})
