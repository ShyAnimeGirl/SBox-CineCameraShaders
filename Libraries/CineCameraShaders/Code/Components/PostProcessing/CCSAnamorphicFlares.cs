using Sandbox;
using System;


/// <summary>
/// Streaks of light across the screen, horizontal and or vertical.
/// </summary>

[Title( "Anamorphic Flares" )]
[Category( "Post Processing" )]
[Icon( "align_horizontal_center" )]




public sealed class CCSAnamorphicFlares : Component, Component.ExecuteInEditor
{

	
	/// <summary>
	/// Adjusts the threshold of where flares are applied.
	/// </summary>
    [Property, Title("Contrast"),Range( 0.001f, 3.0f, 0, true)]  
    public float bContrast { get; set; } = 1.5f; 	// future plan: use FFT to convolve highlights instead of contrast detect
	
	/// <summary>
	/// Allows you to somewhat reduce the amount of flares produced. (input is not clampled)
	/// </summary>
    [Property, Title("Cutoff"),Range( 0, 100.0f, 0, false)]  
    public float fCutoff { get; set; } = 0.01f; 
	
	/// <summary>
	/// Brightness and quality of the flares.
	/// </summary>
    [Property, Title("Power"),Range( 1.0f, 1000.0f, 1, true)]  
    public float fPower { get; set; } = 200.0f; 
	
	/// <summary>
	/// How wide the horizontal flares are.
	/// </summary>
    [Property, Title("Horizontal Flare Size"),Range( 0.01f, 1.0f, 0, true)]  
    public float fStretch { get; set; } = 0.5f; 
	
	/// <summary>
	/// How tall the vertical flares are.
	/// </summary>
    [Property, Title("Vertical Flare Size"),Range( 0.01f, 1.0f, 0, true)]  
    public float fVStretch { get; set; } = 0.1f; 	
	
	/// <summary>
	/// Sort of like brightness + falloff on the edges.
	/// </summary>
    [Property, Title("Horizontal Flare Shape"),Range( 0.01f, 10.0f, 0, true)]  
    public float fShape { get; set; } = 0.35f; 
	
	/// <summary>
	/// Sort of like brightness + falloff on the edges.
	/// </summary>
    [Property, Title("Vertical Flare Shape"),Range( 0.01f, 10.0f, 0, true)]  
    public float fVShape { get; set; } = 2.0f; 		
	
	
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
	/// Enable Vertical flares.
	/// </summary>
    [Property, Title("Vertical Flares")]  
    public bool fVertON { get; set; }

	/// <summary>
	/// Enable Horizontal flares.
	/// </summary>
    [Property, Title("Horizontal Flares")]  
    public bool fHoriON { get; set; }	
	
	/// <summary>
	/// Doubles the brightness of the whole image. I had this on while writing the shader so I now I think it looks good. 
	/// </summary>
    [Property, Title("Double Add")]  
    public bool fDoubleAdd { get; set; }		
	
	
	
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
		//spent a long time here trying to do compute shaders and stuff that didnt work
		//blurpass?.Dispose();
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );

		renderHook = cc.AddHookAfterTransparent( "CCSAnamorphicFlares", 4000, RenderEffect );
		
		
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
		attributes.Set( "fPower", fPower );
		attributes.Set( "fStretch", fStretch );
		attributes.Set( "fVStretch", fVStretch );
		attributes.Set( "fShape", fShape );
		attributes.Set( "fVShape", fVShape );
		attributes.Set( "fGain", fGain );
		attributes.Set( "fColor", fColor);
		

		attributes.Set( "bRadius", bRadius );

		
		attributes.Set( "fVertON", fVertON );
		attributes.Set( "fHoriON", fHoriON );
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
	   Graphics.GrabFrameTexture( "blurBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_anamorphicflares.vmat" ), attributes );
			

    }
}
