HEADER
{
	Description = "Special lens flare selection blur filter";
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

	
	// inputs from tonecurve
	float iB < Attribute("Blacks"); >;
	float iS < Attribute("Shadows"); >;
	float iM < Attribute("Midtones"); >;
	float iH < Attribute("Highlights"); >;
	float iW < Attribute("Whites"); >;		

	// inputs
	float bContrast < Attribute("bContrast"); >;
	float bRadius < Attribute("bRadius"); >;

	
	bool bFineTune < Attribute("bFineTune"); >;	

	float SRGBValuetoLinear(float color)
	{
		if (color <= 0.04045)
			return color / 12.92;
		else
			return pow((color + 0.055) / 1.055, 2.2); 
	}
	
	float SRGBLumaValue(float3 color)
	{
		float3 lininput = float3(SRGBValuetoLinear(color.r), SRGBValuetoLinear(color.g), SRGBValuetoLinear(color.b));
		
		return (0.299 * lininput.r) + (0.587 * lininput.g) + (0.114 * lininput.b);
		
	}	

	//CM-R spline interp i think (i tried like 10 different formulas and this is the only one that sorta works)
	float SplineInterp(float color, float p0, float p1, float p2, float p3)
	{
		float c0 = -.5 * p0 + 0.5 * p2;
		float c1 = p0 + -2.5 * p1 + 2.0 * p2 + -0.5 * p3;
		float c2 = -0.5 * p0 + 1.5 * p1 + -1.5 * p2 + 0.5 * p3;
		
		return (((c2 * color + c1) * color + c0) * color + p1);
	}

	
	//single float tone this is all copy paste directly from the tonecurve shader
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
	
	float3 ToneCurveColor(float3 color, float p0, float p1, float p2, float p3, float p4)
	{
		float3 output;
		output.r = toneCurve(color.r, p0, p1, p2, p3, p4);
		output.g = toneCurve(color.g, p0, p1, p2, p3, p4);
		output.b = toneCurve(color.b, p0, p1, p2, p3, p4);
		return output;
	}
	
// modified box blur to generate a better input
	float3 boxBlur(Texture2D scene, float2 uv, float blurRadius)
	{
		float3 blur = float3(0.0f,0.0f,0.0f);
		float accumulate = 0.0f;
		
		for (float x = -blurRadius; x <= blurRadius; x++)
		{
			for (float y = -blurRadius; y <= blurRadius; y++)
			{
				float2 offset = float2(x,y);
				
				
				//these next two lines make it a round blur instead of a box
				float dist = length(offset);	
				if (dist <= blurRadius)
				{
					offset.x = offset.x / g_vViewportSize.x;
					offset.y = offset.y / g_vViewportSize.y;
					float2 uvfix = clamp(uv + offset, 0.001, 0.999); //it wants to loop otherwise lol		
					blur = blur + SRGBLumaValue(scene.Sample(g_sTrilinearClamp, uvfix).rgb);
					accumulate = accumulate + 1.0f;
				}
			}
			
		}
		
		
		blur = blur / accumulate; //apply blur
		blur = (blur -0.5) * bContrast + 0.5f; //boost contrast
		//blur = (blur -0.5) * fPower + 0.5f; //boost contrast
		//radial vignette
		float2 center = float2(0.5f, 0.5f);
		float vRadius = distance(uv, center);
		float fade = saturate(1.0 - vRadius / 0.8); // last value controls fade 
		
		blur = blur * fade;
		
		//now a square fade in from the sides
		float fade_amount = 0.08;
	//	float aspect = g_vViewportSize.x / g_vViewportSize.y;
		float2 edgeDist = abs(uv - center) * 2.0;
		float vDist = max(edgeDist.x, edgeDist.y);
		float fadeS = saturate(1.0 - (vDist - (1.0 - fade_amount)) / fade_amount);
		blur = blur * fadeS;
		//apply it twice result is slightly curved outer mask

		return blur * fade;
	}
	


    float4 MainPs( PixelInput i ) : SV_Target0
    {

		
		float3 input_color;

		input_color = boxBlur(g_tColorBuffer, i.vTexCoord, bRadius);
		
		if(bFineTune)
			input_color = ToneCurveColor(input_color.rgb, iB, iS, iM, iH, iW);

		return float4(input_color, 1);
    }
}