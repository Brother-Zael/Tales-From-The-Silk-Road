Includes = {
	"flatmap_lerp.fxh"
	"pdxmesh_base.fxh"
	"cw/terrain.fxh"	
	"terrain.fxh"
	"winter.fxh"
	"dynamic_masks.fxh"
	"jomini/jomini_mapobject.fxh"
}


Effect standard
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "TERRAIN" "GRADIENT_BORDERS"   "TERRAIN" "CITY_GRADIENT" }
}
Effect standardShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}

Effect standard_no_city
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "TERRAIN" "GRADIENT_BORDERS" }
}
Effect standard_no_cityShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	RasterizerState = RasterizerState_two_sided
	Defines = { "TERRAIN" }
}
Effect standard_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}
Effect standard_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS"  "CITY_GRADIENT"  "TERRAIN"  "ENABLE_SNOW"}
}

Effect standard_atlasShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_atlas_no_colors
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "TERRAIN" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "ENABLE_SNOW"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"
	}
}

Effect standard_atlas_no_colorsShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" }
}

Effect building_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS"   "TERRAIN" "CITY_GRADIENT"}
}
Effect building_atlasShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect building_atlas_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS"   "TERRAIN" "CITY_GRADIENT"}
	RasterizerState = RasterizerState_two_sided
}
Effect building_atlas_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}

Effect standard_atlas_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS"  "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}
Effect standard_atlas_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}
Effect standard_snow
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS"  "TERRAIN" }
}
Effect standard_snowShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_snow_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS"  "TERRAIN" }

	RasterizerState = RasterizerState_two_sided
}
Effect standard_snow_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}

Effect ship_hull
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET"  "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_hullShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}
Effect ship_hull_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = ShadowRasterizerState_two_sided
}
Effect ship_hull_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect ship_flag
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "UNIT_BUFFERS" "TERRAIN"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_flagShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG""UNIT_BUFFERS"  "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_flag_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "UNIT_BUFFERS" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_flag_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG""UNIT_BUFFERS"  "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect ship_sail
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "SAIL" "UNIT_BUFFERS" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_sailShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "SAIL""UNIT_BUFFERS"  "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_sail_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "SAIL" "UNIT_BUFFERS" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_sail_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "SAIL""UNIT_BUFFERS"  "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}


Effect ship_ensign
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "ENSIGN" "FLAG" "UNIT_BUFFERS" "TERRAIN"  
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_ensignShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "ENSIGN" "FLAG" "UNIT_BUFFERS" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_ensign_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "ENSIGN" "FLAG" "UNIT_BUFFERS"  "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_ensign_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "ENSIGN" "FLAG" "UNIT_BUFFERS" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect ship_pennant
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS" "TERRAIN"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_pennantShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG"  "PENNANT" "UNIT_BUFFERS" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_pennant_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS" "TERRAIN"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_pennant_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG"  "PENNANT" "UNIT_BUFFERS" "TERRAIN"}
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect standard_building
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "CITY_GRADIENT" "TERRAIN"}
}
Effect standard_buildingShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_building_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRADIENT"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_building_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}

Effect standard_building_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRADIENT"}
}
Effect standard_buildingShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_building_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRADIENT"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_building_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}


Effect standard_usercolor
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "USER_COLOR" "TERRAIN" }

}
Effect standard_usercolorShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "USER_COLOR" "TERRAIN" }
}
Effect standard_usercolor_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "USER_COLOR" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}
Effect standard_usercolor_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "USER_COLOR" "TERRAIN" }
}

Effect standard_flag
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "FLAG"  "TERRAIN" "GRADIENT_BORDERS"
	"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"
	}
}
Effect standard_flagShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "FLAG" "TERRAIN" }
}
Effect standard_flag_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "FLAG"  "TERRAIN" "GRADIENT_BORDERS"
	"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_flag_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "FLAG" "TERRAIN" }
}

Effect standard_usercolor_flag
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "USER_COLOR" "FLAG" "TERRAIN" "GRADIENT_BORDERS"
	"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect standard_usercolor_flagShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "USER_COLOR" "FLAG" "TERRAIN" }
}
Effect standard_usercolor_flag_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "USER_COLOR" "FLAG" "TERRAIN" "GRADIENT_BORDERS"
	"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_usercolor_flag_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "USER_COLOR" "FLAG" "TERRAIN" }
}

Effect standard_waving_flag
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "FLAG" "TERRAIN" 		
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect standard_waving_flagShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState
	Defines = { "FLAG" "TERRAIN" }
}
Effect standard_waving_flag_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "FLAG" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_waving_flag_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "FLAG" "TERRAIN" }
}


Effect material_test
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "NORMAL_UV_SET Input.UV1" "DIFFUSE_UV_SET Input.UV1" "TERRAIN" }
}
Effect material_test_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "NORMAL_UV_SET Input.UV1" "DIFFUSE_UV_SET Input.UV1" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}

