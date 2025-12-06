Includes = {
	"flatmap_lerp.fxh"
	"cw/terrain.fxh"
}

VertexShader =
{
	Code [[
		VS_OUTPUT_RIVER CaesarRiverVertexShader( in VS_INPUT_RIVER Input )
		{
			VS_OUTPUT_RIVER Out;
			
				Out.UV 				= Input.UV;
				Out.Tangent 		= Input.Tangent;
				Out.Normal			= Input.Normal;
				Out.WorldSpacePos 	= Input.Position;
				Out.Transparency 	= Input.Transparency;
				Out.Width 			= Input.Width * max( GetMapSize().x, GetMapSize().y );
				Out.DistanceToMain	= Input.DistanceToMain;
				float3 Binormal = cross (Input.Tangent,Input.Normal);
				float Left = (Out.UV.y)*2.0f-1.0f;
				float Height0 = GetHeight(Out.WorldSpacePos.xz);
				float Height1 = GetHeight(Out.WorldSpacePos.xz+Binormal.xz*Out.Width*Left*0.5);
				float2 DisplacementXZ = Out.Tangent.xz*Out.Width*0.5;
				float Height2 = GetHeight(Out.WorldSpacePos.xz+DisplacementXZ);
				float Height3 = GetHeight(Out.WorldSpacePos.xz-DisplacementXZ);
				Out.WorldSpacePos.y = Height0;
				AdjustFlatMapHeight( Out.WorldSpacePos );
				float MaxHeight = max(max(max(Height0,Height1),Height2),Height3);
				float MinHeight = min(min(min(Height0,Height1),Height2),Height3);
				float HeightDifference = MaxHeight - MinHeight;
				HeightDifference*=0.25;
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos, 1.0f ) );
				float4 BiasPosition = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos.x,Out.WorldSpacePos.y+HeightDifference,Out.WorldSpacePos.z, 1.0f ) );
				Out.Position.z = BiasPosition.z;
				return Out;
		}
	]]
}