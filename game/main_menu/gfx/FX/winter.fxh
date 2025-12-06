Includes = {
	"cw/terrain.fxh"
	"cw/utility.fxh"
	"standardfuncsgfx.fxh"
	"constants.fxh"
	"flatmap_detailed.fxh"
}

ConstantBuffer( WinterConstants )
{
	float2 	TerrainSnowMinMaxCosAngles;
	float2 	MeshSnowMinMaxCosAngles;
	float2 	TreeSnowMinMaxCosAngles;
	float2 	InvSnowTextureSize;
	float2	SnowTextureSize;
	float2	SnowNoiseTextureSize;
	float3	SnowLevelLimits;
	
	int		SnowTerrainTextureArrayIndex;
	int		IceTerrainTextureArrayIndex;
	float 	SnowNoiseFactor;
	float	SnowNoiseSmallTiling;
	float	SnowNoiseLargeTiling;
	float	SnowNoiseOverlayFactor;
	float	SnowThinStrength;
	
	float IceWaterDepthMin;
	float IceWaterDepthMax;
	float IceWinternessMin;
	float IceWinternessMax;
	float IceBaseFadeRange;
	float IceDetailFadeRange;
	
	float RiverIceWinternessMin;
	float RiverIceWinternessMax;
	float RiverIceWaterDepthMinFlat;
	float RiverIceWaterDepthMaxFlat;
	float RiverIceWaterDepthMinByWidth;
	float RiverIceWaterDepthMaxByWidth;
	float RiverIceBaseFadeRangeFlat;
	float RiverIceBaseFadeRangeByWidth;
	float RiverIceDetailFadeRange;
}

