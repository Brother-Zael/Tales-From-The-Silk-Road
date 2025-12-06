Includes = {
	"cw/pdxgui.fxh"
	"cw/pdxgui_helper.fxh"
	"cw/pdxgui_sprite_base.fxh"
}

PixelShader = 
{
	MainCode Up
	{
		TextureSampler BaseTexture
		{
			Ref = PdxTexture0
			MagFilter = Linear
			MinFilter = Linear
			MipFilter = Linear
			SampleModeU = Wrap
			SampleModeV = Wrap
		}

		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float OpVar_18 = GuiTime * 2.000000;
				float Var_sin_17 = sin( OpVar_18 );
				float OpVar_23 = Var_sin_17 * 0.500000;
				float OpVar_24 = OpVar_23 + 0.500000;
				float4 Combine_25 = float4( 1.000000, 1.000000, 1.000000, OpVar_24 );
				float4 Var_SampleImageSprite_11 = SampleImageSprite( BaseTexture, Input.UV0 );
				float4 OpVar_20 = Combine_25 * Var_SampleImageSprite_11;
				return OpVar_20;
			}
		]]
	}
}

PixelShader = 
{
	MainCode Over
	{
		TextureSampler BaseTexture
		{
			Ref = PdxTexture0
			MagFilter = Linear
			MinFilter = Linear
			MipFilter = Linear
			SampleModeU = Wrap
			SampleModeV = Wrap
		}

		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float OpVar_44 = GuiTime * 20.000000;
				float Var_sin_43 = sin( OpVar_44 );
				float OpVar_47 = Var_sin_43 * 0.500000;
				float OpVar_48 = OpVar_47 + 0.500000;
				float4 Combine_33 = float4( 1.000000, 1.000000, 1.000000, OpVar_48 );
				float4 Var_SampleImageSprite_11 = SampleImageSprite( BaseTexture, Input.UV0 );
				float4 OpVar_34 = Combine_33 * Var_SampleImageSprite_11;
				return OpVar_34;
			}
		]]
	}
}

Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "Up"
}
Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "Over"
}
Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "Up"
}
Effect Disabled
{
	VertexShader = "VertexShader"
	PixelShader = "Up"
	Defines = { "DISABLED" }
}

