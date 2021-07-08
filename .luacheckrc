
globals = {
	"replacer",
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- deps
	"technic",
	"default",
	"minetest",
	"creative",
	"circular_saw"
}
