Includes = {
	"cw/shadow.fxh"
	"cw/terrain.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_decals.fxh"
	"fog_of_war.fxh"
	"terrain.fxh"
	"winter.fxh"
	"specular_back_light.fxh"
	"mesh_vertexshader.fxh"
	"city_grid.fxh"
}

PixelShader =
{
	TextureSampler DiffuseMap
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PropertiesMap
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalMap
	{
		Index = 2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler EnvironmentMap
	{
		Ref = JominiEnvironmentMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "Cube"
	}
	TextureSampler ShadowTexture
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}
	TextureSampler ClimateMap
	{
		Ref = ClimateMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}

VertexShader =
{	
	MainCode VS_standard_caesar
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out = ConvertOutput( StandardVertexShader( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;

				#ifdef CITY_GRID_SQUISH
				ApplyCitySquish( Out.WorldSpacePos.xyz, Input.Position.xyz, Out.InstanceIndex );
				#endif

				Out.WorldSpacePos.y = GetHeight( Out.WorldSpacePos.xz ) + 0.05;
				AdjustFlatMapHeight( Out.WorldSpacePos );
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos.xyz, 1.0 ) );

				return Out;
			}
		]]
	}
	
	MainCode VS_mapobject_caesar
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.Index24_Packed1_Opacity6_Sign1 );
				VS_OUTPUT Out = ConvertOutput( StandardVertexShader( PdxMeshConvertInput( Input ), 0/*bone offset not supported*/, WorldMatrix ) );
				Out.InstanceIndex = Input.Index24_Packed1_Opacity6_Sign1;

				Out.WorldSpacePos.y = GetHeight( Out.WorldSpacePos.xz ) + 0.05;
				AdjustFlatMapHeight( Out.WorldSpacePos );
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos.xyz, 1.0 ) );

				return Out;
			}
		]]
	}
}

