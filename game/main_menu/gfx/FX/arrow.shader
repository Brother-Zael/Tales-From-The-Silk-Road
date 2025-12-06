Includes = {
	"cw/camera.fxh"
	"jomini/jomini_fog.fxh"
	"standardfuncsgfx.fxh"
	"flatmap_lerp.fxh"
}


VertexStruct VS_INPUT
{
    float3 vPosition  : POSITION;
	float2 vTexCoord  : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
    float4 vPosition : PDX_POSITION;
    float2 vTexCoord : TEXCOORD0;
	float3 vPos		 : TEXCOORD1;
};


ConstantBuffer( 0 )
{
	float AnimationLength;
	float MoveLength;
	float ClipLength;
	float TotalLength;
	float Width;
};


VertexShader = 
{
	MainCode VertexShader
	{
		Input = "VS_INPUT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out;
				float4 pos = float4( Input.vPosition, 1.0f );
				AdjustFlatMapHeight( pos.xyz );
				pos.y += 1.0f;
				
				Out.vPos = pos.xyz;
				Out.vPosition  = FixProjectionAndMul( ViewProjectionMatrix, pos );	
				Out.vTexCoord = Input.vTexCoord;
				
				return Out;
			}
		]]
	}
}


PixelShader = 
{
	TextureSampler DiffuseTexture
	{
		Index = 0
		MipFilter = "Linear"
		MinFilter = "Linear"
		MagFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	#TextureSampler NormalMap
	#{
	#	Index = 1
	#	MipFilter = "Linear"
	#	MinFilter = "Linear"
	#	MagFilter = "Linear"
	#	SampleModeU = "Clamp"
	#	SampleModeV = "Clamp"
	#}
	#TextureSampler SpecularMap
	#{
	#	Index = 2
	#	MipFilter = "Linear"
	#	MinFilter = "Linear"
	#	MagFilter = "Linear"
	#	SampleModeU = "Clamp"
	#	SampleModeV = "Clamp"
	#}
	
	MainCode PixelShader
	{
		Input = VS_OUTPUT
		Output = PDX_COLOR
		
		Code
		[[
			PDX_MAIN
			{	
				//return float4( mod( Input.vTexCoord.yyy, 1 ), 1.0f );
				
				clip( AnimationLength - Input.vTexCoord.y );
				clip( Input.vTexCoord.y - ClipLength );
				
				float vPassed = Input.vTexCoord.y < MoveLength ? 1.0f : 0.0f;
				
				float Tiling = 12.0 * Width;
				float NumTiles = floor( TotalLength / Tiling );
				float Offset = ( TotalLength - ( Tiling * NumTiles ) ) / Tiling;
				float2 UV = Input.vTexCoord.yx;
				UV.x = min(UV.x,TotalLength-0.01);
				UV.x /= Tiling;
				UV.x = UV.x + 1.0 - Offset;
				UV.y *= 0.5;
				
				float2 texDdx = ddx(UV);
				float2 texDdy = ddy(UV);
				
				float Tile = UV.x;
				UV.x = mod( UV.x, 0.5 );

				if( Tile >= NumTiles + 0.5 )
				{
					UV.x += 0.5;
				}
				else if( frac( Tile ) > 0.5 )
				{
					UV.x = 0.5 - UV.x;
				}
				
				float2 UVPass = UV;
				UVPass.y += 0.5;
				
				float4 OutColor = PdxTex2DGrad( DiffuseTexture, UV, texDdx, texDdy );
				float4 OutColorPass = PdxTex2DGrad( DiffuseTexture, UVPass, texDdx, texDdy );
				OutColor = lerp( OutColor, OutColorPass, vPassed );

				float vAlpha = RemapClamped( Input.vTexCoord.y, ClipLength, ClipLength + 2.0f, 0.0f, 1.0f );
				
			#ifdef FLAT_MAP
				vAlpha = lerp( 0.0, vAlpha, GetSimulatedFlatMapLerp() );
				//return float4( vAlpha.xxx, 1 );
			#else
				vAlpha = lerp( vAlpha, 0.0, GetSimulatedFlatMapLerp() );
			#endif
				OutColor.rgb = ApplyDistanceFog( OutColor.rgb, Input.vPos );
				
				//return float4(1, 0, 0, 1);
				return float4( OutColor.rgb, OutColor.a * vAlpha );
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

RasterizerState RasterizerState
{
	DepthBias = -10000
	#fillmode = wireframe
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}


Effect ArrowEffect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"

	Defines = {  "ENABLE_GAME_CONSTANTS" } 
}

Effect ArrowEffectFlatMap
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "FLAT_MAP" "ENABLE_GAME_CONSTANTS" }
}