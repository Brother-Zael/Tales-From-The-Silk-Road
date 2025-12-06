Includes = {
	"cw/utility.fxh"
	"standardfuncsgfx.fxh"
	"constants.fxh"
}

ConstantBuffer( ClimateConstants )
{
	float 	UVMonthTint;
}

PixelShader =
{
	Code
	[[
		float loc_GetHemisphereUVOffset( float3 WorldSpacePos, in PdxTextureSampler2D HemisphereUVOffsetSampler )
		{
				float GetHemisphereUVOffset = PdxTex2D( HemisphereUVOffsetSampler, WorldSpacePos.xz / GetMapSize() ).b;
				return GetHemisphereUVOffset;
		}
	]]
}