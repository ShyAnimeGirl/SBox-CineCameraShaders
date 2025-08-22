HEADER
{
	Description = "Draw a video waveform";
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


    Texture2D g_tColorBuffer < Attribute( "ColorBuffer" );  >;

	

	float SRGBValuetoLinear(float color)
	{
		if (color <= 0.04045)
			return color / 12.92;
		else
			return pow((color + 0.055) / 1.055, 2.2); //SRGB is 2.2 REC709 is 2.4
	}
	
	float SRGBLumaValue(float3 color)
	{
		float3 lininput = float3(SRGBValuetoLinear(color.r), SRGBValuetoLinear(color.g), SRGBValuetoLinear(color.b));
		
		return (0.299 * lininput.r) + (0.587 * lininput.g) + (0.114 * lininput.b);
		
	}

	
	float3 DrawGrid(int y, float crop, int gridsize)
	{
		
		int lower_border = floor((1.0 - crop) * g_vViewportSize.y);
		int upper_border = floor(crop * g_vViewportSize.y);
		int range = upper_border - lower_border;
		int spacing = range / gridsize;
		
		if(y == lower_border || y == upper_border)
			return 0.65;
		
		if(y < lower_border && y > upper_border)
		{
			int firstline = upper_border + spacing;
			if (y >= firstline)
			{
				int lines = (y - firstline) / spacing;
				if(lines * spacing == (y - firstline))
					return 0.15;
			}
				
			else
				return 0.0;
		}
		
		return 0.0;
	}
	
    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		float2 uv = i.vTexCoord;
		
		int2 xy = floor(uv * g_vViewportSize); // current pixel on the screen
		
		float crop = 0.05;  //could bind these to inputs if u wanted.
		
		int gridsize = 24; 
		
		float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		float3 output_color = DrawGrid(xy.y, crop, gridsize);
		
		
		
		

		//future idea: full image histogram
		
		for(int screeny = 0; screeny < int(g_vViewportSize.y); screeny++)
		{
			//gotta iterate through every single col and determine the colors
			float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, float2(i.vTexCoord.x, screeny/g_vViewportSize.y)).rgb;
			
			//this works but it sucks
 			int rlevel = floor(lerp(0.0 + crop, 1.0 - crop, input_color.r) * g_vViewportSize.y);
			int glevel = floor(lerp(0.0 + crop, 1.0 - crop, input_color.g) * g_vViewportSize.y);
			int blevel = floor(lerp(0.0 + crop, 1.0 - crop, input_color.b) * g_vViewportSize.y);
			int llevel = floor(lerp(0.0 + crop, 1.0 - crop, SRGBLumaValue(input_color)) * g_vViewportSize.y);
			if((g_vViewportSize.y - xy.y)== rlevel)
				output_color.r += input_color.r;
			if((g_vViewportSize.y - xy.y) == glevel)
				output_color.g += input_color.g;
			if((g_vViewportSize.y - xy.y) == blevel)
				output_color.b += input_color.b;
			if((g_vViewportSize.y - xy.y) == llevel)
				output_color += SRGBLumaValue(input_color); 
		}

		return float4(output_color, 1.0);
		
    }
}