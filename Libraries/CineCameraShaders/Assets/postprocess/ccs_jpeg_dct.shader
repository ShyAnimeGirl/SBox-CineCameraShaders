HEADER
{
	Description = "JPEG DCT";
	DevShader = true;
	Version = 1;
}


MODES
{
    VrForward();
   // Depth();
}

FEATURES
{
    #include "common/features.hlsl"
}

COMMON
{
	#include "common/shared.hlsl"
}


struct VertexInput
{
    float3 vPositionOs : POSITION < Semantic( PosXyz ); >;
    float2 vTexCoord : TEXCOORD0 < Semantic( LowPrecisionUv ); >;
};

struct PixelInput
{
    float2 vTexCoord : TEXCOORD0;

	#if ( PROGRAM == VFX_PROGRAM_VS )
		float4 vPositionPs		: SV_Position;
	#endif

	#if ( ( PROGRAM == VFX_PROGRAM_PS ) )
		float4 vPositionSs		: SV_Position;
	#endif
};


VS
{
	//#include "common/vertex.hlsl"
    PixelInput MainVs( VertexInput i )
    {
        PixelInput o;
        
        o.vPositionPs = float4( i.vPositionOs.xy, 0.0f, 1.0f );
        o.vTexCoord = i.vTexCoord;
        return o;
    }
}



PS
{
	#include "postprocess/common.hlsl"
    #include "postprocess/functions.hlsl"
	
    RenderState( DepthWriteEnable, false );
    RenderState( DepthEnable, false );

    // "ColorBuffer" passed from the graphics.GrabFrameTexture
    Texture2D g_tColorBuffer < Attribute( "ColorBuffer" ); SrgbRead( true ); >;
	
	int levels < Attribute("levels"); >;
	
	int freq < Attribute("freq"); >;
	
	float DCTc(float2 a, float2 b)
	{
		return cos(3.1415972 * a.x * b.x) * cos(3.1415972 * a.y * b.y);
	}
	
	float3 DCT(Texture2D scene, float2 uv)
	{
		float2 loc = (uv % 8.0) - 0.5;
		float2 block = uv - 0.5 - loc;
		float3 color = 0.0;
		
		for(int x=0; x<8; x++)
		{
			for(int y=0; y<8; y++)
			{
				// Compute location for each sample in  8x8 block
				float2 uvi = ((uv - 0.5 - loc) + float2(x,y) + 0.5) / g_vViewportSize;
				//color += (((scene.Sample(g_sPointClamp, (block + float2(x,y) - 0.5) / g_vViewportSize.xy).rgb - 0.5)) * DCTc(loc, float2(x,y) + 0.5) / 8.0) * (loc.x<0.5?0.70710678118:1.0) * (loc.y<0.5?0.70710678118:1.0);
				color = color + scene.Sample(g_sPointClamp, uvi ).rgb * DCTc(loc, (float2(x,y) + 0.5) /8.0) * (loc.x<0.5?0.70710678118:1.0) * (loc.y<0.5?0.70710678118:1.0);
			}
		}
		
		return color / 8;
	}
	
	
    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		float2 uv = i.vTexCoord * g_vViewportSize;
		//float3 dctColor = DCT(g_tColorBuffer, uv).rgb;
		
		//dctColor = round(dctColor * levels) / levels;
		//dctColor = floor(dctColor * levels) / levels;
		return float4(round(DCT(g_tColorBuffer, uv) / 8.0 * levels) / levels * 8.0 , 1.0);		

		//return float4(dctColor, 1.0);
    }
}

		
		//return float4(DCT(g_tColorBuffer, uv), 1.0);
		
		//return g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord);