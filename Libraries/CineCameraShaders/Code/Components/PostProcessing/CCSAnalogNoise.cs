using Sandbox;
using System;


/// <summary>
/// Generate random noise (not very good).
/// </summary>

[Title( "TV Static" )]
[Category( "Post Processing" )]
[Icon( "broken_image" )]




public sealed class CCSAnalogNoise : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// noise-image belnd, please note: the fine tune controls effect the entire image
	/// </summary>
    [Property, Title("Opacity"),Range( 0.00f, 1.0f, 0, true)]  
    public float fOpacity { get; set; } = 0.75f; 
	
	

	

	
    


	
	

	/// <summary>
	/// Makes the noise less stretched out.
	/// </summary>
	[Property, Title("Don't Stretch"),Group("Fine Tune")]  
    public bool bAspect { get; set; } 	
	

	/// <summary>
	/// How much to blur the image + noise
	/// </summary>
	[Property, Title("Blur Radius"), Range( 0.0f, 20.0f, 1, true ),Group("Fine Tune")]  
    public float bRadius { get; set; } = 4.0f;	
	
	/// <summary>
	/// Darkest parts of the image. cool value: -0.25
	/// </summary>
	[Property, Title("Blacks"), Group("Fine Tune"), Range( -0.25f, 1.0f, 0 )]  
    public float Blacks { get; set; } = 0.0f;
	

	
	/// <summary>
	/// Rolloff from midtones to shadow. cool value: 0.0
	/// </summary>
	[Property, Title("Shadows"), Group("Fine Tune"), Range( 0.0f, 1.0f, 0 )]  
    public float Shadows { get; set; } = 0.25f;	

	/// <summary>
	/// Parts of the image around 50%. cool value: 0.05
	/// </summary>
	[Property, Title("Midtones") ,Group("Fine Tune"), Range( 0.0f, 1.0f, 0 )]  
    public float Midtones { get; set; } = 0.5f;	
	
	/// <summary>
	/// Rolloff from midtones to whites.  cool value: 0.365
	/// </summary>
	[Property, Title("Highlights") ,Group("Fine Tune"), Range( 0.0f, 1.0f, 0)]  
    public float Highlights { get; set; } = 0.75f;	

	/// <summary>
	/// Brightest parts of the image. cool value: 1.35
	/// </summary>
	[Property, Title("Whites") ,Group("Fine Tune"), Range( 0.0f, 1.5f, 0)]  
    public float Whites { get; set; } = 1.0f;	


	
	private float bMulti { get; set; } = 8.0f;	
    private bool bCircle = false;	
	private bool bLoop = true;
	
	
    IDisposable renderHook;
	
//	protected override void OnUpdate()
//	{
//
//	}

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSAnalogNoise", 8000, RenderEffect );
		
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

		//three passes and it is still ugly
		attributes.Set( "fOpacity", fOpacity);
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_analog.vmat" ), attributes );
		
		//attributes.Set( "bContrast", bContrast );
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
		attributes.Set( "Blacks", Blacks );
		attributes.Set( "Shadows", Shadows );
		attributes.Set( "Midtones", Midtones);
		attributes.Set( "Highlights", Highlights );
		attributes.Set( "Whites", Whites);	
		Graphics.Blit( Material.Load( "materials/postprocess/ccs_tonecurves.vmat" ), attributes );
		
		attributes.Set( "bRadius", bRadius );
		attributes.Set( "bMulti", bMulti );
		attributes.Set( "bAspect", bAspect );
		attributes.Set( "bCircle", bCircle );
		attributes.Set( "bLoop", bLoop );
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
		
		
	   // Graphics.Blit( Material.Load( "materials/postprocess/ccs_flareprepass.vmat" ), attributes );
		Graphics.Blit( Material.Load( "materials/postprocess/ccs_boxblur.vmat" ), attributes );
		
    }
}
