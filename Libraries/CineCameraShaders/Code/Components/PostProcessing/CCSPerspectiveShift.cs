using Sandbox;
using System;


/// <summary>
/// Shift the perspective of the image.(very basic)
/// </summary>

[Title( "Perspective Shift" )]
[Category( "Post Processing" )]
[Icon( "grid_4x4" )]


public sealed class CCSPerspectiveShift : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// Scale the upper edge of the image to simulate perspective shift
	/// </summary>
    [Property, Title("Upper Scale"),Range( 0.0f, 1.0f, 0, true)]  
    public float dUpper { get; set; } = 0.0f; 
	
	/// <summary>
	///  Scales the lower edge, disables upper scale when above 0.
	/// </summary>
    [Property, Title("Lower Scale"), Range( 0.0f, 1.0f, 0, true )]  
    public float dLower { get; set; } = 0.0f;
	
	
	
	/// <summary>
	/// Smooth the resulting image.
	/// </summary>
	[Property, Title("Smooth"), Range( 100.0f, 200.0f, 0, true )]  //zoom
    public bool Filter { get; set; }

	

    IDisposable renderHook;
	
//	protected override void OnUpdate()
//	{
//
//	}

    protected override void OnEnabled()
    {
		
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookAfterTransparent( "CCSPerspectiveShift", 2001, RenderEffect );
		
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

		
		
		attributes.Set( "dUpper", dUpper );
        attributes.Set( "dLower", dLower );
		attributes.Set( "Filter", Filter );
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_perspectiveshift.vmat" ), attributes );

    }
}
