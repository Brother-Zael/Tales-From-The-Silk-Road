Includes = {
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
	"cw/curve.fxh"
	"cw/utility.fxh"
	"standardfuncsgfx.fxh"
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

	MainCode ProfilerGraphVertexShader
	{
		Input = "VS_INPUT_PDX_GUI_PROFILER"
		Output = "VS_OUTPUT_PDX_GUI"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_GUI Out;
				float2 PixelPos = WidgetLeftTop + Input.LeftTop_WidthHeight.xy + Input.Position * Input.LeftTop_WidthHeight.zw;
				Out.Position = PixelToScreenSpace( PixelPos );

				float2 UV = float2( 0.0, 0.0 );
				if ( Input.VertexID == 0 )
				{
					UV = float2( 1.0, 0.0 );
				}
				else if ( Input.VertexID == 1 )
				{
					UV = float2( 1.0, 1.0 );
				}
				else if ( Input.VertexID == 2 )
				{
					UV = float2( 0.0, 0.0 );
				}
				else if ( Input.VertexID == 3 )
				{
					UV = float2( 0.0, 1.0 );
				}

				Out.UV0 = Input.UVLeftTop_WidthHeight.xy + UV * Input.UVLeftTop_WidthHeight.zw;
				Out.Color = Input.Color;
				return Out;
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
	
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				/////////////////////////////////////////////////////////////

				float4 	HSV_SHADOW = float4( 
					198, 	// background 	hue
					0.25, 	//            	saturation %
					0.1,  	//            	value %
					1.0 	//            	alpha
				);

				float4 	HSV_BG = float4( 
					197, 	// background 	hue
					100, 	//            	saturation %
					7,  	//            	value %
					0.9 	//            	alpha
				);

				float4 	HSV_FRAME = float4( 
					35, 	// frame		hue
					100, 	//            	saturation %
					80,  	//            	value %
					1.0 	//            	alpha
				);
				
				float SHINE_SPEED = 1.5;
				float SHINE_INTENSITY = 0.25;
				float SHINE_SCALE = 100;

				/////////////////////////////////////////////////////////////

				float SinePos = ( -Input.Position.x -Input.Position.y ) / SHINE_SCALE;
				float Sine = Sin01( SinePos + ( GetGlobalTime() * SHINE_SPEED ) );

				float4 Color0 = HSVtoRGB( HSV_SHADOW.r/360, HSV_SHADOW.g/100, HSV_SHADOW.b/100, HSV_SHADOW.a );
				float4 Color1 = HSVtoRGB( HSV_BG.r/360, HSV_BG.g/100, HSV_BG.b/100, HSV_BG.a );
				float4 Color2 = HSVtoRGB( HSV_FRAME.r/360, HSV_FRAME.g/100, HSV_FRAME.b/100, HSV_FRAME.a );

				float4 Masks = SampleImageSprite( Texture, Input.UV0 );

				float4 OutColor = Color0;
				OutColor = lerp( OutColor, Color1, Masks.r );
				OutColor = lerp( OutColor, Color2, Masks.g );
				OutColor.rgb = GetOverlay( OutColor.rgb, Sine, Masks.g * SHINE_INTENSITY );
				OutColor.a *= Masks.a;


				OutColor *= Input.Color;
				
				#ifdef DISABLED
					OutColor.rgb = DisableColor( OutColor.rgb );
				#endif
			    return OutColor;
			}
		]]
	}

	MainCode ProfilerGraphPixelShader
	{
		TextureSampler Texture
		{
			Ref = PdxTexture0
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "Point"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}

			Input = "VS_OUTPUT_PDX_GUI"
			Output = "PDX_COLOR"
			Code
			[[
			PDX_MAIN
			{
				float4 OutColor = SampleImageSprite( Texture, Input.UV0 );
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

Effect PdxGuiDefaultNoAlpha
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = BlendStateNoAlpha
}
Effect PdxGuiDefaultNoAlphaDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = BlendStateNoAlpha
	
	Defines = { "DISABLED" }
}

Effect PdxGuiPreMultipliedAlpha
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = PreMultipliedAlpha
}
Effect PdxGuiPreMultipliedAlphaDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = PreMultipliedAlpha
	
	Defines = { "DISABLED" }
}

Effect PdxGuiProfileGraph
{
	VertexShader = "ProfilerGraphVertexShader"
	PixelShader = "ProfilerGraphPixelShader"
}
Effect PdxGuiProfileGraphDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" }
}
