
ConstantBuffer( GradientBorders )
{
	float GB_GradientAlphaInside;
	float GB_GradientAlphaOutside;
	float GB_GradientWidth;
	float GB_GradientColorMul;
	float GB_EdgeWidth;
	float GB_EdgeSmoothness;
	float GB_EdgeAlpha;
	float GB_EdgeColorMul;
	float GB_PreLightingBlend;
	float GB_PostLightingBlend;
	
	float GB_Flatmap_GradientAlphaInside;
	float GB_Flatmap_GradientAlphaOutside;
	float GB_Flatmap_GradientWidth;
	float GB_Flatmap_GradientColorMul;
	float GB_Flatmap_EdgeWidth;
	float GB_Flatmap_EdgeSmoothness;
	float GB_Flatmap_EdgeAlpha;
	float GB_Flatmap_EdgeColorMul;
	float GB_Flatmap_PreLightingBlend;
	float GB_Flatmap_PostLightingBlend;
	
	float3 SecondaryColorBorderColor;
	float SecondaryColorBorderWidth;

	float SecondaryColorBorderStrenght;
	float SecondaryColorBorderPadding1;
	float SecondaryColorBorderPadding2;
	float SecondaryColorBorderPadding3;

	float3	FlatMapColorCoast;
	float	FlatMapSdfNoiseScale;
	float3	FlatMapColorDetail;
	float	FlatMapSdfNoiseStrength;
	float3	FlatMapColorWater;
	float	FlatMapDetailTiles;
	float3	FlatMapColorLand;
	float	FlatMapCoastDetailTiles;
	float4	FlatMapDetailRemap;
	float	FlatMapSdfOffset;
	float	FlatMapMaterialInvSize;
	float	FlatMapHeight_LandStart;
	float	FlatMapHeight_LandStop;
	float	FlatMapHeight_SplinesStart;
	float	FlatMapHeight_SplinesStop;
	float	FlatMapHeight_RegionStart;
	float	FlatMapHeight_RegionStop;
	float	FlatMapHeight_BlendRange;
	float	FlatMapUntileNoiseSize;
	float	FlatMapUntileHeightmapScale;
	float	FlatMapUntileFadeRange;
	float	FlatMapUntileNumRegions;
	float	FlatMapColorDetailStrength;
	float	FlatMapColorDetailMidPoint;
	float	FlatMapMaterialColorStrength;
	float	FlatMapMaterialColorMidPoint;
}