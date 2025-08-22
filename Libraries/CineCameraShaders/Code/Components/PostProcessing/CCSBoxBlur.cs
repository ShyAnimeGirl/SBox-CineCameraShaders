using Sandbox;
using System;


/// <summary>
/// Box-Blur filter with various options, looks OK, not very performant.
/// </summary>

[Title( "Simple Blur" )]
[Category( "Post Processing" )]
[Icon( "blur_linear" )]




public sealed class CCSBoxBlur : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// size of the box used to blur the image
	/// </summary>
	[Property, Title("Blur Radius"), Range( 0.0f, 50.0f, 1, true )]  
    public float bRadius { get; set; } = 0.0f;
	

	
	/// <summary>
	/// Use this to make the blur larger, but lower quality
	/// </summary>
	[Property, Title("Blur Size") , Range( 0.5f, 50.0f, 0, true )]  
    public float bMulti { get; set; } = 2.0f;	

	/// <summary>
	/// Will actually make the blur a perfect square instead of it stretching to your screen's aspect ratio.
	/// </summary>
	[Property, Title("Don't Stretch")]  
    public bool bAspect { get; set; } 	
	
	/// <summary>
	/// The blur will be generated using a circle instead of a box.
	/// </summary>
	[Property, Title("Circularize")]  
    public bool bCircle { get; set; } 	
	
	private bool bLoop = false;
    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookAfterTransparent( "CCSBoxBlur", 2001, RenderEffect );
		
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

		
		attributes.Set( "bRadius", bRadius );
		attributes.Set( "bMulti", bMulti );
		attributes.Set( "bAspect", bAspect );
		attributes.Set( "bCircle", bCircle );
		attributes.Set( "bLoop", bLoop );
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_boxblur.vmat" ), attributes );

    }
}
