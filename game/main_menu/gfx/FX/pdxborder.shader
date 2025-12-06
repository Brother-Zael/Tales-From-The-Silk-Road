Includes = {
	"cw/camera.fxh"
    "cw/shadow.fxh"
	"jomini/jomini_fog.fxh"
	"fog_of_war.fxh"
	"jomini/jomini_flat_border.fxh"
	"standardfuncsgfx.fxh"
	"flatmap_lerp.fxh"
    "jomini/jomini_lighting.fxh"
	"terra_incognita_visibility.fxh"
}

VertexStruct VS_OUTPUT_PDX_BORDER
{
	float4 Position : PDX_POSITION;
	float3 WorldSpacePos : TEXCOORD0;
	float2 UV : TEXCOORD1;
	float AlphaMultipliyer : PSIZE0;
	float SmoothTexture : PSIZE1;
	float BorderLod : PSIZE2;
    float3 Normal : TEXCOORD2;
};

Code =
[[
	float4 UnpackJominiColor( uint Packed )
	{
		return float4( uint4( ( Packed >> 16 ) & 0xff, ( Packed >> 8 ) & 0xff, Packed & 0xff, Packed >> 24) ) / UINT8_MAX;
	}
]]

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_BORDER"
		Output = "VS_OUTPUT_PDX_BORDER"
		Code
		[[			
			PDX_MAIN
			{
				VS_OUTPUT_PDX_BORDER Out;
				float DisappearLevel = 700.0f;
				//Disappear levels reflect the values in ZOOM_STEPS game/gfx/defines/00_gfx.txt
				#ifdef DISAPEAR_L10
					DisappearLevel = 1000.0f;
				#endif
				#ifdef DISAPEAR_L20
					DisappearLevel = 3583.0f;
				#endif
				
				float TooSmall = saturate ( 0.001f * ( DisappearLevel - CameraPosition.y ) );
				float TooSmallForSize = saturate ( 0.001f * ( 1500 - CameraPosition.y ) );
				//We always shrink the borders (as they have multipliyed by this amount the desired width in code) to be able to unshirnk them when zooming out if they are being drawn and avoid artifacts
				#ifdef ALWAYS_DRAW
					float SizeMult = 1+3*(1-TooSmallForSize);
				#else
					float SizeMult =1+(1-TooSmallForSize);;
				#endif
				//TODO-8799 find the cause for the pixel offset and remove this Correction 
				float2 Correction  = float2(0.5f, 0.5f);
				float2 InputPositionCorrected =  Input.Position + Correction;
				float2 InputCenterCorrected =Input.Center + Correction;
				//using the max height instead of the correct height will make borders smoother and go over the terrain in most of the cases
				float InputPositionHeight = GetHeight( InputPositionCorrected );
				float CenterPositionHeight = GetHeight( InputCenterCorrected );
				// MaxHeight = max(InputPositionHeight, GetHeight( InputCenterCorrected ));
				float3 VertexPos3d = float3( InputPositionCorrected.x, InputPositionHeight, InputPositionCorrected.y );                
				float3 CenterPos3d = float3( InputCenterCorrected.x, CenterPositionHeight, InputCenterCorrected.y );
				float OriginalHalfWidth = length( Input.Position - Input.Center );
				
				#ifdef WIDTH
					SizeMult *= WIDTH;
				#endif
				
				VertexPos3d = CenterPos3d + normalize( VertexPos3d - CenterPos3d ) * OriginalHalfWidth * SizeMult;
				
				const float SampleWidth = 0.1f;
				float HeightSampleX = GetHeight( float2( VertexPos3d.x + SampleWidth, VertexPos3d.z ));
				float HeightSampleY = GetHeight( float2( VertexPos3d.x, VertexPos3d.z + SampleWidth ));
				float3 X = float3( SampleWidth,HeightSampleX - VertexPos3d.y, 0.0f );
				float3 Z = float3( 0.0f, HeightSampleY - VertexPos3d.y, SampleWidth );
				Out.Normal = normalize( -cross( X, Z ) );
				
                AdjustFlatMapHeight( VertexPos3d );
				VertexPos3d.y += _HeightOffset;
				#ifdef SEA_LEVEL
					VertexPos3d.y = max(VertexPos3d.y, GetWaterHeight());
				#endif

				float MaxHeight = max(max(max(InputPositionHeight,CenterPositionHeight),HeightSampleX),HeightSampleY);
				float MinHeight = min(min(min(InputPositionHeight,CenterPositionHeight),HeightSampleX),HeightSampleY);
				float HeightDifference = MaxHeight - MinHeight;
				HeightDifference*=0.2f;//This value is added by trial and error (1.0f) would avoid all clipping but trees start to bein drawn below in mountains
				HeightDifference = max(HeightDifference,0.01f); //Minimum offset for avoiding z-fighting in a totally flat terrain
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( VertexPos3d, 1.0 ) );
				float4 BiasPosition = FixProjectionAndMul( ViewProjectionMatrix, float4( VertexPos3d.x,VertexPos3d.y+HeightDifference,VertexPos3d.z, 1.0 ) );
				Out.Position.z = BiasPosition.z;
				Out.WorldSpacePos = VertexPos3d;
                Out.UV = Input.UV;
				
				Out.AlphaMultipliyer =TooSmall;
				Out.SmoothTexture = TooSmallForSize;
				Out.BorderLod = log2(max (1,CameraPosition.y/32.0f));
				return Out;
			}
		]]
	}
}


