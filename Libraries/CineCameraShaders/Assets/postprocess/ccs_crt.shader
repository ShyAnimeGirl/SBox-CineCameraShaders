HEADER
{
	Description = "CRT Emulation Shader";
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
	bool slEnable < Attribute("ScanLines"); >;
	float slCount < Attribute("slCount"); >;
	float slOpacity < Attribute("slOpacity"); >;
	float slScroll < Attribute("slScroll"); >;
	
	bool fEnable < Attribute("Flicker"); >;
	float fOpacity < Attribute("fOpacity"); >;
	float fRate < Attribute("fRate"); >;
	
	bool rWhite < Attribute("rWhite"); >;
	float bLevel < Attribute("bLevel"); >;
	
//	Texture2D crt_mask < Attribute("crt_mask"); SrgbRead( true ); >;
	
	
	int style < Attribute("style"); >;

	float3 boxBlur(float2 uv, float blurRadius, float blurScale)
	{
		float3 blur = float3(0.0f,0.0f,0.0f);
		float accumulator = 0.0f;
		
		for (float x = -blurRadius; x <= blurRadius; x++)
		{
			for (float y = -blurRadius; y <= blurRadius; y++)
			{
				float2 offset = float2(x,y) / blurScale; 
				blur = blur + g_tColorBuffer.Sample(g_sTrilinearClamp, uv + offset).rgb;
				accumulator = accumulator + 1.0f;
			}
			
		}	
		return float3(blur / accumulator);	
	}
	
	float Luma(float3 color)
	{
		return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
	}

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		float3 input_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		float2 uv = i.vTexCoord / float2(g_vViewportSize.x, g_vViewportSize.y);
	
		//this should have been bloom but i guess it is blur now. Works as bloom with whites on but add proper bloom later
		//maybe use https://www.shadertoy.com/view/MdSyWh 
		if(bLevel)
		{
			input_color = boxBlur(i.vTexCoord, bLevel, g_vViewportSize.x);
		}
	
		//scanlines
		if(slEnable)
		{
			float speed = g_flTime * slScroll;
			float slNum = (g_vViewportSize.y * slCount) ;
			float2 sl = float2(sin(uv.y * slNum - speed), cos(uv.y * slNum - speed) );
			float3 slColor = float3(sl.x, sl.y, sl.x);
			input_color = input_color + input_color * slColor * slOpacity ;
		}
		
		
		if(fEnable)
			input_color = input_color + input_color * sin(fRate * g_flTime) * fOpacity;
		// flicker^ 

		
		
		//crt mask effects 
		
		int texelx = (int)(i.vTexCoord.x * g_vViewportSize.x);
		int texely = (int)(i.vTexCoord.y * g_vViewportSize.y);
		
		// alternating, kinda looks like aperture grille 
		if(style == 0)
		{
			if ( texelx % 2 == 0.0)
			{
				input_color = input_color * float3(0.0f, 1.0f, 0.0f);
			}
			else
				input_color = input_color * float3(1.0f, 0.0f, 1.0f);
		}
		// checkerboard kinda looks like a shadowmask
		if(style == 1)
		{
			if ( (texelx + texely) % 2 == 0.0)
			{
				input_color = input_color * float3(0.0f, 1.0f, 0.0f);
			}
			else
				input_color = input_color * float3(1.0f, 0.0f, 1.0f);
		}
		// fake slot mask
		if(style == 2)
		{
			texely = texely % 3;
			if (texely == 0)
			{
				if (texelx % 4 == 0)
					input_color = input_color * float3(1.0f, 0.0f, 1.0f);
				else if (texelx % 4 == 1)
					input_color = input_color * float3(0.0f, 1.0f, 0.0f);
				else
					input_color = float3(0.0f, 0.0f, 0.0f);
			}
			else if (texely == 1)
			{
				if (texelx % 2 == 0 )
					input_color = input_color * float3(1.0f, 0.0f, 1.0f);
				else
					input_color = input_color * float3(0.0f, 1.0f, 0.0f);
			}
			else if (texely == 2)
			{
				if (texelx % 4 == 0 || texelx % 4 == 1)
					input_color =  float3(0.0f, 0.0f, 0.0f);
				else if (texelx % 4 == 2)
					input_color = input_color * float3(1.0f, 0.0f, 1.0f);
				else
					input_color = input_color * float3(0.0f, 1.0f, 0.0f);
			}
				
		}
		//full rbg aperture grille
		if( style == 3)
		{
			if (texelx % 4 == 0)
				input_color = input_color * float3(1.0f, 0.0f, 0.0f);
			else if (texelx % 4 == 1)
				input_color = input_color * float3(0.0f, 1.0f, 0.0f);
			else if (texelx % 4 == 2)
				input_color = input_color * float3(0.0f, 0.0f, 1.0f);
			else
				input_color = float3(0.0f, 0.0f, 0.0f);			
		}
		// kinda sorta shadow mask full rbg
		if(style == 4)
		{
			texely = texely % 2;
			if (texely == 0)
			{
				if (texelx % 4 == 0)
					input_color = input_color * float3(1.0f, 0.0f, 0.0f);
				else if (texelx % 4 == 1)
					input_color = input_color * float3(0.0f, 1.0f, 0.0f);
				else if (texelx % 4 == 2)
					input_color = input_color * float3(0.0f, 0.0f, 1.0f);
				else
					input_color = float3(0.0f, 0.0f, 0.0f);
			}
			else
			{
				if (texelx % 4 == 0 )
					input_color = float3(0.0f, 0.0f, 0.0f);
				else if (texelx % 4 == 1)
					input_color = input_color * float3(1.0f, 0.0f, 0.0f);
				else if (texelx % 4 == 2)
					input_color = input_color * float3(0.0f, 1.0f, 0.0f);
				else
					input_color = input_color * float3(0.0f, 0.0f, 1.0f);
			}
		}
		
	
		//this is stupid 
		//replace this in the future with something else 
		if(rWhite)
		{
			for(int xbloom = 0; xbloom < 30; xbloom++)
			{
				float falloff = xbloom - 10 / 5 * 0.5;
				input_color = input_color + (g_tColorBuffer.Sample(g_sPointWrap, ((uv + 3) * float2(g_vViewportSize.x, g_vViewportSize.y) )).rgb * falloff/1000);
			}
			
		}		
		
		// more presets :?
		//https://www.shadertoy.com/view/MsjXzh this might be the best looking crt shader 
		//lots of code tho so not adding right now 
		//https://www.shadertoy.com/view/43l3zB alternate with better brightness control, again cant be bothered to TRANSLATE from glsl ugly yucky vec's FLOAT 4 LYFE.
		
		
		return float4(input_color, 1);
    }
}