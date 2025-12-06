Includes = {
	"cw/fullscreen_vertexshader.fxh"
	"cw/camera.fxh"
	"jomini/jomini.fxh"
}

PixelShader =
{
    MainCode PixelShaderTexture
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
			
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{
				float4 Ret = float4( PdxTex2D( Texture, Input.uv ).rgb, 1.0 );
                
				return Ret;
			}
		]]
	}
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
	DepthWriteEnable = no
}


Effect DrawBackground
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "PixelShaderTexture"
}