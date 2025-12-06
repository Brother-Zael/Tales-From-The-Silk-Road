Includes = {
	"cw/pdxmesh.fxh"
	"cw/utility.fxh"
	"cw/shadow.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/jomini_mapobject.fxh"
	"fog_of_war.fxh"
	"terrain.fxh"
	"cw/terrain.fxh"
	"cw/terrain2_virtual_layers.fxh"
	"climate.fxh"
	"gbuffer.fxh"
	"winter.fxh"
	"dynamic_masks.fxh"
	"specular_back_light.fxh"
	"flatmap_lerp.fxh"
	"mesh_vertexshader.fxh"
}

VertexStruct VS_OUTPUT_TREE
{
	float4 	Position 		: PDX_POSITION;
	float3 	Normal			: TEXCOORD0;
	float3 	Tangent			: TEXCOORD1;
	float3 	Bitangent		: TEXCOORD2;
	float2 	UV0				: TEXCOORD3;
	float3 	WorldSpacePos	: TEXCOORD4;
	uint	InstanceIndex	: TEXCOORD5;
	float3	Scale_Seed_Yaw	: TEXCOORD6;
}
VertexStruct VS_OUTPUT_TREE_BILLBOARD
{
	float4 	Position 		: PDX_POSITION;
	float3 	Normal			: TEXCOORD0;
	float3 	Tangent			: TEXCOORD1;
	float3 	Bitangent		: TEXCOORD2;
	float2 	UV0				: TEXCOORD3;
	float2 	UV1				: TEXCOORD4;
	float3 	WorldSpacePos	: TEXCOORD5;
	uint	InstanceIndex	: TEXCOORD6;
	float2	Random			: TEXCOORD7;	// x = per billboard random, y = per mesh random. X is based on the billboard pivot point and may contain rounding issues causing an interpolated random value accross the quad (i.e if all 4 vertices don't get the same random value
	float3	TerrainAlbedo	: TEXCOORD8;
	float3 	TerrainNormal	: TEXCOORD9;
	float3	ObjectPosition	: TEXCOORD10;
}

