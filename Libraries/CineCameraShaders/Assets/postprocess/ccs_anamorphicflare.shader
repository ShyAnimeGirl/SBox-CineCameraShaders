HEADER
{
	Description = "Anamorphic Lens Flares";
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
	Texture2D g_tBlurBuffer < Attribute( "blurBuffer" ); SrgbRead( true ); >;
	
	
	

	// inputs
	float fCutoff < Attribute("fCutoff"); >;
	float fPower < Attribute("fPower"); >;
	float fStretch < Attribute("fStretch"); >;
	float fVStretch < Attribute("fVStretch"); >;
	float fShape < Attribute("fShape"); >;
	float fVShape< Attribute("fVShape"); >;
	float fGain < Attribute("fGain"); >;
	float3 fColor < Attribute("fColor"); >;
		
	bool fVertON < Attribute("fVertON"); >;
	bool fHoriON < Attribute("fHoriON"); >;	
	bool fDoubleAdd < Attribute("fDoubleAdd"); >;		
	bool fBypass < Attribute("fBypass"); >;
	
	float3 flare(Texture2D scene, float2 uv, float cutoff, float power, float gain)
	{
		
		float3 flares = g_tColorBuffer.Sample(g_sTrilinearClamp, uv).rgb; //sample the ORIGINAL unblured image
		
		
		float flarePower = power * fStretch ;
		float vflarePower = power * fVStretch ;
		
		if(fHoriON)
		{
			for (float ix = flarePower; ix > -1.0; ix--)
			{
				float lPixels = scene.Sample(g_sTrilinearClamp, uv + float2(ix / power, 0.0f)).r;
				float rPixels = scene.Sample(g_sTrilinearClamp, uv - float2(ix / power, 0.0f)).r;

				
				if(max(lPixels,rPixels) > cutoff)
					flares = flares + abs(floor(pow(max(lPixels,rPixels), fShape)) * (1.0 - ix / flarePower ) * gain) * fColor;

			}
		}
		
		if(fVertON)
		{
			for (float iy = vflarePower ; iy > -1.0; iy--)
			{

				float tPixels = scene.Sample(g_sTrilinearClamp, uv + float2(0.0f, iy / power)).r;
				float bPixels = scene.Sample(g_sTrilinearClamp, uv - float2(0.0f, iy / power)).r;
				if(max(tPixels, bPixels) > cutoff)
					flares = flares + abs(floor( pow(max(tPixels, bPixels), fVShape)) * (1.0 - iy / vflarePower) * gain) * fColor;
				
				//iy = iy - 0.5;
			}
		}

		return flares;
	}


    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		
		float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		
		if(fBypass)
			input_color = g_tBlurBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		else
		{
			if(fDoubleAdd)
				input_color = input_color + flare(g_tBlurBuffer, i.vTexCoord, fCutoff, fPower, fGain);
			else
				input_color = flare(g_tBlurBuffer, i.vTexCoord, fCutoff, fPower, fGain);
		}
		return float4(input_color, 1);
    }
}