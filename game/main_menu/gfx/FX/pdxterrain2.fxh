#file for functions that are modifications of any pof the cw terrain files

Includes = {

	"cw/camera.fxh"
	"cw/utility.fxh"

	"terrain.fxh"
	"cw/terrain.fxh"
	"cw/terrain2_materials.fxh"

	"jomini/jomini_lighting.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_fog.fxh"


	"standardfuncsgfx.fxh"

	"fog_of_war.fxh"
	"winter.fxh"
	"climate.fxh"
	"gbuffer.fxh"
	"dynamic_masks.fxh"
	"grass_scatter.fxh"
	"specular_back_light.fxh"

	"cw/terrain2_shader_mains.fxh"
	"cw/terrain2_materials.fxh"
}
PixelShader =
{
	# PdxTerrain uses texture index 0 - 6

	# Jomini specific
	TextureSampler ShadowMap
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}
	
	# Game specific
	TextureSampler ClimateMap
	{
		Ref = ClimateMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	
	TextureSampler FlatMapTexture
	{
		Ref = FlatMap0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlatMapDetail
	{
		Ref = FlatMap1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler TerrainTint3D
	{
		Ref = TerrainTint3D
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "3D"
		
		srgb = "no"
	}

	TextureSampler TerrainTintCoords
	{
		Ref = TerrainTintCoords
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		srgb = "no"

		file = "gfx/map/climate/coordinates.dds"
	}
}


VertexStruct VS_OUTPUT_SHADOW
{
	float4 Position : PDX_POSITION;
};

VertexStruct VS_OUTPUT
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD1;
	float4 ShadowProj		: TEXCOORD2;

	@ifdef MIP_LEVEL_ENABLED
	float4 Color				: COLOR0;
	@endif
};


VertexShader = 
{
	Code = 
	[[
			//Same as Terrain2_VertexShaderMain but with nudging for the flatmap
			STerrain2Vertex CalcTerrainVertex( STerrain2VertexInput Input )
			{
					STerrain2NodeData NodeData = Terrain2_UnpackNodeDataFromVertex( Input );
					float2 GridPosition0To1 = Terrain2_CalcGridPosition01( Input.VertexID, NodeData );
					STerrain2Vertex Vertex = Terrain2_CalcTerrainVertex( GridPosition0To1, NodeData );
					
					#if defined(TERRAIN_FLAT_MAP) && defined(ENABLE_TERRAIN)
						Vertex._WorldSpacePos.y = GetFlatMapHeight();
					#else
						AdjustFlatMapHeight( Vertex._WorldSpacePos );
					#endif

					return Vertex;
			}
	]]
}

PixelShader =
{

	Code =
	[[
			float3 CalculateWorldSpaceNoise (float3 WorldSpacePosition)
			{
				float3 NoisedWorldSpace = WorldSpacePosition;
				float  NoiseList[16] = {0, 0.125, 0.5, -0.625, 0.75, 1,  -0.25, -0.375, -0.5,  0.25, -0.875, 0.625, -0.125,  0.875, 0.375, -0.75  };
				NoisedWorldSpace.x += CalcNoise( WorldSpacePosition.z+ WorldSpacePosition.x *0.25 ) * 0.65 + sin( WorldSpacePosition.z*4+ WorldSpacePosition.x *1.25 ) * 0.05;
				NoisedWorldSpace.z += CalcNoise( WorldSpacePosition.x+ WorldSpacePosition.z *0.25 ) * 0.65 + sin( WorldSpacePosition.z*4+ WorldSpacePosition.x *1.25 ) * 0.05;
				NoisedWorldSpace.x += NoiseList[((int)(NoisedWorldSpace.z*3.356 + NoisedWorldSpace.x * 0.5346) )% 16]*0.1;
				NoisedWorldSpace.z += NoiseList[((int)(NoisedWorldSpace.x*3.46 +NoisedWorldSpace.z * 0.5153) ) % 16]*0.1;
				return NoisedWorldSpace;
			}

		void ApplySnow( inout float3 Diffuse, inout float3 Normal, inout float4 Material, float3 TerrainNormal, float3 WorldSpacePos, in PdxTextureSampler2D ClimateMap)
		{
			float Snow = GetSnowAmountForTerrain( TerrainNormal, WorldSpacePos, ClimateMap );
			if( Snow > 0.0f )
			{
				float2 SnowUV = float2(  WorldSpacePos.xz * _InvMaterialTileSize ) ;
				float4 SnowDiffuse = PdxTex2D( DetailDiffuseSnow, SnowUV );
				float3 SnowNormal = UnpackRRxGNormal( PdxTex2D( DetailNormalSnow, SnowUV ) );
				float4 SnowMaterial = PdxTex2D( DetailPropertiesSnow, SnowUV );
				
				float SnowNoiseFactor = 0.1;
				float SnowBlend = saturate( Snow * (1.0f+SnowNoiseFactor) - SnowNoiseFactor + ( SnowDiffuse.a * SnowNoiseFactor ) );
				//return vec4(SnowBlend);
				Diffuse = lerp( Diffuse, SnowDiffuse.rgb, SnowBlend );
				Material = lerp( Material, SnowMaterial, SnowBlend );
				
				//SnowNormal.xy *= SnowBlend;
				//SnowNormal.z = sqrt( 1.0f - dot(SnowNormal.xy,SnowNormal.xy) );
				//
				//Normal.xy += SnowNormal.xy;
				//Normal.z *= SnowNormal.z;
				//normalize( Normal );
				Normal = normalize( lerp( Normal, SnowNormal, SnowBlend ) );
			}	
		}

	//Calculate materials bilinear with noise
	void CalculateCustomMaterialsBilinear( float3 WorldSpacePosition, float3 WorldSpaceNormal, out float4 DiffuseAndHeight, out float3 Normal, out float4 Properties, out float3 BlendWeights )
	{
		DiffuseAndHeight = float4( 0, 0, 0, 0 );
		Normal = float3( 0, 1, 0 );
		Properties = float4( 0, 0, 0, 0 );

		float3 WorldSpacePosWithNoise = CalculateWorldSpaceNoise(WorldSpacePosition);

		SPhysicalTexel MaterialsTexel = CalcPhysicalMaterialsTexel( WorldSpacePosWithNoise, CalculateVirtualLayerDistanceMip( WorldSpacePosWithNoise, _VirtualMaterialsConstants ) );
#ifdef TERRAIN2_CURVATURE_ENABLED
		SPhysicalTexel CurvatureTexel = CalcPhysicalCurvatureTexel( WorldSpacePosWithNoise, CalculateVirtualLayerDistanceMip( WorldSpacePosWithNoise, _VirtualCurvatureConstants ) );
#endif // TERRAIN2_CURVATURE_ENABLED

		int2 Offsets[ 4 ] = { int2( 0, 0 ), int2( 1, 0 ), int2( 0, 1 ), int2( 1, 1 ) };

		float2 MaterialUV = WorldSpacePosition.xz * _InvMaterialTileSize;

		float4 Diffuses[ 4 ];
		float3 Normals[ 4 ];
		float4 _Properties[ 4 ];
#ifdef TERRAIN2_CURVATURE_ENABLED
		float Curvatures[ 4 ];
#endif // TERRAIN2_CURVATURE_ENABLED

		float2 MaterialToWorld = _TerrainSize * _VirtualMaterialsConstants._ClipmapConstants._InvVirtualTextureSize;
		float2 MaterialTexelSizeInWorldSpace = MaterialToWorld * float( 1u << MaterialsTexel._PageMip );
		float2 WorldSpace00 = WorldSpacePosition.xz - MaterialTexelSizeInWorldSpace * MaterialsTexel._PositionFrac;

		int4 MaterialIndex;
		int4 Biome;
		for ( int i = 0; i < 4; ++i )
		{
			MaterialIndex[ i ] = GetTopMaterialIndexAt( MaterialsTexel._Position + Offsets[ i ] );
			Biome[ i ] = GetBiomeWorldspace( WorldSpace00 + MaterialTexelSizeInWorldSpace * Offsets[ i ], MaterialIndex[ i ] );
#ifdef TERRAIN2_CURVATURE_ENABLED
			Curvatures[ i ] = PdxTexture2DLoad0( VirtualCurvaturePhysicalTexture, CurvatureTexel._Position + Offsets[ i ] ).r;
#endif // TERRAIN2_CURVATURE_ENABLED
		}

#ifndef TRIPLANAR_UV_MAPPING_ENABLED
		for ( int i = 0; i < 4; ++i )
		{
			SampleMaterialTextures( MaterialUV, Biome[ i ], MaterialIndex[ i ], Diffuses[ i ], Normals[ i ], _Properties[ i ] );
		}

		DiffuseAndHeight = LerpBilinear( MaterialsTexel._PositionFrac, Diffuses[ 0 ], Diffuses[ 1 ], Diffuses[ 2 ], Diffuses[ 3 ] );
		Normal = LerpBilinear( MaterialsTexel._PositionFrac, Normals[ 0 ], Normals[ 1 ], Normals[ 2 ], Normals[ 3 ] );
		Properties = LerpBilinear( MaterialsTexel._PositionFrac, _Properties[ 0 ], _Properties[ 1 ], _Properties[ 2 ], _Properties[ 3 ] );

		// For material debugging only
		BlendWeights = float3( 0, 1, 0 );
#else
		float3 BlendFactor = GetTriPlanarUVBlendFactor( WorldSpaceNormal );
		CalcTriPlanarUV( WorldSpacePosition, MaterialIndex, Biome, MaterialsTexel._PositionFrac, BlendFactor, DiffuseAndHeight, Normal, Properties );

		// For material debugging only
		BlendWeights = BlendFactor;
#endif

#ifdef TERRAIN2_CURVATURE_ENABLED
		float Curvature = LerpBilinear( CurvatureTexel._PositionFrac, Curvatures[ 0 ], Curvatures[ 1 ], Curvatures[ 2 ], Curvatures[ 3 ] );
		DiffuseAndHeight.rgb = saturate( BlendAddSub( DiffuseAndHeight.rgb, Curvature, _CurvatureMapStrength ) );
#endif // TERRAIN2_CURVATURE_ENABLED
	}


	//Similar code to Terrain2_PixelShaderMain
		PS_OUTPUT TerrainShader( VS_OUTPUT Input )
		{
			#ifdef MIP_LEVEL_ENABLED
				return PS_Return( Input.Color );
			#else
				///////Begins Terrain2_PixelShaderMain///////
				float HeightLod = CalculateVirtualLayerDistanceMip( Input.WorldSpacePos, _VirtualHeightmapConstants );

				int HeightLodTruncated = HeightLod;
				float HeightLodFrac = HeightLod - (float)HeightLodTruncated;
				float LerpFactor = smoothstep( 0.7, 1.0, HeightLodFrac );

				float3 DerivedNormal = CalculateNormal( Input.WorldSpacePos.xz, HeightLodTruncated );
				if ( LerpFactor > 0.0 )
				{
					int NextLevelLod = HeightLodTruncated + 1;
					float3 NormalNext = CalculateNormal(  Input.WorldSpacePos.xz, NextLevelLod );
					DerivedNormal = lerp( DerivedNormal, NormalNext, LerpFactor );
				}

				//Needs to be out because in flatmap case it does not compute and it is used for debug
				float4 MaterialDiffuseAndHeight = vec4(0.0f);
				float3 MaterialNormal = float3(0,1,0);
				float3 ReorientedNormal = float3(0,1,0);
				float4 MaterialProperties = vec4(0.0f);
				float3 BlendWeights = vec3(0.0f);
				///////Ends Terrain2_PixelShaderMain///////
				float3 FinalColor = vec3( 0.0f );
				float2 ColorMapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				SMaterialProperties MaterialProps;
				MaterialProps._PerceptualRoughness = 0.0f;
				MaterialProps._Roughness = 0.0f;
				MaterialProps._Metalness = 0.0f;
				MaterialProps._DiffuseColor = vec3(0.0f);
				MaterialProps._SpecularColor = vec3(0.0f);
				MaterialProps._Normal = float3(0,1,0);

			#ifndef TERRAIN_UNDERWATER
				float2 FlatMapBlend = GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp() );
				if( FlatMapBlend.x < 1.0f )
			#endif
				{
					///////Begins Terrain2_PixelShaderMain///////
					
					//TODO CAESAR-4124: Check if it would be apropiated CalculateDetailsLow version of this function
					CalculateCustomMaterialsBilinear( Input.WorldSpacePos, DerivedNormal, MaterialDiffuseAndHeight, MaterialNormal, MaterialProperties, BlendWeights );
	
					///////Ends Terrain2_PixelShaderMain///////

					float2 CoordsTint = PdxTex2D( TerrainTintCoords, float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ) ).rg;
					float3 ColorMap = vec3( 0.0f );
					ColorMap = PdxTex3DLod0( TerrainTint3D, float3( CoordsTint.x, CoordsTint.y, UVMonthTint ) ).rgb;
					
					float ColorMapOverlayStrength = MaterialProperties.r;
					
					#ifndef TERRAIN_UNDERWATER
						ApplyDevastationMaterial( MaterialDiffuseAndHeight, MaterialNormal, MaterialProperties, Input.WorldSpacePos.xz );
					#endif
					float3 Diffuse = GetOverlay( MaterialDiffuseAndHeight.rgb, ColorMap, ColorMapOverlayStrength );
					
					//#ifdef ENABLE_SNOW
					#ifndef TERRAIN_UNDERWATER						
						ApplySnow( Diffuse, MaterialNormal, MaterialProperties, DerivedNormal, Input.WorldSpacePos, ClimateMap );		
					#endif //Under water
					//#endif
					
					ReorientedNormal = ReorientNormal( DerivedNormal, MaterialNormal );

					#ifdef TERRAIN_COLOR_OVERLAY
						float3 BorderColor =float3(0.0,0.0,0.0);
						float BorderPostLightingBlend=0.0;
						ApplyTerrainColor( Diffuse, BorderColor, BorderPostLightingBlend, ColorMapCoords );

						float4 HighlightColor = BilinearColorSampleAtOffset( ColorMapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
						Diffuse.rgb = lerp( Diffuse.rgb, HighlightColor.rgb, HighlightColor.a );
					#endif
					
					float ShadowTerm = 1.0;
					
					#ifdef SHADOWS_ENABLED
					ShadowTerm = CalculateShadow( Input.ShadowProj, ShadowMap );
					#endif
			
					MaterialProps = GetMaterialProperties( Diffuse, ReorientedNormal, MaterialProperties.a, MaterialProperties.g, MaterialProperties.b );
					SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTerm );

					FinalColor = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
					
					#if defined( GRASS_SCATTERING ) && !defined( LOW_QUALITY_SHADERS )
						float3 Color0 = vec3(0.0f);
						float3 Color1 = vec3(0.0f);
						
						float GrassMask = MaterialProperties.r;
						//LightingProps._CubemapIntensity = 0.0f;
						if( GrassMask * GetGrassScatterStrength() > 0.0f )
						{
							float3 ScatterLight = CalculateGrassScatterLighting( MaterialProps, LightingProps );
							FinalColor += ScatterLight * saturate( GetGrassScatterStrength() );
						}
					#endif
					#if defined( STRANGE_BACK_LIGHT ) && !defined( LOW_QUALITY_SHADERS )
						ApplySpecularBackLight( FinalColor, MaterialProps, LightingProps );
					#endif

					#ifdef TERRAIN_COLOR_OVERLAY
						FinalColor = lerp( FinalColor, BorderColor, BorderPostLightingBlend );
					#endif
					DebugReturn( FinalColor, MaterialProps, LightingProps, EnvironmentMap );
				}
				
				#ifndef TERRAIN_UNDERWATER
					if( FlatMapBlend.x > 0.0f )
					{
						float3 FlatMap = FlatTerrainShader( Input.WorldSpacePos, ColorMapCoords, FlatMapTexture, FlatMapDetail, 0 ).rgb;
						FinalColor = lerp( FinalColor, FlatMap * FlatMapBlend.y, FlatMapBlend.x );
					}
					
					FinalColor = ApplyFogOfWar( FinalColor, Input.WorldSpacePos, FogOfWarAlpha );
					if( GetFlatMapLerp() < 1.0f )
					{
						float3 FoggedColor = ApplyDistanceFog( FinalColor, Input.WorldSpacePos );
						FinalColor = lerp( FoggedColor, FinalColor, GetFlatMapLerp() );
					}
				#endif

				
				float Alpha = 1.0;
				#ifdef TERRAIN_UNDERWATER					
					Alpha = CompressWorldSpace( Input.WorldSpacePos );
				#endif
					
				#ifdef TERRAIN_DEBUG
					TerrainDebug( FinalColor, Input.WorldSpacePos );
				#endif

				#if defined( TERRAIN2_DEBUG_MODE )
					if ( TERRAIN2_DEBUG_MODE != 0 )
					{
						// FinalColor = TerrainMaterialDebug( Input.WorldSpacePos );
						FinalColor = TerrainMaterialDebug( CalculateWorldSpaceNoise(Input.WorldSpacePos), MaterialDiffuseAndHeight, MaterialNormal, MaterialProperties, DerivedNormal, ReorientedNormal, BlendWeights );
					}
				#endif

				PS_OUTPUT Out = PS_Return( FinalColor, Alpha, MaterialProps );
				return Out;
			#endif
		}
		
	]]
}