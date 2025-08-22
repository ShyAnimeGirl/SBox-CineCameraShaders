HEADER
{
	Description = "Perspective Correction Effect";
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
	
	
	// inputs
	float shiftAmount < Attribute("dUpper"); >;
	float lshiftAmount < Attribute("dLower"); >;
	float CropIn < Attribute("CropIn"); >;
	bool Filter < Attribute("Filter"); >;
	

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		float2 uv = i.vTexCoord;
		
		//very very very stupid and basic and bad. make this more correct in the future lol
		if(lshiftAmount > 0.0)
			uv.x = uv.x + (0.5 - uv.x) * lshiftAmount * (uv.y);
		else
			uv.x = uv.x + (0.5 - uv.x) * shiftAmount * (1.0 - uv.y);
			
			
		//will need crop later with more advanced settings 	
		// brings the uv into a working space
		//uv = uv * 2.0f - 1.0f;

		//uv = uv * (1.0f / (CropIn / 100.0f));

		//bring the uv back into normal space
		//uv = (uv + 1.0f) * 0.5f;
		
		
		
		
		if(Filter) 
		{
			return g_tColorBuffer.Sample(g_sTrilinearClamp, uv);
		}
		//reenable later when more advanced shifts are added
		//if((uv.y > 1.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.x < 0.0))
		//	return float4(1.0,0.0,0.0,1.0);
		
		return g_tColorBuffer.Sample(g_sPointClamp, uv);
    }
}