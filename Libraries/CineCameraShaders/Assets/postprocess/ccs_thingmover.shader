HEADER
{
	Description = "Moves a thing around the screen and combines it with the original image";
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
	
	float xScale < Attribute("xScale"); >;
	float xPos < Attribute("xPos"); >;
	float yScale < Attribute("yScale"); >;
	float yPos < Attribute("yPos"); >;
	
	float fOpacity < Attribute("fOpacity"); >;

	
	
	Texture2D Thing < Attribute("ThingBuffer"); SrgbRead( true ); >;
	
	//float aspect = g_vViewportSize.x / g_vViewportSize.y;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		float2 uv = i.vTexCoord;
		

		
		float3 output_color;
		
		float2 scale = float2(1/xScale, 1/yScale);
		float2 offset = float2(xPos,yPos);
		
		
		float2 imageuv = i.vTexCoord + offset;
		imageuv = (imageuv - 0.5) * scale + 0.5;
		
	
		float3 screen_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
			

		float3 thing_color = Thing.Sample(g_sTrilinearClamp, imageuv).rgb;
		
		
		if (imageuv.x < 0.0 || imageuv.x > 1.0 || imageuv.y < 0.0 || imageuv.y > 1.0)
		{
			// If the imageuv is outside of bounds, return the screen color
			output_color = screen_color;
		}
		else	
			output_color = lerp( screen_color, thing_color, fOpacity);
			

		return float4(output_color,1);
    }
}