Includes = {
	"cw/camera.fxh"
	"cw/pdxmesh.fxh"
	"cw/shadow.fxh"
	"cw/utility.fxh"
	"cw/terrain.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/jomini_lighting.fxh"
	"constants.fxh"
	"fog_of_war.fxh"
	"standardfuncsgfx.fxh"
	"units_data.fxh"
	"gbuffer.fxh"
}

BufferTexture ScriptedColors
{
	Ref = UnitScriptedColors
	type = float4
}

BufferTexture MaterialIndicesBuffer
{
	Ref = UnitMaterialIndices
	type = float2 # x = Material index, y = local repaint data offset
}

VertexStruct VS_OUTPUT
{
	float4 Position			: PDX_POSITION;
	float3 Normal			: TEXCOORD0;
	float3 Tangent			: TEXCOORD1;
	float3 Bitangent		: TEXCOORD2;
	float2 UV0				: TEXCOORD3;
	float2 UV1				: TEXCOORD4;
	float3 WorldSpacePos	: TEXCOORD6;
	uint InstanceIndex 	: TEXCOORD7;
	@ifdef PDX_MESH_UV2
	float2 UV2				: TEXCOORD8;
	@endif
	float TerrainHeight 	: TEXCOORD9;

};

Code
[[

	// Produces the same result as:
	// lerp( 
	//		lerp( lerp( Values.x, Values.y, T ), lerp( Values.y, Values.z, T ), T ), 
	//		lerp( lerp( Values.y, Values.z, T ), lerp( Values.z, Values.w, T ), T ), 
	//		T )
	float CubicLerp4( in float4 Values, in float T )
	{
		float T2 = T * T;
		float T3 = T2 * T;
		float OneMinusT = 1.0f - T;
		float OneMinusT2 = OneMinusT * OneMinusT;
		float OneMinusT3 = OneMinusT2 * OneMinusT;
		float4 Coeffs = float4( OneMinusT3, 3.0f * OneMinusT2 * T, 3.0f * OneMinusT * T2, T3 );
		return dot( Values, Coeffs );
	}
]]

VertexShader =
{	
	Code 
	[[
		VS_OUTPUT ConvertOutput( VS_OUTPUT_PDXMESH In )
		{
			VS_OUTPUT Out;
		
			Out.Position = In.Position;
			Out.Normal = In.Normal;
			Out.Tangent = In.Tangent;
			Out.Bitangent = In.Bitangent;
			Out.UV0 = In.UV0;
		#ifdef PDX_MESH_UV1
			Out.UV1 = In.UV1;
		#else
			Out.UV1 = In.UV0;
		#endif
		#ifdef PDX_MESH_UV2
			Out.UV2 = In.UV2;
		#endif
			Out.WorldSpacePos = In.WorldSpacePos;
			return Out;
		}
	]]
	MainCode VS_standard
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 Transform = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShader( PdxMeshConvertInput( Input ), Input.InstanceIndices.x, Transform ) );
				Out.InstanceIndex = Input.InstanceIndices.y;
				float3 Translation = float3( GetMatrixData(Transform, 0, 3), GetMatrixData(Transform, 1, 3), GetMatrixData(Transform, 2, 3) );
				#ifdef ENABLE_TERRAIN
				Out.TerrainHeight = GetHeight( Translation.xz );
				#else
				Out.TerrainHeight = 0.0f;
				#endif
				return Out;
			}
		]]
	}
	MainCode VS_selection_marker
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 Transform = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
				
			#ifdef ENABLE_UNIT_SHADER
				SUnitUserData UserData = GetUnitUserData( Input.InstanceIndices.y );
				float Scale = 1.0f;
				if( UserData._Selection != 0.0f ) 
				{
					Scale = CubicLerp4( SelectionMarkerScaleValues, abs(UserData._Selection) );
					GetMatrixData(Transform, 0, 0) *= Scale;
					GetMatrixData(Transform, 1, 1) *= Scale;
					GetMatrixData(Transform, 2, 2) *= Scale;
				}
			#endif
				
				float3 Translation = float3( GetMatrixData(Transform, 0, 3), GetMatrixData(Transform, 1, 3), GetMatrixData(Transform, 2, 3) );
				#ifdef ENABLE_TERRAIN
				Translation.y = max( GetHeight( Translation.xz ), GetWaterHeight() );
				GetMatrixData(Transform, 1, 3) = Translation.y;
				#endif
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShader( PdxMeshConvertInput( Input ), Input.InstanceIndices.x, Transform ) );
				Out.InstanceIndex = Input.InstanceIndices.y;
				Out.TerrainHeight = Translation.y;
			
				return Out;
			}
		]]
	}
}

