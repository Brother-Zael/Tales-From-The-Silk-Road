Includes = {
	"cw/utility.fxh"
	"jomini/jomini_province_overlays.fxh"	
	"flatmap_detailed.fxh"
	"flatmap_lerp.fxh"
	"constants.fxh"
}

TextureSampler DetailFlatMapCurrents
{
	Ref = DynamicTerrainMask10
	MagFilter = "Linear"
	MinFilter = "Linear"
	MipFilter = "Linear"
	SampleModeU = "Wrap"
	SampleModeV = "Wrap"
	File = "gfx/map/flatmap/sea_currents_arrows.dds"
}	

TextureSampler SeaColorsTexture
{
	Ref = SeaColors
	MagFilter = "Point"
	MinFilter = "Point"
	MipFilter = "Point"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
}
ConstantBuffer( SeaCurrentsConstats )
{
	float _SeaCurrentsSpeed;
	float _SeaCurrentsAlphaLerp;
	float _SeaCurrentsUVScale;
	float _SeaCurrentsAnimationSpeed3D;
	
	float _SeaCurrentsUVScale3D;
	float _SeaCurrentsWavesSeparation3D;
	float _SeaCurrentsSpawnChance3D;
	float _SeaCurrentsDisappearenceDebug3D;

	float2 _SeaCurrentsDisappearenceUvScale3D;
	float _SeaCurrentsDisappearenceThresshold3D;
	float _SeaCurrentsDisappearenceThressholdCorrection3D;
	
	float _SeaCurrentsDisappearenceDissapearanceSpeed3D;

}

BufferTexture CurrentAngles
{
	Ref = SeaCurrentsTexture
	type = float4;
}
	
