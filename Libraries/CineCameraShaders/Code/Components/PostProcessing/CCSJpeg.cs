using Sandbox;
using System;


/// <summary>
/// Do I look like I know what a JAY-PEG is? (not fully working)
/// </summary>

[Title( "JPEG Compression" )]
[Category( "Post Processing" )]
[Icon( "gradient" )]

//ok im at my limit with this one, can't figure out how to get it to actually work right.
//still makes an interesting effect even when broken though. 


public sealed class CCSJpeg : Component, Component.ExecuteInEditor
{

	
	/// <summary>
	/// JPEG Compression level. Lower = worse. 
	/// </summary>
	[Header("Currently kinda broken")]
	[Property, Title("Compression Level"), Range( 1, 99, 1, true )]  
    public int levels { get; set; } = 15;
	

	
	/// <summary>
	/// Changes the number of reconstruction steps, higher = more weird. 
	/// </summary>
	[Property, Title("Reconstruction Frequency") , Range( 1, 20, 1, true )]  
    public int freq { get; set; } = 8;	
	
	/// <summary>
	/// Display the quanitized DCT, which is some weird math thing that looks kinda cool.
	/// </summary>
	[Property, Title("Show DCT") , Range( 1, 20, 1, true )]  
    public bool bypass { get; set; }	


    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSJpeg", 3001, RenderEffect );
		
    }
	
    protected override void OnDisabled()
    {
        renderHook?.Dispose();
        renderHook = null;
    }

    RenderAttributes attributes = new RenderAttributes();

	
    public void RenderEffect( SceneCamera camera )
    {
        if ( !camera.EnablePostProcessing )
            return;

		
		attributes.Set( "levels", levels );
		attributes.Set( "freq", freq );
		attributes.Set( "bypass", bypass );
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_jpeg_dct.vmat" ), attributes );
		
		Graphics.GrabFrameTexture( "DCTBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_jpeg.vmat" ), attributes );

    }
}