VertexShader = 
{	
	Code
	[[	
		VS_OUTPUT_TREE ConvertOutput( VS_OUTPUT_PDXMESH In )
		{
			VS_OUTPUT_TREE Out;
			Out.Position = In.Position;
			Out.Normal = In.Normal;
			Out.Tangent = In.Tangent;
			Out.Bitangent = In.Bitangent;
			Out.UV0 = In.UV0;
			Out.WorldSpacePos = In.WorldSpacePos;
			return Out;
		}
		
		void FinalizeOutput( inout VS_OUTPUT_TREE Out, in uint InstanceIndex, in float4x4 WorldMatrix )
		{
			Out.InstanceIndex = InstanceIndex;
			Out.Scale_Seed_Yaw.x = 1.0f;
			Out.Scale_Seed_Yaw.y = CalcRandom( float2( GetMatrixData( WorldMatrix, 0, 2 ), GetMatrixData( WorldMatrix, 2, 2 ) ) );
			Out.Scale_Seed_Yaw.z = frac(Out.Scale_Seed_Yaw.y) * TWO_PI; //We could calculate a correct Yaw from the WorldMatrix, we could also just fake it!
		}
		
		float3x3 CalcRotationMatrixFromDir( float3 FaceDir )
		{
			float3 ZAxis = -FaceDir;
			float3 XAxis = normalize( cross( float3( 0.0f, 1.0f, 0.0f ) + FaceDir.zxy * 0.0001, ZAxis ) );
			float3 YAxis = cross( ZAxis, XAxis );
			
			return Create3x3( XAxis, YAxis, ZAxis );
		}
		
		#define BILLBOARD_PITCH_DEFAULT 0
		#define BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA 1
		#define BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA_X_AXIS 2
		#define BILLBOARD_PITCH_CLAMP 3
		#define BILLBOARD_YAW_TO_CAMERA 4
		#define BILLBOARD_YAW_INV_CAMERA_DIR 5
		
		#ifndef BILLBOARD_PITCH_MODE
			// #define BILLBOARD_PITCH_MODE BILLBOARD_PITCH_DEFAULT
			// #define BILLBOARD_PITCH_MODE BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA
			// #define BILLBOARD_PITCH_MODE BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA_X_AXIS
			#define BILLBOARD_PITCH_MODE BILLBOARD_PITCH_CLAMP
		#endif
		#ifndef BILLBOARD_YAW_MODE
			// #define BILLBOARD_YAW_MODE BILLBOARD_YAW_TO_CAMERA 
			#define BILLBOARD_YAW_MODE BILLBOARD_YAW_INV_CAMERA_DIR
		#endif
		
		#ifdef PDX_MESH_UV1
		#define BILLBOARD_UV_SET Input.UV1
		#else
		#define BILLBOARD_UV_SET Input.UV0
		#endif

		// Returns a float4: xyz is the normal of the billboard plane, w is the y component of the normal before clamping, factoring, or flipping.
		float4 CalcBillboardFacingDirection( in float Random, in float3 Position, in float MaxTilt, in float MaxRandomRotation )
		{
			#if BILLBOARD_YAW_MODE == BILLBOARD_YAW_TO_CAMERA
				const float3 ToCameraDir = normalize( CameraPosition - Position );
			#elif BILLBOARD_YAW_MODE == BILLBOARD_YAW_INV_CAMERA_DIR
				const float3 ToCameraDir = -CameraLookAtDir;
			#endif
			
			const float ToCameraY = ToCameraDir.y;
			
			#if BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_DEFAULT
				float3 FaceDir = ToCameraDir;
			
			#elif BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA || BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA_X_AXIS
				#if BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA
					const float3 TiltDir = normalize( CameraPosition - Position );
				#elif BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_TILT_FACTOR_TO_CAMERA_X_AXIS
					const float3 ToCamera = CameraPosition - Position;
					const float3 FacingPoint = CameraPosition - CameraRightDir * dot( ToCamera, CameraRightDir ) - CameraUpDir * dot( ToCamera, CameraUpDir );
					const float3 TiltDir = normalize( FacingPoint - Position );
				#endif				
				const float TiltFactor = pow( TiltDir.y, 2.0f ) * 0.5f;
				float3 FaceDir = normalize( ToCameraDir * float3( 1.0f, TiltFactor, 1.0f ) );
			
			#elif BILLBOARD_PITCH_MODE == BILLBOARD_PITCH_CLAMP
				float3 FaceDir = ToCameraDir;
				FaceDir.y = min( FaceDir.y, MaxTilt );
				FaceDir = normalize( FaceDir );
			#endif
			
			if( MaxRandomRotation > 0.0f )
			{
				const float MaxRandomAngleOffset = MaxRandomRotation * PI / 180.0f;					
				float RotationOffset = Remap( Random, 0.0f, 1.0f, -MaxRandomAngleOffset, MaxRandomAngleOffset );
				float2 CosSin = float2( cos( RotationOffset ), sin( RotationOffset ) );
				float2x2 OffsetRotationMatrix = Create2x2( CosSin.x, CosSin.y, -CosSin.y, CosSin.x );
				FaceDir.xz = mul( OffsetRotationMatrix, FaceDir.xz );
			}
			return float4( FaceDir, ToCameraY );
		}
		void CalcBillboardFacingDirectionShadow( out float3 ToCameraDir, out float3 UpDir )
		{
			// in the shadow pass the camera constant buffer is a mix of the main camera and the shadow "camera"
			// i.e everything except the ViewProjectionMatrix belongs to the main camera
			// We want billboards to face the shadow camera
			ToCameraDir.x = GetMatrixData( ViewProjectionMatrix, 2, 0 );
			ToCameraDir.y = GetMatrixData( ViewProjectionMatrix, 2, 1 );
			ToCameraDir.z = GetMatrixData( ViewProjectionMatrix, 2, 2 );
			ToCameraDir = -normalize(ToCameraDir);
			
			UpDir.x = GetMatrixData( ViewProjectionMatrix, 1, 0 );
			UpDir.y = GetMatrixData( ViewProjectionMatrix, 1, 1 );
			UpDir.z = GetMatrixData( ViewProjectionMatrix, 1, 2 );
			UpDir = normalize(UpDir);
		}
		
		float3 SampleTerrainAlbedo( float3 WorldSpacePosition, uint TerrainMip, float TextureMip )
		{
			const uint Mip = max( TerrainMip, CalculateVirtualLayerDistanceMip( WorldSpacePosition, _VirtualMaterialsConstants ) );
			SPhysicalTexel MaterialsTexel = CalcPhysicalMaterialsTexel( WorldSpacePosition, Mip );

			int2 Offsets[ 4 ] = {
				int2( 0, 0 ),
				int2( 1, 0 ),
				int2( 0, 1 ),
				int2( 1, 1 ),
			};

			float2 MaterialUV = WorldSpacePosition.xz * _InvMaterialTileSize;

			float3 Samples[ 4 ];

			float2 HeightmapToWorld = _TerrainSize * _VirtualHeightmapConstants._ClipmapConstants._InvVirtualTextureSize;
			float2 TexelSizeInWorldSpace = HeightmapToWorld * float( 1u << MaterialsTexel._PageMip );

			float2 WorldSpace00 = WorldSpacePosition.xz - TexelSizeInWorldSpace * MaterialsTexel._PositionFrac;
			for ( int i = 0; i < 4; ++i )
			{
				int MaterialIndex = GetTopMaterialIndexAt( MaterialsTexel._Position + Offsets[ i ] );
				int Biome = GetBiomeWorldspace( WorldSpace00 + TexelSizeInWorldSpace * Offsets[ i ], MaterialIndex );
				STerrain2MaterialHandles Handles = GetMaterialHandles( Biome, MaterialIndex );
				Texture2D MaterialDiffuse = GetBindlessTexture2DNonUniform( Handles._DiffuseHandle );
				Samples[i] = PdxSampleTex2DLod( MaterialDiffuse, BiomeMaterialSampler, MaterialUV, TextureMip ).rgb;
			}

			return LerpBilinear( MaterialsTexel._PositionFrac, Samples[ 0 ], Samples[ 1 ], Samples[ 2 ], Samples[ 3 ] );
		}
		
		float3 SampleTerrainNormal( in float3 WorldSpacePosition, in int LowestDesiredMip )
		{
			float HeightLod = CalculateVirtualLayerDistanceMip( WorldSpacePosition, _VirtualHeightmapConstants );
			int HeightLodTruncated = HeightLod;
			if( HeightLodTruncated < LowestDesiredMip )
			{
				HeightLodTruncated = LowestDesiredMip;
				HeightLod = float(HeightLodTruncated);
			}
			float HeightLodFrac = HeightLod - (float)HeightLodTruncated;
			float LerpFactor = smoothstep( 0.7, 1.0, HeightLodFrac );

			float3 DerivedNormal = CalculateNormal( WorldSpacePosition.xz, HeightLodTruncated );
			if ( LerpFactor > 0.0 )
			{
				int NextLevelLod = HeightLodTruncated + 1;
				float3 NormalNext = CalculateNormal( WorldSpacePosition.xz, NextLevelLod );
				DerivedNormal = lerp( DerivedNormal, NormalNext, LerpFactor );
			}
			return DerivedNormal;
		}
	
		VS_OUTPUT_TREE_BILLBOARD BillboardVertexShader( in float4x4 WorldMatrix, in VS_INPUT_PDXMESH Input, in uint InstanceIndex )
		{			
			VS_OUTPUT_TREE_BILLBOARD Out;
			float4 Position = float4( Input.Position.xyz, 1.0 );
			float3 BaseNormal = Input.Normal;
			float3 BaseTangent = Input.Tangent.xyz;
			float3 BaseBitangent = normalize( cross(BaseNormal, BaseTangent) * Input.Tangent.w );
			float3 Translation = float3( GetMatrixData(WorldMatrix, 0, 3), GetMatrixData(WorldMatrix, 1, 3), GetMatrixData(WorldMatrix, 2, 3) );
			
			float2 OffsetToPivot = BILLBOARD_UV_SET;
			OffsetToPivot.y = 1.0f - OffsetToPivot.y;
			#ifdef BILLBOARD_SCALE_CORRECTION
			OffsetToPivot *= BILLBOARD_SCALE_CORRECTION;
			#endif
			float3 PivotObjectSpace = Position.xyz - BaseTangent * OffsetToPivot.x + BaseBitangent * OffsetToPivot.y;
			float3 ToPivotObjectSpace = PivotObjectSpace - Position.xyz;
			
			#ifdef ENABLE_TERRAIN
				#ifdef PDX_MESH_SNAP_MESH_TO_TERRAIN 
					WorldMatrix[1][3]=GetHeight(Translation.xz);
				#endif
			#endif

			Out.Normal = normalize( mul( CastTo3x3( WorldMatrix ), BaseNormal ) );
			Out.Tangent = normalize( mul( CastTo3x3( WorldMatrix ), BaseTangent ) );
			Out.Bitangent = normalize( cross( Out.Normal, Out.Tangent ) * Input.Tangent.w );
			
			float3 PivotWorldSpace = mul( WorldMatrix, float4( PivotObjectSpace, 1.0f ) ).xyz;
			PivotWorldSpace /= WorldMatrix[3][3];
		
			#if defined(ENABLE_TERRAIN)
				#if defined( PDX_MESH_SNAP_VERTICES_TO_TERRAIN_CLAMPED )
					PivotWorldSpace = SnapVerticesToTerrainCapped( PivotWorldSpace, WorldMatrix );
				#elif defined( PDX_MESH_SNAP_VERTICES_TO_TERRAIN )
					PivotWorldSpace = SnapVerticesToTerrain( PivotWorldSpace.xz, PivotObjectSpace.y, WorldMatrix );
				#endif
				#if defined(TERRAIN)
					#ifndef SHOW_IN_PAPERMAP
						AdjustFlatMapHeight( PivotWorldSpace );
					#endif
				#endif
			#endif
		
			float3 ToPivotWorldSpace = mul( CastTo3x3( WorldMatrix ), ToPivotObjectSpace );
			float2 ToPivotTangentSpace = float2( dot( ToPivotWorldSpace, Out.Tangent ), dot( ToPivotWorldSpace, Out.Bitangent ) );
			
			Out.InstanceIndex = InstanceIndex;
			const float RoundingFraction = 2.0f;
			Out.Random.x = CalcRandom( floor( PivotWorldSpace.xz * RoundingFraction ) / RoundingFraction ); // 1 Random value per billboard - Has rounding issues - not sure what best solution is, current method works pretty well but quads that have their pivot near a fraction line may still get different seeds on different vertices. Higher fraction = more errors
			Out.Random.y = CalcRandom( Translation.xz ); // 1 Random value per mesh instance
			
			#ifdef SHADOW
			float3 ShadowUpDir;
			CalcBillboardFacingDirectionShadow( Out.Normal, ShadowUpDir );
			Out.Bitangent = -ShadowUpDir;
			#else
			Out.Normal = CalcBillboardFacingDirection( Out.Random.x, PivotWorldSpace, 0.5f, 30.0f ).xyz;
			
			#ifdef BILLBOARD_DISABLE_PITCH
			Out.Normal = normalize( float3( Out.Normal.x, 0.0f, Out.Normal.z ) );
			#endif
		
			Out.Bitangent = normalize( CameraUpDir - Out.Normal * dot( CameraUpDir, Out.Normal ) ) * -Input.Tangent.w;
			#endif
			Out.Tangent = cross( Out.Bitangent, Out.Normal );			
			Out.WorldSpacePos = PivotWorldSpace - Out.Tangent * ToPivotTangentSpace.x - Out.Bitangent * ToPivotTangentSpace.y;
			
			#if !defined( LOW_QUALITY_SHADERS )
			Out.TerrainAlbedo = SampleTerrainAlbedo( PivotWorldSpace, 4, 7 );
			Out.TerrainNormal = SampleTerrainNormal( PivotWorldSpace, 2 );
			#else
			Out.TerrainAlbedo = vec3( 1.0 );
			Out.TerrainNormal = float3( 0.0, 1.0, 0.0 );
			#endif
			
			Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4(Out.WorldSpacePos, 1.0f) );
			Out.ObjectPosition = PivotWorldSpace;
			//Out.ObjectPosition = Translation;
	
			Out.UV0 = Input.UV0;
			#ifdef PDX_MESH_UV1
			Out.UV1 = Input.UV1;
			#else			
			Out.UV1 = Input.UV0;
			#endif
	
			return Out;
		}
	]]
	
	MainCode VS_standard
	{	
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_TREE"
		Code
		[[			
			PDX_MAIN
			{				
				VS_OUTPUT_TREE Out = ConvertOutput( StandardVertexShader( Input ) );
				FinalizeOutput( Out, Input.InstanceIndices.y, PdxMeshGetWorldMatrix( Input.InstanceIndices.y ) );
				return Out;
			}
		]]
	}
	MainCode VS_mapobject
	{	
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT_TREE"
		Code
		[[			
			PDX_MAIN
			{				
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.Index24_Packed1_Opacity6_Sign1 );
				WorldMatrix[1][3]=GetHeight(float2 (WorldMatrix[0][3],WorldMatrix[2][3]));
				VS_OUTPUT_TREE Out = ConvertOutput( StandardVertexShader( PdxMeshConvertInput( Input ), Input.Index24_Packed1_Opacity6_Sign1, WorldMatrix ) );
				FinalizeOutput( Out, Input.Index24_Packed1_Opacity6_Sign1, WorldMatrix );
				return Out;
			}
		]]
	}
	MainCode VS_mapobject_shadow
	{		
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT_MAPOBJECT_SHADOW"
		Code
		[[						
			PDX_MAIN
			{			
				uint InstanceIndex;
				bool Packed;
				float Opacity;
				UnpackMapObjectInstanceData( Input.Index24_Packed1_Opacity6_Sign1, InstanceIndex, Packed, Opacity );
				float4x4 WorldMatrix = GetWorldMatrixMapObject( InstanceIndex, Packed );
				WorldMatrix[1][3]=GetHeight(float2 (WorldMatrix[0][3],WorldMatrix[2][3]));
				VS_OUTPUT_MAPOBJECT_SHADOW Out = ConvertOutputMapObjectShadow( StandardVertexShaderShadow( PdxMeshConvertInput( Input ), 0/*Not supported*/, WorldMatrix ) );
				Out.Index24_Packed1_Opacity6_Sign1 = Input.Index24_Packed1_Opacity6_Sign1;
				return Out;
			}
		]]
	}
	MainCode VS_billboard_test
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_TREE_BILLBOARD"
		Code
		[[			
			PDX_MAIN
			{							
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
				return BillboardVertexShader( WorldMatrix, PdxMeshConvertInput( Input ), Input.InstanceIndices.y );
			}
		]]
	}
	MainCode VS_billboard_test_shadow
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Code
		[[			
			PDX_MAIN
			{							
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
				VS_OUTPUT_TREE_BILLBOARD BillboardOut = BillboardVertexShader( WorldMatrix, PdxMeshConvertInput( Input ), Input.InstanceIndices.y );
				VS_OUTPUT_PDXMESHSHADOWSTANDARD Out;
				Out.Position = BillboardOut.Position;
				Out.UV_InstanceIndex.xy = BillboardOut.UV0;
				Out.UV_InstanceIndex.z = float(Input.InstanceIndices.y);
				return Out;
			}
		]]
	}
	MainCode VS_billboard_test_mapobject
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT_TREE_BILLBOARD"
		Code
		[[			
			PDX_MAIN
			{							
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.Index24_Packed1_Opacity6_Sign1 );
				return BillboardVertexShader( WorldMatrix, PdxMeshConvertInput( Input ), Input.Index24_Packed1_Opacity6_Sign1 );
			}
		]]
	}
	MainCode VS_billboard_test_mapobject_shadow
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT_MAPOBJECT_SHADOW"
		Code
		[[			
			PDX_MAIN
			{							
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.Index24_Packed1_Opacity6_Sign1 );
				WorldMatrix[1][3]=GetHeight(float2 (WorldMatrix[0][3],WorldMatrix[2][3]));
				VS_OUTPUT_TREE_BILLBOARD BillboardOut = BillboardVertexShader( WorldMatrix, PdxMeshConvertInput( Input ), Input.Index24_Packed1_Opacity6_Sign1 );
				VS_OUTPUT_MAPOBJECT_SHADOW Out;
				Out.Position = BillboardOut.Position;
				Out.UV = BillboardOut.UV0;
				Out.Index24_Packed1_Opacity6_Sign1 = Input.Index24_Packed1_Opacity6_Sign1;
				return Out;
			}
		]]
	}
}

