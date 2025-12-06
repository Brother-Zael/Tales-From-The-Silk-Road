Includes = {
	"cw/camera.fxh"
	"cw/random.fxh"
	"cw/utility.fxh"
	"standardfuncsgfx.fxh"
	"terra_incognita_visibility.fxh"
	"terrain.fxh"
}

VertexStruct VS_OUTPUT_TERRA_INCOGNITA
{
	float4 	Position 		: PDX_POSITION;
	float3  	WorldSpacePos	: TEXCOORD0;
	float2 	UV0				: TEXCOORD1;
}

VertexStruct VS_INPUT_TERRA_INCOGNITA
{
    float2 Position					: POSITION;
	float2 UV0      				: TEXCOORD0;
};

VertexShader =
{
	MainCode VS_TerraIncognita
	{
		Input = "VS_INPUT_TERRA_INCOGNITA"
		Output = "VS_OUTPUT_TERRA_INCOGNITA"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_TERRA_INCOGNITA Out;

				float4 pos = float4(Input.Position.x, 0.0f, Input.Position.y, 1.0f);
			#ifdef FLAT_MAP
				pos.y = lerp(pos.y, GetFlatMapHeight(), GetFlatMapLerp());
			#endif
				pos.y += TerraIncognitaHeight;

				Out.Position = FixProjectionAndMul(ViewProjectionMatrix, pos);
				Out.WorldSpacePos = pos.xyz;
				Out.UV0 = Input.UV0;
				return Out;
			}
		]]
		
		
	}
}

PixelShader =
{
	TextureSampler TerraIncognitaDetailTexture
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"

		file = "gfx/map/flatmap/flatmap_detail.dds"
		srgb = yes
	}
	
	TextureSampler TerraIncognitaWorldTexture
	{
		Index = 2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"

		file = "gfx/map/flatmap/terra_incognita.dds"
		srgb = no
	}
	
	TextureSampler FlatMapTexture
	{
		Ref = FlatMap0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler FlatMapDetail
	{
		Ref = FlatMap1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	MainCode PS_TerraIncognita
	{
		Input = "VS_OUTPUT_TERRA_INCOGNITA"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float2 WorldTextureUV = Input.UV0;
				float3 WorldTexture = PdxTex2D( TerraIncognitaWorldTexture, WorldTextureUV ).rgb;

				float2 FlatMapUV = float2(WorldTextureUV.x, 1-WorldTextureUV.y);

				

				#ifdef LOW_QUALITY_SHADERS
					float Visibility = GetBilinear(Input.WorldSpacePos.xz);
				#else
					float Visibility = GetVisibility(Input.WorldSpacePos.xz);
				#endif


				bool Discoverable = (Visibility < 0.01f);
				float3 FlatMap = FlatTerrainShader( Input.WorldSpacePos, FlatMapUV, FlatMapTexture, FlatMapDetail,  Discoverable ).rgb;

				float4 Output = float4( FlatMap.rgb, 1.0f );

				Output.rgb = lerp(Output.rgb, vec3(0.0f), WorldTexture.r * 0.75f);
				Output.rgb = lerp(Output.rgb, vec3(0.0f), WorldTexture.g * 0.5f);

				float3 GreyscaleOutput = dot(Output.rgb, float3(0.299, 0.587, 0.114)).xxx; // matches human color perception
				Output.rgb = lerp(Output.rgb, GreyscaleOutput, 0.5);
				if(Discoverable)
					Output *= 0.1;
				else					
					Output *= 0.25;

				//float2 DetailTextureUV = Input.UV0 * TerraIncognitaTextureScale;
				//float2 DetailTextureUVLarge = TextureUV * 0.375;
				//float4 DetailTexture = PdxTex2D( TerraIncognitaTexture, DetailTextureUV ).rgba;
				//float4 DetailTextureLarge = PdxTex2D( TerraIncognitaTexture, DetailTextureUVLarge ).rgba;

				//float3 Color1 = HSVtoRGB( float3 ( 0.05,  0.5, 0.0 ) );
				//float3 Color2 = HSVtoRGB( float3 ( 0.2,  0.5, 0.15 ) );

				//float3 Color3 = HSVtoRGB( float3 ( 0.01,  0.2, 0.15 ) );
				//float3 Color4 = HSVtoRGB( float3 ( 0.2,  0.2, 0.1 ) );

				//float3 Gradient1 = lerp(Color1, Color2, DetailTexture.r );
				//float3 Gradient2 = lerp(Color3, Color4, DetailTexture.g );

				////float Blend = GetOverlay(DetailTexture.r, DetailTexture, 0.5 );

				//float4 Output = float4( lerp(Gradient1, Gradient2, DetailTextureLarge.g ), 1.0f );

				//Output.rgb = ToGamma( Output.rgb );
				#ifdef LOW_QUALITY_SHADERS
					Output.a = 1 - GetVisibility(Input.WorldSpacePos.xz);
				#else
					Output.a = 1 - GetBilinear(Input.WorldSpacePos.xz);
					Output.rgb *= Output.a;
				#endif
				return Output;
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}

RasterizerState RasterizerState
{
	#DepthBias = -10000
	FillMode = "solid"
	CullMode = "none"
	#FrontCCW = yes
	#FillMode = "wireframe"
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
	DepthWriteEnable = no
}

Effect TerraIncognita
{
	VertexShader = VS_TerraIncognita
	PixelShader = PS_TerraIncognita
}