# Map object shaders
Effect standard_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "GRADIENT_BORDERS" "TERRAIN" }
}
Effect standardShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "GRADIENT_BORDERS" "TERRAIN"}
	RasterizerState = RasterizerState_two_sided	
}
Effect standard_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}

Effect standard_snow_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"}
}
Effect standard_snowShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	Defines = { "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}
Effect standard_snow_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"}
	RasterizerState = RasterizerState_two_sided	
}
Effect standard_snow_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}



Effect standard_alpha_blend_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	
	BlendState = "alpha_blend"
	Defines = { "IS_ALPHA_BLEND" "GRADIENT_BORDERS" "TERRAIN" }
}
Effect standard_alpha_blendShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState
	Defines = { "IS_ALPHA_BLEND" "GRADIENT_BORDERS" "TERRAIN" }
}
Effect standard_alpha_blend_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	
	BlendState = "alpha_blend"
	Defines = { "IS_ALPHA_BLEND" "GRADIENT_BORDERS" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}
Effect standard_alpha_blend_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "IS_ALPHA_BLEND" "GRADIENT_BORDERS" "TERRAIN" }
}

Effect standard_atlas_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS" "TERRAIN" }
}
Effect standard_atlasShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_atlas_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}
Effect standard_atlas_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}


Effect bridge
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"

	Defines = { "BRIDGE" "ENABLE_SNOW"  "TERRAIN" }
}

Effect bridge_shadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"

	RasterizerState = ShadowRasterizerState
	Defines = { "BRIDGE" "TERRAIN" }
}

Effect bridge_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"

	Defines = { "BRIDGE" "ENABLE_SNOW"  "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}

Effect bridge_two_sided_shadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"

	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "BRIDGE" "TERRAIN" }
}

Effect snap_to_terrain_no_deform
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "GRADIENT_BORDERS" "TERRAIN" }
}

Effect snap_to_terrain_no_deformShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	

	RasterizerState = ShadowRasterizerState
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "TERRAIN" }
}

Effect snap_to_terrain_no_deform_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "GRADIENT_BORDERS" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_no_deform_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "TERRAIN" }
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect snap_to_terrain_no_deform_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "GRADIENT_BORDERS" "TERRAIN" }
}

Effect snap_to_terrain_no_deformShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	

	RasterizerState = ShadowRasterizerState
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "TERRAIN" }
}

Effect snap_to_terrain_no_deform_two_sided_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "GRADIENT_BORDERS" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_no_deform_two_sidedShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	
	Defines = { "PDX_MESH_SNAP_MESH_TO_TERRAIN" "TERRAIN" }
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect snap_to_terrain
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "GRADIENT_BORDERS" "ENABLE_SNOW"  "TERRAIN" }
}
Effect snap_to_terrainShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "TERRAIN" }
	RasterizerState = ShadowRasterizerState
}
Effect snap_to_terrain_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "TERRAIN" }
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect snap_to_terrain_alpha_to_coverage
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	BlendState = "alpha_to_coverage"
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" }
}
Effect snap_to_terrain_alpha_to_coverageShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	
	RasterizerState = ShadowRasterizerState
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "TERRAIN" }
}
Effect snap_to_terrain_alpha_to_coverage_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	BlendState = "alpha_to_coverage"
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"  }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_alpha_to_coverage_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN" "TERRAIN"  }
}

Effect snap_to_terrain_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" }
}
Effect snap_to_terrain_atlasShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState
}
Effect snap_to_terrain_building_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRADIENT"}
}

Effect snap_to_terrain_building_atlasShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState
}
Effect snap_to_terrain_atlas_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"  }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_atlas_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState_two_sided
}
Effect snap_to_terrain_building_atlas_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"  "CITY_GRADIENT"}
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_building_atlas_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState_two_sided
}

#######
Effect atlas_political_fix
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" }
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = {  "TERRAIN"  }
	RasterizerState = ShadowRasterizerState
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRADIENT"}
}

Effect atlas_political_fix
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = {  "TERRAIN"  }
	RasterizerState = ShadowRasterizerState
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"  }
	RasterizerState = RasterizerState_two_sided	
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "TERRAIN"  }
	RasterizerState = ShadowRasterizerState_two_sided
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN"  "CITY_GRADIENT"}
	RasterizerState = RasterizerState_two_sided	
}
Effect atlas_political_fix
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "TERRAIN"  }
	RasterizerState = ShadowRasterizerState_two_sided
}
##############
Effect standard_papermap_only
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines ={"FLATLIGHT" "SHOW_IN_PAPERMAP" "NOT_SHOW_WITHOUT_PAPERMAP" "TERRAIN" }
}

Effect standard_papermap_only_map_table
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines ={"FLATLIGHT" "SHOW_IN_PAPERMAP" "MAP_TABLE" "TERRAIN" }
}