PixelShader =
{	
	Code [[
		float3 SampleCoaEmblem( in SUnitUserData UserData, in float2 UV, in float2 Ddx, in float2 Ddy )
		{
			float4 OffsetAndScale = CoaOffsetAndScale[UserData._CountryIndex];
			float2 UVScaled = UV;
			#ifdef COA_SCALE
			UVScaled*= COA_SCALE;
			#endif
			float2 CoaUV = frac(UVScaled*1.0f) * OffsetAndScale.zw + OffsetAndScale.xy;
			return ToLinear(PdxTex2DGrad( CoaAtlas, CoaUV, Ddx, Ddy )).rgb;
		}
		
		float GreyOverlayBase( float GrayedBase, float Base, float Blend )
		{
			return (GrayedBase < 0.5) ? (2.0 * Base * Blend) : (1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend));
		}
		float3 GreyOverlay( float3 Base, float3 Blend )
		{
			float GrayedBase = 0.20 * Base.r + 0.7154* Base.g + 0.0721 * Base.b;
			
			float Red = GreyOverlayBase(GrayedBase, Base.r, Blend.r);
			float Green = GreyOverlayBase(GrayedBase, Base.g, Blend.g);
			float Blue = GreyOverlayBase(GrayedBase, Base.b, Blend.b);
			return float3( Red, Green, Blue);
		}

	]]
	MainCode PS_shadow
	{
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[			
			PDX_MAIN
			{
				PdxMeshApplyOpacity( 1.0f, Input.Position.xy, PdxMeshGetOpacity( Input.InstanceIndex ) );
				return vec4(1.0f);
			}
		]]
	}
	MainCode PS_material_repaint
	{
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
		TextureSampler MaskMap
		{
			Ref = PdxTexture3
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "Point"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
		}
	
		#Skin/Hair/Eye palettes	
		TextureSampler SkinColorPalette
		{
			Ref = PdxTexture4
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
			file = "gfx/portraits/skin_palette.dds"
			sRGB = yes
		}
		TextureSampler HairColorPalette
		{
			Ref = PdxTexture5
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
			file = "gfx/portraits/hair_palette.dds"
			sRGB = yes
		}
		TextureSampler EyeColorPalette
		{
			Ref = PdxTexture6
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
			file = "gfx/portraits/eye_palette.dds"
			sRGB = yes
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

		TextureSampler MaterialDiffuseArray 
		{
			Ref = UnitGfxMaterials0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
			type = "2darray"
		}
		TextureSampler MaterialNormalArray
		{
			Ref = UnitGfxMaterials1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
			type = "2darray"
		}
		TextureSampler MaterialPropertiesArray
		{
			Ref = UnitGfxMaterials2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
			type = "2darray"
		}
		TextureSampler MaterialRepaintArray
		{
			Ref = UnitGfxMaterials3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Wrap"
			SampleModeV = "Wrap"
			type = "2darray"
		}

		Input = "VS_OUTPUT"
		Output = "PS_OUTPUT"
		Code
		[[
			
			//Converts an HSL color to a position within a unit sphere
			//The unit sphere has black at one pole, white at the opposite pole, and each color at their brightest along the equator
			float3 HSLtoXYZ( float3 HSL )
			{
				float2 DarkToLight = float2( sin(HSL.z * PI), cos(HSL.z * PI) );
				float3 Coord;
				Coord.x = DarkToLight.x * HSL.y * cos( HSL.x * PI * 2.0 );
				Coord.y = DarkToLight.x * HSL.y * sin( HSL.x * PI * 2.0 );
				Coord.z = DarkToLight.y;
				return Coord;
			}
			float3 RGBtoHSL( float3 RGB )
			{
				//First convert to HSV, then to HSL
				//Probably less efficient but seemed simpler
				//https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_HSL
				float3 HSL;
				float3 HSV = RGBtoHSV(RGB);
				HSL.x = HSV.x;
				HSL.z = HSV.z * ( 1.0 - HSV.y * 0.5 );
				if( HSL.z > 0.0 && HSL.z < 1.0 )        
					HSL.y = (HSV.z-HSL.z) / min(HSL.z,1.0-HSL.z);
				else 
					HSL.y = 0.0;
				return HSL;
			}
			
			float CalcDistance( float3 ColorA, float3 ColorB )
			{
				float3 CoordA = HSLtoXYZ( RGBtoHSL(ColorA) );
				float3 CoordB = HSLtoXYZ( RGBtoHSL(ColorB) );
				return length( CoordA - CoordB ) * 0.5f;
			}
			float CalcMask( in float3 MaskColor, in float3 TargetColor, in float Tolerance, in float Hardness, in float Output ) 
			{
				float Distance = CalcDistance( MaskColor, TargetColor );
				return RemapClamped( Distance, Tolerance * Hardness, Tolerance, Output, 0.0f );
			}
			
			float3 UnpackMaterialNormal( float4 NormalMapSample, float Strength )
			{
				float x = Strength * ( NormalMapSample.g * 2.0 - 1.0 );
				float y = Strength * ( NormalMapSample.a * 2.0 - 1.0 );
				y = -y;
				float z = sqrt( saturate( 1.0 - x * x - y * y ) );
				return float3( x, y, z );
			}
			
			float4 Blend( float4 Bottom, float3 Top, float Alpha )
			{
				Bottom.rgb = lerp( Bottom.rgb, Top.rgb, Alpha );
				Bottom.a += ( 1.0f - Bottom.a ) * Alpha;
				return Bottom;
			}

#ifdef  ENABLE_UNIT_SHADER
			void ApplyMaterials( in VS_OUTPUT Input, in SUnitUserData UserData, inout float4 Diffuse, inout float3 Normal, inout float4 Properties ) 
			{
				float2 MaskSize;
				float2 HalfInvMaskSize;
				PdxTex2DSize( MaskMap, MaskSize);
				HalfInvMaskSize= 0.5/MaskSize;

				float3 MaterialMask00 = PdxTex2DLod( MaskMap ,	Input.UV0 - HalfInvMaskSize ,0).rgb;	
				float3 MaterialMask01 = PdxTex2DLod( MaskMap , Input.UV0 + float2(HalfInvMaskSize.x, -HalfInvMaskSize.y) ,0).rgb;
				float3 MaterialMask10 = PdxTex2DLod( MaskMap ,	Input.UV0 + float2(-HalfInvMaskSize.x, HalfInvMaskSize.y),0).rgb;	
				float3 MaterialMask11 = PdxTex2DLod( MaskMap ,	Input.UV0 + HalfInvMaskSize,0).rgb;
				float AlfaX = frac(MaskSize.x * Input.UV0.x+0.5);
				float AlfaY = frac(MaskSize.y * Input.UV0.y+0.5);

				float3 BilinearMaterialMask = lerp(
					lerp(MaterialMask00, MaterialMask01, AlfaX),
					lerp(MaterialMask10, MaterialMask11, AlfaX),
					AlfaY
					);
				float Distance00 = CalcDistance(BilinearMaterialMask,MaterialMask00);
				float Distance01 = CalcDistance(BilinearMaterialMask,MaterialMask01);
				float Distance10 = CalcDistance(BilinearMaterialMask,MaterialMask10);
				float Distance11 = CalcDistance(BilinearMaterialMask,MaterialMask11);
				float3 MaterialMask;
				float Distance00Mult= (Distance00<=Distance01)&&(Distance00<=Distance10)&&(Distance00<=Distance11);
				float Distance01Mult= (Distance01<Distance00)&&(Distance01<=Distance10)&&(Distance01<=Distance11);
				float Distance10Mult= (Distance10<Distance00)&&(Distance10<Distance01)&&(Distance10<=Distance11);
				float Distance11Mult= (Distance11<Distance00)&&(Distance11<Distance01)&&(Distance11<Distance10);
				
				MaterialMask = Distance00Mult*MaterialMask00 + Distance01Mult*MaterialMask01 + Distance10Mult*MaterialMask10 + Distance11Mult*MaterialMask11;
				
				float3 DetailNormal = float3( 0, 0, 1 );
				float4 DetailDiffuseMultiply = float4( 1.0f, 1.0f, 1.0f, 0.0f );
				float4 DetailDiffuseOverlay = float4( 0.5f, 0.5f, 0.5f, 0.0f );

				float2 UV = Input.UV1;
				float2 Ddx = ddx(UV);
				float2 Ddy = ddy(UV);
				int MaterialDataBegin = UserData._MaterialDataBegin;
				int MaterialDataEnd = min(UserData._MaterialDataEnd , 100+MaterialDataBegin);//Hardcodded value to avoid infinite loops

				for( int MaterialIndexIndirect = MaterialDataBegin; MaterialIndexIndirect < MaterialDataEnd; MaterialIndexIndirect++ )
				{
					float2 EntityMaterialIndices = PdxReadBuffer2( MaterialIndicesBuffer, MaterialIndexIndirect );
					int MaterialIndex = int( EntityMaterialIndices.x );
					int RepaintOffset = int( EntityMaterialIndices.y );
					SUnitMaterialData Material = GetMaterialData( MaterialIndex );

					float4 DefaultColor = vec4( 0.0f );
					if ( Material._BlendMode == BlendModeMultiply )
					{
						DefaultColor.rgb = vec3( 1.0f );
					}
					else if ( Material._BlendMode == BlendModeOverlay )
					{
						DefaultColor.rgb = vec3( 0.5f );
					}
					
					float Mask = CalcMask( MaterialMask, Material._MaterialMaskColor, Material._MaterialMaskTolerance, Material._MaterialMaskHardness, Material._MaterialMaskOutput );

					float4 MaterialDiffuse = DefaultColor;
					
						#ifdef DEBUG_MASK
						if( EnableDebug > 0 )
						{
							MaterialDiffuse = PdxTex2DGrad( MaterialDiffuseArray, float3( UV, float( Material._DiffuseIndex ) ), Ddx, Ddy );
							Mask *= MaterialDiffuse.a;
							if(( MaterialSelection < 0 || MaterialIndexIndirect-MaterialDataBegin == MaterialSelection )&& Mask > 0 )
							{
								MaterialDiffuse.rgb = lerp(float3 (2.0,2.0,2.0) ,Material._MaterialMaskColor, UseMaskColor);
								if ( Material._BlendMode == BlendModeMultiply )
								{
									DetailDiffuseMultiply = Blend( Diffuse, MaterialDiffuse.rgb, MaterialDiffuse.a );
									DetailDiffuseOverlay.a *= 1.0f - DetailDiffuseMultiply.a;
								}
								else if ( Material._BlendMode == BlendModeOverlay )
								{
									DetailDiffuseOverlay = Blend( Diffuse, MaterialDiffuse.rgb, MaterialDiffuse.a );
									DetailDiffuseMultiply.a *= 1.0f - DetailDiffuseOverlay.a;
								}
							}
							continue;
						}
						#endif

					if( Mask > 0.0f && Material._DiffuseIndex >= 0 )
					{

						MaterialDiffuse = PdxTex2DGrad( MaterialDiffuseArray, float3( UV, float( Material._DiffuseIndex ) ), Ddx, Ddy );
						Mask *= MaterialDiffuse.a;
						if( Material._RepaintCount > 0 )
						{
							float3 RepaintMaskSample = float3(0.0f,0.0f,0.0f);
							if( Material._RepaintMaskIndex != -1 )
							{
								RepaintMaskSample = PdxTex2DGrad( MaterialRepaintArray, float3( UV, float( Material._RepaintMaskIndex ) ), Ddx, Ddy ).rgb;
							}
							float4 PaintColor = DefaultColor;
							for ( int RepaintIterator = 0; RepaintIterator < int( Material._RepaintCount ); RepaintIterator++ )
							{
								int RepaintIndex = Material._RepaintBegin + RepaintOffset * Material._RepaintCount + RepaintIterator;
								SMaterialRepaintData Repaint = GetRepaintData( RepaintIndex );
								float RepaintMask = CalcMask( RepaintMaskSample, Repaint._MaskColor, Repaint._MaskTolerance, Repaint._MaskHardness, Repaint._MaskOutput );

								if( RepaintMask > 0.0f )
								{
									if ( Repaint._ColorIndex == CoaEmblemColorIndex )
									{
									#if defined(PDX_MESH_UV2)
										float2 CoaEmblemUV = Input.UV2;
									#else
										float2 CoaEmblemUV = UV;
									#endif
										float3 CoaEmblem = SampleCoaEmblem( UserData, CoaEmblemUV, Ddx, Ddy );
										PaintColor = Blend( PaintColor, CoaEmblem, RepaintMask );
									}
									else if ( Repaint._ColorIndex >= ScriptedColorOffset )
									{
										int Index = Repaint._ColorIndex - ScriptedColorOffset;
										float4 Color = ToLinear( PdxReadBuffer4( ScriptedColors, Index ) );
										PaintColor = Blend( PaintColor, Color.rgb, RepaintMask * Color.a );
									}
									else if ( Repaint._ColorIndex == SkinColorIndex )
									{
										float4 Color = PdxTex2DGrad( SkinColorPalette, UserData._SkinColorUV, vec2( 0 ), vec2( 0 ) );
										PaintColor = Blend( PaintColor, Color.rgb, RepaintMask );
									}
									else if ( Repaint._ColorIndex == EyeColorIndex )
									{
										float4 Color = PdxTex2DGrad( EyeColorPalette, UserData._EyeColorUV, vec2( 0 ), vec2( 0 ) );
										PaintColor = Blend( PaintColor, Color.rgb, RepaintMask );
									}
									else if ( Repaint._ColorIndex == HairColorIndex )
									{
										float4 Color = PdxTex2DGrad( HairColorPalette, UserData._HairColorUV, vec2( 0 ), vec2( 0 ) );
										PaintColor = Blend( PaintColor, Color.rgb, RepaintMask );
									}
									else
									{
										PaintColor = Blend( PaintColor, SampleCountryColor( UserData, Repaint._ColorIndex ), RepaintMask );
									}
								}
							}

							MaterialDiffuse = Blend( MaterialDiffuse, GreyOverlay( MaterialDiffuse.rgb, PaintColor.rgb ), PaintColor.a );
						}

						if ( Material._BlendMode == BlendModeMultiply )
						{
							DetailDiffuseMultiply = Blend( Diffuse, MaterialDiffuse.rgb,  Mask );
							DetailDiffuseOverlay.a *= 1.0f - DetailDiffuseMultiply.a;
						}
						else if ( Material._BlendMode == BlendModeOverlay )
						{
							DetailDiffuseOverlay = Blend( Diffuse, MaterialDiffuse.rgb, Mask );
							DetailDiffuseMultiply.a *= 1.0f - DetailDiffuseOverlay.a;
						}
					}

					if( Mask > 0.0f && Material._NormalIndex >= 0 )
					{					
						
						float3 MaterialNormal = UnpackMaterialNormal( PdxTex2DGrad( MaterialNormalArray, float3( UV, float( Material._NormalIndex ) ), Ddx, Ddy ), Mask ).xyz;
						DetailNormal.xy += MaterialNormal.xy;
						DetailNormal.z *= MaterialNormal.z;
					}
					if( Mask > 0.0f && Material._PropertyIndex >= 0 )
					{
						float4 MaterialProperties = PdxTex2DGrad( MaterialPropertiesArray, float3( UV, float( Material._PropertyIndex ) ), Ddx, Ddy );
						Properties = lerp( Properties, MaterialProperties, Mask );
					}
				}
				
				float3 MultipliedColor = Diffuse.rgb * DetailDiffuseMultiply.rgb;
				float3 OverlayedColor = GreyOverlay( Diffuse.rgb, DetailDiffuseOverlay.rgb );

				#ifndef DEBUG_MASK
						Diffuse.rgb = lerp( Diffuse.rgb, MultipliedColor, DetailDiffuseMultiply.a );
						Diffuse.rgb = lerp( Diffuse.rgb, OverlayedColor, DetailDiffuseOverlay.a );
				#else
					if(EnableDebug > 0 && MaterialSelection < 0 && ! UseMaskColor&&DetailDiffuseMultiply.a+DetailDiffuseOverlay.a < 0.01)
					{
						Diffuse.rgb = float3 (1.0 ,0.0, 1.0);
					}
					else
					{
						Diffuse.rgb = lerp( Diffuse.rgb, MultipliedColor, DetailDiffuseMultiply.a );
						Diffuse.rgb = lerp( Diffuse.rgb, OverlayedColor, DetailDiffuseOverlay.a );
					}

					if( EnableDebugMask > 0)
					{
						float Mask = CalcMask( MaterialMask, DebugMaskColor, DebugMaskTolerance, DebugMaskHardness, DebugMaskOutput );
						Diffuse.rgb = lerp( Diffuse.rgb, DebugMaskColor, Mask);
					}
				#endif

				Normal = ReorientNormal( Normal, normalize( DetailNormal ) );
			}
#endif


			PDX_MAIN
			{
				PdxMeshApplyOpacity( 1.0f, Input.Position.xy, PdxMeshGetOpacity( Input.InstanceIndex ) );
				#ifdef DEBUG_MASK
					float4 Diffuse; 
					if(DissableDiffuse > 0  )
					{
						Diffuse = float4(0.5,0.5,0.5,1.0);
					}
					else{
						Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
					}
				#else
				float4 Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
				#endif
				
				float3 TangentSpaceNormals = UnpackRRxGNormal( PdxTex2D( NormalMap, Input.UV0 ) );
				float4 Properties = PdxTex2D( PropertiesMap, Input.UV0 );
				#ifdef ENABLE_UNIT_SHADER
					SUnitUserData UserData = GetUnitUserData( Input.InstanceIndex );
					ApplyMaterials( Input, UserData, Diffuse, TangentSpaceNormals, Properties );
					float SelectionValue = abs(UserData._Selection);
					float SelectionDir = sign(UserData._Selection);
					if( SelectionValue > 0.0f && SelectionValue < 1.0f )
					{
						// Schwing-effect when the unit is selected
						float2 TimeStamps = SelectionSchwingTimestamps;
						if( SelectionDir < 0.0f )
						{
							TimeStamps += 1.0f - TimeStamps.y;
						}
						float FadeDuration = 0.25f;
						float Mask = min( smoothstep( 0.0f, FadeDuration, SelectionValue ), smoothstep( 1.0f, 1.0f - FadeDuration, SelectionValue ) );
						float WaveT = smoothstep( TimeStamps.x, TimeStamps.y, SelectionValue );
						float WavePos = lerp( Input.TerrainHeight - SelectionSchwingThickness, Input.TerrainHeight + SelectionSchwingThickness + SelectionSchwingHeight, WaveT );
						float Wave = saturate( 1.0f - abs( Input.WorldSpacePos.y - WavePos ) / SelectionSchwingThickness );
						Wave = CubicLerp4( SelectionSchwingOpacityValues, Wave );
						Wave *= smoothstep( 1.0f, 0.5f, SelectionValue );
						Diffuse.rgb += SelectionSchwingColor.rgb * SelectionSchwingColor.a * Wave * Mask;
					}
				#endif
				float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), normalize( Input.Normal ) );
				float3 Normal = mul( TangentSpaceNormals, TBN );
				#ifdef DEBUG_MASK
					if(EnableDebug > 0 || EnableDebugMask > 0 )
					{
						SMaterialProperties EmptyProperties;
						return PS_Return( Diffuse.rgb, Diffuse.a, EmptyProperties );
					}

				#endif
				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTexture );

				{
					// This fake lighting for units so they get more instensity from the sun than the terrain.
					// Don't feel bad removing this later on.

					#ifdef LIGHT_INTENSITY_FACTOR
					LightingProps._LightIntensity *= LIGHT_INTENSITY_FACTOR; // LIGHT_INTENSITY_FACTOR is required to be defined with a value, for example "LIGHT_INTENSITY_FACTOR 2.5"
					#endif
					#ifdef CUBEMAP_INTENSITY_FACTOR
					LightingProps._CubemapIntensity *= CUBEMAP_INTENSITY_FACTOR; // CUBEMAP_INTENSITY_FACTOR is required to be defined with a value, for example "CUBEMAP_INTENSITY_FACTOR 2.5"
					#endif
					#ifdef ROUGHTNESS_FACTOR
					MaterialProps._Roughness = pow(MaterialProps._Roughness, ROUGHTNESS_FACTOR);// ROUGHTNESS_FACTOR is required to be defined with a value, for example "ROUGHTNESS_FACTOR 0.5"
					//MaterialProps._Roughness = MaterialProps._Roughness*ROUGHTNESS_FACTOR;// ROUGHTNESS_FACTOR is required to be defined with a value, for example "ROUGHTNESS_FACTOR 0.5"
					#endif
				}

				float3 Color = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
				#ifdef ENABLE_FOG				
					#ifndef UNDERWATER
						Color = ApplyFogOfWar( Color, Input.WorldSpacePos, FogOfWarAlpha );
						Color = ApplyDistanceFog( Color, Input.WorldSpacePos );
					#endif
				#endif
				DebugReturn( Color, MaterialProps, LightingProps, EnvironmentMap );
				return PS_Return( Color, Diffuse.a, MaterialProps );
			}
		]]
	}
	MainCode PS_selection_marker
	{
		TextureSampler DiffuseMap
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		Input = "VS_OUTPUT"
		Output = "PS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				PdxMeshApplyOpacity( 1.0f, Input.Position.xy, PdxMeshGetOpacity( Input.InstanceIndex ) );
				float Rotation = SelectionMarkerUvRotationSpeed * GetGlobalTime();
				float2 UvSinCos = float2( sin( Rotation ), cos( Rotation ) );
				float2x2 Rot = Create2x2(UvSinCos.y, UvSinCos.x, -UvSinCos.x, UvSinCos.y);
				float2 UV = vec2(0.5f) + mul( Input.UV0 - vec2(0.5f), Rot );
				float4 Diffuse = PdxTex2D( DiffuseMap, UV );
				#ifdef ENABLE_UNIT_SHADER
					SUnitUserData UserData = GetUnitUserData( Input.InstanceIndex );
					float SelectionValue = abs(UserData._Selection);
					float SelectionDir = sign(UserData._Selection);
					if( SelectionValue < 1.0f )
					{
						float Opacity = CubicLerp4( SelectionMarkerOpacityValues, SelectionValue );
						Diffuse.a *= Opacity;
					}
				#endif
				clip( dot( Diffuse.rgb * Diffuse.a, vec3(1.0f) ) - 0.01f );
				float3 Color = Diffuse.rgb;
				#ifdef ENABLE_FOG				
					#ifndef UNDERWATER
						Color = ApplyFogOfWar( Color, Input.WorldSpacePos, FogOfWarAlpha );
						Color = ApplyDistanceFog( Color, Input.WorldSpacePos );
					#endif
				#endif
				return PS_Return( Color * Diffuse.a, Diffuse.a );
			}
		]]
	}
}
#endif

