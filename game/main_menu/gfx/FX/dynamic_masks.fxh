Includes = {
	"cw/utility.fxh"
	"cw/terrain.fxh"
	"cw/curve.fxh"
	"cw/camera.fxh"
	"cw/lighting.fxh"
	"constants.fxh"
}


PixelShader =
{
	ConstantBuffer( DevastationConstants )
	{
		float2 DevastationBezierPoint1;
		float2 DevastationBezierPoint2;

		int DevastationTexIndex;
		int DevastationTexIndexOffset;

		int DevastationNoiseTiling;
		int DevastationTextureTiling;

		float DevastationHue;
		float DevastationSaturation;
		float DevastationValue;

		float DevastationTreeHue;
		float DevastationTreeSaturation;
		float DevastationTreeValue;

		float DevastationAreaPosition;
		float DevastationAreaContrast;
		float DevastationAreaMax;

		float DevastationHeightWeight;
		float DevastationHeightContrast;

		float DevastationExclusionMaskMin;
		float DevastationExclusionMaskMax;

		float DevastationTreeAlphaReduce;

		float DevastationForceAdd;
	};

	#Devastation in R
	#Pollution in G
	#Exclusion mask in B
	#Noise in A
	TextureSampler DevastationPollution
	{
		Ref = DevastationPollutionMask
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler DevastationVFXLUT
	{
		Ref = DynamicTerrainMask0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		File = "gfx/map/dynamic_masks/devastation_vfx_lut.dds"
		srgb = yes
	}

	TextureSampler DetailDiffuseDevastation
	{
		Ref = DynamicTerrainMask1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/terrain2/terrain_textures/textures/devastation_mud_01/devastation_mud_01_diffuse.dds"
	}

	TextureSampler DetailNormalDevastation
	{
		Ref = DynamicTerrainMask2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/terrain2/terrain_textures/textures/devastation_mud_01/devastation_mud_01_normal.dds"
	}

	TextureSampler DetailPropertiesDevastation
	{
		Ref = DynamicTerrainMask3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/terrain2/terrain_textures/textures/devastation_mud_01/devastation_mud_01_properties.dds"
	}


	Code
	[[
		float2 CalcHeightBlendFactors( float2 MaterialHeights, float2 MaterialFactors, float BlendRange )
		{
			float2 Mat = MaterialHeights + MaterialFactors;
			float BlendStart = max( Mat.x, Mat.y ) - max( BlendRange, 0.0 );

			float2 MatBlend = max( Mat - vec2( BlendStart ), vec2( 0.0 ) );

			float Epsilon = 0.00001f;
			return float2( MatBlend ) / ( dot( MatBlend, vec2( 1.0 ) ) + Epsilon );
		}

		/* Amplitude reflection coefficient (s-polarized) */
		float Rs(float n1, float n2, float cosI, float cosT)
		{
			return ( n1 * cosI - n2 * cosT ) / ( n1 * cosI + n2 * cosT );
		}

		/* Amplitude reflection coefficient (p-polarized) */
		float Rp(float n1, float n2, float cosI, float cosT)
		{
			return ( n2 * cosI - n1 * cosT ) / ( n1 * cosT + n2 * cosI );
		}

		/* Amplitude transmission coefficient (s-polarized) */
		float Ts( float n1, float n2, float cosI, float cosT )
		{
			return 2 * n1 * cosI / ( n1 * cosI + n2 * cosT );
		}

		/* Amplitude transmission coefficient (p-polarized) */
		float Tp( float n1, float n2, float cosI, float cosT )
		{
			return 2 * n1 * cosI / ( n1 * cosT + n2 * cosI );
		}

		// cosI is the cosine of the incident angle, that is, cos0 = dot(view angle, normal)
		// lambda is the wavelength of the incident light (e.g. lambda = 510 for green)
		// From http://www.gamedev.net/page/resources/_/technical/graphics-programming-and-theory/thin-film-interference-for-computer-graphics-r2962
		float ThinFilmReflectance(float cos0, float lambda, float thickness, float n0, float n1, float n2 )
		{

			// Compute the phase change term (constant)
			float d10 = ( n1 > n0 ) ? 0.0 : PI;
			float d12 = ( n1 > n2 ) ? 0.0 : PI;
			float delta = d10 + d12;

			// Compute cos1, the cosine of the reflected angle
			float sin1 = pow( n0 / n1, 2.0 ) * (1.0 - pow( cos0, 2.0 ) );
			if ( sin1 > 1 ) return 1.0; // total internal reflection
			float cos1 = sqrt( 1.0 - sin1 );

			// Compute cos2, the cosine of the final transmitted angle, i.e. cos(theta_2)
			float sin2 = pow( n0 / n2, 2.0 ) * ( 1.0 - pow( cos0, 2.0 ) );
			if ( sin2 > 1.0 )
			{
				return 1.0; // Total internal reflection
			}

			float cos2 = sqrt( 1.0 - sin2 );

			// Get the reflection transmission amplitude Fresnel coefficients
			float alpha_s = Rs( n1, n0, cos1, cos0 ) * Rs( n1, n2, cos1, cos2 ); // rho_10 * rho_12 (s-polarized)
			float alpha_p = Rp( n1, n0, cos1, cos0 ) * Rp( n1, n2, cos1, cos2 ); // rho_10 * rho_12 (p-polarized)

			float beta_s = Ts( n0, n1, cos0, cos1 ) * Ts( n1, n2, cos1, cos2 ); // tau_01 * tau_12 (s-polarized)
			float beta_p = Tp( n0, n1, cos0, cos1 ) * Tp( n1, n2, cos1, cos2 ); // tau_01 * tau_12 (p-polarized)

			// Compute the phase term (phi)
			float phi = ( 2.0 * PI / lambda ) * ( 2.0 * n1 * thickness * cos1 ) + delta;

			// Evaluate the transmitted intensity for the two possible polarizations
			float ts = pow( beta_s, 2.0 ) / ( pow( alpha_s, 2.0 ) - 2.0 * alpha_s * cos( phi ) + 1.0 );
			float tp = pow( beta_p, 2.0 ) / ( pow( alpha_p, 2.0 ) - 2.0 * alpha_p * cos( phi ) + 1.0 );

			// Take into account conservation of energy for transmission
			float beamRatio = ( n2 * cos2 ) / ( n0 * cos0 );

			// Calculate the average transmitted intensity
			float t = beamRatio * ( ts + tp ) / 2;

			// Derive the reflected intensity
			return saturate( 1 - t );
		}

		float GetDevastation( float2 MapCoordinates )
		{
			float Devastation = PdxTex2D( DevastationPollution, MapCoordinates ).r;
			Devastation += DevastationForceAdd;
			Devastation = CubicBezier( Devastation, DevastationBezierPoint1, DevastationBezierPoint2 );

			if( Devastation <= 0.0 )
			{
				return 0.0;
			}

			float2 DevastationCoords = float2( MapCoordinates.x * 2.0, MapCoordinates.y ) * DevastationNoiseTiling;
			float Noise = 1.0 - PdxTex2D( DevastationPollution, DevastationCoords ).a;
			Noise = lerp( 0.0, Noise, Devastation );
			Noise = LevelsScan( Noise, DevastationAreaPosition, DevastationAreaContrast );
			return Noise;
		}

		float GetDevastationExclusionMask( float2 MapCoordinates )
		{
			// Exclusion mask
			float DevastationMask = PdxTex2D( DevastationPollution, float2( MapCoordinates.x, MapCoordinates.y ) ).b;
			DevastationMask = smoothstep( DevastationExclusionMaskMin, DevastationExclusionMaskMax, DevastationMask );
			return DevastationMask;
		}

		void ApplyDevastationMaterialVFX( inout float4 Diffuse, float DevastationMask, float2 UV, float2 TerrainBlendFactors )
		{
			// Effect Properties
			float3 BurnColor = float3( 1.0, 0.3, 0.0 );

			float BorderEffectStrength = 7.0;

			float FireUVDistortionStrength = 0.5f;

			float2 PanSpeedA = float2( 0.005, 0.001 );
			float2 PanSpeedB = float2( 0.010, 0.005 );

			// UV & UV Panning Properties
			float2 UVPan02 = float2( -frac( GetGlobalTime() * PanSpeedA.x ), frac( GetGlobalTime() * PanSpeedA.y ) );
			float2 UVPan01 = float2( frac( GetGlobalTime() * PanSpeedB.x ),  frac( GetGlobalTime() * PanSpeedB.y ) );

			float2 UV02 = ( UV + 0.5 ) * 0.1;
			float2 UV01 = UV * 0.2;

			// Pan and Sample noise for UV distortion
			UV02 += UVPan02;
			float DevastationAlpha02 = PdxTex2D( DevastationPollution,  UV02 ).a;

			// Apply the UV Distortion
			UV01 += UVPan01;
			UV01 += DevastationAlpha02 * FireUVDistortionStrength;
			float DevastationAlpha01 = PdxTex2D( DevastationPollution, UV01 ).a;

			// Adjust Mask Value ranges to clamp the effect
			DevastationAlpha01 = max( smoothstep( 0.1, 0.5, DevastationAlpha01 ), 0.88 );

			// Calculate the effect masks
			float BorderMask = saturate( saturate( TerrainBlendFactors.y - 0.4 ) - saturate( TerrainBlendFactors.y - 0.6 ) );
			BorderMask = saturate( TerrainBlendFactors.x * ( DevastationMask - 0.1 ) ) * DevastationAlpha01;
			BorderMask *= BorderEffectStrength * DevastationAlpha01;

			float FinalMask = BorderMask;

			BurnColor = PdxTex2D( DevastationVFXLUT , saturate( float2( FinalMask, FinalMask) ) ).rgb;

			float3 Result = saturate(lerp( Diffuse.rgb, BurnColor, FinalMask ));

			Diffuse.rgb = Result;
		}

		void ApplyDevastationTrees( inout float4 Diffuse, float2 MapCoordinates )
		{
			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) * 2.0 );
			if( Devastation <= 0.0 )
			{
				return;
			}

			// Diffuse coloration
			float3 DevastatedDiffuse = RGBtoHSV( Diffuse.rgb );
			DevastatedDiffuse.x += DevastationTreeHue;				// Hue
			DevastatedDiffuse.y *= DevastationTreeSaturation;		// Saturation
			DevastatedDiffuse.z *= DevastationTreeValue;			// Value
			DevastatedDiffuse = HSVtoRGB( DevastatedDiffuse );

			// Alpha
			float DevastatedAlpha = smoothstep( DevastationTreeAlphaReduce, 1.0, Diffuse.a );

			// Return
			Diffuse.a = lerp( Diffuse.a, DevastatedAlpha, Devastation );
			Diffuse.rgb = lerp( Diffuse.rgb, DevastatedDiffuse, Devastation );
		}

		void ApplyDevastationRoads( inout float4 Diffuse, float2 WorldSpacePosXZ )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV = WorldSpacePosXZ *_InvMaterialTileSize * DevastationTextureTiling;

			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) * ROAD_DEVASTATION_MULT );

			if( Devastation <= 0.0 )
			{
				return;
			}

			// Diffuse coloration
			float3 DevastatedDiffuse = Overlay( Diffuse.rgb, ROAD_DEVASTATION_COLOR );
			Diffuse.rgb = lerp( Diffuse.rgb, DevastatedDiffuse, Devastation );

			// Terrain material blend
			float DevAlpha = PdxTex2D( DetailDiffuseDevastation,  DetailUV ).a;
			DevAlpha = lerp( 1.0, DevAlpha, 1.0 - DevastationHeightWeight );
			Devastation = clamp( Devastation, 0.0, ROAD_DEVASTATION_MAX );
			float2 BlendFactors = CalcHeightBlendFactors( float2( 1.0, DevAlpha ), float2( 1.0 - Devastation, Devastation ), /*_DetailBlendRange */ 0.5* DevastationHeightContrast );

			// Return
			Diffuse.a = saturate( Diffuse.a - BlendFactors.y );
		}

		void ApplyDevastationWater( inout float3 Color, float2 WorldSpacePosXZ )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV =  WorldSpacePosXZ * _InvMaterialTileSize  * DevastationTextureTiling;

			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) * WATER_DEVASTATION_MULT );
			if( Devastation <= 0.0 )
			{
				return;
			}

			Color = lerp( Color, WATER_DEVASTATION_COLOR, Devastation );
		}

		void ApplyDevastationShore( inout float3 Color, float2 WorldSpacePosXZ )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV = WorldSpacePosXZ  * _InvMaterialTileSize * DevastationTextureTiling;

			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) * SHORE_DEVASTATION_MULT );
			if( Devastation <= 0.0 )
			{
				return;
			}

			Color = Overlay( Color, SHORE_DEVASTATION_COLOR, Devastation );
		}

		void ApplyDevastationBuilding( inout float3 Diffuse, float2 WorldSpacePosXZ, float Height, float2 UV )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV =  float2( UV.x, UV.y * 2.0f ) * _InvMaterialTileSize  * BUILDING_DEVASTATION_UV_SCALE;

			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) * BUILDING_DEVASTATION_MULT );
			if( Devastation <= 0.0 )
			{
				return;
			}

			// Diffuse
			float4 DevDiffuse = PdxTex2D( DetailDiffuseDevastation, DetailUV );
			float3 HSV_ = RGBtoHSV( DevDiffuse.rgb );
			HSV_.x += DevastationHue;					// Hue
			HSV_.y *= DevastationSaturation; 			// Saturation
			HSV_.z *= DevastationValue;					// Value
			DevDiffuse.rgb = HSVtoRGB( HSV_ );

			float TintBlend = ( smoothstep( BUILDING_DEVASTATION_HEIGHT_MIN, BUILDING_DEVASTATION_HEIGHT_MAX, ( 1.0 - Height ) * Devastation ) );
			Diffuse = lerp( Diffuse, DevDiffuse.rgb, TintBlend );
		}

		void ApplyDevastationDecal( inout float4 Diffuse, float2 WorldSpacePosXZ, float Blend )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV =  WorldSpacePosXZ *_InvMaterialTileSize  * DevastationTextureTiling;

			// Devastation area
			float Devastation = saturate( GetDevastation( MapCoordinates ) );
			if( Devastation <= 0.0 )
			{
				return;
			}

			// Terrain material blend
			float DevAlpha = PdxTex2D( DetailDiffuseDevastation, DetailUV ).a;
			DevAlpha = lerp( 1.0, DevAlpha, 1.0 - DevastationHeightWeight );
			float2 BlendFactors = CalcHeightBlendFactors( float2( Blend, DevAlpha ), float2( 1.0 - Devastation, Devastation ), /*_DetailBlendRange */ 0.5 * DevastationHeightContrast );

			// Diffuse coloration
			float3 DevastatedDiffuse = Overlay( Diffuse.rgb, DECAL_DEVASTATION_COLOR );
			Diffuse.rgb = lerp( Diffuse.rgb, DevastatedDiffuse, saturate( Devastation * DECAL_DEVASTATION_MULT ) );

			// Return
			Diffuse.a = saturate( Diffuse.a - BlendFactors.y );
		}

		void ApplyDevastationMaterial( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXZ )
		{
			// UVs
			float2 MapCoordinates = WorldSpacePosXZ * _WorldSpaceToTerrain0To1;
			float2 DetailUV = WorldSpacePosXZ * _InvMaterialTileSize  * DevastationTextureTiling;

			// Devastation area
			float Devastation = GetDevastation( MapCoordinates );
			Devastation = clamp( Devastation, 0.0, DevastationAreaMax );
			if( Devastation <= 0.0 )
			{
				return;
			}

			// Diffuse
			float4 DevDiffuse = PdxTex2D( DetailDiffuseDevastation, DetailUV );
			float3 HSV_ = RGBtoHSV( DevDiffuse.rgb );
			HSV_.x += DevastationHue;			// Hue
			HSV_.y *= DevastationSaturation; 	// Saturation
			HSV_.z *= DevastationValue;			// Value
			DevDiffuse.rgb = HSVtoRGB( HSV_ );

			// Normal
			float4 DevNormalRRxG = PdxTex2D( DetailNormalDevastation,  DetailUV );
			float3 DevNormal = UnpackRRxGNormal( DevNormalRRxG ).xyz;

			// Properties
			float4 DevProperties = PdxTex2D( DetailPropertiesDevastation, DetailUV);

			// Exclusion mask
			//Devastation *= GetDevastationExclusionMask( MapCoordinates );
			//TO DO[AG]: Excluding everything

			// Terrain material blend
			Diffuse.a = lerp( 0.0, Diffuse.a, DevastationHeightWeight );
			DevDiffuse.a = lerp( 1.0, DevDiffuse.a, 1.0 - DevastationHeightWeight );
			float2 BlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, DevDiffuse.a), float2( 1.0 - Devastation, Devastation ), /*_DetailBlendRange */ 0.5 * DevastationHeightContrast );

			// Return
			Diffuse = Diffuse * BlendFactors.x + DevDiffuse * BlendFactors.y;
			//Diffuse = Diffuse * (1.0 - Devastation) + DevDiffuse * Devastation;
			//Diffuse.rgb = Devastation * float3(0.0, 1.0, 0.0);
			//Diffuse.rgb = float3(0.0, BlendFactors.y, 0.0);
			//Diffuse.rgb = float3(0.0,  Devastation , 0.0);
			//Diffuse.rgb = float3(0.0,  Diffuse.a, 0.0);
			//Diffuse.rgb = float3(0.0,  1.0, 0.0);
			//Diffuse = DevDiffuse;

			// Apply VFX on the final Diffuse
			ApplyDevastationMaterialVFX(Diffuse, Devastation, DetailUV, BlendFactors );

			Normal = Normal * BlendFactors.x +  DevNormal * BlendFactors.y;
			Properties = Properties * BlendFactors.x + DevProperties * BlendFactors.y;
		}

	]]
}