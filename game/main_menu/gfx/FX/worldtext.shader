Includes = {
	"standardfuncsgfx.fxh"
	"cw/camera.fxh"
}

ConstantBuffer( PdxConstantBuffer0 )
{
	float3		OriginPosition;
	float		Transparency;
	float2		TextureSize;
	float		LodFactor;
	float 		OutlineWidth;
	float4		TextColor;
	float4		OutlineColor;
	float 		Scale;
	float2 		ScreenPositionOffset;
};

VertexStruct VS_INPUT_WORLDTEXT
{
    float2 Position 	: POSITION;
	float2 TexCoord 	: TEXCOORD0;
};

VertexStruct VS_OUTPUT_WORLDTEXT
{
    float4 Position 		: PDX_POSITION;
	float3 WorldSpacePos 	: TEXCOORD0;
    float2 TexCoord			: TEXCOORD1;
};


VertexShader =
{
	MainCode WorldTextVertexShader
	{
		Input = "VS_INPUT_WORLDTEXT"
		Output = "VS_OUTPUT_WORLDTEXT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_WORLDTEXT Out;
				Out.WorldSpacePos =  (Input.Position.x*CameraRightDir*Scale)+(Input.Position.y*CameraUpDir*Scale)+OriginPosition;
				Out.TexCoord = Input.TexCoord;
				float4  vPos =  float4(Out.WorldSpacePos, 1.0f );
				float4 ScreenPosition =  FixProjectionAndMul( ViewProjectionMatrix, vPos );
				ScreenPosition.xy += ScreenPositionOffset;
				Out.Position = ScreenPosition;
				return Out;
			}
		]]
	}
}

PixelShader =
{
	TextureSampler FontAtlas
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	
	MainCode WorldTextPixelShader
	{
		Input = "VS_OUTPUT_WORLDTEXT"
		Output = "PDX_COLOR"
		Code
		[[
			float CalcTexelPixelRatio( float2 TextureCoordinate )
			{
				float2 DX = ddx( TextureCoordinate );
				float2 DY = ddy( TextureCoordinate );
				float MaxSquared = max( dot( DX, DX ), dot( DY, DY ) );
				return sqrt( MaxSquared );
			}
		
			PDX_MAIN
			{

			float Sample = PdxTex2D( FontAtlas, Input.TexCoord ).r;
			
			float2 TextureCoordinate = Input.TexCoord * TextureSize;
			float Ratio = CalcTexelPixelRatio( TextureCoordinate );
			float Smoothing = 0.05+ Ratio * LodFactor;
			float Mid = 0.5f;

			float Factor = smoothstep( Mid - Smoothing, Mid, Sample );
			float4 MixedColor = lerp(  OutlineColor, TextColor, Factor );


			float OutlineSmoothing = OutlineWidth + Ratio * LodFactor * 0.1f;
			float OutlineFactor = smoothstep( Mid - OutlineSmoothing, Mid, Sample );
			MixedColor.a *= OutlineFactor;
			
			MixedColor.a *= Transparency;
			//return TextColor;
			return MixedColor;
			}
		]]
	}
}

	
BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
	WriteMask = "RED|GREEN|BLUE"
}

RasterizerState RasterizerState
{
	frontccw = yes
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
	StencilEnable = no
}


Effect worldtext
{
	VertexShader = "WorldTextVertexShader"
	PixelShader = "WorldTextPixelShader"
}

