Includes = {
	"cw/heightmap.fxh"
	"cw/utility.fxh"
	"fog_of_war.fxh"
	"standardfuncsgfx.fxh"
}

TextureSampler TerrainBlendNoise
{
	Ref = FlatMap3
	MagFilter = "Linear"
	MinFilter ="Linear"
	MipFilter = "Linear"
	SampleModeU= "Wrap"
	SampleModeV="Wrap"
	srgb="no"

	file ="gfx/map/terrain/unmasked/noise.dds"
}

VertexShader = {
	Code [[
		float GetNoisyFlatMapLerp( in float3 Coordinate, in float FoW )
		{
			FoW = smoothstep( FoWNeighborAlpha, FoWBaseAlpha, 1.0f - FoW );
			float Noise = PdxTex2DLod0( TerrainBlendNoise, Coordinate.xz / max( 1.0f, GetFlatMapNoiseSize() ) ).r;
			float x = saturate( ( GetFlatMapLerp() + FoW ) * 2.0f - 1.0f + Noise );
			
			float2 BreakPoint = float2( 0.75f, 0.5f );
			if( x < BreakPoint.x )
				return Remap( x, 0.0f, BreakPoint.x, 0.0f, BreakPoint.y );
			else
				return Remap( x, BreakPoint.x, 1.0f, BreakPoint.y, 1.0f );
		}
		float GetNoisyFlatMapLerp( in float3 Coordinate )
		{
			float FoW = 0.0f;
			if( GetFlatMapAsFoWEnabled() )
			{
				float Width = 15.0f;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz ) * InverseWorldSize ).r * 2.0f;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 0,-1) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2(-1, 0) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 1, 0) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 0, 1) * Width ) * InverseWorldSize ).r;
				FoW /= 6.0f;
				FoW = 1.0f - FoW;
			}
			
			return GetNoisyFlatMapLerp( Coordinate, FoW );
		}
		void AdjustFlatMapHeight( inout float3 Coordinate, in float FoW )
		{
			float FlatMap = GetNoisyFlatMapLerp( Coordinate, FoW );
			Coordinate.y = lerp( Coordinate.y, GetFlatMapHeight(), FlatMap );
		}
		void AdjustFlatMapHeight( inout float3 Coordinate )
		{
			float FlatMap = GetNoisyFlatMapLerp( Coordinate );
			Coordinate.y = lerp( Coordinate.y, GetFlatMapHeight(), FlatMap );
		}
	]]
}

PixelShader = {
	Code [[
		// GetNoisyFlatMapLerp
		// Returns two different blend values
		// x = A sharp, noisy, alpha value meant for blending between paper map shader and 3d shader
		// y = A darkness gradient, meant to darken the paper shader n ear the paper/3d edge
		float2 GetNoisyFlatMapLerp( in float3 Coordinate, in float FoW , in float FlatMapLerp)
		{
			FoW = smoothstep( FoWNeighborAlpha, FoWBaseAlpha, 1.0f - FoW );
			float Noise = PdxTex2DLod0( TerrainBlendNoise, Coordinate.xz / max( 1.0f, GetFlatMapNoiseSize() ) ).r;
			float2 HighFrequencyNoise = PdxTex2DLod0( TerrainBlendNoise, Coordinate.xz /  max( 1.0f, GetFlatMapFadeEdgeNoiseSize() ) ).r;
			float Height = RemapClamped( Coordinate.y, GetFlatMapHeight(), _HeightScale, 0.0f, 1.0f );
			Height = smoothstep( GetFlatMapLerpHeight1(), GetFlatMapLerpHeight0(), Height );
			float OverallBlend = saturate( ( FlatMapLerp + FoW ) * 2.0f - 1.0f + Noise ) * Height;
			float Softness = saturate( FlatMapLerp * 5.0f );
			float HardBlend = lerp( smoothstep( 0.0, GetFlatMapFadeEdgeWidth(), OverallBlend * 2.0f - HighFrequencyNoise.r ), OverallBlend, Softness );
			float SoftBlend = saturate( lerp( 0, FoW, pow(abs( HardBlend), GetFlatMapFadeEdgeDarkness() ) ) + Softness );
			return float2( HardBlend, SoftBlend );
		}
		float2 GetNoisyFlatMapLerp( in float3 Coordinate , in float FlatMapLerp)
		{
			float FoW = 0.0f;
			if( GetFlatMapAsFoWEnabled() )
			{
				//float Alpha = PdxTex2DLod0( FogOfWarAlpha, Coordinate.xz * InverseWorldSize );
				//FoW = 1.0f - Alpha;
				float Width = 10.0;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz ) * InverseWorldSize ).r * 2.0f;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 0,-1) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2(-1, 0) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 1, 0) * Width ) * InverseWorldSize ).r;
				FoW += PdxTex2DLod0( FogOfWarAlpha, ( Coordinate.xz + float2( 0, 1) * Width ) * InverseWorldSize ).r;
				FoW /= 6.0f;
				FoW = 1.0f - FoW;
			}
			return GetNoisyFlatMapLerp( Coordinate, FoW, FlatMapLerp );
		}

	]]
}