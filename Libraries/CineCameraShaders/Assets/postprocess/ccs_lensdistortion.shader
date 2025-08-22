HEADER
{
	Description = "Lens Distortion Effect";
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
	
	//https://sbox.game/dev/doc/shaders/sampler-states/
	//not using clamped predefines for main
	SamplerState PixelSample < Filter(Point); >;

	
	
	// inputs
	float dBarrel < Attribute("dBarrel"); >;
	float dPin < Attribute("dPin"); >;
	float CropIn < Attribute("CropIn"); >;
	bool Filter < Attribute("Filter"); >;
	bool dCircle < Attribute("dCircle"); >;
	bool dPanini < Attribute("dPanini"); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		float2 uv = i.vTexCoord;
		
		
		// brings the uv into a working space
		uv = uv * 2.0f - 1.0f;
		float aspectRatio;
		
		if(dCircle)
		{
			aspectRatio = g_vViewportSize.x / g_vViewportSize.y;
			uv.x *= aspectRatio;
		}
		
		float r_ideal = length(uv);
	
		float pincushion = 1.0f - dPin * r_ideal * r_ideal;
		
		float barrel = 1.0f + dBarrel * r_ideal * r_ideal;
		
		float distortion = pincushion * barrel;
		
		uv = uv * (1.0f / (CropIn / 100.0f));
		
		//http://tksharpless.net/vedutismo/Pannini/panini.pdf
		if(dPanini)// i feel like this could be changed out with a custom func with more options in the future 
			uv = PaniniProjection(uv, (100*dBarrel + 0.001) + (100*dPin + 0.001));
		else
			uv = uv * distortion;
		
		
		
		if(dCircle)
			uv.x /= aspectRatio;
		
		
		
		
		//bring the uv back into normal space
		uv = (uv + 1.0f) * 0.5f;
		
		
			
		if(Filter) 
		{

			
			return g_tColorBuffer.Sample(g_sTrilinearClamp, uv);
			
		}
		if((uv.y > 1.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.x < 0.0))
			return float4(1.0,0.0,0.0,1.0); //red when no-go
			
		return g_tColorBuffer.Sample(g_sPointClamp, uv);
    }
}