PixelShader =
{
	TextureSampler DetailDiffuseSnow
	{
		Ref = DynamicTerrainMask4
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		srgb = yes
		File = "gfx/terrain2/terrain_textures/unmasked/snow/snow_dense_variation_01_diffuse.dds"
	}

		TextureSampler DetailNormalSnow
	{
		Ref = DynamicTerrainMask5
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/terrain2/terrain_textures/unmasked/snow/snow_dense_variation_01_normal.dds"
	}

		TextureSampler DetailPropertiesSnow
	{
		Ref = DynamicTerrainMask6
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/terrain2/terrain_textures/unmasked/snow/snow_dense_variation_01_properties.dds"
	}
	
	TextureSampler WorldSnowRandom
	{
		Ref = DynamicTerrainMask12
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/terrain/unmasked/noise_snow2.dds"
	}

	TextureSampler NoiseText
	{
		Ref = DynamicTerrainMask13
		MagFilter = "Linear"
		MinFilter ="Linear"
		MipFilter = "Linear"
		SampleModeU= "Wrap"
		SampleModeV="Wrap"
		srgb="no"

		file ="gfx/map/terrain/unmasked/noise.dds"
	}
	Code
	[[
		float loc_BlendSnow( float Lower, float Upper, float Value )
		{
			//return smoothstep( Lower, Upper, Value );
			//return Remap( Value, Lower, Upper, 0.0f, 1.0f );
			return RemapClamped( Value, Lower, Upper, 0.0f, 1.0f );
		}
		float loc_GetSnowAmount( float3 Normal, float3 WorldSpacePos, float2 SnowMinMaxCosAngles, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			if( GetEnableSnow() > 0.5f )
			{
				float Winterness = SnowLevelLimits.z * PdxTex2D( SnowMask, WorldSpacePos.xz / GetMapSize() ).r;
				float InvWinterness = 1.0f - Winterness;
				float2 ReversedWorldPos = WorldSpacePos.xz;
				ReversedWorldPos.y = 1-ReversedWorldPos.y;
				float NoiseLargeTiles = PdxTex2D( WorldSnowRandom, ReversedWorldPos / GetMapSize()).r;
				float2 UV = WorldSpacePos.xz * SnowNoiseSmallTiling/ GetMapSize();
				float UntileNoise = PdxTex2D( NoiseText, (WorldSpacePos.xz * 0.0116125) ).r;
				float NoiseSmallTiles = SampleNoTile( NoiseText, UV*float2(2.0,1.0), UntileNoise, 0.7 ).g*2.0;// PdxTex2D( SnowMask, WorldSpacePos.xz * SnowNoiseSmallTiling / GetMapSize()).g*2.0;
				float Noise = Overlay( NoiseLargeTiles, NoiseSmallTiles, SnowNoiseOverlayFactor );;
				
				//Same blending as EU4 but with tweakable parameters
				float ThinSnow = saturate( loc_BlendSnow( SnowLevelLimits.x, SnowLevelLimits.y, Noise ) - InvWinterness );
				float ThickSnow = loc_BlendSnow( 0.0, 0.4, Noise - InvWinterness );
				
				float Snow = saturate( ThickSnow + ThinSnow * SnowThinStrength * 3.0f );
				float NdotUp = Normal.y;
				float AngleMask = smoothstep( SnowMinMaxCosAngles.y, SnowMinMaxCosAngles.x, NdotUp );
	
				return AngleMask * Snow;
			}
			#endif
			return 0.0f;
		}
		

		void loc_ApplySnowWithAmount( inout float3 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, float2 SnowMinMaxCosAngles, in PdxTextureSampler2D SnowMask,  float SnowAmount)
		{
			#ifndef TERRAIN_DISABLED
			float Snow = loc_GetSnowAmount( Normal, WorldSpacePos, SnowMinMaxCosAngles, SnowMask );
			Snow *= SnowAmount; 
			if( Snow > 0.0f )
			{
				float2 UV = WorldSpacePos.xz * _InvMaterialTileSize ;
				float4 SnowDiffuse = PdxTex2D( DetailDiffuseSnow, UV );
				float4 SnowProperties = PdxTex2D( DetailPropertiesSnow, UV );
				
				//float Blend = Snow * SnowDiffuse.a;
				float Blend = saturate(smoothstep( 0.05f, 2.0f, Snow )); //this change how much snow is applied depending on winterness value.
				//float Blend = Snow;
				
				float2 ColorMapUV = WorldSpacePos.xz / ( GetMapSize() - vec2(1) );
				ColorMapUV.y = 1.0f - ColorMapUV.y;
				//float3 ColorMapSample = PdxTex2D( ColorMap, ColorMapUV ).rgb;
				//SnowDiffuse.rgb = GetOverlay( SnowDiffuse.rgb, ColorMapSample, COLORMAP_OVERLAY_STRENGTH );
				
				Diffuse.rgb = lerp( Diffuse, SnowDiffuse.rgb, Blend );
				Properties = lerp( Properties, SnowProperties, Blend );
				
				//TODO(maybe) normals
			}
			#endif
		}

		void loc_ApplySnow( inout float3 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, float2 SnowMinMaxCosAngles, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			loc_ApplySnowWithAmount(Diffuse, Normal, Properties, WorldSpacePos, SnowMinMaxCosAngles, SnowMask, 1.0);
			#endif
		}
		
		//Helpers
		float GetSnowAmountForWater( float3 Normal, float3 WorldSpacePos, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			if( GetEnableSnow() > 0.5f )
			{
				return PdxTex2D( SnowMask, WorldSpacePos.xz / GetMapSize() ).r;
			}
			#endif
			return 0.0f;
		}
		float GetSnowAmountForTerrain( float3 Normal, float3 WorldSpacePos, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			return loc_GetSnowAmount( Normal, WorldSpacePos, TerrainSnowMinMaxCosAngles, SnowMask );
			#else
			return 0.0f;
			#endif
		}

		void ApplySnowMeshWithAmount( inout float3 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, in PdxTextureSampler2D SnowMask, float Amount )
		{
			#ifndef TERRAIN_DISABLED
			loc_ApplySnowWithAmount( Diffuse, Normal, Properties, WorldSpacePos, MeshSnowMinMaxCosAngles, SnowMask, Amount );
			#endif
		}

		void ApplySnowMesh( inout float3 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			loc_ApplySnow( Diffuse, Normal, Properties, WorldSpacePos, MeshSnowMinMaxCosAngles, SnowMask );
			#endif
		}
		void ApplySnowTree( inout float3 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, in PdxTextureSampler2D SnowMask )
		{
			#ifndef TERRAIN_DISABLED
			loc_ApplySnow( Diffuse, Normal, Properties, WorldSpacePos, TreeSnowMinMaxCosAngles, SnowMask );
			#endif
		}
	]]
}