BlendState BlendState
{
	BlendEnable = no
}

#RasterizerState RasterizerState
#{
#	fillmode = wireframe
#}

DepthStencilState DepthStencilState
{
	StencilEnable = yes
	FrontStencilPassOp = replace
	StencilRef = 1
}

RasterizerState ShadowRasterizerState
{
	DepthBias = 40000
	SlopeScaleDepthBias = 2
}


Effect unit_material_repaint
{
	VertexShader = "VS_standard"
	PixelShader = "PS_material_repaint"

	Defines = {
		"LIGHT_INTENSITY_FACTOR 2.1"
		"CUBEMAP_INTENSITY_FACTOR 6"
		"ROUGHTNESS_FACTOR 0.7"
	}
}


Effect unit_material_repaintShadow
{
	VertexShader = "VS_standard"
	PixelShader = "PS_shadow"
	RasterizerState = ShadowRasterizerState
}

BlendState marker_blend_state
{
	BlendEnable = yes
	
	WriteMask = "RED|GREEN|BLUE"
	
	# Alpha blend
	#SourceBlend = "SRC_ALPHA"
	#DestBlend = "INV_SRC_ALPHA"
	
	# Additive
	SourceBlend = "SRC_ALPHA"
	DestBlend = "ONE"
}
DepthStencilState marker_depth_stencil_state
{
	DepthEnable = no
	DepthWriteEnable = no
	StencilEnable = yes
	FrontStencilFunc = not_equal
	StencilRef = 1
}
Effect unit_selection_marker
{
	BlendState = marker_blend_state
	DepthStencilState = marker_depth_stencil_state
	VertexShader = "VS_selection_marker"
	PixelShader = "PS_selection_marker"
}