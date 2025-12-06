Includes = {
	"cw/terrain2_virtual_layer_utils.fxh"
}

# This file declares all resources necessary for the game's virtual layers.

# Heightmap
Texture VirtualHeightmapIndirectionTexture
{
	Ref = Terrain2VirtualLayerIndirection0
	format = uint4
	type = "2darray"
}

Texture VirtualHeightmapPhysicalTexture
{
	Ref = Terrain2VirtualLayerPhysical0
}

ConstantBuffer( Terrain2VirtualLayerConstants0 )
{
	STerrain2VirtualLayerConstants _VirtualHeightmapConstants;
}

Code
[[
	SPhysicalTexel CalcPhysicalHeightmapTexel( float3 WorldSpacePosition, uint Mip )
	{
		return _CalcPhysicalTexel( WorldSpacePosition, VirtualHeightmapIndirectionTexture, _VirtualHeightmapConstants, Mip );
	}
]]

# TODO: PSGE-7892
Texture VirtualHeightmapDecalTextures
{
	Ref = Terrain2VirtualLayerDecalTextures0
	ResourceArraySize = 512
}

# Materials
Texture VirtualMaterialsIndirectionTexture
{
	Ref = Terrain2VirtualLayerIndirection1
	format = uint4
	type = "2darray"
}

Texture VirtualMaterialsPhysicalTexture
{
	Ref = Terrain2VirtualLayerPhysical1
	format = uint
}

ConstantBuffer( Terrain2VirtualLayerConstants1 )
{
	STerrain2VirtualLayerConstants _VirtualMaterialsConstants;
}

Code
[[
	SPhysicalTexel CalcPhysicalMaterialsTexel( float3 WorldSpacePosition, uint Mip )
	{
		return _CalcPhysicalTexel( WorldSpacePosition, VirtualMaterialsIndirectionTexture, _VirtualMaterialsConstants, Mip );
	}
]]

Texture VirtualMaterialsDecalTextures
{
	Ref = Terrain2VirtualLayerDecalTextures1
	ResourceArraySize = 512
}

