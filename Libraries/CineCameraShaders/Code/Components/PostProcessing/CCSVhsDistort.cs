using Sandbox;
using System;


/// <summary>
/// Simulation of the vertical scrolling - horizontal "tracking" effect on old VHS tapes.
/// </summary>

[Title( "VHS Distortion" )]
[Category( "Post Processing" )]
[Icon( "dehaze" )]




public sealed class CCSVHSD : Component, Component.ExecuteInEditor
{




	/// <summary>
	/// How big are the distortion lines.
	/// </summary>
	[Property, Title("Warp Size"), Range( 0, 20.0f, 0, true )]  
    public float warp_size { get; set; } = 12.0f;

	/// <summary>
	/// Enhance the distorted areas.
	/// </summary>
	[Property, Title("Warp Distortion Multiplier"), Range( -0.5f, 0.5f, 0, true )]  
    public float warp_distort { get; set; } = 0.05f;	

	/// <summary>
	/// How fast the distorted areas scroll.
	/// </summary>
	[Property, Title("Warp Speed"), Range( -30.0f, 30.0f, 0, true )]  
    public float warp_speed { get; set; } = 6.0f;	
	
	/// <summary>
	/// number of smaller lines to chop the main warp lines into.
	/// </summary>
	[Property, Title("Warp Variation"), Range( -30.0f, 30.0f, 0, true )]  
    public float warp_random { get; set; } = 1.5f;	



	/// <summary>
	/// How fast the distorted areas scroll.
	/// </summary>
	[Property, Title("Chromatic Abberation"), Range( -0.25f, 0.25f, 0, true )]  
    public float ca { get; set; } = 0.02f;	
	
	/// <summary>
	/// Amount of static that each warp line has
	/// </summary>
	[Property, Title("Static Amount"), Range( 0.0f, 1.0f, 0, true )]  
    public float Static { get; set; } = 0.5f;
	

	/// <summary>
	/// high frequency horizontal ripple distortion effect on the entire image.
	/// </summary>
	[Property, Title("DeInterlace Skew"), Range( 0.0f, 20.0f, 0, true )]  
    public float dSkew { get; set; } = 0.5f;



    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSVHSD", 9000, RenderEffect );
		
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

		

		
		attributes.Set( "warp_size", warp_size );
		attributes.Set( "warp_speed", warp_speed );
		attributes.Set( "warp_random", warp_random );
		attributes.Set( "warp_distort", warp_distort );
		attributes.Set( "ca", ca );
		attributes.Set( "Static", Static );
		attributes.Set( "dSkew", dSkew);
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_vhsd.vmat" ), attributes );

    }
}
