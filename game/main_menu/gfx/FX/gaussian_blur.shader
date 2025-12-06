
Includes = {
	"cw/fullscreen_vertexshader.fxh"
	"cw/utility.fxh"
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
		
		ConstantBuffer( PdxConstantBuffer0 )
		{
			float Lod;
			float StandardDeviation;
			
			float2 Axis;
			float2 SourceSize;
			float2 ViewPortSize;
			float2 OriginalSourceSize;
		}
	
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			float Gaussian( float Distance )
			{
				static const float InvSqrt2Pi = 0.398942280401;
				return ( InvSqrt2Pi / StandardDeviation ) * exp( -Distance * Distance / ( 2.0f * StandardDeviation * StandardDeviation ) );
			}
			PDX_MAIN
			{
				float4 Color = vec4(0.0f);
				float R = StandardDeviation * 3.0f;
				float Step = R * 2 / ceil( R * 2 / Lod );
				//float Step = R * 2 / ( R * 2 / Lod );
				float Acc = 0.0f;
				
				float2 ViewPortScale = ViewPortSize / OriginalSourceSize;
				float2 DownScaling = ViewPortSize / SourceSize;
				float2 UvScale = ViewPortScale / DownScaling;
				float2 AxisScale = 1.0f / DownScaling;
				
				float2 UV = Input.uv * UvScale;
					
				for( float i = -R; i <= R; i += Step )
				{
					float Gauss = Gaussian( i );
					float2 Coord = UV + Axis * AxisScale * i;		
					Coord = clamp( Coord, vec2(0.0), ( SourceSize - vec2(0.5f) ) / OriginalSourceSize );
					Acc += Gauss;
					#ifdef GAMMA
					Color += ToLinear( PdxTex2DLod0( Texture, Coord ) ) * Gauss;
					#else
					Color += PdxTex2DLod0( Texture, Coord ) * Gauss;
					#endif
				}
				#ifdef GAMMA
			    return float4( ToGamma( Color.rgb / Acc ), Color.a / Acc );
				#else
				return Color / Acc;
				#endif
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = no
	WriteMask = "RED|GREEN|BLUE|ALPHA"
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
}

Effect Gamma
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "PixelShader"
	Defines = { "GAMMA" }
}
Effect Linear
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "PixelShader"
}
