HEADER
{
	Description = "Normal Lens Flares";
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
	
	Texture2D color_map < Attribute( "color_map" ); SrgbRead( true ); >;
	Texture2D opacity_map < Attribute( "opacity_map" ); SrgbRead( true ); >;
	
	
	//obviously this was made using the other shader, keeping the inputs here for ez additions later
	// inputs
	float fCutoff < Attribute("fCutoff"); >;
	//float fPower < Attribute("fPower"); >;
	float fStretch < Attribute("fStretch"); >;
	//float fVStretch < Attribute("fVStretch"); >;
	float fShape < Attribute("fShape"); >;
	//float fVShape< Attribute("fVShape"); >;
	float fGain < Attribute("fGain"); >;
	float3 fColor < Attribute("fColor"); >;
		
	//bool fVertON < Attribute("fVertON"); >;
	//bool fHoriON < Attribute("fHoriON"); >;	
	bool fDoubleAdd < Attribute("fDoubleAdd"); >;		
	bool fBypass < Attribute("fBypass"); >;
	

	//based off of this https://john-chapman.github.io/2017/11/05/pseudo-lens-flare.html
	//after writing I found https://www.shadertoy.com/view/mtVSRd which is also based on the above page
	//but it has some extra features that could be added in the future maybe?
	//I am not a huge fan of how these look realism wise. 
	//Real life lens flares change depending on the lens, aperture, and focal distance.
	//Real lens flares are 3D objects that would take a LOT of work to mimmic correctly. 
	
	//this shader looks OKAY with certain settings but is far from ideal.
	
	float3 flare(Texture2D scene, float2 uv)
	{
		
		//float3 flares = g_tColorBuffer.Sample(g_sTrilinearClamp, uv).rgb; //sample the ORIGINAL unblured image
		
		float2 uvi = 1.0 - uv;
		float2 flareUV = (0.5 - uvi) * fStretch; //power aka spacing 0.2
		float3 flareColor = float3(0.0f, 0.0f, 0.0f);
		float Flares = fShape;
		
		float2 flareDir = normalize(flareUV);
		
		//MUCH MUCH MUCH MUCH better lens flares could be made by passing
		//screen space positions of lights to the shader and using the shader to draw 
		//proper lens flare-like shapes instead of this shader which just takes bright stuff
		//and sorta duplicates it .
		for(float ix = 0.0; ix < Flares; ix++)
		{
			float2 pos = uvi + flareUV * ix;
			float dist = length(0.5 - pos) / length(float2(0.5,0.5));
			float Weight = pow(max(1.0 - dist, 0.0), 8.0);
			float3 Pixels = scene.Sample(g_sTrilinearClamp, pos).rgb;
			Pixels = max(Pixels - fCutoff, 0.0);
			
			flareColor = flareColor + Pixels * Weight ;
		}

		
		
		flareColor = flareColor * color_map.Sample(g_sTrilinearClamp, uv).rgb;
		float3 opacity = opacity_map.Sample(g_sTrilinearClamp, uv).rgb;

		if(fDoubleAdd)
			opacity = opacity * opacity;
		
		flareColor = flareColor *  opacity ;
		flareColor = flareColor *  fGain;
		flareColor = flareColor * fColor;
		
		return flareColor;
	}


    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		
		if(fBypass)
			input_color = g_tBlurBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		else
		{
				input_color = input_color + flare(g_tBlurBuffer, i.vTexCoord);
		}
		return float4(input_color, 1);
    }
}