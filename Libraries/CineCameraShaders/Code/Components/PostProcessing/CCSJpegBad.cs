using Sandbox;
using System;


/// <summary>
/// Make everything look horrid (VERY FLASHY COLORS!)
/// </summary>

[Title( "Wacky Screen" )]
[Category( "Post Processing" )]
[Icon( "coronavirus" )]



public sealed class CCSJGlitch_bad : Component, Component.ExecuteInEditor
{

	
	/// <summary>
	/// Higher = more messed up.
	/// </summary>
	[Property, Title("Goofyness"), Range( 1, 99, 1, true )]  
    public int levels { get; set; } = 75;
	

	
	/// <summary>
	/// Sorta zooms in on the image. 
	/// </summary>
	[Property, Title("Zoomyness") , Range( 1, 20, 1, true )]  
    public int freq { get; set; } = 3;	
	



    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSJGlitch_bad", 5001, RenderEffect );
		
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

		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_jpeg_bad.vmat" ), attributes );

    }
}
