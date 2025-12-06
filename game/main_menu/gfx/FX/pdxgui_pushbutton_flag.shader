Includes = {
	"standardfuncsgfx.fxh"
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
	"cw/curve.fxh"
	"cw/utility.fxh"
}


ConstantBuffer( PdxConstantBuffer2 )
{
	float3 HighlightColor;
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
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{			
				return SampleImageSprite( Texture, Input.UV0 );
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


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "ENABLE_GAME_CONSTANTS" }
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "ENABLE_GAME_CONSTANTS" }
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "ENABLE_GAME_CONSTANTS" }
}

Effect Disabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "DISABLED" "ENABLE_GAME_CONSTANTS" }
}


Effect NoHighlightUp
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "NO_HIGHLIGHT" "ENABLE_GAME_CONSTANTS" }
}

Effect NoHighlightOver
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "NO_HIGHLIGHT" "ENABLE_GAME_CONSTANTS" }
}

Effect NoHighlightDown
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "NO_HIGHLIGHT" "ENABLE_GAME_CONSTANTS" }
}

Effect NoHighlightDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "DISABLED" "NO_HIGHLIGHT" "ENABLE_GAME_CONSTANTS" }
}

Effect GreyedOutUp
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "DISABLED" "ENABLE_GAME_CONSTANTS" }
}

Effect GreyedOutOver
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "DISABLED" "ENABLE_GAME_CONSTANTS" }
}

Effect GreyedOutDown
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "DISABLED" "ENABLE_GAME_CONSTANTS" }
}

Effect GreyedOutDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"	
	Defines = { "DISABLED" "NO_HIGHLIGHT" "ENABLE_GAME_CONSTANTS" }
}
