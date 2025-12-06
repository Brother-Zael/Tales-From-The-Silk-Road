Includes = {
	"cw/camera.fxh"
	"cw/random.fxh"
	"cw/utility.fxh"
	"jomini/jomini_colormap_constants.fxh"
	"standardfuncsgfx.fxh"
}

ConstantBuffer( TerraIncognitaConstants )
{
	float2 TerraIncognitaTextureScale;
	float TerraIncognitaHeight;
	float TerraIncognitaExtraSamplesDistance;
	int TerraIncognitaNumExtraSamples;
	float4 TerraIncognitaSampleOffsets[16]; //each float4 contains 2 float2 offsets
};

TextureSampler VisibilityMap
{
    Ref = TerraIncognitaVisibilityTexture
    MagFilter = "Point"
    MinFilter = "Point"
    MipFilter = "Point"
    SampleModeU = "Wrap"
    SampleModeV = "Wrap"
}

PixelShader =
{
	Code
	[[
		float2 TexelPosToUV( float2 TexelPos, float2 TextureSize )
		{
			TexelPos.x = clamp( TexelPos.x, 0.0f, TextureSize.x - 1.0f );
			TexelPos.y = clamp( TexelPos.y, 0.0f, TextureSize.y - 1.0f );
			return TexelPos / TextureSize;
		}
			
		float GetVisibility( float2 WorldSpacePos )
		{
			float2 ColorIndex = PdxTex2DLod0( ProvinceColorIndirectionTexture, TexelPosToUV( WorldSpacePos, IndirectionMapSize ) ).rg;	
			float HasVisibility = PdxTex2DLoad0( VisibilityMap, int2( ColorIndex  * 255.0 ) ).r;
			return HasVisibility;
		}
			
		float GetBilinear( float2 WorldSpacePos )
		{
			float2 Base = WorldSpacePos;
				
			float C11 = GetVisibility( Base );
			float C21 = GetVisibility( Base + float2( 1.0, 0.0 ) );
			float C12 = GetVisibility( Base + float2( 0.0, 1.0 ) );
			float C22 = GetVisibility( Base + float2( 1.0, 1.0 ) );
			
			float2 Frac = frac( WorldSpacePos );
			float x1 = lerp( C11, C21, Frac.x );
			float x2 = lerp( C12, C22, Frac.x );
			return lerp( x1, x2, Frac.y );
		}
			
		float2 RotateDiscForMultisample( float2 Disc, float2 Rotate )
		{
			return float2( Disc.x * Rotate.x - Disc.y * Rotate.y, Disc.x * Rotate.y + Disc.y * Rotate.x );
		}
		float GetMultiSamples( float2 WorldSpacePos )
		{
			float2 TimeOffset = float2( 0.7, 0.1 ) * GetGlobalTime() * 0.1f;
			float SpatialFactor = 1.0f;
			float TemporalFactor = 2.0f;
			float RandomAngle = CalcNoise( WorldSpacePos * 0.1 + TimeOffset * SpatialFactor ) * 3.14159 * 2.0 + TimeOffset.x * TemporalFactor;
				
			float2 Rotate = float2( cos( RandomAngle ), sin( RandomAngle ) );
			float Sum = 0.0f;
			float Tot = 0.0f;
			for( int i = 0; i < TerraIncognitaNumExtraSamples / 2; ++i )
			{
				float2 OffsetA = RotateDiscForMultisample(TerraIncognitaSampleOffsets[i].xy * TerraIncognitaExtraSamplesDistance, Rotate);
				float2 OffsetB = RotateDiscForMultisample(TerraIncognitaSampleOffsets[i].zw * TerraIncognitaExtraSamplesDistance, Rotate);
				Sum += GetBilinear( WorldSpacePos + OffsetA );
				Sum += GetBilinear( WorldSpacePos + OffsetB );
				Tot += 2.0f;
			}
			return Sum / Tot;
		}
	]]
}