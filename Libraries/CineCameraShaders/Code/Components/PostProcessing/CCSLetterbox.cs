using Sandbox;
using System;

/// <summary>
/// Crop the screen using black bars like you are watching a DVD on an old tv.
/// </summary>
[Title( "Letterboxing" )]
[Category( "Post Processing" )]
[Icon( "theaters" )]


public sealed class CCSLetterbox : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// Color of the letterboxing
	/// </summary>
	[Property]
	public Color LetterboxColor { get; set; } = Color.Black; //black by default 
	//but you can change it for other cool effects, this shader can obviously 
	//be used for more than just letterboxing, it's props could be drivin 
	
	//actual list of aspect ratio presets 
	public float[] AspectRatios = {0.00f, 2.39f, 1.85f, 1.33f, 1.50f, 1.00f, 0.5625f, 0.80f, 2.76f, 3.50f,4.00f };
	//FOR FUTURE REFERENCE : the array is initialized ONCE prob on add?. Otherwise relaunch sbox is you change.
	
	private AspectPreset _aspectSelection;
	/// <summary>
	/// Will automatically letterbox the screen to the selected aspect ratio.
	/// </summary>
	[Property, Title("Aspect Ratio Preset")] public AspectPreset AspectSelection
	{//im doing this goofy private var thing with both vars to get the toggle to work
		get => _aspectSelection;
		set
		{
			if (value != AspectPreset.None)
			{
				_aspectSelection = value;
				_manualSettings = false;
			}
			else
			{
				_aspectSelection = value;
			}
		}
	}
	
	public enum AspectPreset
	{
		None,
		[Description( "2.39:1 Widescreen film" )]
		Scope,
		[Description( "1.85:1 Theatrical film" )]
		Flat,
		[Description( "4:3 CLASSIC" )]
		TV,
		[Description( "3:2 35mm Photo" )]
		FilmPhoto,
		[Description( "1:1 Perfection" )]
		Square,
		[Description( "9:16 Vertical Video" )]
		Vertical,
		[Description( "4:5 Slightly less ugly" )]
		InstaVertical = 7,
		[Description( "2.76:1 The Cinema is yours" )]
		UltraPanavision70,
		[Description( "3.5:1 aka 32:9, dual monitor" )]
		SuperUltraWide,
		[Description( "4:1 Napoléon [1927]" )]
		Polyvision
		
	}
	

	
	private bool _manualSettings;
	/// <summary>
	/// Manually set the vertical or horizontal letterboxing amount.
	/// </summary>
	[Property, Title("Aspect Ratio"), ToggleGroup("ManualSettings", Label = "Manual Settings")]
	public bool ManualSettings
	{
		get => _manualSettings;
		set
		{
			if (value)
			{
				_manualSettings = true;
				AspectSelection = AspectPreset.None;
			}
			else
			{
				_manualSettings = false;
			}
		}
	}
	/// <summary>
	/// Approx AspectRatio, based on current camera screen resolution which is goofy in the editor.
	/// </summary>
	[Property, Title("Aspect Ratio"), ReadOnly, Group("ManualSettings")]
	public float AspectRatio { get; set; }
	/// <summary>
	/// Thickness of the bars going across the screen horizontally 
	/// </summary>
    [Property, Title("Horizontal Bar Thickness"),Range( 0, 100.0f, 0, true), Group("ManualSettings")]  // step 0 and clamp true
    public float vPercent { get; set; } = 33.3f; //33 tee hee looks kinda cinematic 
	
	/// <summary>
	/// Thickness of the bars going across the screen vertically 
	/// </summary>
    [Property, Title("Vertical Bar Thickness"), Range( 0, 100.0f, 0, true ), Group("ManualSettings")]  //horizontal
    public float hPercent { get; set; } = 0.0f;
	


    IDisposable renderHook;
	
	protected override void OnUpdate()
	{
		var cc = Components.Get<CameraComponent>( true );
		if(AspectSelection != AspectPreset.None){
			float CameraAspect = cc.ScreenRect.Width / cc.ScreenRect.Height;
			float DesiredAspect = AspectRatios[(int)AspectSelection];
			
			//Log.Info($"desire int: " + (int)AspectSelection);
			//Log.Info("desire: " + DesiredAspect);
			if(DesiredAspect > CameraAspect)
			{
				
				vPercent = 100 * (1 - (CameraAspect / DesiredAspect));
				hPercent = 0f;
				
			}
			if(DesiredAspect < CameraAspect)
			{
				hPercent = 100 * (1 - (DesiredAspect /CameraAspect));
				vPercent = 0f;
			}
		}
		
		
		
		
		AspectRatio = (cc.ScreenRect.Width - (cc.ScreenRect.Width * (hPercent / 100))) / (cc.ScreenRect.Height - (cc.ScreenRect.Height * (vPercent / 100 )));
		
	}

    protected override void OnEnabled()
    {
		
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSLetterbox", 9001, RenderEffect );
		
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
		if (AspectSelection == AspectPreset.None & ManualSettings == false)
			return;

		
		
		
		attributes.Set( "vPercent", vPercent );
        attributes.Set( "hPercent", hPercent );
		attributes.Set( "LetterboxColor", LetterboxColor );

		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_letterbox.vmat" ), attributes );

    }
}
