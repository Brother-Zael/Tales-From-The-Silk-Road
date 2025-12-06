Includes = {
	"cw/utility.fxh"
	"cw/camera.fxh"
	"jomini/jomini_colormap.fxh"
	"jomini/jomini_colormap_constants.fxh"
	"jomini/jomini_province_overlays.fxh"
}

PixelShader =
{
	TextureSampler PapermapMaterial
	{
		Ref = FlatMap2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	
	Code
	[[
//Logaritmic height and LogaritmicUV are passed down to avoid calculating it several times
		float CalculateScrollableStripeMask( in float2 UV, in float Offset, in float LogaritmicHeight, in float2 LogarithmicUV )
		{
			UV.x = -2.5*UV.x;

		
			float UVdistance = LogarithmicUV.x-LogarithmicUV.y+Offset;
			float LoopAlpha = frac(LogaritmicHeight);

			// diagonal
			float StripeFraction = 0.8; //value between 0.5 and 1.0  indicating what faction ocupy the stripes (with 1.0 they will not appear at all and with 0.5 it will ocuppy all the screen)
			float StripeFraction1 = lerp(StripeFraction, 2.0*StripeFraction-1.0, LoopAlpha);
			float StripeFraction2 = lerp(StripeFraction, 1.0f, 1.75f*LoopAlpha);
			float StripeBlending = lerp(0.05,0.10,LoopAlpha);



			//Stripe 2 would be the one that shrinks and dissapears 
			float Stripe1 = smoothstep(StripeFraction1-StripeBlending,StripeFraction1+StripeBlending, abs(2.0f*frac(UVdistance)-1.0f));
			float Stripe2 = smoothstep(StripeFraction2-StripeBlending,StripeFraction2+StripeBlending, abs(2.0f*frac(UVdistance+0.5)-1.0f));
			float StripeMask = Stripe1 + Stripe2 *(1.0f-3.0f*LoopAlpha); 
			return StripeMask;
		}	
	
		void ApplyScrollableDiagonalStripes( inout float4 BaseColor, float4 StripeColor, float ShadowAmount, float2 WorldSpacePosXZ  )
		{
			float2 UV = WorldSpacePosXZ;
			UV.x = -2.5*UV.x;
			float Height = max(1,CameraPosition.y / 400.0f); //we stop scrolling at the denominator height
			float LogarithmicHeight = log2(max(Height,1.0f)); // We have to use a logarimic scale to the height to decrease the scale to half every time the height twices
			float LogarithmicRepetition = pow(2.0f,floor(LogarithmicHeight)); //We repeat the cicle every time the height doubles
			float2 LogarithmicUV = (UV*700.0f/LogarithmicRepetition);

			float Mask = CalculateScrollableStripeMask( WorldSpacePosXZ, 0.0f ,LogarithmicHeight, LogarithmicUV);
			float OffsetMask = CalculateScrollableStripeMask( WorldSpacePosXZ, -0.5f /6.283f, LogarithmicHeight, LogarithmicUV);
			float Shadow = 1.0f - saturate( Mask - OffsetMask );
			Mask *= StripeColor.a;
			BaseColor.rgb = lerp( BaseColor.rgb, BaseColor.rgb * Shadow, Mask * ShadowAmount );
			BaseColor = lerp( BaseColor, StripeColor, Mask );
		}

		float4 CalcPrimaryProvinceOverlayFlatmap( in float2 NormalizedCoordinate, in float DistanceFieldValue )
		{
			float4 PrimaryColor = BilinearColorSample( NormalizedCoordinate, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture );

			float GradientAlpha = lerp( GB_Flatmap_GradientAlphaInside, GB_Flatmap_GradientAlphaOutside, RemapClamped( DistanceFieldValue, GB_Flatmap_EdgeWidth + GB_Flatmap_GradientWidth, GB_Flatmap_EdgeWidth, 0.0f, 1.0f ) );
			float Edge = smoothstep( GB_Flatmap_EdgeWidth + max( 0.0001f, GB_Flatmap_EdgeSmoothness ), GB_Flatmap_EdgeWidth, DistanceFieldValue );

			float4 Color;
			Color.rgb = lerp( PrimaryColor.rgb * GB_Flatmap_GradientColorMul, PrimaryColor.rgb * GB_Flatmap_EdgeColorMul, Edge );
			Color.a = PrimaryColor.a * lerp( GradientAlpha, GB_Flatmap_EdgeAlpha, Edge );

			return Color;
		}
		void ApplySecondaryProvinceOverlayFlatmap( in float2 NormalizedCoordinate, in float DistanceFieldValue, inout float4 Color  )
		{
			float4 SecondaryColor = BilinearColorSampleAtOffset( NormalizedCoordinate, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, SecondaryProvinceColorsOffset );
			SecondaryColor.a *= saturate(smoothstep( GB_Flatmap_EdgeWidth, GB_Flatmap_EdgeWidth + max( 0.0001f, GB_Flatmap_EdgeSmoothness ), DistanceFieldValue )+0.88f);//lines should be visible in top
			ApplyScrollableDiagonalStripes( Color, SecondaryColor, 0.8, NormalizedCoordinate );
		}
		void GetGradiantBorderBlendValuesFlatmap( in float4 ProvinceOverlayColor, out float PreLightingBlend, out float PostLightingBlend )
		{
			PreLightingBlend = GB_Flatmap_PreLightingBlend * ProvinceOverlayColor.a;
			PostLightingBlend = GB_Flatmap_PostLightingBlend * ProvinceOverlayColor.a;
		}
		void GetProvinceOverlayAndBlendFlatmap( in float2 NormalizedCoordinate, out float3 ProvinceOverlayColor, out float PreLightingBlend, out float PostLightingBlend )
		{
			float DistanceFieldValue = CalcDistanceFieldValue( NormalizedCoordinate );
			float4 ProvinceOverlayColorWithAlpha = CalcPrimaryProvinceOverlayFlatmap( NormalizedCoordinate, DistanceFieldValue );

			ApplySecondaryProvinceOverlayFlatmap( NormalizedCoordinate, DistanceFieldValue, ProvinceOverlayColorWithAlpha );
			ApplyAlternateProvinceOverlay( NormalizedCoordinate, ProvinceOverlayColorWithAlpha );

			GetGradiantBorderBlendValuesFlatmap( ProvinceOverlayColorWithAlpha, PreLightingBlend, PostLightingBlend );
			ProvinceOverlayColor = ProvinceOverlayColorWithAlpha.rgb;
		}


		//Sample a texture using no tile as explained by this article https://iquilezles.org/articles/texturerepetition/ technique 3
		float4 SampleNoTile(PdxTextureSampler2D Texture, in float2 UV, in float Noise, in float Variation)  {
			//in the code they use a second texture to to input the noise to define the textures but using the same texture as its own noise can work
			float RegionLookUp = Noise * 4;
			float FractionalRegionLookUp= frac(RegionLookUp);

			float2 DxUV = ddx(UV);
			float2 DyUV = ddy(UV);

			float2 HashA= sin(float2(11.0,5.0)*floor(RegionLookUp+0.5));
			float2 HashB = sin(float2(11.0,5.0)*floor(RegionLookUp));
			
			float4 SampleA=PdxTex2DGrad(Texture,  UV+ (Variation*HashA), DxUV,DyUV);
			float4 SampleB=PdxTex2DGrad(Texture,  UV+ (Variation*HashB), DxUV,DyUV);

			float DistanceToTexture = (min(FractionalRegionLookUp,1.0-FractionalRegionLookUp)*2.0)-(0.1*dot(SampleA.rgb-SampleB.rgb,float3(1.0,1.0,1.0)));

			return lerp (SampleA, SampleB, smoothstep(0.2,0.8,DistanceToTexture));
		}
		float4 SampleNoTile(PdxTextureSampler2D Texture, in float2 UV, in float Variation)  
		{
			return SampleNoTile( Texture, UV, PdxTex2D( Texture, 0.05 * UV ).r, Variation );
		}
	]]

}