PixelShader =
{
	Code
	[[
		float3 CalcDecal( float2 UV, float3 Bitangent, float3 WorldSpacePos, float3 Diffuse, out float4 Properties, out float3 Normal)
		{
			Properties = PdxTex2D( PropertiesMap, UV );
			float4 NormalPacked = PdxTex2D( NormalMap, UV );
			float3 NormalSample = UnpackRRxGNormal( NormalPacked );
			Normal = CalculateNormal( WorldSpacePos.xz );
			
			#ifdef TANGENT_SPACE_NORMALS
				//the Bitangent should be already normalized
				float3 Tangent = cross( Bitangent, Normal );
				float3x3 TBN = Create3x3( Tangent, -Bitangent , Normal );
				Normal = normalize( mul( NormalSample, TBN ) );
			#else
				Normal = ReorientNormal( Normal, NormalSample );
			#endif
			
			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			float3 ColorMap = PdxTex2D( ColorTexture, float2( MapCoords.x, 1.0 - MapCoords.y ) ).rgb;
			Diffuse = GetOverlay( Diffuse, ColorMap, 0.5 );
		

			#if defined( ENABLE_SNOW )
				ApplySnowMesh( Diffuse.rgb, Normal, Properties, WorldSpacePos, ClimateMap );
			#endif

			// Gradient borders pre light
			#ifndef NO_BORDERS
				float3 ColorOverlay;
				float PreLightingBlend;
				float PostLightingBlend;
				GetProvinceOverlayAndBlendCustom( MapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
				Diffuse.rgb = ApplyGradientBorderColorPreLighting( Diffuse.rgb, ColorOverlay, PreLightingBlend );
			#endif

			float4 HighlightColor = BilinearColorSampleAtOffset( MapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
			Diffuse.rgb = lerp( Diffuse.rgb, HighlightColor.rgb, HighlightColor.a );
			
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( WorldSpacePos, ShadowTexture );
			
			float3 Color = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
			ApplySpecularBackLight( Color, MaterialProps, LightingProps );
			
			// Color overlay post light
			#ifndef NO_BORDERS
				Color = ApplyGradientBorderColor( Color, ColorOverlay, PostLightingBlend );
			#endif

			Color = ApplyFogOfWar( Color, WorldSpacePos, FogOfWarAlpha );
			Color = ApplyDistanceFog( Color, WorldSpacePos );
			
			DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
			return Color;
		}
	]]
	
	MainCode PS_world
	{
		TextureSampler DecalAlphaTexture
		{
			Index = 3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			static const float DECAL_TILING_SCALE = 0.15;
		
			PDX_MAIN
			{
				float Alpha = PdxTex2D( DecalAlphaTexture, Input.UV0 ).r;
				//return float4( vec3( 1 ), Alpha );
				
				float FlatmapFade = 1.0f - GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp() ).x;
				Alpha = PdxMeshApplyOpacity( Alpha, Input.Position.xy, GetOpacity( Input.InstanceIndex )  ) * FlatmapFade;
				
				float2 DetailUV = Input.WorldSpacePos.xz * float2( DECAL_TILING_SCALE, -DECAL_TILING_SCALE );
				
				#ifdef PDX_USE_MIPLEVELTOOL
					float4 Diffuse = PdxTex2DMipTool( DiffuseMap, DetailUV );
				#else
					float4 Diffuse = PdxTex2D( DiffuseMap, DetailUV );
				#endif // PDX_USE_MIPLEVELTOOL

				float4 Properties;
				float3 Normal;

				float3 Color = CalcDecal( DetailUV, Input.Bitangent, Input.WorldSpacePos, Diffuse.rgb, Properties, Normal );

				#if defined( ENABLE_SNOW )
					ApplySnowMesh( Diffuse.rgb, Normal, Properties, Input.WorldSpacePos, ClimateMap );
				#endif
				
				Alpha = CalcHeightBlendFactors( float4( Diffuse.a, 0.3, 0.0, 0.0 ), float4( Alpha, 1.0 - Alpha, 0.0, 0.0 ), 0.25 ).r;
				return float4( Color, Alpha );
			}
		]]
	}
	
	MainCode PS_local
	{
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				#ifdef PDX_USE_MIPLEVELTOOL
					float4 Diffuse = PdxTex2DMipTool( DiffuseMap, Input.UV0 );
				#else
					float4 Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
				#endif // PDX_USE_MIPLEVELTOOL

				float FlatmapFade = 1.0f - GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp()  ).x;
				Diffuse.a = PdxMeshApplyOpacity( Diffuse.a, Input.Position.xy, GetOpacity( Input.InstanceIndex ) ) * FlatmapFade;
								
				float4 Properties;
				float3 Normal;

				float3 Color = CalcDecal( Input.UV0, Input.Bitangent, Input.WorldSpacePos, Diffuse.rgb, Properties, Normal );
				#if defined( ENABLE_SNOW )
					ApplySnowMesh( Diffuse.rgb, Normal, Properties, Input.WorldSpacePos, ClimateMap );
				#endif
				return float4( Color, Diffuse.a );
			}
		]]
	}
}

Effect decal_world
{
	VertexShader = "VS_standard_caesar"
	PixelShader = "PS_world"
	Defines = { "ENABLE_SNOW" }
}

Effect decal_local
{
	VertexShader = "VS_standard_caesar"
	PixelShader = "PS_local"
	
	Defines = { "TANGENT_SPACE_NORMALS" "ENABLE_SNOW" }
}

Effect decal_world_mapobject
{
	VertexShader = "VS_mapobject_caesar"
	PixelShader = "PS_world"
	Defines = { "ENABLE_SNOW" }
}

Effect decal_local_mapobject
{
	VertexShader = "VS_mapobject_caesar"
	PixelShader = "PS_local"
	
	Defines = { "TANGENT_SPACE_NORMALS" "ENABLE_SNOW"}
}

Effect city_grid_decal_local
{
	VertexShader = "VS_standard_caesar"
	PixelShader = "PS_local"
	
	Defines = { "TANGENT_SPACE_NORMALS" "CITY_GRID_SQUISH" "ENABLE_SNOW"}
}

Effect city_grid_decal_world
{
	VertexShader = "VS_standard_caesar"
	PixelShader = "PS_world"

	Defines = { "CITY_GRID_SQUISH" "ENABLE_SNOW"}
}
