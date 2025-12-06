
Includes = {
	"jomini/posteffect_base.fxh"
}

PixelShader =
{	
	MainCode CalcReflectedColor
	{
		TextureSampler MainImage
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Border"
			SampleModeV = "Border"
		}
		TextureSampler GBufferNormal
		{
			Ref = SsrGBuffer0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		TextureSampler GBufferMaterial
		{
			Ref = SsrGBuffer1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		TextureSampler GBufferSpecular
		{
			Ref = SsrGBuffer2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		ConstantBuffer( SsrConstants )
		{
			float MaskMin;
			float MaskMax;
		}
		
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			float4 ViewSpaceToScreenSpace( float3 ViewSpace, float2 TextureSize )
			{
				float4 ScreenSpace = mul( ProjectionMatrix, float4( ViewSpace, 1 ) );
				//ScreenSpace.y *= -1;
				ScreenSpace.xyz /= ScreenSpace.w;
				ScreenSpace.xy = ScreenSpace.xy * 0.5f + vec2( 0.5f );
				ScreenSpace.xy *= TextureSize;
				//ScreenSpace.y = 1.0f - ScreenSpace.y;
				return ScreenSpace;
			}
			
			float3 ScreenSpaceToViewSpace( float4 ScreenSpace, float2 TextureSize )
			{
				float4 ClipSpace = ScreenSpace;
				ClipSpace.xy /= TextureSize;
				ClipSpace.xy = ClipSpace.xy * 2.0f - vec2(1.0f);
				ClipSpace.xyz *= ScreenSpace.w;
				
				float4 ViewSpace = mul( InvProjectionMatrix, ClipSpace );
				return ViewSpace.xyz;
			}
			
			float2 ScreenSpaceToUV( float2 ScreenSpace, float2 TextureSize )
			{
				float2 Uv = ScreenSpace / TextureSize;
				Uv.y = 1.0f - Uv.y;
				return Uv;
			}
			
			float CalcReflectionAmount( float4 MaterialSample, float4 SpecularSample )
			{				
				float Spec = smoothstep( MaskMin, MaskMax, dot(SpecularSample.rgb, vec3(1.0f)) / 3.0f );
				float Roughness = smoothstep( MaskMax, MaskMin, MaterialSample.g );
				return Roughness * Spec;
			}
		
			PDX_MAIN
			{
				// Optimization note:
				// The ray marching in this shader is very expensive simply because of the sheer amount of samples needed.
				// A good way to optimize it would be to use mip-maps for the depth buffer created with a min filter. The result would be similar to raymarching in a quad-tree
				
				#if defined( SSR_QUALITY_HIGH )
					int MaxInitialSearchSteps = 64; 	// Limits how many iterations the initial search is allowed to do.Low values will make reflections cut of earlier but can drasticly improve performance
					float Resolution = 0.3f;			// Quality metric for the initial search. 1.0 will sample every pixel along the reflection ray at a higher performance cost
					float Thickness = 0.15f;				// Quality metric. Higher thickness allows more errors. Lower thickness increases "sharpness" but also introduces noise		
				#else
					int MaxInitialSearchSteps = 16; 	// Limits how many iterations the initial search is allowed to do.Low values will make reflections cut of earlier but can drasticly improve performance
					float Resolution = 0.23f;			// Quality metric for the initial search. 1.0 will sample every pixel along the reflection ray at a higher performance cost
					float Thickness = 0.15f;				// Quality metric. Higher thickness allows more errors. Lower thickness increases "sharpness" but also introduces noise
				#endif
					float MaxDistanceViewSpace = 15.0f;	// How far, in view-space, rays will reach (higher values impacts performance negatively)					
					int MaxRefinementSteps = 5;			// Quality metric for the refinement search. More is "better" but more expensive. Quality suffers diminishing returns but performance cost is linear. Mostly improves aliasing in large reflected surfaces.
					int RefinementSteps = 0;
					float2 EdgeFadeRange = vec2( 32.0f ); // Range in pixels where SSR will be faded out near edges of the screen
				
				Thickness /= max( Resolution, 0.00001f );
				
				float2 TextureSize;				
				PdxTex2DSize( GBufferMaterial, TextureSize );
				
				EdgeFadeRange /= TextureSize;
				
				float4 MaterialSample = PdxTex2DLod0( GBufferMaterial, Input.uv );
				float4 SpecularSample = PdxTex2DLod0( GBufferSpecular, Input.uv );
				float Mask = CalcReflectionAmount( MaterialSample, SpecularSample );
				
				float4 Out = PdxTex2D( MainImage, Input.uv );
				Out.a = 0.0f;

				if( Mask <= 0.0f )
				{
					return Out;
				}
				
				// Initial ray calculations
				// We are working in view-space and screean-space.
				// Normals are saved in world-space and need to be converted
				float Depth = SampleDepthBuffer( Input.uv, TextureSize );
				float3 RayOrigin = ViewSpacePosFromDepth( Depth, Input.uv );
				float3 NormalSample = PdxTex2DLod0( GBufferNormal, Input.uv ).rgb;
				float3 Normal = normalize( mul( float4( NormalSample, 1.0f ), InvViewMatrix ).xyz );
				float3 RayDir = normalize( reflect( RayOrigin, Normal ) );
				float3 RayEnd = RayOrigin + RayDir * MaxDistanceViewSpace;
				
				// We're going to follow the reflected ray in screen-space, starting and stopping at where RayOrigin andRayEnd are projected on the screen
				float4 RayOriginScreenSpace = ViewSpaceToScreenSpace( RayOrigin, TextureSize );
				float4 RayEndScreenSpace = ViewSpaceToScreenSpace( RayEnd, TextureSize );
				float3 StartPixel  = RayOriginScreenSpace.xyz;
				float3 TargetPixel = RayEndScreenSpace.xyz;
				
				// The search for where the ray hits something we can show a reflection for is in two parts.
				// First we march the ray (in screenspace) to find a point where the ray has gone "through" the depth buffer. SearchFar will contain the t-value for that point
				// Secondly we will refine the hit position using a binary search. SearchNear and SearchFar will converge at the intersection point
				float SearchNear = 0.0f;
				float SearchFar = 0.0f;
				
				// Initial search - marching the ray screen-space. We should end with a miss or an intersection between two pixels (or further apart if resolution < 1.0 )
				float2 Delta = TargetPixel.xy - StartPixel.xy;
				float MajorAxis = abs(Delta.x) >= abs(Delta.y) ? 0 : 1;
				float Iterations = lerp( abs(Delta.x), abs(Delta.y), MajorAxis ) * Resolution;
				float2 Increment = Delta / max( Iterations, 0.001f );
				
				float2 CurrentPixel = StartPixel.rg;
				bool DidHit = false;
				float3 HitPosition = RayOrigin;
				float HitDeltaDepth = 0.0f;
				
				int i = 0;
				for( i = 0; i < min( MaxInitialSearchSteps, int(Iterations) ); ++i )
				{
					CurrentPixel += Increment;
					float2 CurrentUv = ScreenSpaceToUV( CurrentPixel, TextureSize );
					float DepthBufferSample = SampleDepthBuffer( CurrentUv, TextureSize );
					HitPosition = ViewSpacePosFromDepth( DepthBufferSample, CurrentUv );
					
					float T = lerp( ( CurrentPixel.x - StartPixel.x ) / Delta.x,( CurrentPixel.y - StartPixel.y ) / Delta.y, MajorAxis );
					T = saturate( T );
					
					//Perspective-correct lerp of the depth. ViewSpace z-axis goes "into" the screen
					float ViewDepth = (RayOrigin.z * RayEnd.z ) / lerp( RayEnd.z, RayOrigin.z, T );
					HitDeltaDepth = ViewDepth - HitPosition.z;
					
					if( HitDeltaDepth >= 0.0f && HitDeltaDepth <= Thickness )
					{
						// Intersects. Update SearchFar to our current position (best known "hit")
						SearchFar = T;
						DidHit = true;
						break;
					}
					else
					{
						// No intersection yet. Update SearchNear to our current position (best known "miss")
						SearchNear = T;
						RefinementSteps = MaxRefinementSteps;
					}
				}
				float RelativeIterationCount = float(i) / float(MaxInitialSearchSteps);
				if( !DidHit )
				{
					return Out;
				}
				
				// Secondary search - refining the hit position 
				float RefinementThickness = Thickness / 2; //Thickness should use a more precise hit each iteration since we are decreasing the step length
				for( int j = 0; j < RefinementSteps; ++j )
				{
					RefinementThickness = RefinementThickness / 2;
					float T = ( SearchNear + SearchFar ) * 0.5f;
					float2 CurrentPixel = lerp( StartPixel, TargetPixel, T ).rg;
					float2 CurrentUv = ScreenSpaceToUV( CurrentPixel, TextureSize );
					float DepthBufferSample = SampleDepthBuffer( CurrentUv, TextureSize );
					float ViewDepth = (RayOrigin.z * RayEnd.z ) / lerp( RayEnd.z, RayOrigin.z, T );
					
					float3 CurHitPosition = ViewSpacePosFromDepth( DepthBufferSample, CurrentUv );
					float  CurHitDeltaDepth = ViewDepth - HitPosition.z;
					
					if( CurHitDeltaDepth >= 0 && CurHitDeltaDepth <= RefinementThickness )
					{
						SearchFar = T;
						HitPosition = CurHitPosition;
						HitDeltaDepth = CurHitDeltaDepth;
					}
					else
					{
						SearchNear = T;
					}
				}
				
				float2 Uv = ScreenSpaceToUV( ViewSpaceToScreenSpace( HitPosition, TextureSize ).rg, TextureSize );
				
				float Visibility = Mask;
				
				// Fade out reflection vectors that point toward the camera
				float3 ToCameraDir = normalize( -RayOrigin );
				Visibility *= 1.0f - saturate( dot(ToCameraDir,RayDir) *0.5);
				
				// Fade out reflection based on the amount of error in the sample
				Visibility *= 1.0f - smoothstep( 0.25f, 1.0f, saturate( HitDeltaDepth / Thickness ) );
				
				// Fade out based on the distance from RayOrigin to HitPosition
				// Also consider if we hit the iteration limit
				float RelativeDistance = max( pow( RelativeIterationCount, 2.0f ), saturate( length( HitPosition - RayOrigin ) / MaxDistanceViewSpace ) );
				Visibility *= 1.0f - RelativeDistance;
				
				// Fade out reflections that want to sample close to the edge of the screen				
				Visibility *= smoothstep( 0.0f, EdgeFadeRange.x, Uv.x );
				Visibility *= smoothstep( 0.0f, EdgeFadeRange.y, Uv.y );
				Visibility *= smoothstep( 1.0f, 1.0f - EdgeFadeRange.x, Uv.x );
				Visibility *= smoothstep( 1.0f, 1.0f - EdgeFadeRange.y, Uv.y );

				float4 Reflected = PdxTex2D( MainImage, Uv );				
				Out.rgb = lerp( Reflected.rgb, Reflected.rgb * SpecularSample.rgb, MaterialSample.b );
				Out.a = Visibility;
				return Out;
			}
		]]
	}
	
	MainCode Cleanup
	{
		TextureSampler ReflectedColor
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Border"
			SampleModeV = "Border"
		}
		
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				#define CleanupMethod 2
				
				#if ( CleanupMethod == 0 )
				return PdxTex2D( ReflectedColor, Input.uv );
				
				
				#elif( CleanupMethod == 1 )
				float2 TextureSize;
				PdxTex2DSize( ReflectedColor, TextureSize );
				float2 PixelSize = vec2(1.0f) / TextureSize;
				
				float3 OffsetX = float3( -PixelSize.x, 0.0f, PixelSize.x ) * 1.0f;
				float3 OffsetY = float3( -PixelSize.y, 0.0f, PixelSize.y ) * 1.0f;
				
				float4 Sample = PdxTex2D( ReflectedColor, Input.uv );
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.x, OffsetY.x ) ).a;
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.y, OffsetY.x ) ).a;
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.z, OffsetY.x ) ).a;				
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.x, OffsetY.y ) ).a;
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.z, OffsetY.y ) ).a;				
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.x, OffsetY.z ) ).a;
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.y, OffsetY.z ) ).a;
				Sample.a += PdxTex2D( ReflectedColor, Input.uv + float2( OffsetX.z, OffsetY.z ) ).a;
				Sample.a /= 9.0f;
				return Sample;
				
				
				#elif( CleanupMethod == 2 )
				float2 TextureSize;
				PdxTex2DSize( ReflectedColor, TextureSize );
				float2 PixelSize = vec2(1.0f) / TextureSize;
				
				float w0 = 0.2;
				float w1 = 0.3;
				float w2 = 1.0f;
				
				float3 Kernel[] = { 
					float3( -1, -1, w0 ), float3( 0, -1, w1 ), float3( 1, -1, w0 ),
					float3( -1,  0, w1 ), float3( 0,  0, w2 ), float3( 1,  0, w1 ),
					float3( -1,  1, w0 ), float3( 0,  1, w1 ), float3( 1,  1, w0 )
				};
				
				float4 Sum = vec4( 0.0f );
				float SumWeights = w0 * 4 + w1 * 4 + w2;
				float SumAlpha = 0.0f;
				for( int i = 0; i < 9; ++i )
				{
					float4 Sample = PdxTex2D( ReflectedColor, Input.uv + Kernel[i].xy * PixelSize );
					SumAlpha += Kernel[i].z * Sample.a;
					Sample.rgb *= Kernel[i].z * Sample.a;
					Sample.a *= Kernel[i].z;
					Sum += Sample;
				}
				
				if( SumAlpha > 0.001f )
				{
					Sum.rgb /= SumAlpha;
				}
					
				Sum.a /= SumWeights;
				return Sum;
				#endif
			}
		]]
	}
	MainCode Downsample
	{
		TextureSampler ReflectedColor
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		ConstantBuffer( PdxConstantBuffer0 )
		{
			float2 UvScale;
			float2 PixelSize;
		}
		
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float3 OffsetX = float3( -PixelSize.x, 0.0f, PixelSize.x ) * 0.25f;
				float3 OffsetY = float3( -PixelSize.y, 0.0f, PixelSize.y ) * 0.25f;
				
				float4 Sample = vec4(0.0f);
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.x, OffsetY.x ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.y, OffsetY.x ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.z, OffsetY.x ) );
				
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.x, OffsetY.y ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.y, OffsetY.y ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.z, OffsetY.y ) );
				
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.x, OffsetY.z ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.y, OffsetY.z ) );
				Sample += PdxTex2D( ReflectedColor, Input.uv * UvScale * 2.0f + float2( OffsetX.z, OffsetY.z ) );
				Sample /= 9.0f;
				
				return Sample;
			}
		]]
	}
	MainCode ApplyReflectedColors
	{
		TextureSampler ReflectedColor
		{
			Ref = PdxTexture0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Border"
			SampleModeV = "Border"
		}
		TextureSampler GBufferMaterial
		{
			Ref = SsrGBuffer1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			float RoughnessToMip( float PerceptualRoughness )
			{
				const float MipCount = 4;
				const float MipOffset = 0;
				float Scale = PerceptualRoughness * (1.7 - 0.7 * PerceptualRoughness);
				return Scale * ( MipCount - 1 - MipOffset );
			}
			PDX_MAIN
			{
				float4 Material = PdxTex2DLod0( GBufferMaterial, Input.uv );
				float4 Color = PdxTex2DLod( ReflectedColor, Input.uv, RoughnessToMip( Material.r ) );
				return Color;
			}
		]]
	}
}


BlendState BlendState {
	BlendEnable = no
}

DepthStencilState DepthStencilState {
	DepthEnable = no
	DepthWriteEnable = no
}

BlendState BlendStateApply {
	BlendEnable = yes	
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

Effect CalcReflectedColor
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "CalcReflectedColor"
}
Effect Cleanup
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "Cleanup"
}
Effect Downsample
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "Downsample"
}
Effect ApplyReflectedColors
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "ApplyReflectedColors"
	
	BlendState = BlendStateApply
}
