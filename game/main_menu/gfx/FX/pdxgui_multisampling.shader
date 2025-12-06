Includes = {
	"cw/pdxgui_sprite_base.fxh"
	"cw/pdxgui_sprite_textures.fxh"
	"cw/pdxgui_default_base.fxh"
}

PixelShader =
{
	MainCode PixelShaderMultisample
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
	
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float2 UV = Input.UV0;
				float2 TexelSize = 1/SpriteSize.xy;
				float4 Color1=SampleSpriteTexture( Texture, UV + float2(TexelSize.x,TexelSize.y), 0 );
				float4 Color2=SampleSpriteTexture( Texture, UV + float2(TexelSize.x,-TexelSize.y), 0 );
				float4 Color3=SampleSpriteTexture( Texture, UV + float2(-TexelSize.x,TexelSize.y), 0 );
				float4 Color4=SampleSpriteTexture( Texture, UV + float2(-TexelSize.x,-TexelSize.y), 0 );
				
				float4 OutColor = SampleSpriteTexture( Texture, UV , 0 );
				OutColor.a = (OutColor.a+Color1.a+Color2.a+Color3.a+Color4.a)*0.20;


				UV = (UV - SpriteUVRect.xy) / SpriteUVRect.zw;

				ApplyModifyTextures( OutColor, UV );

				OutColor *= Input.Color;
				
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

BlendState BlendStateNoAlpha
{
	BlendEnable = no
}

BlendState PreMultipliedAlpha
{
	BlendEnable = yes
	SourceBlend = "ONE"
	DestBlend = "INV_SRC_ALPHA"
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
}

Effect PdxGuiAlphaMultisampled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderMultisample"
}

Effect PdxGuiAlphaMultisampledDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderMultisample"
	Defines = { "DISABLED" }
}