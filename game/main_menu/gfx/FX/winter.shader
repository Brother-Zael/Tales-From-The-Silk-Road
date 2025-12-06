Includes = {
	"cw/fullscreen_vertexshader.fxh"
	"jomini/jomini_colormap.fxh"
	"cw/random.fxh"
	"winter.fxh"
}

PixelShader =
{
	TextureSampler IndirectionMap
	{
		Ref = JominiProvinceColorIndirection
		MinFilter = "Point"
		MagFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler ProvinceWinterness
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
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
				float Winterness = BilinearColorSample( Input.uv, SnowTextureSize * 0.5f, InvSnowTextureSize * 2.0f, IndirectionMap, ProvinceWinterness ).r;
				float Noise = PdxTex2DLod0( SnowNoise, Input.uv * SnowTextureSize / SnowNoiseTextureSize ).r;
				return float4( Winterness, Noise, 0, 0 );
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = no
}
Effect create_winter_map
{
	VertexShader = VertexShaderFullscreen
	PixelShader = PS_main
}