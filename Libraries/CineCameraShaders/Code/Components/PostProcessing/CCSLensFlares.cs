using Sandbox;
using System;


/// <summary>
/// Simple Screen-Space lens flares.
/// </summary>

[Title( "Lens Flares" )]
[Category( "Post Processing" )]
[Icon( "auto_awesome" )]




public sealed class CCSLensFlares : Component, Component.ExecuteInEditor
{

	
	
	/// <summary>
	/// Changes the color of the flare across the screen.
	/// </summary>
	[Property]
	public Texture color_map;
	
	/// <summary>
	/// Changes the opacity of the flares across the screen AKA DIRT MAP.
	/// </summary>
	[Property]
	public Texture opacity_map;	
	
	
	/// <summary>
	/// Adjusts the threshold of where flares are applied.
	/// </summary>
    [Property, Title("Contrast"),Range( 0.001f, 3.0f, 0, true)]  
    public float bContrast { get; set; } = 1.5f; 
	
	/// <summary>
	/// Allows you to somewhat reduce the amount of flares produced. (input is not clampled)
	/// </summary>
    [Property, Title("Cutoff"),Range( 0, 100.0f, 0, false)]  
    public float fCutoff { get; set; } = 0.01f; 
	
	
	/// <summary>
	/// How far apart each flare is, if you set this high they start to wrap around and produce different effeects.
	/// </summary>
    [Property, Title("Flare Spacing"),Range( 0.01f, 1.0f, 0, true)]  
    public float fStretch { get; set; } = 0.5f; 
	

	
	/// <summary>
	/// Number of flares to render.
	/// </summary>
    [Property, Title("Flare Count"),Range( 1.0f, 10.0f, 1, false)]  
    public float fShape { get; set; } = 1.0f; 
	

	
	
	/// <summary>
	/// How much to fade the flares with the rest of the scene
	/// </summary>
    [Property, Title("Gain"),Range( 0, 0.5f, 0, true)]  
    public float fGain { get; set; } = 0.016f; 
	
	/// <summary>
	/// Color to tint the flares.
	/// </summary>
    [Property, Title("Tint"),Range( 0, 0.5f, 0, true)]  
    public Color fColor { get; set; } = new Color(0.2f, 0.4f, 1.0f, 1.0f); 	


	
	/// <summary>
	/// Boosts the contrast of the Opacity Map. 
	/// </summary>
    [Property, Title("Dirt Enhancer")]  
    public bool fDoubleAdd { get; set; }		
	
	/// <summary>
	/// Ensures the effect is applied AFTER others in the stack.(you must disable and re-enable the component for the change to take place)
	/// </summary>
    [Property, Title("Low Priority")]  
    public bool fPriority { get; set; }		
	
	/// <summary>
	/// curves adjustments for the prepass
	/// </summary>
    [Property, ToggleGroup("bFineTune", Label = "Fine Tune Pre-Pass")]  
    public bool bFineTune { get; set; }		

	/// <summary>
	/// Disables the flares and shows you the prepass, makes it easier to fine tune the effect. 
	/// </summary>
    [Property, Title("Visualize Pre-Pass"),Group("bFineTune")]  
    public bool fBypass { get; set; }	
	
	/// <summary>
	/// Adjust the amount of blur on the pre pass (default 10)
	/// </summary>
	[Property, Title("Blur Radius") ,Group("bFineTune"), Range( 1.0f, 25f, 1)]  
    public float bRadius { get; set; } = 10.0f;			
	
	/// <summary>
	/// Darkest parts of the image.
	/// </summary>
	[Property, Title("Blacks"), Group("bFineTune"), Range( -0.25f, 1.0f, 0 )]  
    public float Blacks { get; set; } = 0.0f;
	

	
	/// <summary>
	/// Rolloff from midtones to shadow.
	/// </summary>
	[Property, Title("Shadows"), Group("bFineTune"), Range( 0.0f, 1.0f, 0 )]  
    public float Shadows { get; set; } = 0.25f;	

	/// <summary>
	/// Parts of the image around 50%.
	/// </summary>
	[Property, Title("Midtones") ,Group("bFineTune"), Range( 0.0f, 1.0f, 0 )]  
    public float Midtones { get; set; } = 0.5f;	
	
	/// <summary>
	/// Rolloff from midtones to whites.
	/// </summary>
	[Property, Title("Highlights") ,Group("bFineTune"), Range( 0.0f, 1.0f, 0)]  
    public float Highlights { get; set; } = 0.75f;	

	/// <summary>
	/// Brightest parts of the image.
	/// </summary>
	[Property, Title("Whites") ,Group("bFineTune"), Range( 0.0f, 1.5f, 0)]  
    public float Whites { get; set; } = 1.0f;		
	
	
    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		//
		//blurpass?.Dispose();
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );

		if(fPriority)
			renderHook = cc.AddHookAfterTransparent( "CCSLensFlares", 5000, RenderEffect );
		else
			renderHook = cc.AddHookAfterTransparent( "CCSLensFlares", 3000, RenderEffect );
		
		
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
		
		attributes.Set( "bContrast", bContrast );
		attributes.Set( "fCutoff", fCutoff );
		//attributes.Set( "fPower", fPower );
		attributes.Set( "fStretch", fStretch );
		//attributes.Set( "fVStretch", fVStretch );
		attributes.Set( "fShape", fShape );
		//attributes.Set( "fVShape", fVShape );
		attributes.Set( "fGain", fGain );
		attributes.Set( "fColor", fColor);
		

		attributes.Set( "bRadius", bRadius );

		
		//attributes.Set( "fVertON", fVertON );
		//attributes.Set( "fHoriON", fHoriON );
		attributes.Set( "fDoubleAdd", fDoubleAdd );
		attributes.Set( "fBypass", fBypass );
		attributes.Set( "bFineTune", bFineTune );
		

		attributes.Set( "Blacks", Blacks );
		attributes.Set( "Shadows", Shadows );
		attributes.Set( "Midtones", Midtones);
		attributes.Set( "Highlights", Highlights );
		attributes.Set( "Whites", Whites);			
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
	    Graphics.Blit( Material.Load( "materials/postprocess/ccs_flareprepass.vmat" ), attributes );
		
		attributes.Set( "color_map", color_map);		
		attributes.Set( "opacity_map", opacity_map);		
	   Graphics.GrabFrameTexture( "blurBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_lensflares.vmat" ), attributes );
			

    }
}
