using Sandbox;
using System;


/// <summary>
/// Realistic Camera Lens Distortion.
/// </summary>

[Title( "Lens Distortion" )]
[Category( "Post Processing" )]
[Icon( "panorama_photosphere_select" )]


//future todo: create other shader which takes texture input of a dudv map (flowmap) or something else so you can 
//input real life lens distortion profiles(?) and other shapes for cool screen effects. 

public sealed class CCSLensDistortion : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// Amount of Barrel (outward bending) Lens Distortion 
	/// </summary>
    [Property, Title("Barrel Distortion"),Range( 0, 0.5f, 0, true)]  // step 0 and clamp true
    public float dBarrel { get; set; } = 0.0f; 
	
	/// <summary>
	///  Amount of Pincushion (inward bending) Lens Distortion 
	/// </summary>
    [Property, Title("Pincushion Distortion"), Range( 0, 0.5f, 0, true )]  
    public float dPin { get; set; } = 0.0f;
	
	
	/// <summary>
	/// Zoom in on the image to hide repeating effect. Non-circular max barrel distortion requires only 200% (2X crop) while Circular max requires 420% to fully hide the edges.
	/// </summary>
	[Property, Title("Crop"), Range( 100.0f, 420.0f, 0, true )]  
    public float CropIn { get; set; } = 1.0f;
	
	/// <summary>
	/// Smooth the resulting image (makes it less pixelated and stretches the edges instead of displaying red). 
	/// </summary>
	[Property, Title("Smooth"), Range( 100.0f, 200.0f, 0, true )]  
    public bool Filter { get; set; }

	/// <summary>
	/// Forces the distortion to be perfectly circular. This more closely simulates non anamorphic lenses but requires more crop.
	/// </summary>
	[Property, Title("Circularize"), Range( 100.0f, 200.0f, 0, true )]  
    public bool dCircle { get; set; }	
	
	/// <summary>
	/// Uses the built-in sbox panini perspective mode, which maintains vertical lines in wide images. In this mode barrel and pin sliders become the strength of the effect. Not a lens-effect but interesting. 
	/// </summary>
	[Property, Title("Panini"), Range( 100.0f, 200.0f, 0, true )]  
    public bool dPanini { get; set; }	
	

    IDisposable renderHook;
	
//	protected override void OnUpdate()
//	{
//
//	}

    protected override void OnEnabled()
    {
		
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookAfterTransparent( "CCSLensDistortion", 1001, RenderEffect );
		
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

		
		
		attributes.Set( "dBarrel", dBarrel );
        attributes.Set( "dPin", dPin );
		attributes.Set( "CropIn", CropIn );
		attributes.Set( "Filter", Filter );
		attributes.Set( "dCircle", dCircle );
		attributes.Set( "dPanini", dPanini);
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_lensdistortion.vmat" ), attributes );

    }
}
