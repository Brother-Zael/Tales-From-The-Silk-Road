Includes = {
	"jomini/countrynames.fxh"
	"jomini/jomini_fog.fxh"
	"fog_of_war.fxh"
	"standardfuncsgfx.fxh"
	"flatmap_lerp.fxh"
}

VertexShader =
{
	MainCode MapNameVertexShader
	{
		Input = "VS_INPUT_MAPNAME"
		Output = "VS_OUTPUT_MAPNAME"
		Code
		[[
			PDX_MAIN
			{
				float3 Position = Input.Position;
				AdjustFlatMapHeight( Position );
				VS_OUTPUT_MAPNAME Out = MapNameVertexShader( Input, Position.y, 1.0f );
				return Out;
			}
		]]
	}
}

PixelShader =
{
	TextureSampler FontAtlas
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	MainCode MapNamePixelShader
	{
		Input = "VS_OUTPUT_MAPNAME"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
			float4 TextColor = float4( 0, 0, 0, 1 );
			float4 OutlineColor = float4( 1, 1, 1, 0.5 );

			float Sample = PdxTex2D( FontAtlas, Input.TexCoord ).r;
			
			float2 TextureCoordinate = Input.TexCoord * TextureSize;
			float Ratio = CalcTexelPixelRatio( TextureCoordinate );
			
			float Smoothing = 0.05f + Ratio * LodFactor;
			float Mid = 0.5f;

			float Factor = smoothstep( Mid - Smoothing, Mid, Sample );

			float4 MixedColor = lerp( OutlineColor, TextColor, Factor );

			// Set OutlineWidth to control outline width
			float OutlineWidth = 0.075;
			float OutlineSmoothing = OutlineWidth + Ratio * LodFactor * 0.1f;
			float OutlineFactor = smoothstep( Mid - OutlineSmoothing, Mid, Sample );
			MixedColor.a *= OutlineFactor;
			
			MixedColor.a *= Transparency;

			MixedColor.rgb = ApplyFogOfWar( MixedColor.rgb, Input.WorldSpacePos, FogOfWarAlpha );
			if( GetFlatMapLerp() < 1.0f )
			{
				MixedColor.rgb = lerp( ApplyDistanceFog( MixedColor.rgb, Input.WorldSpacePos ), MixedColor.rgb, GetFlatMapLerp() );
			}
			//Avoid displaying the text if it is too small to be read
			MixedColor.a=min( (1-smoothstep(8,16,Ratio)),MixedColor.a);
			return MixedColor;
			
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
	WriteMask = "RED|GREEN|BLUE"
}

RasterizerState RasterizerState
{
	frontccw = yes
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
	StencilEnable = yes
	FrontStencilFunc = not_equal
	StencilRef = 1
}


Effect mapname
{
	VertexShader = "MapNameVertexShader"
	PixelShader = "MapNamePixelShader"
}