PixelShader =
{
	Code
	[[
		float2 RotateUV(float2 UV, float2 Pivot, float Rotation) {
			float Sine = sin(Rotation);
			float Cosine = cos(Rotation);
			float2 ReturnUV;
			ReturnUV =  UV - Pivot;
			ReturnUV.x = UV.x * Cosine + UV.y * Sine;
			ReturnUV.y = UV.y * Cosine - UV.x * Sine;
			ReturnUV += Pivot;

			return ReturnUV;
		}

	float CalculateStripeMaskCustom( in float2 UV, float Offset )
	{
		// diagonal
		float t = 3.14159 / 8.0;
		float w = 24000;			  // larger value gives smaller width
		
		float StripeMask = cos( ( UV.x * cos( t ) * w ) + ( UV.y * sin( t ) * w ) + Offset ); 
		StripeMask = smoothstep(0.0, 1.0, StripeMask * 2.2f );
		return StripeMask;
	}	
		
		void ApplyDiagonalStripesCustom( inout float4 BaseColor, float4 StripeColor, float2 WorldSpacePosXZ )
		{
			float Mask = CalculateStripeMaskCustom( WorldSpacePosXZ, 0.0f );
			float OffsetMask = saturate(CalculateStripeMaskCustom( WorldSpacePosXZ, -SecondaryColorBorderWidth)+CalculateStripeMaskCustom( WorldSpacePosXZ, SecondaryColorBorderWidth));
			float Border = saturate(   OffsetMask - Mask );
			Mask *= StripeColor.a;
			BaseColor = lerp( BaseColor, StripeColor, Mask );
			BaseColor = lerp( BaseColor, float4(SecondaryColorBorderColor, StripeColor.a * SecondaryColorBorderStrenght), saturate(Border  * StripeColor.a));
		}

		void ApplySecondaryProvinceOverlayCustom( in float2 NormalizedCoordinate, in float DistanceFieldValue, inout float4 Color )
		{
			float4 SecondaryColor = BilinearColorSampleAtOffset( NormalizedCoordinate, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, SecondaryProvinceColorsOffset );

			
			//Replicate the shading that is done to the primary color
			float Edge = smoothstep(GB_EdgeWidth + max(0.0001f, GB_EdgeSmoothness), GB_EdgeWidth, DistanceFieldValue);
			SecondaryColor.rgb = lerp(SecondaryColor.rgb * GB_GradientColorMul, SecondaryColor.rgb * GB_EdgeColorMul, Edge);
	
			SecondaryColor.a *= smoothstep( GB_EdgeWidth, GB_EdgeWidth + 0.01f, DistanceFieldValue+ 0.88f);//lines should be visible in top
			ApplyDiagonalStripesCustom( Color, SecondaryColor, NormalizedCoordinate );
		}

		void ApplySecondaryProvinceOverlayCustomForCity( in float2 NormalizedCoordinate, in float2 ColorIndex, in float DistanceFieldValue, inout float4 Color )
		{
			float4 SecondaryColor = PdxTex2DLoad0( ProvinceColorTexture, int2( ColorIndex +  SecondaryProvinceColorsOffset  ) );

			//Replicate the shading that is done to the primary color
			float Edge = smoothstep(GB_EdgeWidth + max(0.0001f, GB_EdgeSmoothness), GB_EdgeWidth, DistanceFieldValue);
			SecondaryColor.rgb = lerp(SecondaryColor.rgb * GB_GradientColorMul, SecondaryColor.rgb * GB_EdgeColorMul, Edge);

			SecondaryColor.a *= smoothstep( GB_EdgeWidth, GB_EdgeWidth + 0.01f, DistanceFieldValue + 0.88f);//lines should be visible in top
			ApplyDiagonalStripesCustom( Color, SecondaryColor, NormalizedCoordinate );
		}

		float4 CalcPrimaryProvinceOverlayForCities(  in float4 PrimaryColor, in float DistanceFieldValue )
		{
			float GradientAlpha = lerp( GB_GradientAlphaInside, GB_GradientAlphaOutside, RemapClamped( DistanceFieldValue, GB_EdgeWidth + GB_GradientWidth, GB_EdgeWidth, 0.0f, 1.0f ) );
			float Edge = smoothstep( GB_EdgeWidth + max( 0.0001f, GB_EdgeSmoothness ), GB_EdgeWidth, DistanceFieldValue );

			float4 Color;
			Color.rgb = lerp( PrimaryColor.rgb * GB_GradientColorMul, PrimaryColor.rgb * GB_EdgeColorMul, Edge );
			Color.a = PrimaryColor.a * max( GradientAlpha * ( 1.0f - pow( Edge, 2 ) ), GB_EdgeAlpha * Edge );

			return Color;
		}

		void GetProvinceOverlayAndBlendCustom( in float2 NormalizedCoordinate, out float3 ProvinceOverlayColor, out float PreLightingBlend, out float PostLightingBlend )
		{
			float DistanceFieldValue = CalcDistanceFieldValue( NormalizedCoordinate );
			float4 ProvinceOverlayColorWithAlpha = CalcPrimaryProvinceOverlay( NormalizedCoordinate, DistanceFieldValue );

			ApplySecondaryProvinceOverlayCustom( NormalizedCoordinate, DistanceFieldValue, ProvinceOverlayColorWithAlpha );
			
			ApplyAlternateProvinceOverlay( NormalizedCoordinate, ProvinceOverlayColorWithAlpha );
			GetGradiantBorderBlendValues( ProvinceOverlayColorWithAlpha, PreLightingBlend, PostLightingBlend );
			PreLightingBlend = saturate(PreLightingBlend);
			PostLightingBlend = saturate(PostLightingBlend);

			ProvinceOverlayColor = saturate(ProvinceOverlayColorWithAlpha.rgb);
		}

		void GetProvinceOverlayAndBlendForCityCustom( in float2 NormalizedCoordinate, in float2 ColorIndex, in float4 PrimaryColor, out float3 ProvinceOverlayColor, out float PreLightingBlend, out float PostLightingBlend )
		{

			float DistanceFieldValue = CalcDistanceFieldValue( NormalizedCoordinate );
			float4 ProvinceOverlayColorWithAlpha = CalcPrimaryProvinceOverlayForCities( PrimaryColor, DistanceFieldValue );

			ApplySecondaryProvinceOverlayCustomForCity( NormalizedCoordinate, ColorIndex, DistanceFieldValue, ProvinceOverlayColorWithAlpha );

			GetGradiantBorderBlendValues( ProvinceOverlayColorWithAlpha, PreLightingBlend, PostLightingBlend );

			PreLightingBlend = saturate(PreLightingBlend);
			PostLightingBlend = saturate(PostLightingBlend);
			ProvinceOverlayColor = saturate(ProvinceOverlayColorWithAlpha.rgb);
		}


		float3 ApplyGradientBorderColorPreLighting( in float3 BaseColor, inout float3 BorderColor, in float BlendAmount )
		{	
			float3 Greyscale = dot(BaseColor, float3(0.299, 0.587, 0.114)).xxx; // adjusted to human sensitivity
			float3 BorderColorWithGreyscale = GetOverlay( Greyscale, BorderColor, 1.0 );
			return lerp( BaseColor, BorderColorWithGreyscale, BlendAmount );
		}
		float3 ApplyGradientBorderColor( in float3 BaseColor, inout float3 BorderColor, in float BlendAmount )
		{			
			return lerp( BaseColor, BorderColor, BlendAmount );
		}

		void ApplyTerrainColor( inout float3 Diffuse, inout float3 BorderColor, out float BorderPostLightingBlend, in float2 ColorMapCoords )
		{
			float BorderPreLightingBlend;
			GetProvinceOverlayAndBlendCustom( ColorMapCoords, BorderColor, BorderPreLightingBlend, BorderPostLightingBlend );
			Diffuse = ApplyGradientBorderColorPreLighting( Diffuse, BorderColor, BorderPreLightingBlend );
		}
		
		float4 SampleMaterialTexture( in PdxTextureSampler2DArray Texture, in float Noise, in float3 UV ) 
		{
			if( FlatMapUntileNumRegions <= 1.0 )
			{
				return PdxTex2D( Texture, UV );
			}
			else
			{
				float RegionLookUp = Noise * (FlatMapUntileNumRegions-1.0f);
				float FractionalRegionLookUp = frac( RegionLookUp );

				float2 DxUV = ddx(UV.xy);
				float2 DyUV = ddy(UV.xy);

				float2 HashA = sin( float2(11.0, 5.0) * floor( RegionLookUp ) );
				float2 HashB = sin( float2(11.0, 5.0) * floor( RegionLookUp + 1.0 ) );
				
				float FlatMapUntileOffsetPerRegion = 0.37;
				float4 SampleA = PdxTex2DGrad( Texture, float3( UV.xy + ( HashA * FlatMapUntileOffsetPerRegion ), UV.z ), DxUV, DyUV );
				float4 SampleB = PdxTex2DGrad( Texture, float3( UV.xy + ( HashB * FlatMapUntileOffsetPerRegion ), UV.z ), DxUV, DyUV );

				float BaseHeight = SampleA.a * FlatMapUntileHeightmapScale;
				float NextregionHeight = FractionalRegionLookUp * ( 1.0 + SampleB.a * FlatMapUntileHeightmapScale );
				//float DistanceToTexture = ( min( FractionalRegionLookUp, 1.0 - FractionalRegionLookUp ) * 2.0 ) - ( FlatMapUntileHeightmapScale * (SampleA.a-SampleB.a) );
				float DistanceToTexture = NextregionHeight - BaseHeight;
				
				#ifdef FLAT_MAP_UNTILE_DEBUG
				SampleA.rgb = HSVtoRGB( floor( RegionLookUp + 0.0 ) * 0.625, 1.0, 1.0 );
				SampleB.rgb = HSVtoRGB( floor( RegionLookUp + 1.0 ) * 0.625, 1.0, 1.0 );
				#endif
				
				float FadeHalf = FlatMapUntileFadeRange * 0.5;
				return lerp (SampleA, SampleB, smoothstep( 0.5 - FadeHalf, 0.5 + FadeHalf, DistanceToTexture ) );
			}
		}
		
		struct SFlatMapBase
		{
			float2	_FlatMapUV;
			float4	_FlatMapSample;
			float 	_RawSdfSample;
			float	_CoastLineDistance;
			float	_LandMask;
			float	_Gradient;
		};
		
		SFlatMapBase CalcFlatMapBase( in float3 WorldSpacePos, in float2 ColorMapCoords, in PdxTextureSampler2D FlatMapTex,  in PdxTextureSampler2D FlatMapDetailsTex )
		{
			SFlatMapBase Base;
			Base._FlatMapUV = float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y );
			Base._FlatMapSample = PdxTex2D( FlatMapTex, Base._FlatMapUV );
			Base._RawSdfSample = saturate( Base._FlatMapSample.a + FlatMapSdfOffset );
			
			float SdfNoise = PdxTex2D( TerrainBlendNoise, WorldSpacePos.xz * FlatMapSdfNoiseScale ).r * 2.0f - 1.0f;
			Base._CoastLineDistance = ( 1.0f - Base._RawSdfSample) * 2.0f - 1.0f;
			Base._CoastLineDistance += SdfNoise * FlatMapSdfNoiseStrength;
			
			Base._LandMask = smoothstep( 0.001, -0.01, Base._CoastLineDistance );
			Base._Gradient = pow( RemapClamped( Base._CoastLineDistance, 0.0f, 1.0f, 1.0f, 0.0f ), 3.0f ) * 0.6f;
			
			return Base;
		}

		struct SSeaCurrentLocationData
		{
			float _RotationData;
			float2 _LocationPosition;
		};

		SSeaCurrentLocationData CalcSeaCurrent( in float2 ColorMapCoords)
		{
			SSeaCurrentLocationData LocationData;
			int2 ColorIndex = int2(PdxTex2D( ProvinceColorIndirectionTexture, ColorMapCoords ).rg * IndirectionMapDepth + vec2(0.5f) );
			float2 ColorTextureSize;
			PdxTex2DSize( ProvinceColorTexture, ColorTextureSize );
			int  BufferTextureColorIndex = ColorIndex.r + ColorIndex.g * ColorTextureSize.r;
			float4 BufferData = PdxReadBuffer4(CurrentAngles, BufferTextureColorIndex);
			LocationData._RotationData =  BufferData.z;
			LocationData._LocationPosition = BufferData.xy;
			return LocationData;
		}

		float2 AdjustWorldWrap(in float2 WorldWrap, in float2 CenterPos)
		{
			float DistanceCenter = WorldWrap.x-CenterPos.x;
			if ( abs(DistanceCenter*2.0) < GetMapSize().x )
			{
				return WorldWrap;
			}
			if(WorldWrap.x>CenterPos.x)
			{
				return  float2(WorldWrap.x-GetMapSize().x,WorldWrap.y);
			}
			else
			{
				return  float2(WorldWrap.x+GetMapSize().x,WorldWrap.y);
			}
		}

		float4 FlatTerrainShader( in float3 WorldSpacePos, in float2 ColorMapCoords, in PdxTextureSampler2D FlatMapTex,  in PdxTextureSampler2D FlatMapDetailsTex, bool LandColorOnly )
		{	
			SFlatMapBase Base = CalcFlatMapBase( WorldSpacePos, ColorMapCoords, FlatMapTex, FlatMapDetailsTex );

			float UntileNoise = PdxTex2D( TerrainBlendNoise, WorldSpacePos.xz * 0.0078125/*(1/128)*/ * FlatMapUntileNoiseSize  ).r;
			float3 Detail = SampleNoTile( FlatMapDetailsTex, float2( ColorMapCoords.x * 2.0, 1.0 - ColorMapCoords.y ) * FlatMapDetailTiles, UntileNoise, 0.37 ).rgb;
			Detail.rg = RemapClamped( Detail.rg, FlatMapDetailRemap.xx, FlatMapDetailRemap.yy, FlatMapDetailRemap.zz, FlatMapDetailRemap.ww );

			float3 SeaColor = FlatMapColorWater;
			float3 LandColor = FlatMapColorLand;

			float LandLerp =  Base._LandMask;
			if(LandColorOnly)
				LandLerp = 1.0f;

			float4 DetailColor = float4( FlatMapColorCoast, 1 );
			float2 CoastDetailUV =  float2( ColorMapCoords.x, 1.0 - ColorMapCoords.y ); //TODO: aspect ratio
			CoastDetailUV *= FlatMapCoastDetailTiles;
			CoastDetailUV = RotateUV( CoastDetailUV, vec2(0.5), 0.25 );//TODO: needed? can't we just rotate in texture instead. Saves instructions and sampling
			float CoastDetail = PdxTex2D( FlatMapDetailsTex, CoastDetailUV ).a;
			DetailColor.rgb = lerp( DetailColor.rgb, FlatMapColorDetail, CoastDetail );
			
			// Stylized Terrain Textures
			float4 TerrainSample = vec4( 0.0f );
			if( GetSimulatedFlatMapLerp() < 1.0f )
			{
				float TerrainMaterialIndex = floor( Base._FlatMapSample.b * 32.0f ); // blue channel is 5 bits and the texture is generated with this in consideration. scale up 2^5
				float3 MaterialUV = float3( WorldSpacePos.xz * FlatMapMaterialInvSize * float2(1,-1), TerrainMaterialIndex );
				TerrainSample = SampleMaterialTexture( PapermapMaterial, UntileNoise, MaterialUV );
				float LandHeight = Remap( Base._RawSdfSample, FlatMapHeight_LandStart, FlatMapHeight_LandStop, -1.0, 1.0 );
				float RiverHeight = Remap( Base._FlatMapSample.g, FlatMapHeight_SplinesStart, FlatMapHeight_SplinesStop, -1.0, 1.0 );
				float MaterialHeight = Remap( Base._FlatMapSample.r, FlatMapHeight_RegionStart, FlatMapHeight_RegionStop, -1.0, 1.0 );
				float BaseHeight = max( LandHeight, max( RiverHeight, MaterialHeight ) );
				float SampleHeight = TerrainSample.a;
				TerrainSample.a = smoothstep( 0.0, FlatMapHeight_BlendRange, SampleHeight - BaseHeight ) * ( 1.0f - GetSimulatedFlatMapLerp() );
			}

			#ifdef TERRAIN_COLOR_OVERLAY
				float3 ColorOverlay;
				float PreLightingBlend;
				float PostLightingBlend;
				
				if( Base._RawSdfSample < (129.0f / 255.0) && Base._LandMask > 0.0f )
				{
					// This is a hack to sample colors a bit more "inwards" in an attempt to hide uncolored pixels
					// Might not be needed with an SDF offset
					float PixelSize = ColorMapCoords.x / ( WorldSpacePos.x + 0.0001f );
					float SampC = Base._RawSdfSample;
					float SampX = PdxTex2DLod( FlatMapTex, Base._FlatMapUV + PixelSize * float2(3,0), 0.0 ).a;
					float SampY = PdxTex2DLod( FlatMapTex, Base._FlatMapUV + PixelSize * float2(0,3), 0.0 ).a;
					float2 Derivatives = float2( SampX - SampC, SampC - SampY );
					float DeltaLen = length(Derivatives);
					if( DeltaLen > 0.0f )
					{
						float2 SampleOffset = ( Derivatives / DeltaLen );
						ColorMapCoords += SampleOffset * PixelSize;
					}
				}
				
				GetProvinceOverlayAndBlendFlatmap( ColorMapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
				float ColorMask = saturate( PreLightingBlend + PostLightingBlend );
				ColorMask = saturate( ColorMask + RemapClamped( Base._FlatMapSample.g, -0.1, 0.1, 0.2, 0.0 ) * ( 1.0f - GetFlatMapLerp() ) );
				float TerrainColorMod = Remap( TerrainSample.g, FlatMapMaterialColorMidPoint, 1.0, 0.0, FlatMapMaterialColorStrength );
				ColorMask = saturate( ColorMask + TerrainColorMod * TerrainSample.a );
				
				float ColorNoise = Remap( Detail.b, FlatMapColorDetailMidPoint, 1.0, 0.0, FlatMapColorDetailStrength );
				ColorMask = lerp( ColorMask, saturate( ColorMask + ColorNoise ), smoothstep( 0.5f, 0.0f, abs( ColorMask - 0.5f ) ) );
				if( Base._CoastLineDistance > -0.015f && Base._CoastLineDistance < 0.015f )
				{
					// Hide areas where we don't have color data
					// This is a bit of a hack to prevent "white" edges or pixels near the coastline
					float4 Color = BilinearColorSample( ColorMapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, SeaColorsTexture );
					LandLerp *= RemapClamped( Color.r, 1.0, 0.8, 1.0, 0.0 );
				}

				LandColor = lerp( LandColor, ColorOverlay, ColorMask );
				SeaColor = lerp( SeaColor, ColorOverlay, ColorMask );
				//Drop shadow
				LandColor *= LandLerp;

			#endif

			SSeaCurrentLocationData SeaCurrentLocationData = CalcSeaCurrent(ColorMapCoords) ;

			if(SeaCurrentLocationData._RotationData != 0)
			{
				float Time = GetGlobalTime() * _SeaCurrentsSpeed;
				float2 UV = AdjustWorldWrap(WorldSpacePos.xz,SeaCurrentLocationData._LocationPosition) - SeaCurrentLocationData._LocationPosition;
				float2 RotatedUVs = RotateUV(UV* _SeaCurrentsUVScale,vec2(0.0f), SeaCurrentLocationData._RotationData);
				RotatedUVs +=  SeaCurrentLocationData._LocationPosition;
				RotatedUVs.x -= frac(Time);
				float4 SeaFlatMapArrows = PdxTex2D(DetailFlatMapCurrents,RotatedUVs);
				SeaColor = lerp(SeaColor, SeaFlatMapArrows.rgb, SeaFlatMapArrows.a*_SeaCurrentsAlphaLerp);
				
			}
			// Stylized Terrain Textures 
			if( TerrainSample.a > 0.0f )
			{
				LandColor.rgb = lerp( LandColor.rgb, LandColor.rgb * TerrainSample.r, TerrainSample.a );
			}
			
			SeaColor = lerp( SeaColor, DetailColor.rgb, DetailColor.a * Base._Gradient * Base._Gradient );


			float3 FinalColor = lerp( SeaColor, LandColor, LandLerp );

			FinalColor.rgb *= lerp( Detail.g, Detail.r, LandLerp );

			#ifdef TERRAIN_COLOR_OVERLAY
				float4 HighlightColor = BilinearColorSampleAtOffset( ColorMapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
				FinalColor.rgb = lerp( FinalColor.rgb, HighlightColor.rgb,  HighlightColor.a);
			#endif
			#ifdef TERRAIN_DEBUG
				TerrainDebug( FinalColor, WorldSpacePos );
			#endif
			
			//DebugReturn( FinalColor, lightingProperties, ShadowTerm );
			return float4( FinalColor, 1 );
		}
	]]
}
