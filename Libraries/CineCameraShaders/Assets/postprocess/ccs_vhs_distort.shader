HEADER
{
	Description = "VHS-like distortion";
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
	
	
	float warp_size < Attribute("warp_size"); >;
	
	float warp_speed < Attribute("warp_speed"); >;
	
	float warp_random < Attribute("warp_random"); >;
	float warp_distort < Attribute("warp_distort"); >;
	float ca < Attribute("ca"); >;
	float Static < Attribute("Static"); >;
	float dSkew < Attribute("dSkew"); >;
	

	
	//these funcs suck maybe replace them with the also bad but better ish looking ones from the analog static shader
	float2 rand(float2 uv)
	{
		uv = float2( dot(uv, float2(123.4,567.8)), dot(uv, float2(234.5, 142.4)));
		return -1.0 + 2.0 * frac(sin(uv) * 5.8539428);
	}

	float Noise(float2 a, float b, float c)
	{
		return frac(sin(a.x*b+a.y*c)*313.37);
	}
	
	float pnoise(float2 uv)
	{
		float2 ui = floor(uv);
		float2 uf = frac(uv);
		float2 blur = smoothstep(0.0, 1.0, uf);
		//unreal
		return lerp( lerp( dot( rand(ui + 0.0), uf - 0.0),dot(rand(ui + float2(10,0.0)), uf - float2(1.0,0.0)),blur.x),lerp(dot(rand(ui + float2(0.0,1.0)), uf - float2(0.0,1.0)),dot(rand(ui + 1.0), uf - 1.0), blur.x), blur.y) * 0.5 + 0.5;
	}

    float4 MainPs( PixelInput i ) : SV_Target0
    {
		
		float2 uv = i.vTexCoord;

		
		float2 warp_uv = 0.0;
		float warp_line = 0.0;
		float StaticSpeed = 200;	


		warp_line = smoothstep(0.2, 0.9, sin(uv.y * warp_size - (g_flTime * warp_speed)));
		
		warp_line *= warp_line * smoothstep(0.2, 0.9, sin(uv.y * warp_size * warp_random - (g_flTime * warp_speed * warp_random)));
		warp_uv = float2(( warp_line * warp_distort * (1.0 - uv.x)), 0.0);
		
		
		//fix this in the future so it keeps the image centered also it breaks down into ugly low freq noise after a while
		warp_uv.x += ((pnoise(float2(g_flTime * 16, uv.y*80))*0.003) + (pnoise(float2(g_flTime*2.0,uv.y*30.0))*0.004) ) * dSkew;
		
		float3 output_color;
		if(warp_size > 0.001)
		{
			output_color.r = g_tColorBuffer.Sample(g_sTrilinearClamp, uv + warp_uv * 0.8 + float2(ca, 0.0) * 0.1).r;
			output_color.g = g_tColorBuffer.Sample(g_sTrilinearClamp, uv + warp_uv * 1.2 - float2(ca, 0.0) * 0.1).g;
			output_color.b = g_tColorBuffer.Sample(g_sTrilinearClamp, uv + warp_uv).b;
		}
		else//only do CA
		{
			output_color.r = g_tColorBuffer.Sample(g_sTrilinearClamp, uv + float2(ca, 0.0) * 0.1).r;
			output_color.g = g_tColorBuffer.Sample(g_sTrilinearClamp, uv - float2(ca, 0.0) * 0.1).g;
			output_color.b = g_tColorBuffer.Sample(g_sTrilinearClamp, uv).b;
		}
		
		if(Static > 0.01)
		{
			float warp_noise = smoothstep(0.4,0.5, pnoise(uv * float2( 2.0, 200.0) + float2(10.0, (g_flTime * StaticSpeed))));
			
			warp_line *= warp_noise * clamp(rand((ceil(uv * g_vViewportSize) / g_vViewportSize) + float2(g_flTime * 0.8, 0.0)).x + 0.8, 0.0, 1.0);
			output_color = clamp(lerp(output_color, output_color + warp_line, Static), 0.0, 1.0);
		}
		
		
		//float3 output_color = pnoise(uv*g_flTime);
		
		return float4(output_color, 1);		
		
		
		
    }
}