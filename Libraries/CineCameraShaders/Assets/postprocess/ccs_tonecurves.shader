HEADER
{
	Description = "Basic 5 point tone curve adjustment";
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
	float iB < Attribute("Blacks"); >;
	float iS < Attribute("Shadows"); >;
	float iM < Attribute("Midtones"); >;
	float iH < Attribute("Highlights"); >;
	float iW < Attribute("Whites"); >;	

//	bool wLinear < Attribute("wLinear"); >;
	bool wLuma < Attribute("LumaOnly"); >;	

	
	float SRGBtoLinear(float color)
	{
		if (color <= 0.04045)
			return color / 12.92;
		else
			return pow((color + 0.055) / 1.055, 2.2); //SRGB is 2.2 REC709 is 2.4 if you need it
	}		
	
	float LineartoSRGB(float color)
	{
		if (color <= 0.0031308)
			return color / 12.92;
		else
			return 1.055 * pow(color, 1.0 / 2.2) - 0.055;
	}			
	
	//converts an rgb value to a luma value
	float Luma(float3 color)
	{
		return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
	}	
	
	//CM-R spline interp i think (i tried like 10 different formulas and this is the only one that sorta works)
	float SplineInterp(float color, float p0, float p1, float p2, float p3)
	{
		float c0 = -.5 * p0 + 0.5 * p2;
		float c1 = p0 + -2.5 * p1 + 2.0 * p2 + -0.5 * p3;
		float c2 = -0.5 * p0 + 1.5 * p1 + -1.5 * p2 + 0.5 * p3;
		
		return (((c2 * color + c1) * color + c0) * color + p1);
	}

	
	//single float tone
	float toneCurve(float color, float p0, float p1, float p2, float p3, float p4)
	{
		float neg = -0.25f; //overshoots for better interp
		float over = 1.25f;
		
		if (color < 0.25)
		{
			return SplineInterp(color * 4.0f, neg, p0, p1, p2);
		}
		else if (color < 0.5)
		{
			return SplineInterp((color - 0.25) * 4.0f, p0, p1, p2, p3);
		}
		else if (color < 0.75)
		{
			return SplineInterp((color - 0.50) * 4.0f, p1, p2, p3, p4);
		}
		else if (color < 1.0f)
		{
			return SplineInterp((color - 0.75) * 4.0f, p2, p3, p4, over);
		}
		else if (color >= 1.0f)
			return color * p4;
		else
			return 0.0f;
	}
	// apply the tone to each component
	float3 ToneCurveColor(float3 color, float p0, float p1, float p2, float p3, float p4)
	{
		float3 output;
		output.r = toneCurve(color.r, p0, p1, p2, p3, p4);
		output.g = toneCurve(color.g, p0, p1, p2, p3, p4);
		output.b = toneCurve(color.b, p0, p1, p2, p3, p4);
		return output;
	}
	// apply the tone to only the luma and then scale the color by the resulting luma change
	float3 ToneCurveLuma(float3 color, float p0, float p1, float p2, float p3, float p4)
	{
		float3 orig_luma = Luma(color);
		float lumachange = toneCurve(Luma(color), p0, p1, p2, p3, p4);
		float3 scale = lumachange / orig_luma;
		return color * scale;
	}
	//linear doesn't work right, might be because input is SRGB read
    float4 MainPs( PixelInput i ) : SV_Target0
    {
		float3 output_color;
		float4 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord);
		
//		if(wLinear)
//		{
//			input_color.r = SRGBtoLinear(input_color.r);
//			input_color.g = SRGBtoLinear(input_color.g);
//			input_color.b = SRGBtoLinear(input_color.b);
//		}
		
		if(wLuma)
			output_color = ToneCurveLuma(input_color.rgb, iB, iS, iM, iH, iW);
		else
			output_color = ToneCurveColor(input_color.rgb, iB, iS, iM, iH, iW);
		
//		if(wLinear)
//		{
//			output_color.r = LineartoSRGB(output_color.r);
//			output_color.g = LineartoSRGB(output_color.g);
//			output_color.b = LineartoSRGB(output_color.b);
//		}
	
		return float4(output_color, 1);
    }
}