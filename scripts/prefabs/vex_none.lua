local assets =
{
	Asset( "ANIM", "anim/vex.zip" ),
	Asset( "ANIM", "anim/ghost_vex_build.zip" ),
}

local skins =
{
	normal_skin = "vex",
	ghost_skin = "ghost_vex_build",
}

return CreatePrefabSkin("vex_none",
{
	base_prefab = "vex",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"VEX", "CHARACTER", "BASE"},
	build_name_override = "vex",
	rarity = "Character",
})