PixelShader = 
{
	ConstantBuffer( TreeTweakConstants )
	{	
		float3 _SssRadii;
		float _SssNormalizeAlbedo;
		
		float3 _SssColor;
		float _TreeSoftShadowSize;
		
		float3 _TranslucencyColor;
		int _TreeSoftShadowSamples;
		
		float _TerrainNormalBlend;
		float _TerrainNormalStrength;
		float _TerrainNormalBiasToSun;
		float _WindEffectIntensity;

		float2 _WindEffectDirection;
		float _WindEffectSpeed;
		float _WindEffectSpread;

		float _WindEffectNormalMapTiling;
		float _WindEffectNormalStrength;
		float _TranslucencyCosineBegin;
		float _TranslucencyCosineEnd;

		float _BacklightIntensity;
	}

	TextureSampler DiffuseMap
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PropertiesMap
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalMap
	{
		Ref = PdxTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler TintMap
	{
		Index = 3
		Ref = PdxTexture3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		
		file = "gfx/models/mapitems/trees/tree_tint_01.dds"
		srgb = yes
	}
	
	TextureSampler ClimateMap
	{
		Ref = ClimateMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
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
	TextureSampler WindNormalMap
	{
		Ref = WindEffectNormal
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	
	Code
	[[		
		float ApplyOpacity( in float Alpha, in float2 NoiseCoordinate, in uint InstanceIndex )
		{
			#ifdef JOMINI_MAP_OBJECT
				float Opacity = UnpackAndGetMapObjectOpacity( InstanceIndex );
			#else
				float Opacity = PdxMeshGetOpacity( InstanceIndex );
			#endif
			return PdxMeshApplyOpacity( Alpha, NoiseCoordinate, Opacity );
		}

		float3 CalculateLighting( in VS_OUTPUT_TREE Input, in float4 Diffuse, in float3 NormalSample, in float4 Properties )
		{
			float3 InNormal = normalize( Input.Normal );
			float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), InNormal );
			float3 Normal = normalize( mul( NormalSample, TBN ) );
			
			float3 WorldSpacePos = Input.WorldSpacePos;

			
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( WorldSpacePos, ShadowTexture );
	
			float3 Color = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
			ApplySpecularBackLight( Color, MaterialProps, LightingProps );
			
			Color = ApplyFogOfWar( Color, WorldSpacePos, FogOfWarAlpha );
			Color = ApplyDistanceFog( Color, WorldSpacePos );
			
			DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
			return Color;
		}
	]]
	
	MainCode PS_leaf
	{
		Input = "VS_OUTPUT_TREE"
		Output = "PS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				#ifdef PDX_USE_MIPLEVELTOOL
					float4 Diffuse = PdxTex2DMipTool( DiffuseMap, Input.UV0 );
				#else
					float4 Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
				#endif // PDX_USE_MIPLEVELTOOL

				float4 PackedNormal = PdxTex2D( NormalMap, Input.UV0 );
				float3 NormalSample = UnpackRRxGNormal( PackedNormal );
				float4 Properties = PdxTex2D( PropertiesMap, Input.UV0 );
				float HemisphereUVOffset = loc_GetHemisphereUVOffset(Input.WorldSpacePos, ClimateMap);
				
				float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), normalize( Input.Normal ) );
				float3 Normal = mul( NormalSample, TBN );

				//Opacity
				float FlatmapFade = 1.0f - GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp() ).x;
				Diffuse.a = ApplyOpacity( Diffuse.a, Input.Position.xy, Input.InstanceIndex ) * FlatmapFade;
				clip( Diffuse.a - 0.001f );

				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				
				//Tint
				float3 Tint = PdxTex2DLod0( TintMap, float2( UVMonthTint + HemisphereUVOffset, Input.Scale_Seed_Yaw.y ) ).rgb;
				Diffuse.rgb = GetOverlay( Diffuse.rgb, Tint, 1-PackedNormal.b );

				
				ApplyDevastationTrees( Diffuse, MapCoords );
				#if defined( ENABLE_SNOW )
					ApplySnowMesh( Diffuse.rgb, Normal, Properties, Input.WorldSpacePos, ClimateMap );
				#endif

					
				// Gradient borders pre light
				#ifndef NO_BORDERS
					#if defined( GRADIENT_BORDERS )
						float3 ColorOverlay;
						float PreLightingBlend;
						float PostLightingBlend;
						GetProvinceOverlayAndBlendCustom( MapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
						Diffuse.rgb = ApplyGradientBorderColorPreLighting( Diffuse.rgb, ColorOverlay, PreLightingBlend );
					#endif
				#endif

				float4 HighlightColor = BilinearColorSampleAtOffset( MapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
				Diffuse.rgb = lerp( Diffuse.rgb, HighlightColor.rgb, HighlightColor.a );

				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal,
				 Properties.a, Properties.g, Properties.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTexture );
				
				float3 Color = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
				ApplySpecularBackLight( Color, MaterialProps, LightingProps );

				// Color overlay post light
				#ifndef NO_BORDERS
					#if defined( GRADIENT_BORDERS )
						Color = ApplyGradientBorderColor( Color, ColorOverlay, PostLightingBlend );
					#endif
				#endif

				#ifndef UNDERWATER
					Color = ApplyFogOfWar( Color, Input.WorldSpacePos, FogOfWarAlpha );
					Color = ApplyDistanceFog( Color, Input.WorldSpacePos );
				#endif
				
				DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
				return PS_Return( Color, Diffuse.a, MaterialProps );
			}
		]]
	}
	MainCode PS_billboard
	{
		Input = "VS_OUTPUT_TREE_BILLBOARD"
		Output = "PS_OUTPUT"
		Code
		[[
			// These are not proper PBR, we skip specular entirely and add some fake translucency stuff
			void CalculateCustomLeafFromLight( in float TranslucencyMask, SMaterialProperties MaterialProps, float3 ToCameraDir, float3 ToLightDir, float3 LightIntensity, in float ShadowTerm, in float SoftShadowTerm, out float3 DiffuseOut, out float3 ScatterLightOut )
			{
				float3 H = normalize( ToCameraDir + ToLightDir );
				float NdotV = saturate( dot( MaterialProps._Normal, ToCameraDir ) ) + 1e-5;
				float NdotL = saturate( dot( MaterialProps._Normal, ToLightDir ) ) + 1e-5;
				float LdotH = saturate( dot( ToLightDir, H ) );
				
				float3 ScatteringColor = normalize( MaterialProps._DiffuseColor ); // Normalize to get a "proper" albedo, i.e a diffuse without any baked shadows or AO
				
				// Direct light
				float DiffuseBRDF = CalcDiffuseBRDF( NdotV, NdotL, LdotH, MaterialProps._PerceptualRoughness );
				DiffuseOut = DiffuseBRDF * MaterialProps._DiffuseColor * LightIntensity * NdotL * ShadowTerm;
				
				// Subsurface scattering
				float3 Sss = 0.2 * exp( -3.0 * abs(NdotL) / (_SssRadii + 0.001) );
				float3 SssOut = _SssColor * _SssRadii * Sss;
				SssOut *= lerp( MaterialProps._DiffuseColor, ScatteringColor, _SssNormalizeAlbedo );
				SssOut *= LightIntensity * SoftShadowTerm;
				
				// Translucency
				float NormalDistortion = 1.0;
				float3 LightDir = ( ToLightDir - MaterialProps._Normal * NormalDistortion );
				float VdotL = RemapClamped( dot( CameraLookAtDir, LightDir ), _TranslucencyCosineBegin, _TranslucencyCosineEnd, 0.0f, 1.0f );
				float NdotLRemapped = RemapClamped( NdotL, 1.0, -1.0, 1.0, 0.0 ); // Remap just to make it more pleasant to look at. We're doing quite a lot of normal manipulation so this is to fine tune where translucency is visible
				float TranslucencyFactor = saturate( VdotL * NdotLRemapped ) * SoftShadowTerm;
				float3 TranslucencyOut = ScatteringColor * _TranslucencyColor * LightIntensity * TranslucencyFactor * TranslucencyMask;
				
				ScatterLightOut = SssOut + TranslucencyOut;
			}
			float3 CalculateCustomLeafLighting( in float TranslucencyMask, SMaterialProperties MaterialProps, SLightingProperties LightingProps, PdxTextureSamplerCube EnvironmentMap, in float ShadowTerm, in float SoftShadowTerm )
			{
				float3 DiffuseLight;
				float3 ScatterLight;
				CalculateCustomLeafFromLight( TranslucencyMask, MaterialProps, LightingProps._ToCameraDir, LightingProps._ToLightDir, LightingProps._LightIntensity, ShadowTerm, SoftShadowTerm, DiffuseLight, ScatterLight );
				
				if( _BacklightIntensity > 0.0f )
				{
					float3 BackLightDiffuse;
					float3 BackLightScatter;
					float3 BackLightIntensity = LightingProps._LightIntensity * _BacklightIntensity;
					float3 ToBackLightDir = reflect( -LightingProps._ToLightDir, float3( 0, 1, 0 ) );
					
					CalculateCustomLeafFromLight( TranslucencyMask, MaterialProps, LightingProps._ToCameraDir, ToBackLightDir, BackLightIntensity, ShadowTerm, SoftShadowTerm, BackLightDiffuse, BackLightScatter );
					DiffuseLight += BackLightDiffuse;
					ScatterLight += BackLightScatter;
				}	
				
				// Diffuse from IBL
				float3 RotatedDiffuseCubemapUV = mul( CastTo3x3( LightingProps._CubemapYRotation ), MaterialProps._Normal );
				float3 DiffuseRad = PdxTexCubeLod( EnvironmentMap, RotatedDiffuseCubemapUV, ( PDX_NumMips - 1 - PDX_MipOffset ) ).rgb * LightingProps._CubemapIntensity;
				float3 DiffuseIBL = DiffuseRad * MaterialProps._DiffuseColor;
			
			
				//return (DiffuseLight + ScatterLight) + DiffuseIBL;
				return (DiffuseLight + ScatterLight)*0.5 + DiffuseIBL*2.0f;
			}
			float CalculateSoftShadow( float4 ShadowProj, PdxTextureSampler2DCmp ShadowMap )
			{
				// Copy of the regular shadow calc but with custom settings
				ShadowProj.xyz = ShadowProj.xyz / ShadowProj.w;
				
				float RandomAngle = CalcRandom( round( ShadowScreenSpaceScale * ShadowProj.xy ) ) * 3.14159 * 2.0;
				float2 Rotate = float2( cos( RandomAngle ), sin( RandomAngle ) );

				// Sample each of them checking whether the pixel under test is shadowed or not
				float ShadowTerm = 0.0;
				for( int i = 0; i < min( 4, _TreeSoftShadowSamples); i++ )
				{
					float4 Samples = DiscSamples[i] * _TreeSoftShadowSize;
					ShadowTerm += PdxTex2DCmpLod0( ShadowMap, ShadowProj.xy + RotateDisc( Samples.xy, Rotate ), ShadowProj.z - Bias );
					ShadowTerm += PdxTex2DCmpLod0( ShadowMap, ShadowProj.xy + RotateDisc( Samples.zw, Rotate ), ShadowProj.z - Bias );
				}
				
				// Get the average
				ShadowTerm *= 0.5; // We have 2 samples per "sample"
				ShadowTerm = ShadowTerm / float(_TreeSoftShadowSamples);
				
				float3 FadeFactor = saturate( float3( 1.0 - abs( 0.5 - ShadowProj.xy ) * 2.0, 1.0 - ShadowProj.z ) * 32.0 ); // 32 is just a random strength on the fade
				ShadowTerm = lerp( 1.0, ShadowTerm, min( min( FadeFactor.x, FadeFactor.y ), FadeFactor.z ) );
				
				return lerp( 1.0, ShadowTerm, ShadowFadeFactor );
			}
			float CalcDither( in float2 NoisePosition )
			{
				const float4x4 ThresholdMatrix =
				{
					1.0  / 17.0,  9.0  / 17.0,  3.0 / 17.0, 11.0 / 17.0,
					13.0 / 17.0,  5.0  / 17.0, 15.0 / 17.0,  7.0 / 17.0,
					4.0  / 17.0,  12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
					16.0 / 17.0,  8.0  / 17.0, 14.0 / 17.0,  6.0 / 17.0
				};
				return ThresholdMatrix[NoisePosition.x % 4][NoisePosition.y % 4];
				//return CalcRandom( NoisePosition );
			}
			
			float2 SampleWind( in float3 WorldSpacePos, float Random )
			{
				float Time = GetGlobalTime();
				float2 WindTangentDir = float2( -_WindEffectDirection.y, _WindEffectDirection.x );
				float2 RandomOffset = ( float2( Random, frac(Random*47111.0f) ) - 0.5f ) * _WindEffectSpread;
				float2 SamplePos = WorldSpacePos.xz + RandomOffset;
				
				float TimeOffset = Time * _WindEffectSpeed;
				float2 UV = float2( dot(SamplePos, WindTangentDir), -dot(SamplePos, _WindEffectDirection) + TimeOffset ) / _WindEffectNormalMapTiling;
				float2 Sample = PdxTex2D( WindNormalMap, UV ).xy;
				// Remap to -Intensity to +Intensity
				Sample = ( Sample * 2.0f - 1.0f ) * _WindEffectIntensity;
				// Align to wind direction
				return _WindEffectDirection * Sample.y + WindTangentDir * Sample.x;
			}
			float2 CalcWindSwayUv( in float2 UV, in float2 WindSample, in float3 Tangent, in float3 Bitangent, out float3 WorldSpaceDelta )
			{
				static const float ConstWindSwayScale = 0.5f; // Hardcoded scale to make "max wind" offset 0.5 in uv-x
				
				#ifndef TEXTURE_TILE_ROWS
				#define TEXTURE_TILE_ROWS 1
				#endif
				#ifndef TEXTURE_TILE_COLUMNS
				#define TEXTURE_TILE_COLUMNS 1
				#endif
				//Transform UV to 0-1 in its local cell
				float2 UvScale = float2( TEXTURE_TILE_COLUMNS, TEXTURE_TILE_ROWS );
				float2 ScaledUV = UV * UvScale;
				float2 OriginalUVRoot = floor( ScaledUV );
				clip(-abs(ddy(OriginalUVRoot)));//cleanup of the OriginalUVRoot for the borders
				clip(-abs(ddx(OriginalUVRoot)));
				UV = frac( ScaledUV );
				const float WindScale = pow( 1.0f - UV.y, 2.0f ) * ConstWindSwayScale;

				// Calculate the pixel's position in world-oriented object-space.
				// Then move the pixel in the wind direction in that space
				// Project the new position back to uv-space.
				// The new UV coordinate should be old-uv - distance-moved-in-uv-space
				float3 PixelPos = Tangent * UV.x + Bitangent * UV.y;
				WorldSpaceDelta = PixelPos;
				PixelPos.xz -= WindSample * WindScale;

				// Push down y in object-space to avoid the stretchy look you get if you just move the top of the tree sideways - this makes it look more like it "rotates" or "tilts" in the wind direction
				// This also helps prevent pixels being pushed "out" of the quad at the top when viewing along the wind direction
				const float XzOffsetLength = length( WindSample * WindScale) / ConstWindSwayScale;
				PixelPos.y += ConstWindSwayScale - ConstWindSwayScale * sqrt( 1.0 - XzOffsetLength * XzOffsetLength );
				WorldSpaceDelta = PixelPos - WorldSpaceDelta;
				// Project PixelPos on the quad plane
				// Without perspective
				float2 Result = float2( dot( Tangent, PixelPos ), dot( Bitangent, PixelPos ) );
				
				// Discard any pixel where the new UV would result sampling in another billboard's UV-space. We do this by comparing a 'billboard-id' in the WindMask texture.
				//should be 0.5 but 0.47 seems to be the epsilon that does not give problems in AMD
				clip( 0.47f - max( abs(Result.x-0.5), abs(Result.y-0.5) ) ); 
				Result = (OriginalUVRoot + Result) / UvScale;
				return Result;
			}
			PDX_MAIN
			{	
				#if !defined( LOW_QUALITY_SHADERS )
				float2 WindSample = SampleWind( Input.ObjectPosition, Input.Random.y );
				float3 WindWorldspaceDelta;
				float2 UV = CalcWindSwayUv( Input.UV0, WindSample, Input.Tangent, Input.Bitangent, WindWorldspaceDelta );
				#else
				float2 UV = Input.UV0; 
				float3 WindWorldspaceDelta = vec3(0.0f);
				#endif

				#ifdef PDX_USE_MIPLEVELTOOL
					float4 Diffuse = PdxTex2DMipTool( DiffuseMap, UV );
				#else
					float4 Diffuse = PdxTex2D( DiffuseMap, UV );
				#endif // PDX_USE_MIPLEVELTOOL

				//Opacity
				float FlatmapFade = 1.0f - GetNoisyFlatMapLerp( Input.WorldSpacePos, GetFlatMapLerp() ).x;
				Diffuse.a = ApplyOpacity( Diffuse.a, Input.Position.xy, Input.InstanceIndex ) * FlatmapFade;
				clip( Diffuse.a - 0.001f );
				
				float4 PackedNormal = PdxTex2D( NormalMap, UV );
				float3 NormalSample = UnpackRRxGNormal( PackedNormal );

				float4 Properties = PdxTex2D( PropertiesMap, UV );
				float HemisphereUVOffset = loc_GetHemisphereUVOffset(Input.WorldSpacePos, ClimateMap);
				
				NormalSample = normalize( NormalSample * float3( vec2(0.5f), 1.0f ) );
				// Bend normals to terrain normal
				#if !defined( LOW_QUALITY_SHADERS )
					float3 TerrainNormal = Input.TerrainNormal;
					TerrainNormal.xz *= _TerrainNormalStrength;
					TerrainNormal += ToSunDir * _TerrainNormalBiasToSun;
					TerrainNormal += WindWorldspaceDelta * _WindEffectNormalStrength;
					float3 VertexNormal = lerp( Input.Normal, TerrainNormal, _TerrainNormalBlend );
					float3 VertexTangent = cross( Input.Bitangent, VertexNormal );
					float3 VertexBitangent = cross( VertexNormal, VertexTangent );
					float3x3 TBN = Create3x3( normalize( VertexTangent ), normalize( VertexBitangent ), normalize( VertexNormal ) );
				#else
					float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), normalize( Input.Normal ) );
				#endif				
				float3 Normal = mul( NormalSample, TBN );

				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				
				//Tint
				#ifndef PDX_USE_MIPLEVELTOOL
					#ifndef BILLBOARD_DISABLE_TINT
					float4 Tint = PdxTex2DLod0( TintMap, float2( UVMonthTint + HemisphereUVOffset, Input.Random.x ) );
					#if !defined( LOW_QUALITY_SHADERS )
					Tint.rgb = lerp( Input.TerrainAlbedo, Tint.rgb, Tint.a );
					#endif
					Diffuse.rgb = GetOverlay( Diffuse.rgb, Tint.rgb, 1-PackedNormal.b );
					#endif
				#endif
				
				ApplyDevastationTrees( Diffuse, MapCoords );
				#if defined( ENABLE_SNOW )
					float SnowAmount = 1.0f;
					#ifdef SNOW_AMOUNT
						SnowAmount = SNOW_AMOUNT;
					#endif
					#ifdef SNOW_VARIANCE
						SnowAmount += SNOW_VARIANCE * Input.Random.x;
					#endif 
					ApplySnowMeshWithAmount( Diffuse.rgb, Normal, Properties, Input.ObjectPosition, ClimateMap, SnowAmount );
					//Diffuse.rgb = vec3(Normal.b);
				#endif

					
				// Gradient borders pre light
				#ifndef NO_BORDERS
					#if defined( GRADIENT_BORDERS )
						float3 ColorOverlay;
						float PreLightingBlend;
						float PostLightingBlend;
						GetProvinceOverlayAndBlendCustom( MapCoords, ColorOverlay, PreLightingBlend, PostLightingBlend );
						Diffuse.rgb = ApplyGradientBorderColorPreLighting( Diffuse.rgb, ColorOverlay, PreLightingBlend );
					#endif
				#endif
				
				float4 HighlightColor = BilinearColorSampleAtOffset( MapCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, HighlightProvinceColorsOffset );
				Diffuse.rgb = lerp( Diffuse.rgb, HighlightColor.rgb, HighlightColor.a );

				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, 1.0f/*custom shadow code later*/ );
				
				float2 LocalUV = frac( Input.UV0 * float2( TEXTURE_TILE_COLUMNS, TEXTURE_TILE_ROWS ) );
				float2 ToUVCenter = LocalUV - float2( 0.5f, 0.75f );
				float TranslucencyMask = RemapClamped( dot( ToUVCenter, ToUVCenter ), -0.0f, 1.0f, 0.0f, 1.0f );
				
				#if !defined( LOW_QUALITY_SHADERS )
				// Custom shadow sampling
				// Push the shadow sampling position a bit, since the shadow billboard is facing another direction than our current billboard
				// i.e imagine looking at a tree that's being lit from the side. The shadow billboard will face the light, and the color billboard faces the camera. The two intersect and and half of color billboard will be in shadow.
				// So we push the sample position a bit towards the sun, to make sure it is in front of the shadow billboard, and a bit upwards, to push it above other trees. Not too much though since we still want nice shadows from terrain etc
				// We also calculate a forced softer shadow, that we use for the internal scattering effects
				float Dither = CalcDither( Input.Position.xy );
				float3 ShadowWorldPos = Input.WorldSpacePos + ToSunDir * lerp( 1.0f, 1.5f, Dither );// + float3(0.0f, 1.0f, 0.0f ) * 0.5f;
				float4 ShadowProj = mul( ShadowMapTextureMatrix, float4( ShadowWorldPos, 1.0 ) );
				float ShadowTerm = CalculateShadow( ShadowProj, ShadowTexture );
				float SoftShadowTerm = CalculateSoftShadow( ShadowProj, ShadowTexture );
				//ShadowTerm = SoftShadowTerm;
				//SoftShadowTerm = ShadowTerm;
				#else
				float ShadowTerm = 1.0f;
				float SoftShadowTerm = 1.0f;
				#endif
				float3 Color = CalculateCustomLeafLighting( TranslucencyMask, MaterialProps, LightingProps, EnvironmentMap, ShadowTerm, SoftShadowTerm );
				
				// Color overlay post light
				#ifndef NO_BORDERS
					#if defined( GRADIENT_BORDERS )
						Color = ApplyGradientBorderColor( Color, ColorOverlay, PostLightingBlend );
					#endif
				#endif

				#ifndef UNDERWATER
					Color = ApplyFogOfWar( Color, Input.WorldSpacePos, FogOfWarAlpha );
					Color = ApplyDistanceFog( Color, Input.WorldSpacePos );
				#endif
				
				DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
				return PS_Return( Color, Diffuse.a, MaterialProps );
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = no	
	#SourceBlend = "src_alpha"
	#DestBlend = "inv_src_alpha"
	alphatocoverage = yes
}
BlendState alpha_to_coverage
{
	#BlendEnable = yes
	#SourceBlend = "SRC_ALPHA"
	#DestBlend = "INV_SRC_ALPHA"
	AlphaToCoverage = yes
}


