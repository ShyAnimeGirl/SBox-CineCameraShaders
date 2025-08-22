HEADER
{
	Description = "Simple Blur Filter, formerly box-blur only";
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
	
	
	float bRadius < Attribute("bRadius"); >;
	
	float bMulti < Attribute("bMulti"); >;
	
	bool bAspect < Attribute("bAspect"); >;
	bool bCircle < Attribute("bCircle"); >;	
	bool bLoop < Attribute("bLoop"); >;	

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		float2 uv = i.vTexCoord;
		float3 blur = float3(0.0f, 0.0f, 0.0f);
		float accumulator = 0.0f;
		float2 scale;
		
		if(bAspect)
			scale = float2(g_vViewportSize.x / (bMulti / 8),g_vViewportSize.y / (bMulti/8));
		else	
			scale = 8192.0f / bMulti;
		
		for (float x = -bRadius; x <= bRadius; x++)
		{
			for (float y = -bRadius; y <= bRadius; y++)
			{
				float2 offset = float2(x,y);
				float dist = length(offset);
				offset = float2(x,y) / scale; 
				if(bCircle)
				{
					if(dist <= bRadius)
					{
						if(bLoop)
							blur = blur + g_tColorBuffer.Sample(g_sTrilinearWrap, uv + offset).rgb;
						else
							blur = blur + g_tColorBuffer.Sample(g_sTrilinearClamp, uv + offset).rgb;
							
						accumulator = accumulator + 1.0f;
					}
				}
				else
				{
					if(bLoop)
						blur = blur + g_tColorBuffer.Sample(g_sTrilinearWrap, uv + offset).rgb;
					else
						blur = blur + g_tColorBuffer.Sample(g_sTrilinearClamp, uv + offset).rgb;
						
					accumulator = accumulator + 1.0f;
				}
				
				
			}
			
		}
		
		return float4(blur / accumulator, 1);		
		
		
		
    }
}