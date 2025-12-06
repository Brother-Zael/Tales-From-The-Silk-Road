Includes = {
	"cw/shadow.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_river_bottom.fxh"
	"terrain.fxh"
	#"constants.fxh"
	"standardfuncsgfx.fxh"
	"river_vertex_shader.fxh"
}

VertexShader = 
{
	MainCode CaesarRiverVertexShader
	{
		Input = "VS_INPUT_RIVER"
		Output = "VS_OUTPUT_RIVER"
		Code
		[[		
			PDX_MAIN
			{
				return CaesarRiverVertexShader( Input );
			}		
		]]
	}
}

PixelShader =
{		
	
	MainCode PS_underwater
	{
		Input = "VS_OUTPUT_RIVER"
		Output = "PS_RIVER_BOTTOM_OUT"
		Code
		[[	
			
			
			PDX_MAIN
			{				
				PS_RIVER_BOTTOM_OUT Out = CalcRiverBottomAdvanced( Input );

				#ifdef TERRAIN_COLOR_OVERLAY
					float3 ColorOverlay;
					float PreLightingBlend;
					float PostLightingBlend;
					float2 ColorMapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;

					GetProvinceOverlayAndBlendCustom( ColorMapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
					float ColorMask = saturate( PreLightingBlend + PostLightingBlend );
					Out.Color.rgb = lerp(Out.Color.rgb, ColorOverlay, ColorMask*0.5);
				#endif
				
				return Out;
			}
		]]
	}
}
RasterizerState RiverBottomRasterizer
{
	DepthBias = -50000
	SlopeScaleDepthBias = -5
}
Effect river_underwater
{
	RasterizerState = RiverBottomRasterizer
	VertexShader = "CaesarRiverVertexShader"
	PixelShader = "PS_underwater"

	Defines = {  "ENABLE_TERRAIN"  "ENABLE_GAME_CONSTANTS"  }
}