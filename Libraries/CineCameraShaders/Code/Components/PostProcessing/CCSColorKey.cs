using Sandbox;
using System;


/// <summary>
/// Key out a color from the image or an image or apply an image on top of the screen.
/// </summary>

[Title( "Color Keyer" )]
[Category( "Post Processing" )]
[Icon( "colorize" )]




public sealed class CCSColorKey : Component, Component.ExecuteInEditor
{


	
	/// <summary>
	/// Color to key out.
	/// </summary>
    [Property, Title("Key Color")] 
    public Color keyColor { get; set; } = new Color(0.0f, 0.83f, 0.0f, 1.0f); 	
	
	/// <summary>
	/// vTex_C to use for the image to be keyed.
	/// </summary>
	[Property]
	public Texture image_texture;	
	
	
	
	/// <summary>
	/// Somewhat control the the color tolerance. Does NOT play well with tonemapping etc...
	/// </summary>
	[Header("Blending")]
	[Property, Title("Background Blend"), Range( 0.0f, 1.0f, 0, true )]  
    public float bBlend { get; set; } = 0.203f;
	

	
	/// <summary>
	/// Somewhat control the the color tolerance. Set both of these pretty close to each other for best results.
	/// </summary>
	[Property, Title("Foreground Blend") , Range( 0.0f, 1.0f, 0, true )]  
    public float fBlend { get; set; } = 0.203f;		
	
	/// <summary>
	/// Adjusts the opacity of the area which is keyed out.
	/// </summary>
	[Property, Title("Mask Opacity"), Range( 0.0f, 1.0f, 0, true )]  
    public float bOpacity { get; set; } = 1.0f;	
	
	/// <summary>
	/// Adjusts the opacity of the main image.
	/// </summary>
	[Property, Title("Foreground Opacity"), Range( 0.0f, 1.0f, 0, true )]  
    public float fOpacity { get; set; } = 1.0f;	
	


	
	/// <summary>
	/// Horizontal scale of the image.
	/// </summary>
	[Header("Image Transform")]
	[Property, Title("Horizontal Scale"), Range( 0.01f, 20.0f, 0, true )]  
    public float xScale { get; set; } = 1.0f;

	/// <summary>
	/// Vertical scale of the image.
	/// </summary>
	[Property, Title("Vertical Scale"), Range( 0.01f, 20.0f, 0, true )]  
    public float yScale { get; set; } = 1.0f;

	/// <summary>
	/// Horizontal image position offset from center.
	/// </summary>
	[Property, Title("Horizontal Position"), Range( -1.0f, 1.0f, 0, false )]  
    public float xPos { get; set; } = 0.0f;

	/// <summary>
	/// Vertical image position offset from center.
	/// </summary>
	[Property, Title("Vertical Position"), Range( -1.0f, 1.0f, 0, false )]  
    public float yPos { get; set; } = 0.0f;	

	
	/// <summary>
	/// Instead of applying the key to the game with the image under it, apply the key to the image and have the game under it.
	/// </summary>
	[Header("Extras")]
    [Property, Title("Overlay Mode")]  
    public bool kSwap { get; set; }		//kinda broken
	
	/// <summary>
	/// Allow the image texture to repeat. 
	/// </summary>
    [Property, Title("Tile Image")]  
    public bool iTile { get; set; }	= true;	
	
	/// <summary>
	/// Don't color key at all, just overlay.
	/// </summary>
    [Property, Title("Disable Keying")]  
    public bool dKey { get; set; }			
	
	/// <summary>
	/// Blend mode, works strangely in Overlay Mode!
	/// </summary>
	[Property, Title("Blend Mode")]
	public BlendMode BlendModeSelection { get; set; } = BlendMode.Normal;
	public enum BlendMode
	{
		[Description( "Normal Opacity blending" )]
		Normal,
		[Description( "Light areas become Brighter" )]
		Additive,
		[Description( "Light areas become darker" )] 
		Subtract, 	
		[Description( "Brightness of the overlay controls the Brightness" )]
		Multiply,
		[Description( "Dark parts of the image lighten and light parts become transparent" )]
		Divide,
		[Description( "Overlay lighter parts of the image" )]
		Screen,
		[Description( "like screen but takes the color of the image below")]
		ColorDodge
		//todo add more complex blend modes that are worthwile 	 
		//  https://www.clipstudio.net/how-to-draw/archives/154182
		//  https://www.deepskycolors.com/tools-tutorials/formulas-for-photoshop-blending-modes/
		
	}		
	
	
    IDisposable renderHook;
	
//	protected override void OnUpdate()
//	{
//
//	}

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSColorKey", 2001, RenderEffect );
		
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

		
		attributes.Set( "image_texture", image_texture );
		attributes.Set( "keyColor", keyColor );
		attributes.Set( "bBlend", bBlend );
		attributes.Set( "fBlend", fBlend );
		attributes.Set( "kSwap", kSwap );
		attributes.Set( "iTile", iTile ); //the latest in apple bathroom smart floor technology
		attributes.Set( "dKey", dKey );
		
		attributes.Set( "xPos", xPos );
		attributes.Set( "xScale", xScale );
		attributes.Set( "yPos", yPos );
		attributes.Set( "yScale", yScale );
		
		attributes.Set( "fOpacity", fOpacity );
		attributes.Set( "bOpacity", bOpacity );		
		
		attributes.Set( "BlendMode", (int)BlendModeSelection );
		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_colorkey.vmat" ), attributes );

    }
}
