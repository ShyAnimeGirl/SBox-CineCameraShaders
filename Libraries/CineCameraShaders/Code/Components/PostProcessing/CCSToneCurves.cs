using Sandbox;
using System;


/// <summary>
/// Basic 5 point curves adjustment
/// </summary>

[Title( "Tone Curves" )]
[Category( "Post Processing" )]
[Icon( "shape_line" )]




public sealed class CCSToneCurve : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// Darkest parts of the image.
	/// </summary>
	[Property, Title("Blacks"), Range( -0.25f, 1.0f, 0 )]  
    public float Blacks { get; set; } = 0.0f;
	

	
	/// <summary>
	/// Rolloff from midtones to shadow.
	/// </summary>
	[Property, Title("Shadows") , Range( 0.0f, 1.0f, 0 )]  
    public float Shadows { get; set; } = 0.25f;	

	/// <summary>
	/// Parts of the image around 50%.
	/// </summary>
	[Property, Title("Midtones") , Range( 0.0f, 1.0f, 0 )]  
    public float Midtones { get; set; } = 0.5f;	
	
	/// <summary>
	/// Rolloff from midtones to whites.
	/// </summary>
	[Property, Title("Highlights") , Range( 0.0f, 1.0f, 0)]  
    public float Highlights { get; set; } = 0.75f;	

	/// <summary>
	/// Brightest parts of the image.
	/// </summary>
	[Property, Title("Whites") , Range( 0.0f, 1.5f, 0)]  
    public float Whites { get; set; } = 1.0f;		
	
	/// <summary>
	/// Reduces saturation increase, you probably want this on.
	/// </summary>
	[Property, Title("Luma Only")]  
    public bool LumaOnly { get; set; }		
	

//	[Property, Title("Work in Linear")]  
 //   public bool wLinear { get; set; }			
	
    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookAfterTransparent( "CCSToneCurve", 8000, RenderEffect );
		
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

		
		attributes.Set( "Blacks", Blacks );
		attributes.Set( "Shadows", Shadows );
		attributes.Set( "Midtones", Midtones);
		attributes.Set( "Highlights", Highlights );
		attributes.Set( "Whites", Whites);		
		
		attributes.Set( "LumaOnly", LumaOnly);
	//	attributes.Set( "wLinear", wLinear);	//i don't like the results of this so it is off for now but keeping code 
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_tonecurves.vmat" ), attributes );

    }
}
