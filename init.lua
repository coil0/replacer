--[[
    Replacement tool for creative building (Mod for MineTest)
    Copyright (C) 2013 Sokomine

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Version 3.0

-- Changelog:
-- 09.12.2017 * Got rid of outdated minetest.env
--            * Fixed error in protection function.
--            * Fixed minor bugs.
--            * Added blacklist
-- 02.10.2014 * Some more improvements for inspect-tool. Added craft-guide.
-- 01.10.2014 * Added inspect-tool.
-- 12.01.2013 * If digging the node was unsuccessful, then the replacement will now fail
--				(instead of destroying the old node with its metadata; i.e. chests with content)
-- 20.11.2013 * if the server version is new enough, minetest.is_protected is used
--				in order to check if the replacement is allowed
-- 24.04.2013 * param1 and param2 are now stored
--			* hold sneak + right click to store new pattern
--			* right click: place one of the itmes
--			* receipe changed
--			* inventory image added

local path = minetest.get_modpath("replacer")

replacer = {}

replacer.blacklist = {};

-- playing with tnt and creative building are usually contradictory
-- (except when doing large-scale landscaping in singleplayer)
replacer.blacklist[ "tnt:boom"] = true;
replacer.blacklist[ "tnt:gunpowder"] = true;
replacer.blacklist[ "tnt:gunpowder_burning"] = true;
replacer.blacklist[ "tnt:tnt"] = true;

-- prevent accidental replacement of your protector
replacer.blacklist[ "protector:protect"] = true;
replacer.blacklist[ "protector:protect2"] = true;

replacer.max_charge = 30000
replacer.charge_per_node = 15
replacer.max_nodes = tonumber( minetest.settings:get("replacer.max_nodes") or "3168")

-- adds a tool for inspecting nodes and entities
dofile(path.."/inspect.lua")
dofile(path.."/replacer.lua")
dofile(path.."/crafts.lua")
