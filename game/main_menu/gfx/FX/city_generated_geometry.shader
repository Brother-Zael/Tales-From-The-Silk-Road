Includes = {
	"cw/camera.fxh"
	"cw/heightmap.fxh"
	"cw/terrain.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_fog.fxh"
	"terrain.fxh"
	"flatmap_lerp.fxh"
	"gbuffer.fxh"
	"winter.fxh"
}

VertexStruct DecalVertexInput
{
	float2 Position 		: POSITION;
	float4 MaterialAlphas 	: TEXCOORD0;
};
VertexStruct DecalVertex
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD0;
	float4 MaterialAlphas	: TEXCOORD1;
};


VertexStruct RoadVertexInput
{
	float2 Position 		: POSITION;
	float2 UV 				: TEXCOORD0;
	float2 V1toV2			: TEXCOORD1;
	uint MaterialIndex		: TEXCOORD2;
};
VertexStruct RoadVertex
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD0;
	float3 UV_Fade			: TEXCOORD1;
	uint MaterialIndex		: TEXCOORD2;
	float2 Tangent			: TEXCOORD3;
};


ConstantBuffer( CommonCityMaterialConstants0 )
{
	int4 MaterialDiffuseTextures;
	int4 MaterialNormalTextures;
	int4 MaterialPropertyTextures;
	int MaterialCount;
	float Opacity;
}
ConstantBuffer( CommonCityMaterialConstants1 ) # ground decals
{
	float4 MaterialUvTiling;
	float4 MaterialSpecular;
}
ConstantBuffer( CommonCityMaterialConstants2 ) # roads
{
	float4 RoadThickness;
	float4 TextureAspectRatio;
}

PixelShader = {
	Sampler MaterialSampler
	{
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
	}
	Texture MaterialTextures
	{
		Ref = CityMaterialTextures
		ResourceArraySize = 128
	}
	Code
	[[
		float4 SampleMaterialTexture( int TextureIndex, float2 UV )
		{
			return PdxSampleTex2D( MaterialTextures[ NonUniformResourceIndex( TextureIndex) ], MaterialSampler, UV );
		}
	]]
}

VertexShader = {
	MainCode VS_decal_grid
	{
		Input = DecalVertexInput
		Output = DecalVertex
		Code
		[[
			PDX_MAIN
			{
				DecalVertex Out;
				Out.WorldSpacePos.xz = Input.Position;
				Out.WorldSpacePos.y = GetHeight( Input.Position );
				AdjustFlatMapHeight( Out.WorldSpacePos );
				
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos, 1.0 ) );
				Out.MaterialAlphas = Input.MaterialAlphas;
				return Out;
			}
		]]
	}
}