PixelShader =
{	
	TextureSampler BorderTexture
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler ProvinceColorIndirectionTexture
	{
		Ref = JominiProvinceColorIndirection
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Wrap"
		SampleModeV = "Border"
		Border_Color = { 0 0 0 0 }
	}
	
	TextureSampler ShadowTexture
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}
	TextureSampler EnvironmentMap
	{
		Ref = JominiEnvironmentMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "Cube"
	}

	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PDX_COLOR"
		Code
		[[	
			PDX_MAIN
			{
				#ifdef PDX_USE_MIPLEVELTOOL
					float4 Diffuse = PdxTex2DLodMipTool( BorderTexture, Input.UV, Input.BorderLod);
				#else
					float4 Diffuse = PdxTex2DLod( BorderTexture, Input.UV, Input.BorderLod);
				#endif // PDX_USE_MIPLEVELTOOL

				#ifdef USER_COLOR
					float4 UserColor = UnpackJominiColor( _UserId );
					float3 GreyscaleUserColor = dot(UserColor.xyz, float3(0.299, 0.587, 0.114)).xxx; // matches human color perception
					UserColor.rgb = lerp(UserColor.rgb, GreyscaleUserColor, 0.2f);
					UserColor.rgb *= 0.9f;
					Diffuse.rgb *= UserColor.rgb;
					#ifdef NOT_USER_COLOR_IN_FLATMAP
					float FlatMapBlend = GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp() ).x;
					Diffuse.rgb *= 1.0f - FlatMapBlend;
					Diffuse.a = lerp( Diffuse.a, 0.5f, FlatMapBlend );
					#endif
					
				#endif

				#ifdef PULSATE
					Diffuse.rgb *= 1.0f + pow( sin( GetGlobalTime() * 2 ) * 0.5f + 0.5f, 1.5 ) * 3.0f;
				#endif
				#ifdef PULSATE_ROTATE
					Diffuse.rgb *= 1.0f + pow( sin( GetGlobalTime() * 2 + 0.2f * (Input.WorldSpacePos.x + Input.WorldSpacePos.z) ) * 0.5f + 0.5f, 1.5 ) * 3.0f;
				#endif
				
				if( GetFlatMapLerp() < 1.0f ) 
				{
					// diffuse lighting (no specular)
					float ShadowBias = RemapClamped( length( Input.WorldSpacePos - CameraPosition ), 60.0f, 130.0f, 0.0f, 5.0f );
					float4 ShadowProj = mul( ShadowMapTextureMatrix, float4( Input.WorldSpacePos + ToSunDir * ShadowBias, 1.0 ) );
					float ShadowTerm = CalculateShadow( ShadowProj, ShadowTexture );

					// Sample environment map for IBL ambient light
					float3 RotatedDiffuseCubemapUV = mul( CastTo3x3( CubemapYRotation ), Input.Normal );
					float3 IBLDiffuseLight = PdxTexCubeLod( EnvironmentMap, RotatedDiffuseCubemapUV, ( PDX_NumMips - 1 - PDX_MipOffset ) ).rgb * CubemapIntensity;

					// Calc light from the sun
					float NdotL = saturate( dot( Input.Normal, ToSunDir ) ) + 1e-5;
					float3 SunDiffuseLight = SunDiffuse * SunIntensity * ShadowTerm * NdotL / PI;

					Diffuse.rgb = Diffuse.rgb * ( SunDiffuseLight + IBLDiffuseLight );

					float3 Unfogged = Diffuse.rgb;
					Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, Input.WorldSpacePos, FogOfWarAlpha );
					Diffuse.rgb = ApplyDistanceFog( Diffuse.rgb, Input.WorldSpacePos );
					Diffuse.rgb = lerp( Diffuse.rgb, Unfogged, GetFlatMapLerp() );
				}
				

				Diffuse.a*=(saturate(Input.UV.y)==Input.UV.y);
				#ifndef ALWAYS_DRAW
					Diffuse.a *= _Alpha*Input.AlphaMultipliyer;
				#else
					Diffuse.a *= _Alpha;
					#ifdef  HALF_ALFA
						Diffuse.a=lerp(0.25f,Diffuse.a,Input.SmoothTexture);	
					#else
						Diffuse.a=lerp(1.0f,Diffuse.a,Input.SmoothTexture);
					#endif
				#endif
				#ifndef SEA_LEVEL
					Diffuse.a *=smoothstep(-1,0,Input.WorldSpacePos.y-GetWaterHeight());
				#endif
				
				#ifndef IGNORE_TERRA_INCOGNITA
					if(GetBorderTakeTerraIncognitaIntoAccount() > 0)
					{
					#ifdef LOW_QUALITY_SHADERS
						Diffuse.a = Diffuse.a * GetVisibility(Input.WorldSpacePos.xz);
					#else
						Diffuse.a = Diffuse.a * GetBilinear(Input.WorldSpacePos.xz);
						Diffuse.rgb *= Diffuse.a;
					#endif
					}
				#endif

				return Diffuse;
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}

