HEADER
{
	Description = "JPEG Compression Artifacts";
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
	Texture2D DCTBuffer < Attribute( "DCTBuffer" );  >;
	
	int levels < Attribute("levels"); >;
	
	int freq < Attribute("freq"); >;
	
	bool bypass < Attribute("bypass"); >;
	
	float DCTc(float2 a, float2 b)
	{
		return cos(3.1415972 * a.x * b.x) * cos(3.1415972 * a.y * b.y);
	}
	

	
    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		float2 uv = i.vTexCoord * g_vViewportSize;
		
		float2 loc = (uv % 8.0) - 0.5;
		float2 block = uv - loc - 0.5;
		
		float3 color = float3(0.0f,0.0f, 0.0f);
		
		for(int u=0; u<freq; u++)
		{
			for(int v=0; v<freq; v++)
			{
				float2 uvi = ((uv - loc - 0.5) + float2(u,v) + 0.5) / g_vViewportSize;
				//color = color + DCTBuffer.Sample(g_sTrilinearClamp, uvi).rgb * DCTc(float2(u,v), (loc + 0.5) / 8.0) * (u==0 ? 0.70710678118:1.0) * (v==0 ? 0.70710678118:1.0);
				color = color + DCTBuffer.Sample(g_sPointClamp, uvi).rgb * DCTc(float2(u,v), (loc) / 8.0) * (u==0 ? 0.70710678118:1.0) * (v==0 ? 0.70710678118:1.0);
				//color += DCTBuffer.Sample(g_sPointClamp, (block + float2(u,v) + 0.5) / g_vViewportSize.xy).rgb * DCTc(float2(u,v), (loc + 0.5) / 8.0) * (u==0?0.70710678118:1.0) * (v==0?0.70710678118:1.0);
				//cant get it to work quite right, not sure if the problem is in the initial DCT or the inverse here
			}
		}
		
		
		
		
		if(bypass)
			return DCTBuffer.Sample(g_sPointClamp, i.vTexCoord);
		else
			return float4(((color / 2.0)  ) , 1.0);		
		
		
    }
}