PixelShader = {
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
	
	Code [[
		PS_OUTPUT CalculateCommonLighting( in float3 WorldSpacePos, in float3 Diffuse, in float3 Normal, in float4 Properties, float Specular, in float Alpha )
		{
			float2 FlatmapFade = 1.0f - GetNoisyFlatMapLerp( WorldSpacePos, GetFlatMapLerp() );	
			clip(FlatmapFade.x-0.00001f);
			
			ApplySnowMesh( Diffuse.rgb, Normal, Properties, WorldSpacePos, ClimateMap );
			
			float2 ColorMapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			// Gradient borders pre light
			#ifndef NO_BORDERS
				float3 ColorOverlay;
				float PreLightingBlend;
				float PostLightingBlend;
				GetProvinceOverlayAndBlendCustom( ColorMapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
				Diffuse = ApplyGradientBorderColorPreLighting( Diffuse, ColorOverlay, PreLightingBlend );
			#endif

			// Location highlighting
			#ifndef NO_HIGHLIGHT
				float4 HighlightColor = BilinearColorSampleAtOffset( ColorMapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
				Diffuse = lerp( Diffuse, HighlightColor.rgb, HighlightColor.a );
			#endif
			
			// Calculate lighting
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse, Normal, Properties.a, Specular, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( WorldSpacePos, ShadowTexture );
			LightingProps._ShadowTerm *= Properties.r;
			float3 Color = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
			
			// Color overlay post light
			#ifndef NO_BORDERS
				Color = ApplyGradientBorderColor( Color, ColorOverlay, PostLightingBlend );
			#endif
			#ifndef UNDERWATER
				Color = ApplyFogOfWar( Color, WorldSpacePos, FogOfWarAlpha );
				Color = ApplyDistanceFog( Color, WorldSpacePos );
			#endif
			DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
			return PS_Return( Color, Alpha * Opacity * FlatmapFade.y, MaterialProps );
		}
	]]
}

PixelShader = {
	MainCode PS_decal_grid
	{
		TextureSampler NoiseTexture
		{
			Ref = PdxTexture6
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
			file = "gfx/city_materials/textures/shape_noise.dds"
			srgb = yes
		}
		Input = DecalVertex
		Output = PS_OUTPUT
		Code
		[[
			float4 CalcBlendFactors( float4 MaterialHeights, float4 MaterialFactors, float BlendRange )
			{
				float4 Mat = MaterialHeights * MaterialFactors + MaterialFactors;
				float BlendStart = max( max( Mat.x, Mat.y ), max( Mat.z, Mat.w ) ) - BlendRange;

				float4 MatBlend = max( Mat - vec4( BlendStart ), vec4( 0.0 ) );

				float Epsilon = 0.00001;
				return float4( MatBlend ) / ( dot( MatBlend, vec4( 1.0 ) ) + Epsilon );
			}
			PDX_MAIN
			{
				float2 UV[4];
				float4 PropertySamples[4];
				float4 HeightmapValues;
				for( int i = 0; i < 4; ++i )
				{
					UV[i] = Input.WorldSpacePos.xz * MaterialUvTiling[i];
					if( i < MaterialCount )
					{
						PropertySamples[i] = SampleMaterialTexture( MaterialPropertyTextures[i], UV[i] );
					}
					else
					{
						PropertySamples[i] = vec4(0.0f);
					}
					HeightmapValues[i] = PropertySamples[i].g;
				}
				
				float4 BlendWeights = CalcBlendFactors( HeightmapValues, Input.MaterialAlphas, 0.15f );
				float4 Diffuse = vec4(0.0f);
				float4 RawNormalSample = vec4(0.0f);
				float4 Properties = vec4(0.0f);
				float Specular = 0.0f;
				
				for( int i = 0; i < min( 4, MaterialCount ); ++i )
				{
					Properties += PropertySamples[i] * BlendWeights[i];
					Diffuse += SampleMaterialTexture( MaterialDiffuseTextures[i], UV[i] ) * BlendWeights[i];
					RawNormalSample += SampleMaterialTexture( MaterialNormalTextures[i], UV[i] ) * BlendWeights[i];
					Specular += MaterialSpecular[i] * BlendWeights[i];
				}
				
				float3 NormalSample = UnpackRRxGNormal( RawNormalSample );
				float3 Normal = CalculateNormal( Input.WorldSpacePos.xz );
				Normal = ReorientNormal( Normal, NormalSample );
				
				float Noise = PdxTex2D( NoiseTexture, Input.WorldSpacePos.xz * 0.5 ).r;
				float AlphaMult = RemapClamped( dot( Input.MaterialAlphas, vec4(1.0f) ), 0.05f, 1.0f, 0.0f, 1.0f );
				AlphaMult = saturate( AlphaMult + Noise * AlphaMult );
				return CalculateCommonLighting( Input.WorldSpacePos, Diffuse.rgb, Normal, Properties, Specular, Diffuse.a * AlphaMult );
			}
		]]
	}
}

VertexShader = {
	MainCode VS_road
	{
		Input =  RoadVertexInput
		Output = RoadVertex
		Code
		[[
			PDX_MAIN
			{
				RoadVertex Out;
				Out.WorldSpacePos.xz = Input.Position;
				const float Thickness = RoadThickness[Input.MaterialIndex];
				const float TextureAspect = TextureAspectRatio[Input.MaterialIndex];
				float Length = length( Input.V1toV2 );
				Out.Tangent = Input.V1toV2 / Length;
				float LengthWithOffset = Length + Thickness;
				float2 Offset = Remap( Input.UV, vec2(0), vec2(1), vec2(-Thickness*0.5f), vec2(Thickness*0.5f) );
				Out.WorldSpacePos.xz += Out.Tangent * Offset.x - float2(-Out.Tangent.y,Out.Tangent.x) * Offset.y;
				Out.WorldSpacePos.y = GetHeight( Input.Position );
				AdjustFlatMapHeight( Out.WorldSpacePos );
				
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos, 1.0 ) );
				Out.UV_Fade.xy = Input.UV;
				Out.UV_Fade.z = (LengthWithOffset / Thickness) / TextureAspect;
				Out.UV_Fade.x *= Out.UV_Fade.z;
				Out.MaterialIndex = Input.MaterialIndex;
				return Out;
			}
		]]
	}
}
PixelShader = {
	MainCode PS_road
	{	
		Input = RoadVertex
		Output = PS_OUTPUT
		Code
		[[
			PDX_MAIN
			{
				const float2 UV = Input.UV_Fade.xy;
				
				float2 WorldUV = Input.WorldSpacePos.xz * 1.0f;
				float4 Diffuse = SampleMaterialTexture( MaterialDiffuseTextures[Input.MaterialIndex], UV );
				float4 Properties = SampleMaterialTexture( MaterialPropertyTextures[Input.MaterialIndex], UV );
				float3 NormalSample = UnpackRRxGNormal( SampleMaterialTexture( MaterialNormalTextures[Input.MaterialIndex], UV ) );
			
				float3 Normal = CalculateNormal( Input.WorldSpacePos.xz );
				float3 Bitangent = normalize( cross( Normal, float3( Input.Tangent.x, 0.0f, Input.Tangent.y ) ) );
				float3 Tangent = normalize( cross( Bitangent, Normal ) );
				float3x3 TBN = Create3x3( Tangent, Bitangent, Normal );
				Normal = normalize( mul( NormalSample, TBN ) );
				
				const float RelativeFade = min( Input.UV_Fade.x, Input.UV_Fade.z - Input.UV_Fade.x ) * 2.0f;
				float Alpha = Diffuse.a * smoothstep( 0.0f, 0.5f, RelativeFade );
				return CalculateCommonLighting( Input.WorldSpacePos, Diffuse.rgb, Normal, Properties, Properties.g, Alpha );
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}
DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}
RasterizerState RasterizerState
{
	#cullmode = "none"
	#fillmode = "wireframe"
	DepthBias = -100000
}
Effect DecalGrid
{
	VertexShader = "VS_decal_grid"
	PixelShader = "PS_decal_grid"
	#defines = { "NO_HIGHLIGHT" "NO_BORDERS" }
}

Effect Road
{
	VertexShader = "VS_road"
	PixelShader = "PS_road"
}