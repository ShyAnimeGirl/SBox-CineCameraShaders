HEADER
{
	Description = "Color Correction using OBS Style png LUTS";
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
	float fOpacity < Attribute("fOpacity"); >;

	
	Texture2D lut_texture < Attribute("lut_texture");  >;
	


    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		//float2 uv = i.vTexCoord;
		
		float4 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord);
		
		float3 Index = input_color.rgb * 63.0f;
		
		float xR = clamp(Index.r / 512.0f, 0.001f, 0.999f); //gotta slightly crush the value so the filter doesn't spill with trilin
		
		float yG = clamp(Index.g / 512.0f, 0.001f, 0.999f);
		
		float zB = round(Index.b);
		
		float2 lutuv = float2((((zB % 8) * 64) / 512) + xR ,((floor(zB / 8) * 64) / 512) + yG);
		
		
		float4 output_color = lut_texture.Sample(g_sTrilinearClamp, lutuv);
		
		output_color = (input_color * (1.0 - fOpacity)) + (output_color * fOpacity) ;
		

		return output_color;
    }
}