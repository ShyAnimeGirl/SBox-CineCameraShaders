HEADER
{
	Description = "Color Key Shader";
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
	
	
	float fBlend < Attribute("fBlend"); >;
	float bBlend < Attribute("bBlend"); >;
	
	float xScale < Attribute("xScale"); >;
	float xPos < Attribute("xPos"); >;
	float yScale < Attribute("yScale"); >;
	float yPos < Attribute("yPos"); >;
	
	float fOpacity < Attribute("fOpacity"); >;
	float bOpacity < Attribute("bOpacity"); >;	
	
	bool kSwap < Attribute("kSwap"); >;
	bool iTile < Attribute("iTile"); >;
	bool dKey < Attribute("dKey"); >;
	
	int BlendMode < Attribute("BlendMode"); >;
	
	float3 ikeyColor < Attribute("keyColor"); >;
	
	Texture2D image_texture < Attribute("image_texture"); >;
	
	
	float3 RGBtoYUV(float3 color) //convert to YUV so it can key out the chroma value while ignoring luma
	{
	
	
		float Y = 0.257 * color.r + 0.504 * color.g + 0.098 * color.b;
		float U = -0.148 * color.r - 0.291 * color.g + 0.439 * color.b;
		float V = 0.439 * color.r - 0.368 * color.g - 0.071 * color.b;

		return float3(Y, U, V);
	}
	
	float3 YUVtoRGB(float3 color) //both of these are approx because it isn't taking into account SRBG input gamma (does it need to?)
	{
		float R = 1.164 * color.x + 1.596 * color.z;
		float G = 1.164 * color.x - 0.392 * color.y - 0.813 * color.z;
		float B = 1.164 * color.x + 2.017 * color.y;
		
		return float3(R, G, B);
	}

	float key_mask(float3 color, float3 key, float bg, float fg)
	{
		float dist = sqrt(pow(key.g, 2.0) + pow(key.b - color.b, 2.0));
		if (dist < bg)
			return 0.0;
		else if (dist < fg)
			return (dist - bg) / (fg - bg);
		else
			return 1.0;
	}

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		// get the input texture coordinate
		//float2 uv = i.vTexCoord;
		
		//this shader is kind of a mess
		//it tries to do too many thing and should be split into multiple 
		
		
		float3 key_color = RGBtoYUV(ikeyColor);
		
		float3 key_image;
		float3 input_color;
		float3 output_color;
		float aspect = g_vViewportSize.x / g_vViewportSize.y;
		float2 scale = float2(xScale * aspect , yScale);
		float2 offset = float2(xPos,yPos);
		
		
		float2 imageuv = i.vTexCoord + offset;
		imageuv = (imageuv - 0.5) * scale + 0.5;
		
		if(kSwap)
		{
			
			
			key_image = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
			
			if(iTile)
			{
				input_color = RGBtoYUV(image_texture.Sample(g_sPointWrap, imageuv).rgb);
				output_color = image_texture.Sample(g_sPointWrap, imageuv).rgb;	
			}			
			else
			{
				input_color = RGBtoYUV(image_texture.Sample(g_sPointClamp, imageuv).rgb);
				if (imageuv.x < 0.0 || imageuv.x > 1.0 || imageuv.y < 0.0 || imageuv.y > 1.0)
					output_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
				else
					output_color = image_texture.Sample(g_sPointClamp, imageuv).rgb;	
			}
		}
		else
		{
			if(iTile)
				key_image = image_texture.Sample(g_sPointWrap, imageuv).rgb;
			else
				key_image = image_texture.Sample(g_sPointClamp, imageuv).rgb;
			
			input_color = RGBtoYUV(g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb);
			
			output_color = g_tColorBuffer.Sample(g_sPointClamp, i.vTexCoord).rgb;
		}
		
		
		
		
		
		float mask = 1.0 - key_mask(input_color, key_color, bBlend, fBlend);
		
		//float bOpacity = 0.8f;
		//float fOpacity = 0.5f;
		
		mask = mask * bOpacity;
		
		if(!iTile)
		{
			if (imageuv.x < 0.0 || imageuv.x > 1.0 || imageuv.y < 0.0 || imageuv.y > 1.0)
			{
				mask = 0.0;
			}
		}
		

			if(BlendMode == 0)
				output_color = lerp( key_image, output_color, fOpacity);
			else if (BlendMode == 1) //add
				output_color = output_color + (key_image * fOpacity);
			else if (BlendMode == 2) //sub
				output_color = output_color - (key_image * fOpacity);	
			else if (BlendMode == 3) //multi
				output_color = output_color * (key_image * fOpacity);
			else if (BlendMode == 4) //div
				output_color = output_color / (key_image * fOpacity);				
			else if (BlendMode == 5) //screen
				output_color = 1.0f - (1.0f - output_color) * (1.0f - (key_image * fOpacity));	
			else if (BlendMode == 6) //Color Dodge
				output_color = output_color / (1.0f - (key_image * fOpacity));
			
			//pointless ?
			//color burn 1.0f - (1.0f - output_color) / (key_image * fOpacity);
			//exclusion 0.5f - 2 * (output_color - 0.5f) * ((key_image * fOpacity) - 0.5f);
		
		if(!dKey)
			output_color = max((output_color) - mask * ikeyColor, 0.0) + key_image * mask;
		
		//input_color = YUVtoRGB(input_color);

		return float4(output_color,1);
    }
}