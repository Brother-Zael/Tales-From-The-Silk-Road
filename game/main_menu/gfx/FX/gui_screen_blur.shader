Includes = {
	"cw/pdxgui_sprite_base.fxh"
	"cw/pdxgui_sprite_textures.fxh"
	"cw/pdxgui.fxh"
}

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_GUI"
		Output = "VS_OUTPUT_PDX_GUI"
		Code
		[[
			PDX_MAIN
			{
				return PdxGuiDefaultVertexShader( Input );
			}
		]]
	}
}

PixelShader =
{
	MainCode PixelShader
	{
		TextureSampler Texture
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}

		TextureSampler ScreenGrab
		{
			Ref = ScreenGrabTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}

		ConstantBuffer( ScreenGrabConstants0 )
		{
			float3x3 ScreenCoordToScreenGrabUV;
		}
	
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			#define GUI_BLUR_MAX_MIPS 6.0f
			
			float4 SampleBlurred(in PdxTextureSampler2D Sampler, float2 UV, float BlurScale)
			{
				return PdxTex2DLod( Sampler, UV, pow( BlurScale, 0.5f ) * ( GUI_BLUR_MAX_MIPS - 1.0f ) );
			}

			PDX_MAIN
			{
				float4 MaskColor = SampleSpriteTexture( Texture, Input.UV0, 0 );
				float2 UV = float2(Input.UV0 - SpriteUVRect.xy) / SpriteUVRect.zw;

				float2 ScreenGrabUV = mul( ScreenCoordToScreenGrabUV, float3( Input.Position.xy, 1.0f ) ).xy;

				float4 ScreenColor = SampleBlurred( ScreenGrab, ScreenGrabUV, MaskColor.r );
				ScreenColor.a = MaskColor.a;

				float4 OutColor = ScreenColor;
				OutColor *= Input.Color;
				
				ApplyModifyTextures( OutColor, Input.UV0 );

				#ifdef DISABLED
					OutColor.rgb = DisableColor( OutColor.rgb );
				#endif
				
			    return OutColor;
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

DepthStencilState DepthStencilState
{
	DepthEnable = no
}

Effect PdxGuiDefault
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect PdxGuiDefaultDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" }
}
