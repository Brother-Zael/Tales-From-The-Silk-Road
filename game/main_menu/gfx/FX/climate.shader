Includes = {
	"cw/fullscreen_vertexshader.fxh"
	"jomini/jomini_colormap.fxh"
	"jomini/jomini_province_overlays.fxh"
	"cw/random.fxh"
	"winter.fxh"
	"climate.fxh"
}

PixelShader =
{

	TextureSampler ProvinceWinterness
	{
		Ref = PdxTexture0
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler SnowNoise
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	
	TextureSampler HemisphereUVOffset
	{
		Ref = PdxTexture2
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	MainCode PS_main
	{
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				//float2 ColorIndex = PdxTex2DLod0( IndirectionMap, Input.uv ).rg;
				//float Winterness = ColorSample( Input.uv, IndirectionMap, ProvinceWinterness );
				float Winterness = BilinearColorSample( Input.uv, SnowTextureSize * 0.5f, InvSnowTextureSize * 2.0f, ProvinceColorIndirectionTexture, ProvinceWinterness ).r;

				float Noise = PdxTex2DLod0( SnowNoise, Input.uv * SnowTextureSize / SnowNoiseTextureSize ).r;
				float HemisphereUVOffsetValue = ColorSample( Input.uv, ProvinceColorIndirectionTexture, HemisphereUVOffset ).r;
				return float4( Winterness, Noise, HemisphereUVOffsetValue, 0 );
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = no
}
Effect create_climate_map
{
	VertexShader = VertexShaderFullscreen
	PixelShader = PS_main
}