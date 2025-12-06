Includes = {
	"cw/camera.fxh"
	"cw/quaternion.fxh"
	"terrain.fxh"
	"flatmap_lerp.fxh"
}

VertexStruct VS_INPUT_PARTICLE
{
	float2 UV0							: TEXCOORD0;
	float4 Position						: TEXCOORD1;	// Position.w contains the flipbook dimensions.
	uint RotQ							: TEXCOORD2;	// Rotation relative to world or camera when billboarded.
	float4 SizeAndOffset				: TEXCOORD3;	// SizeAndOffset.zw contains the local pivot offset
	float4 BillboardAxisAndFlipbookTime : TEXCOORD4;	// BillboardAxisAndFlipbookTime.w contains the flipbook time.
	float4 Color						: TEXCOORD5;
};

VertexStruct VS_OUTPUT_PARTICLE
{
	float4 Pos				: PDX_POSITION;
	float4 Color			: COLOR;
	float2 UV0				: TEXCOORD0;
	float2 UV1				: TEXCOORD1;
	float3 WorldSpacePos	: TEXCOORD2;
	float FrameBlend		: TEXCOORD3;
	float Height 			: TEXCOORD4;
};

Code
[[
	static const float3 ZERO = float3( 0.0, 0.0, 0.0 );
	static const float3 POS_X = float3( 1.0, 0.0, 0.0 );
	static const float3 POS_Y = float3( 0.0, 1.0, 0.0 );
	static const float3 POS_Z = float3( 0.0, 0.0, 1.0 );
	static const float3 NEG_X = float3( -1.0, 0.0, 0.0 );
	static const float3 NEG_Y = float3( 0.0, -1.0, 0.0 );
	static const float3 NEG_Z = float3( 0.0, 0.0, -1.0 );

	uint CalcCurrentFrame( int Columns, int Rows, float Time )
	{
		int TotalFrames = ( Columns * Rows );
		return uint( TotalFrames * Time );
	}

	float CalcFrameBlend(int Columns, int Rows, float Time)
	{
		uint TotalFrames = ( Columns * Rows );
		return frac(TotalFrames * Time);
	}

	float2 CalcCellUV( uint CurrentFrame, float2 UV, int Columns, int Rows, float Time )
	{
		float2 CellUV;
		CellUV.x = float( CurrentFrame % Columns ) / Columns;
		CellUV.y = float( CurrentFrame / Columns ) / Rows;
		
		UV.x = ( UV.x / Columns );
		UV.y = ( UV.y / Rows );
		
		return CellUV + UV;
	}

	#define RED_MASK	0xFFC00000
	#define GREEN_MASK	0x003FF000
	#define BLUE_MASK	0x00000FFC
	#define INDEX_MASK	0x00000003

	// Use this function to fill "empty" bits with MS bit (i.e. sign bit on a negative number)
	int ArithmeticRightShift( int x, int n )
	{
		if ( x < 0 && n > 0 )
		{
			return x >> n | ~( ~0U >> n );
		}
		else
		{
			return x >> n;
		}
	}

	float4 DecodeQuaternion( int RotQ )
	{
		// Use the stored index to reconstruct the full quaternion
		int MaxIndex = RotQ & INDEX_MASK;
	
		// Read the other three fields and derive the value of the omitted field
		int divisor = 1 << 9; // We have 9 bits of precision in a 10 bit signed field
		float a = float( ArithmeticRightShift( ( RotQ & RED_MASK ), 22 ) ) / divisor;
	
		// The following two components do not have their sign bit as MSB so left shift
		// first to preserve the sign bit before shifting right!
		float b = float( ArithmeticRightShift( ( ( RotQ & GREEN_MASK ) << 10 ), 22 ) ) / divisor;
		float c = float( ArithmeticRightShift( ( ( RotQ & BLUE_MASK ) << 20 ), 22 ) ) / divisor;
		float d = sqrt( 1.f - ( a * a + b * b + c * c ) );

		if ( MaxIndex == 0 )
		{
			return float4( d, a, b, c );
		}
		else if ( MaxIndex == 1 )
		{
			return float4( a, d, b, c );
		}
		else if ( MaxIndex == 2 )
		{
			return float4( a, b, d, c );
		}

		return float4( a, b, c, d );
	}

	uint2 UnpackFromFloat( float Packed )
	{
		uint PackedUint = uint( Packed );
		return int2( PackedUint & 0xff, ( PackedUint >> 8 ) & 0xff );
	}
]]

