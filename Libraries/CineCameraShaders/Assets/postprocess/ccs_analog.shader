HEADER
{
	Description = "TV-Static Generator";
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
	#include "common/shared.hlsl"
	
    RenderState( DepthWriteEnable, false );
    RenderState( DepthEnable, false );

    // "ColorBuffer" passed from the graphics.GrabFrameTexture
    Texture2D g_tColorBuffer < Attribute( "ColorBuffer" ); SrgbRead( true ); >;


	float fOpacity < Attribute("fOpacity"); >;
	
	float seed;
	
	
	float Noise(float2 a, float b, float c)
	{
		return frac(sin(a.x*b+a.y*c)*313.37);
	}
	

	
	//these all just suck and don't look at all like real analog noise so redo them with better algos later
    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		// the old docs are wrong
		// float4 randoms = g_vRandomFloats; 
		// https://wiki.facepunch.com/sbox/Constant_Buffers
		
		
		// you can define a var without init and it will be whatever the gpu memory was at that time, but it isnt 
		//really random so it isn't that useful (this is what seed was before)
		
		float seed = 8.310412183116117100105111115; //magic numbers!!!
		// get the input texture coordinate
		float2 uv = i.vTexCoord;
		//uv = uv % CircleOfConfusion(uv.x, uv.y, seed, noise(uv), seed*seed*seed); //ugly
		float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		half bigtime = seed * g_flTime;
		half goofy = bigtime * seed;
		float2 zooter;
		zooter.x = Noise(uv, bigtime, goofy);
		zooter.y = Noise(uv, goofy, bigtime);
		float3 output_color = 1.0;
		
		//from the sbox common funcs 
		output_color = output_color * Noise(PaniniProjection(zooter,goofy),zooter.y,g_flTime );

		//output_color = 1.0f - (1.0f - output_color) * (1.0f - (input_color * fOpacity));	
		//output_color = (step(0.5, output_color)) * (1 - (1 - 2 * (output_color - 0.5)) * (1 - fOpacity)) +(1 - step(0.5, output_color)) * ((2 * input_color) * fOpacity);

		
		
		if(fOpacity < 0.01)
		{
			output_color = input_color;
		}
		else if (fOpacity > 0.99)
		{
			output_color = output_color;
		}
		else
		{
			
			output_color = (input_color * (1.0 - fOpacity)) + (output_color * fOpacity) ;
			
		}
		

	//	if (GetLuminance(input_color) > 1.0 - fOpacity)
	//	{
	//		output_color = input_color * output_color;
	//	}
	//	else if (GetLuminance(input_color) > fOpacity)
	//	{
	//		output_color = input_color / output_color;
	//	}
		
		//return g_tColorBuffer.Sample(g_sTrilinearClamp, uv);
		return float4(output_color, 1.0);

    }
}