RasterizerState RasterizerState
{
	FillMode = "solid"
	#CullMode = "none"
	#FrontCCW = yes
	#FillMode = "wireframe"
}
RasterizerState ShadowRasterizerState
{
	DepthBias = 40000
	SlopeScaleDepthBias = 2
	#FrontCCW = yes
	#CullMode = "none"
}
RasterizerState RasterizerState_two_sided
{
	FillMode = "solid"
	CullMode = None
	#FrontCCW = yes
	#FillMode = "wireframe"
}
RasterizerState ShadowRasterizerState_two_sided
{
	DepthBias = 40000
	SlopeScaleDepthBias = 2
	#FrontCCW = yes
	CullMode = None
}


Effect tree
{
	VertexShader = VS_standard
	PixelShader = PS_leaf
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" }
}
Effect treeShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	RasterizerState = ShadowRasterizerState
	Defines = {"TERRAIN"}
}
Effect tree_two_sided
{
	VertexShader = VS_standard
	PixelShader = PS_leaf
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}
Effect tree_two_sidedShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = {"TERRAIN"}
}

Effect tree_alpha_to_coverage
{
	VertexShader = VS_standard
	PixelShader = PS_leaf
	
	BlendState = "alpha_to_coverage"
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"}
}
Effect tree_alpha_to_coverageShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	
	BlendState = "alpha_to_coverage"
	RasterizerState = ShadowRasterizerState
	Defines = {"TERRAIN"}
}
Effect tree_alpha_to_coverage_two_sided
{
	VertexShader = VS_standard
	PixelShader = PS_leaf
	
	BlendState = "alpha_to_coverage"
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" }
	RasterizerState = RasterizerState_two_sided
}
Effect tree_alpha_to_coverage_two_sidedShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	
	BlendState = "alpha_to_coverage"
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = {"TERRAIN"}
}