VertexShader =
{
	MainCode VertexParticle
	{				
		Input = "VS_INPUT_PARTICLE"
		Output = "VS_OUTPUT_PARTICLE"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PARTICLE Out;
				float3 InitialOffset = float3( ( Input.UV0 - Input.SizeAndOffset.zw - 0.5f ) * Input.SizeAndOffset.xy, 0 );

				float4 RotQ = DecodeQuaternion( Input.RotQ );
				float3 Offset = RotateVector( RotQ, InitialOffset );
				float Alpha = 0.0f;

				#ifdef BILLBOARD
					float3 WorldPos = Input.Position.xyz + Offset.x * CameraRightDir + Offset.y * CameraUpDir;

					if( Input.BillboardAxisAndFlipbookTime.x != 0.0 || 
						Input.BillboardAxisAndFlipbookTime.y != 0.0 || 
						Input.BillboardAxisAndFlipbookTime.z != 0.0 )
					{
						float3 Up = normalize( RotateVector( RotQ, Input.BillboardAxisAndFlipbookTime.xyz ) );
						float3 ToCameraDir = normalize( CameraPosition - Input.Position.xyz );
						float3 Right = normalize( cross( ToCameraDir, Up ) );
						WorldPos = Input.Position.xyz + InitialOffset.x * Right + InitialOffset.y * Up;

						#ifdef FADE_STEEP_ANGLES
							float3 Direction = cross( Right, Up );
							float fresnel = saturate( pow( 1.0f - abs( dot( ToCameraDir, Direction ) ), 2.0f ) * 2.5f );
							Alpha = Input.Color.a * fresnel;
						#else
							Alpha = Input.Color.a;
						#endif
					}
					else
					{
						//Cannot fade steep angles because the lack of a particle normal
						Alpha = Input.Color.a;
					}
				#else
					float3 WorldPos = Input.Position.xyz + Offset;
					//Cannot fade steep angles because the lack of a particle normal
					Alpha = Input.Color.a;
				#endif
				#ifdef ENABLE_TERRAIN
					float NoisyFlatmap = GetNoisyFlatMapLerp( WorldPos ).x;
					WorldPos.y = lerp( WorldPos.y, GetFlatMapHeight(), NoisyFlatmap );
				#endif
				uint2 FlipbookDimensions = UnpackFromFloat( Input.Position.w );
				uint CurrentFrame = CalcCurrentFrame(FlipbookDimensions.x, FlipbookDimensions.y, Input.BillboardAxisAndFlipbookTime.w);
				Out.Pos = FixProjectionAndMul( ViewProjectionMatrix, float4( WorldPos, 1.0f ) );
				Out.UV0 = CalcCellUV( CurrentFrame, float2( Input.UV0.x, 1.0f - Input.UV0.y ), FlipbookDimensions.x, FlipbookDimensions.y, Input.BillboardAxisAndFlipbookTime.w );
				Out.UV1 = CalcCellUV( CurrentFrame + 1, float2( Input.UV0.x, 1.0f - Input.UV0.y ), FlipbookDimensions.x, FlipbookDimensions.y, Input.BillboardAxisAndFlipbookTime.w );
				Out.FrameBlend = CalcFrameBlend( FlipbookDimensions.x, FlipbookDimensions.y, Input.BillboardAxisAndFlipbookTime.w );
				Out.Color = float4(Input.Color.rgb, Alpha);
				Out.WorldSpacePos = WorldPos;

				#ifdef ENABLE_TERRAIN
					float FlatmapFade = 1.0f - NoisyFlatmap;
					Out.Color.a*=FlatmapFade;
					Out.Height = GetHeight( float2( WorldPos.x, WorldPos.z ));
				#else
					Out.Height = 0.0;
				#endif
				
				return Out;
			}
		]]
	}
}


PixelShader =
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
}