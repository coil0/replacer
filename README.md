Replacement tool for creative building (Mod for Minetest)

This tool is helpful for creative purposes (i.e. build a wall and "paint" windows into it).
It replaces nodes with a previously selected other type of node (i.e. places said windows
into a brick wall).

# Crafting
Availability of recipes can be configured with server settings.
Basic replacer:
```
      | chest       |               | gold ingot |
      |             | mese fragment |            |
      | steel ingot |               | chest      |
```
Or `/giveme replacer:replacer`

Technic replacer as upgrade to basic tool:
```
      | replacer:replacer | green energy crystal |        |
      |                   |                      |        |
      |                   |                      |        |
```
Or `/giveme replacer:replacer_technic`

Technic replacer directly crafted:
```
      | chest       | green energy crystal | gold ingot |
      |             | mese fragment        |            |
      | steel ingot |                      | chest      |
```
Or `/giveme replacer:replacer_technic`

# Usage

Sneak-right-click on a node of which type you want to replace other nodes with.
       Left-click (normal usage) on any nodes you want to replace with that type.
       Right-click to place a node of that type onto clicked node.

When in creative mode, the node will just be replaced. Your inventory will not be changed.

When *not* in creative mode, digging will be simulated and you will get what was there.
In return, the replacement node will be taken from your inventory.

If technic mod is installed, modes are available and use depletes charge.
This is true for users without "give" privs and also on servers not running in creative mode.

# Modes

Special-right-click on a node or special-left-click anywhere to change the mode.
Single-mode does not need any charge. The other modes do.
For a description of the modes with pictures, refer to [doc/usage.md](doc/usage.md).
* [Single Mode (doc/usageSingle.md)](doc/usageSingle.md)
* [Field Mode (doc/usageField.md)](doc/usageField.md)
* [Crust Mode (doc/usageCrust.md)](doc/usageCrust.md)

# Inspection tool

The third tool included in this mod is the inspector.

Crafting:
```
      | torch |      |     |
      | stick |      |     |
      |       |      |     |
```
Just wield it and click on any node or entity you want to know more about. A limited craft-guide is included.

# Settings

* **replacer.max_nodes** max allowed nodes to replace (default: 3168)
* **replacer.hide_recipe_basic** hide the basic recipe (default: 0)<br>
These two require technic to be installed, if not they are hidden no matter how you set them
* **replacer.hide_recipe_technic_upgrade** hide the upgrade recipe (default: 0)
* **replacer.hide_recipe_technic_direct** hide the direct technic recipe (default: 1)

# Contributors

* Sokomine
* coil0
* HybridDog
* SwissalpS
* OgelGames
* BuckarooBanzay
* S-S-X

# License


    Copyright (C) 2013,2014,2015 Sokomine

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