RasterizerState RasterizerState
{
	#CullMode = None
    #fillmode = wireframe
    DepthBias = -500
	SlopeScaleDepthBias = -2
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
	StencilEnable = yes
	FrontStencilFunc = not_equal
	StencilRef = 1
}

Effect PdxBorder
{

	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = {"ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect PdxBorderL10
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "DISAPEAR_L10" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS"}
}

Effect CountryBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "USER_COLOR" "HALF_ALFA" "DISAPEAR_L20" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" "NOT_USER_COLOR_IN_FLATMAP" }
}

Effect MarketBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "USER_COLOR" "WIDTH 0.75f" "ALWAYS_DRAW" "HALF_ALFA" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect ImpassableBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "IMPASSABLE_BORDER" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect PdxBorderSelected
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = {  "SEA_LEVEL" "ALWAYS_DRAW" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect PdxBorderLobbySelected
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = {  "SEA_LEVEL" "ALWAYS_DRAW" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}


Effect PdxBorderSea
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "SEA_LEVEL" "DISAPEAR_L20" "HALF_ALFA" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS"}
}

Effect PdxBorderSeaImpassable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "SEA_LEVEL" "ALWAYS_DRAW" "HALF_ALFA" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect WarBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "PULSATE" "ALWAYS_DRAW" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}


Effect AlliesBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = { "PULSATE" "ALWAYS_DRAW" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" }
}

Effect ExplorationBorder
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	Defines = {  "SEA_LEVEL" "ALWAYS_DRAW" "ENABLE_TERRAIN" "ENABLE_GAME_CONSTANTS" "IGNORE_TERRA_INCOGNITA" }
}
