HEADER
{
	Description = "goofy messed up shader";
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
	
	int levels < Attribute("levels"); >;
	
	int freq < Attribute("freq"); >;
	
	// this was obviously an attempt at jpeg using a different algo but it also didnt work totally right
	//so now it is an epic GLITCH SHADER!!!! WHOAH!!!
	float DCT(float u, float v, float x, float y)
	{
		const float PI = asin(1.0) * 2;
		const float SRD = sqrt(0.5);
		float HFRQ = 1.0;
		float VFRQ = 1.4;
		
		return ((u == 0.0)?SRD:HFRQ) * ((v==0.0)?SRD:VFRQ) * cos((2.0 * x + 1.0) * u * PI / 16.0) * cos((2.0 * y + 1.0) * v * PI / 16.0);
	}
//% g_vViewportSize + g_flTime
	float4 MainPs(PixelInput i) : SV_Target0
	{
		// Use normalized texture coordinates directly
		float2 uv = i.vTexCoord ;
		
		float Q = float(100-levels); //quality
		int BS = freq ; //blocksize
		

		float2 blockLoc = uv / float2(BS, BS);
		
		float3 block[64];
		for (int j = 0; j < 64; j++)
		{
			int x = j % 8;
			int y = j / 8;
			block[j] = g_tColorBuffer.Sample(g_sPointClamp, (blockLoc + float2(x , y)  / float2(BS, BS))).rgb;
		}
		
		float3 DCTBlock[64];
		for(int u = 0; u < 8; u++)
		{
			for(int v = 0; v<8; v++)
			{
				float3 sum = 0.0;
				for(int jj = 0; jj < 64; jj++)
				{
					int jx = jj % 8;
					int jy = jj / 8;
					sum += block[jj] * DCT(float(u), float(v), float(jx), float(jy));
				}
				int bAPos = u + v * 8;
				DCTBlock[bAPos] = sum / 4.0; 
				DCTBlock[bAPos] = float3(round(DCTBlock[bAPos].r * Q), round(DCTBlock[bAPos].g * Q), round(DCTBlock[bAPos].b * Q));
			}
		}
		
		int index = int(uv.x % BS) + int(uv.y % BS) * BS;
		int posX = index % BS ;
		int posY = index / BS;
		
		float3 color = 0.0;
		for(int jjj = 0; jjj < 64; jjj++)
		{
			int jjjx = jjj % 8;
			int jjjy = jjj / 8;
			color += DCTBlock[jjjx + jjjy * 8] * DCT(float(jjjx) * (8.0 / BS), float(jjjy) * (8.0 / BS), float(posX), float(posY));
		}
		
		return float4((color / (Q * 4.0) ), 1.0);
	}

}