#Map object shaders
Effect tree_mapobject
{
	PixelShader = PS_leaf
	VertexShader = VS_mapobject
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"}
}
Effect treeShadow_mapobject
{
	VertexShader = VS_mapobject_shadow
	PixelShader = "PS_jomini_mapobject_shadow_alphablend"
	
	RasterizerState = ShadowRasterizerState
	Defines = {"TERRAIN"}
}
#Map object shaders
Effect tree_two_sided_mapobject
{
	PixelShader = PS_leaf
	VertexShader = VS_mapobject
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"}
	RasterizerState = RasterizerState_two_sided
}
Effect tree_two_sidedShadow_mapobject
{
	VertexShader = VS_mapobject_shadow
	PixelShader = "PS_jomini_mapobject_shadow_alphablend"
	
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = {"TERRAIN"}
}

Effect tree_alpha_to_coverage_mapobject
{
	PixelShader = PS_leaf
	VertexShader = VS_mapobject
	
	BlendState = "alpha_to_coverage"
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"}
}
Effect tree_alpha_to_coverageShadow_mapobject
{
	VertexShader = VS_mapobject_shadow
	PixelShader = "PS_jomini_mapobject_shadow_alphablend"
	
	BlendState = "alpha_to_coverage"
	RasterizerState = ShadowRasterizerState
	Defines = {"TERRAIN"}
}
Effect tree_alpha_to_coverage_two_sided_mapobject
{
	PixelShader = PS_leaf
	VertexShader = VS_mapobject
	
	BlendState = "alpha_to_coverage"
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN"}
	RasterizerState = RasterizerState_two_sided
}
Effect tree_alpha_to_coverage_two_sidedShadow_mapobject
{
	VertexShader = VS_mapobject_shadow
	PixelShader = "PS_jomini_mapobject_shadow_alphablend"
	
	BlendState = "alpha_to_coverage"
	RasterizerState = ShadowRasterizerState_two_sided
	Defines = {"TERRAIN"}
}

