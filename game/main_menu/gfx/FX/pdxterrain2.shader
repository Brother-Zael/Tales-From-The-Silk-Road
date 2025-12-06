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

	"pdxterrain2.fxh"
}


VertexShader =
{

	VertexStruct VS_INPUT
	{
		uint4 NodeOffset_Scale_Lerp	: TEXCOORD0;
		uint2 PhysicalPageDataIndex_LodDiff	: TEXCOORD1;
		uint VertexID : PDX_VertexID;
	};

	VertexStruct VS_FAKE_INPUT
	{
		float3 _WorldPosition : POSITION;
	};

	Code
	[[
		
	#ifdef MIP_LEVEL_ENABLED
			float4 CalcDebugMipLevelColor( uint Scale )
			{
				//int Level = _QuadTreeLevels - 1 - log2( Scale );
				int Level = log2( Scale );
				float Value = 1.0 - 0.2 * (Level / 6);
				return float4( HSVtoRGB( mod( Level / 6.0, 1.0 ), Value, Value ), 1 );
			}
	#endif

	]]

	MainCode FakeVertexShader
	{
		Input = "VS_FAKE_INPUT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out;
				
				Out.WorldSpacePos = Input._WorldPosition;
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Input._WorldPosition, 1.0 ) );
				Out.ShadowProj = mul( ShadowMapTextureMatrix, float4( Input._WorldPosition, 1.0 ) );

				#ifdef MIP_LEVEL_ENABLED
					Out.Color = vec4(1.0, 1.0, 1.0, 0.0);
				#endif

				return Out;
			}
		]]

	}

	MainCode FakeVertexShaderShadow
	{
		Input = "VS_FAKE_INPUT"
		Output = "VS_OUTPUT_SHADOW"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_SHADOW Out;
				
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Input._WorldPosition, 1.0 ) );

				return Out;
			}
		]]

	}

	MainCode VertexShader
	{
		Input = "STerrain2VertexInput"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out;
				STerrain2Vertex Vertex = CalcTerrainVertex(Input);
				
				Out.WorldSpacePos = Vertex._WorldSpacePos;
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Vertex._WorldSpacePos, 1.0 ) );
				Out.ShadowProj = mul( ShadowMapTextureMatrix, float4( Vertex._WorldSpacePos, 1.0 ) );
				
				#ifdef MIP_LEVEL_ENABLED
					Out.Color = CalcDebugMipLevelColor( Input.NodeOffset_Scale_Lerp.z );
				#endif

				return Out;
			}
		]]
	}
	
	MainCode VertexShaderShadow
	{
		Input = "STerrain2VertexInput"
		Output = "VS_OUTPUT_SHADOW"
		Code
		[[						
			PDX_MAIN
			{
				STerrain2Vertex Vertex =	CalcTerrainVertex(Input);

				VS_OUTPUT_SHADOW Out;
				
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Vertex._WorldSpacePos, 1.0 ) );

				return Out;
			}
		]]
	}

}

PixelShader =
{
	Code
	[[		
		void CropToWorldSize( in VS_OUTPUT Input )
		{
			float LerpFactor = saturate( ( Input.Position.z - 0.9 ) * 10.0 );
			clip( vec2(1.0) - ( Input.WorldSpacePos.xz - float2( lerp( 0.1, 2.0, LerpFactor ), 0.0 ) ) * _WorldSpaceToTerrain0To1 );
		}
	]]
	
	MainCode PixelShader
	{
	
		Input = "VS_OUTPUT"
		Output = "PS_OUTPUT"
		Code
		[[			
			PDX_MAIN
			{
				CropToWorldSize( Input );
				return TerrainShader( Input );
			}
		]]
	}
	
	MainCode PixelShaderUnderwater
	{
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[			
			PDX_MAIN
			{
				CropToWorldSize( Input );
				return TerrainShader( Input )._Color;
			}
		]]
	}
	
	MainCode PixelShaderFlatMap
	{		
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[			
			PDX_MAIN
			{
				CropToWorldSize( Input );
				float2 ColorMapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				float4 FinalColor = FlatTerrainShader( Input.WorldSpacePos, ColorMapCoords, FlatMapTexture, FlatMapDetail, 0 );
				FinalColor.rgb = ApplyFogOfWar( FinalColor.rgb, Input.WorldSpacePos, FogOfWarAlpha );
				return FinalColor;
			}
		]]
	}
	
	MainCode PixelShaderShadow
	{
		Input = "VS_OUTPUT_SHADOW"
		Output = "void"
		Code
		[[
			PDX_MAIN
			{
			}
		]]
	}
}


RasterizerState ShadowRasterizerState
{
	DepthBias = 40000
	SlopeScaleDepthBias = 2
}

RasterizerState FakeTerrainFlatRasterizerState
{
	CullMode = none
}

Effect Terrain
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "GRASS_SCATTERING" "STRANGE_BACK_LIGHT" "ENABLE_GAME_CONSTANTS" "TRIPLANAR_UV_MAPPING_ENABLED"}
}

Effect TerrainUnderwater
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUnderwater"
	
	Defines = { "TERRAIN_UNDERWATER" "ENABLE_GAME_CONSTANTS"}
}


Effect TerrainFlat
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderFlatMap"
	
	Defines = { "TERRAIN_FLAT_MAP" "ENABLE_GAME_CONSTANTS"}
}

Effect TerrainShadow
{
	VertexShader = "VertexShaderShadow"
	PixelShader = "PixelShaderShadow"
	RasterizerState = ShadowRasterizerState
	Defines = { "ENABLE_GAME_CONSTANTS"}
}

Effect FakeTerrainFlat
{
	VertexShader = "FakeVertexShader"
	PixelShader = "PixelShaderFlatMap"
	RasterizerState = FakeTerrainFlatRasterizerState
	Defines = { "TERRAIN_FLAT_MAP" "ENABLE_GAME_CONSTANTS"}
}

Effect FakeTerrainFlatShadow
{
	VertexShader = "FakeVertexShaderShadow"
	PixelShader = "PixelShaderShadow"
	
	RasterizerState = ShadowRasterizerState

	Defines = { "ENABLE_GAME_CONSTANTS"}
}