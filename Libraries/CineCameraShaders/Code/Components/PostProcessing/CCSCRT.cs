using Sandbox;
using System;


/// <summary>
/// Emulate the look of a CRT screen
/// </summary>

[Title( "CRT Emulation" )]
[Category( "Post Processing" )]
[Icon( "live_tv" )]




public sealed class CCSCRT : Component, Component.ExecuteInEditor
{



//	[Property]
//	public Texture crt_mask;
	
	/// <summary>
	/// Pattern to use for the CRT Mask.
	/// </summary>
	[Property, Title("CRT Mask Preset")]
	public CRTPreset CRTPresetSelection { get; set; } = CRTPreset.SubPixelApertureGrille;
	// http://filthypants.blogspot.com/2020/02/crt-shader-masks.html
	// these patterns exploit the subpixels of modern screens to make them appear somewhat like a CRT would. it isn't perfect
	// can add other presets in the future for things like texture based tiling patterns 
	public enum CRTPreset
	{
		[Description( "Vertical Pattern" )]
		SubPixelApertureGrille,
		[Description( "Alternating pattern, looks like shadow mask." )]
		SubPixelShadowMask,
		[Description( "Fake slot-mask pattern" )]
		SubPixelSlotMask,
		[Description( "RGB mask with black lines" )] //non sub pixel masks below here
		FullPixelGrille,
		[Description( "RGB alternating pattern" )] //non sub pixel masks below here
		FullPixelShadowMask,
		None // always put this at the end 
		
	}	
	/// <summary>
	/// Blur the image slightly to create a "bloomy" look (works best with white enhance).
	/// </summary>
	[Property, Title("Softness"), Range( 0.0f, 10.0f, 0, true)]
	public float bLevel { get; set; }	= 1.0f; 
	
	/// <summary>
	/// FLASHING LIGHTS WARNING! Enables Screen Flicker (defaults are sane).
	/// </summary>	
	[Property, ToggleGroup("Flicker", Label = "Screen Flicker")]
	public bool Flicker { get; set; }	

	/// <summary>
	/// How much to flash, 1 = fully black(crazy). 0.02 = semi realistic.
	/// </summary>
	[Property, Title("Flicker Opacity"), Group("Flicker"), Range( 0.0f, 1.0f, 0, true)]
	public float fOpacity { get; set; }	= 0.02f; 
	
	/// <summary>
	/// How often the screen flickers. Gets weird at high values.
	/// </summary>
	[Property, Title("Flicker Rate"),  Group("Flicker"), Range( 0.0f, 100.0f, 0, true)]
	public float fRate { get; set; } = 60.0f; 	
	
	
	/// <summary>
	/// Enable CRT Scan line emulation.
	/// </summary>	
	[Property, ToggleGroup("ScanLines", Label = "Scan Lines")]
	public bool ScanLines { get; set; }	

	/// <summary>
	/// Not the actual number of lines on the screen, but a value which scales the number of lines.
	/// </summary>
	[Property, Title("Line Count"),  Group("ScanLines"), Range( 0.0f, 1000.0f, 1, true)]
	public float slCount { get; set; }	= 480.0f; 
	
	/// <summary>
	/// How dark the scanlines are.
	/// </summary>
	[Property, Title("Line Opacity"),  Group("ScanLines"), Range( 0.0f, 1.0f, 0, true)]
	public float slOpacity { get; set; } = 0.1f; 	
	
	/// <summary>
	/// Rate at which to scroll the scanlines up or down the screen. high speed + opacity = FLASHING LIGHTS!
	/// </summary>
	[Property, Title("Scroll Rate"),  Group("ScanLines"), Range( -100.0f, 100.0f, 0, true)]
	public float slScroll { get; set; } = 1.2f; 	
	
	/// <summary>
	/// brings back some brighter colors, but some of the crt effect is lost.
	/// </summary>	
	[Property, Title("Enhance Whites")]
	public bool rWhite { get; set; }	
	
	/// <summary>
	/// Ensures the effect is applied AFTER others in the stack.(you must disable and re-enable the component for the change to take place), in this case the CRT shader will become the lowest, meaning even letterboxing will be applied BEFORE this one.
	/// </summary>
    [Property, Title("Low Priority")]  
    public bool fPriority { get; set; }	

    IDisposable renderHook;
	

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		//ideally this shader should run AFTER the UI is drawn so it can change on-screen ui but I don't think you can do that yet?
		//idk i don't have any UI to test with.
		// https://github.com/Facepunch/sbox-issues/issues/4672 like this but everything on screen not just ui. (ui only would b cool tho)
		//another nice to have would be to render this BEFORE the lens distortion or add lens distortion to this shader (could add pri switch to lens distortion for that)
		//to simulate a crt's curved screen, but currently because this uses sub-pixel tricks to make it look like a CRT
		// that wouldn't work at all. 
		
		if(fPriority)
			renderHook = cc.AddHookBeforeOverlay( "CCSCRT", 9999, RenderEffect );
		else
			renderHook = cc.AddHookBeforeOverlay( "CCSCRT", 4000, RenderEffect );
		
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

		
//		attributes.Set( "crt_mask", crt_mask ); //enable later for texture based masks

		
		attributes.Set( "ScanLines", ScanLines );
		attributes.Set( "slCount", slCount );
		attributes.Set( "slOpacity", slOpacity );
		attributes.Set( "slScroll", slScroll );
		
		attributes.Set( "Flicker", Flicker );
		attributes.Set( "fOpacity", fOpacity );
		attributes.Set( "fRate", fRate );
		
		attributes.Set( "rWhite", rWhite );
		attributes.Set( "bLevel", bLevel );
		
		attributes.Set( "style", (int)CRTPresetSelection );
		
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_crt.vmat" ), attributes );

    }
}
