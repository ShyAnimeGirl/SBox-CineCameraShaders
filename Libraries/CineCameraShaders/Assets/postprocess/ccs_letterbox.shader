HEADER
{
	Description = "Letterbox Effect";
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
	//a sampler which samples every point of the texture (which is the screen in this case)
	SamplerState PixelSample < Filter(Point); >;
	
	//the color
    float3 LetterboxColor < Attribute("LetterboxColor"); >;
	
	//percent inputs
	float vPercent < Attribute("vPercent"); >;
	float hPercent < Attribute("hPercent"); >;
	

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		if (vPercent > 99.724f) //help preveent single pixel rounding errors and speeds up process 
		{
			return float4 (LetterboxColor, 1);
		}
		if (hPercent > 99.724f)
		{
			return float4 (LetterboxColor, 1);
		}
		
		float2 uv = i.vTexCoord;
		float lboxH = (hPercent / 100) * 0.5f;
		float lboxV = (vPercent / 100) * 0.5f;
		if(uv.x < lboxH || uv.x > 1 - lboxH || uv.y < lboxV || uv.y > 1- lboxV)
		{
			return float4 (LetterboxColor, 1);
		}
		return g_tColorBuffer.Sample(PixelSample, uv);
    }
}