using Sandbox;
using System;


/// <summary>
/// Uses the same "Neutral" LUT type as OBS, low quality but good for FX
/// </summary>

[Title( "Color Correction LUT" )]
[Category( "Post Processing" )]
[Icon( "filter_center_focus" )]




public sealed class CCSColorCorrection : Component, Component.ExecuteInEditor
{

	/// <summary>
	/// Make sure you set it to RGBA8888 not DXT for best quality.
	/// </summary>
	[Property]
	public Texture lut_texture;
	
	/// <summary>
	/// Blend the corrected image with the original.
	/// </summary>
    [Property, Title("Opacity"),Range( 0.00f, 1.0f, 0, true)]  
    public float fOpacity { get; set; } = 1.0f; 

    IDisposable renderHook;
	
//	protected override void OnUpdate()
//	{
//
//	}

    protected override void OnEnabled()
    {
		
		renderHook?.Dispose();
		var cc = Components.Get<CameraComponent>( true );
		
		renderHook = cc.AddHookBeforeOverlay( "CCSColorCorrection", 2001, RenderEffect );
		//pretty high pri so other fx can manipulate the alternate coloration, but still not that high
		
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

		
		attributes.Set( "lut_texture", lut_texture );
		attributes.Set( "fOpacity", fOpacity);

		
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
       // Graphics.GrabDepthTexture( "DepthBuffer", attributes );
        Graphics.Blit( Material.Load( "materials/postprocess/ccs_colorcorrection.vmat" ), attributes );

    }
}
