Includes = {
	"jomini/jomini_lighting.fxh"
}

PixelShader = {
	Code [[
		/*
		struct SMaterialProperties
		{
			float 	_PerceptualRoughness;
			float 	_Roughness;
			float	_Metalness;
			
			float3	_DiffuseColor;
			float3	_SpecularColor;
			float3	_Normal;
		};
		
		struct SLightingProperties
		{
			float3		_ToCameraDir;
			float3		_ToLightDir;
			float3		_LightIntensity;
			float		_ShadowTerm;
			float		_CubemapIntensity;
			// this rotation matrix is used to rotate cubemap sampling vectors, thus "faking" a rotation of the cubemap
			float4x4	_CubemapYRotation;
		};
		*/
		
		float AshikhminD( float Roughness, float NdotH )
		{
			float r2    = Roughness * Roughness;
			float cos2h = min( 0.99999f, NdotH * NdotH );
			float sin2h = 1. - cos2h;
			float sin4h = sin2h * sin2h;
			return (sin4h + 4. * exp(-cos2h / (sin2h * r2))) / (PI * (1. + 4. * r2) * sin4h);
		}

		float AshikhminV(float NdotV, float NdotL)
		{
			return 1. / max(0.0001f, 4. * (NdotL + NdotV - NdotL * NdotV));
		}

		float CharlieD(float Roughness, float NdotH)
		{
			float rcpR  = 1. / Roughness;
			float cos2h = NdotH * NdotH;
			float sin2h = 1. - cos2h;
			return (2. + rcpR) * pow(sin2h, rcpR * .5) / (2. * PI);
		}

		float3 CalculateGrassScatterLighting( in SMaterialProperties MaterialProps, in SLightingProperties LightingProps )
		{
			float3 HalfVec = normalize( LightingProps._ToCameraDir + LightingProps._ToLightDir );
			
			float3 FibersNormal = normalize( lerp( MaterialProps._Normal, float3( 0, 1, 0 ), saturate( GetGrassScatterNormalSmoothing() ) ) );
			float VdotH = saturate( dot( LightingProps._ToCameraDir, HalfVec ) );
			float NdotH = saturate( dot( FibersNormal, HalfVec ) );
			float NdotV = saturate( dot( FibersNormal, LightingProps._ToCameraDir ) );
			float NdotL = saturate( dot( FibersNormal, LightingProps._ToLightDir ) );
			
			float3 LightColor = LightingProps._LightIntensity * LightingProps._ShadowTerm;
			
			float3 DiffuseColor = 0.25f * 0.25f * MaterialProps._DiffuseColor;
			float3 SpecularColor = sqrt( DiffuseColor );
			//float3 SpecularColor = MaterialProps._SpecularColor;
			//float3 SpecularColor = MaterialProps._DiffuseColor;
			
			float Roughness = clamp( MaterialProps._Roughness * GetGrassScatterRoughnessScale(), 0.0001f, 1.0f );
			float D = CharlieD( Roughness, NdotH );
			float V = AshikhminV( NdotV, NdotL );
			float3 F = F_Schlick( SpecularColor, vec3(1.0f), VdotH );
			float3 Specular = LightColor * F * D * V * PI * NdotL;
			return Specular;
		}
	]]
}