Effect standard_papermap_onlyShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = {"FLATLIGHT" "SHOW_IN_PAPERMAP" "NOT_SHOW_WITHOUT_PAPERMAP" "TERRAIN" }
	RasterizerState = ShadowRasterizerState
}

Effect standard_show_in_papermap
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = {"SHOW_IN_PAPERMAP" "TERRAIN" }
}
Effect standard_show_in_papermapShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = {"SHOW_IN_PAPERMAP" "TERRAIN" }

	RasterizerState = ShadowRasterizerState
}

Effect ship_hull_show_in_papermap
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET" "SHOW_IN_PAPERMAP" "TERRAIN"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_hull_show_in_papermapShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET" "SHOW_IN_PAPERMAP" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}
Effect ship_hull_show_in_papermap_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET"  "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = ShadowRasterizerState_two_sided
}
Effect ship_hull_show_in_papermap_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "HULL" "UNIQUE_UV_SET"  "SHOW_IN_PAPERMAP" "TERRAIN" }
}	


Effect ship_flag_show_in_papermap
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN"
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5" }
}
Effect ship_flag_show_in_papermap_Shadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG""UNIT_BUFFERS"  "SHOW_IN_PAPERMAP""TERRAIN"  }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_flag_show_in_papermap_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5" }
	RasterizerState = RasterizerState_two_sided
}
Effect ship_flag_show_in_papermap_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG""UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect ship_pennant_show_in_papermap
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_pennant_show_in_papermap_Shadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP""TERRAIN"  }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_pennant_show_in_papermap_two_sided
{
	VertexShader = "VS_sine_animation"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_pennant_show_in_papermap_two_sidedShadow
{
	VertexShader = "VS_sine_animation_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "FLAG" "PENNANT" "UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect ship_sail_show_in_papermap
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "SAIL" "UNIT_BUFFERS" "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
}
Effect ship_sail_show_in_papermap_Shadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "SAIL""UNIT_BUFFERS"  "SHOW_IN_PAPERMAP" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState
}

Effect ship_sail_show_in_papermap_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "SHIP" "SAIL" "UNIT_BUFFERS" "SHOW_IN_PAPERMAP" "TERRAIN" 
		"LIGHT_INTENSITY_FACTOR 0.1"
		"CUBEMAP_INTENSITY_FACTOR 8"
		"ROUGHTNESS_FACTOR 0.5"}
	RasterizerState = RasterizerState_two_sided
}
Effect ship_sail_show_in_papermap_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"	
	Defines = { "SHIP" "SAIL""UNIT_BUFFERS" "SHOW_IN_PAPERMAP" "TERRAIN" }
	
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect standard_atlas_use_country_colors
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS"   "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS"}
}
Effect standard_atlas_use_country_colorsShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_atlas_use_country_colors_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS"  "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS"}
	RasterizerState = RasterizerState_two_sided
}
Effect standard_atlas_use_country_colors_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"		
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}

Effect standard_atlas_use_country_colors_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS" "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS"}
}
Effect standard_atlas_use_country_colorsShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	RasterizerState = ShadowRasterizerState
	Defines = { "TERRAIN" }
}
Effect standard_atlas_two_sided_use_country_colors_mapobject
{
	VertexShader = "VS_mapobject"
	PixelShader = "PS_standard"
	Defines = { "ATLAS" "GRADIENT_BORDERS" "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS"}
	RasterizerState = RasterizerState_two_sided	
}
Effect standard_atlas_two_sided_use_country_colorsShadow_mapobject
{
	VertexShader = "VS_mapobject_shadow"
	PixelShader = "PS_jomini_mapobject_shadow"
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = { "TERRAIN" }
}

Effect snap_to_terrain_atlas_use_country_colors
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS" }
}
Effect snap_to_terrain_atlas_use_country_colorsShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState
}
Effect snap_to_terrain_atlas_use_country_colors_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "REPAINT_BUILIDNG_COUNTRY_COLORS" }
	RasterizerState = RasterizerState_two_sided	
}
Effect snap_to_terrain_atlas_use_country_colors_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN"  }
	RasterizerState = ShadowRasterizerState_two_sided
}

Effect city_grid_mesh_atlas
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRID_SQUISH"  }
}
Effect city_grid_mesh_atlasShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN" "CITY_GRID_SQUISH" "PDX_MESH_BLENDSHAPES"  }
	RasterizerState = ShadowRasterizerState
}
Effect city_grid_mesh_two_sided
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	
	Defines = { "ATLAS" "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "ENABLE_SNOW" "GRADIENT_BORDERS" "TERRAIN" "CITY_GRID_SQUISH"  }
	RasterizerState = RasterizerState_two_sided	
}
Effect city_grid_mesh_two_sidedShadow
{
	VertexShader = "VS_standard_shadow"
	PixelShader = "PixelPdxMeshStandardShadow"
	
	Defines = { "PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED" "TERRAIN" "CITY_GRID_SQUISH" "PDX_MESH_BLENDSHAPES"  }
	RasterizerState = ShadowRasterizerState_two_sided
}