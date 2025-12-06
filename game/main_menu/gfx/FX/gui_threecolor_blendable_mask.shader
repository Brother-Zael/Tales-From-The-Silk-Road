Includes = {
	"standardfuncsgfx.fxh"
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
	"cw/curve.fxh"
	"cw/utility.fxh"
}


ConstantBuffer( PdxConstantBuffer2 )
{
	float4 PrimaryColor;
	float4 SecondaryColor;
	float4 TertiaryColor;
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
				float4 MaskColor =  SampleImageSprite(Mask, Input.UV0);
				float Intensity = 0.75f;
				OutColor = Overlay(TextureColor.rgb, PrimaryColor.rgb, MaskColor.r * Intensity);
				OutColor = Overlay(OutColor.rgb, SecondaryColor.rgb, MaskColor.g * Intensity);
				OutColor = Overlay(OutColor.rgb, TertiaryColor.rgb, MaskColor.b * Intensity);
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


Effect ThreeColorBlendableMask
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect ThreeColorBlendableMaskDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" "NO_HIGHLIGHT" }
}