Effect billboard_test
{
	VertexShader = VS_billboard_test
	PixelShader = PS_billboard
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "SNOW_AMOUNT 1.5" "SNOW_VARIANCE -1.0" "TERRAIN" }
}
RasterizerState ShadowRasterizerStateBillboard
{
	DepthBias = 0
}
Effect billboard_testShadow
{
	VertexShader = VS_billboard_test_shadow
	PixelShader = PixelPdxMeshAlphaBlendShadow
	BlendState = alpha_to_coverage
	RasterizerState = ShadowRasterizerStateBillboard
	Defines = {"TERRAIN" "SHADOW" }
}
Effect billboard_test_mapobject
{
	VertexShader = VS_billboard_test_mapobject
	PixelShader = PS_billboard
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "SNOW_AMOUNT 1.5" "SNOW_VARIANCE -0.5" "TERRAIN" }
}
Effect billboard_testShadow_mapobject
{
	VertexShader = VS_billboard_test_mapobject_shadow
	PixelShader = PS_jomini_mapobject_shadow_alphablend
	BlendState = alpha_to_coverage
	RasterizerState = ShadowRasterizerStateBillboard
	Defines = {"TERRAIN" "SHADOW" }
}
Effect billboard_foliage
{
	VertexShader = VS_billboard_test
	PixelShader = PS_billboard
	Defines = { "GRADIENT_BORDERS" "ENABLE_SNOW" "TERRAIN" "BILLBOARD_DISABLE_PITCH" "BILLBOARD_DISABLE_TINT" }
	#RasterizerState = RasterizerState_two_sided
}