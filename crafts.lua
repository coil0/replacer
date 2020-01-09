

minetest.register_craft({
	output = "replacer:replacer",
	recipe = {
		{'default:chest', '', ''},
		{'', 'technic:green_energy_crystal', ''},
		{'', '', 'default:chest'},
	}
})


minetest.register_craft({
  output = 'replacer:inspect',
  recipe = {
		{ 'default:torch'},
		{ 'default:stick'},
  }
})
