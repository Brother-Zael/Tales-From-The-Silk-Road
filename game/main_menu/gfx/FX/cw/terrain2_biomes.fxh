
# This is the game's override to the material system's biomes.
# This file will make sure that we can use our dynamic biome data instead of the static default

Includes = {
	"cw/terrain.fxh"
	#"cw/debug_constants.fxh"
	"cw/random.fxh"
	"jomini/jomini_province_overlays.fxh"
	"jomini/jomini_colormap_constants.fxh"
}

TextureSampler ProvinceBiomeTexture
{
	Ref = BiomeProvinceIndex
	MagFilter = "Point"
	MinFilter = "Point"
	MipFilter = "Point"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
}

Code
[[

	int SampleBiome(float2 Coord){
		float2 ColorIndex = PdxTex2DLod0( ProvinceColorIndirectionTexture, Coord ).rg;
		return (int)PdxTex2DLoad0( ProvinceBiomeTexture, int2( ColorIndex * IndirectionMapDepth + vec2(0.5f) ) ).r;
	} 

	int GetBiomeWorldspace( float2 WorldSpacePosXZ )
	{
		float SpatialNoise = CalcNoise( WorldSpacePosXZ )-0.5f;
		float FadeDistance = 5.0f; // DebugFloat1;
		WorldSpacePosXZ += float2(0.5, 0.5) * SpatialNoise * FadeDistance;
		float2 WorldSpaceUnorm = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
		return SampleBiome(WorldSpaceUnorm);
	}
	
	int GetBiomeWorldspace( float2 WorldSpacePosXZ, int MaterialIndex )
	{
		/* Removed random noise for now until we found a way to use it that does not break the coasts
		float2 Offsets[16] = {
			float2(0.641, 0.767),
			float2(-0.253, 0.967),
			float2(-0.893, -0.175),
			float2(-0.478, 0.878),
			float2(0.282, -0.959),
			float2(0.881, -0.472),
			float2(0.123, -0.992),
			float2(-0.734, -0.680),
			float2(-0.370, -0.929),
			float2(0.540, -0.842),
			float2(0.979, -0.204),
			float2(0.629, -0.777),
			float2(-0.825, -0.565),
			float2(-0.162, 0.987),
			float2(0.406, -0.914),
			float2(-0.996, -0.089)
		};
		float SpatialNoise = CalcNoise( WorldSpacePosXZ )-0.5f;
		float FadeDistance = 20.0f; // DebugFloat1;
		WorldSpacePosXZ += Offsets[ MaterialIndex % 16 ] * SpatialNoise * FadeDistance;
		float2 WorldSpaceUnorm = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
		return SampleBiome(WorldSpaceUnorm);
		*/
		return GetBiomeWorldspace( WorldSpacePosXZ );
	}
]]
