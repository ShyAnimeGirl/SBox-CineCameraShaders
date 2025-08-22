using Sandbox;
using System;


/// <summary>
/// Displays the current scene as a RGB+Luma waveform 
/// </summary>

[Title( "Video Waveform Overlay" )]
[Category( "Post Processing" )]
[Icon( "equalizer" )]




public sealed class CCSVideoScope : Component, Component.ExecuteInEditor
{//these are properties for universal thing mover

	/// <summary>
	/// Opacity of the overlay.
	/// </summary>
    [Property, Title("Opacity"),Range( 0.00f, 1.0f, 0, true)]  
    public float fOpacity { get; set; } = 0.9f; 

	/// <summary>
	/// Horizontal position offset.
	/// </summary>
    [Property, Title("Horizontal Position"),Range( -1.0f, 1.0f, 0, true)]  
    public float xPos { get; set; } = 0.345f; 

	/// <summary>
	/// Vertical Position offset.
	/// </summary>
    [Property, Title("Vertical Position"),Range( -1.0f, 1.0f, 0, true)]  
    public float yPos { get; set; } = -0.345f; 

	/// <summary>
	/// Horizontal Scale of the overlay.
	/// </summary>
    [Property, Title("Horizontal Scale"),Range( 0.01f, 1.0f, 0, true)]  
    public float xScale { get; set; } = 0.33f; 

	/// <summary>
	/// Vertical Scale of the overlay.
	/// </summary>
    [Property, Title("Vertical Scale"),Range( 0.01f, 1.0f, 0, true)]  
    public float yScale { get; set; } = 0.33f; 	
	
	

    IDisposable renderHook;
	


    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		//this one Should PROBABLY be set to a high pri because as of right now it is effected by CC + letterbox, etc
		renderHook = cc.AddHookBeforeOverlay( "CCSVideoScope", 1000, RenderEffect );
		
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


		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_videoscope.vmat" ), attributes );
		
		//thingmover attributes//
		attributes.Set( "xPos", xPos );
		attributes.Set( "xScale", xScale );
		attributes.Set( "yPos", yPos );
		attributes.Set( "yScale", yScale );
		attributes.Set( "fOpacity", fOpacity );
		Graphics.GrabFrameTexture( "ThingBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_thingmover.vmat" ), attributes );

    }
}
