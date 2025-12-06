Includes = {
	"standardfuncsgfx.fxh"
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
	"cw/curve.fxh"
	"cw/utility.fxh"
}


ConstantBuffer( PdxConstantBuffer2 )
{
	float4 OverlayColor;
};


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
	TextureSampler Texture
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Border"
		SampleModeV = "Border"
		Border_Color = { 0 0 0 0 }
	}

	TextureSampler Mask
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Border"
		SampleModeV = "Border"
		Border_Color = { 0 0 0 0 }
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{		
				float4 OutColorAndAlpha;
				float3 OutColor;
				float4 TextureColor = SampleImageSprite( Texture, Input.UV0 );
				float4 MaskColor =  PdxTex2D(Mask, Input.UV0);
				#ifdef RED_CHANNEL
					float Alpha = MaskColor.r;
				#endif
				#ifdef GREEN_CHANNEL
					float Alpha = MaskColor.g;
				#endif
				#ifdef  BLUE_CHANNEL
					float Alpha = MaskColor.b;
				#endif
				#ifdef  ALPHA_CHANNEL
					float Alpha = MaskColor.a;
				#endif
				#ifdef MULTIPLY
					OutColor=Multiply(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef  OVERLAY
					OutColor=Overlay(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef COLOR_DODGE
					OutColor=ColorDodge(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef SOFT_LIGHT
					OutColor=SoftLight(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef HARD_LIGHT
					OutColor=HardLight(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef ADD
					OutColor=Add(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef  DARKEN
					OutColor=Darken(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				#ifdef  LIGHTEN
					OutColor=Lighten(TextureColor.rgb, OverlayColor.rgb, Alpha);
				#endif
				OutColorAndAlpha = float4(OutColor,TextureColor.a);
				OutColorAndAlpha*= Input.Color;

				#ifdef DISABLED
					OutColorAndAlpha.rgb = DisableColor( OutColor.rgb );
				#endif

			    return OutColorAndAlpha;
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


Effect GuiMaskBlend
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect GuiMaskBlendDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" "NO_HIGHLIGHT" }
}
