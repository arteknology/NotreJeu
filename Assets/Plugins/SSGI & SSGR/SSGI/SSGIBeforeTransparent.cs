using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Lighting/SSGIBeforeTransparent")]
public class SSGIBeforeTransparent : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Screen Space GI Intensity")]
    public ClampedFloatParameter Intensity = new ClampedFloatParameter(0, 0,6, true);
    [Tooltip("Activate AO For This To Work")]
    public ClampedFloatParameter AOInfluence = new ClampedFloatParameter(1, 0,1, false);
    [Tooltip("Minimal Ambient Color")]
    public ClampedFloatParameter DiffuseIntensity = new ClampedFloatParameter(0, 0,0.2f, false);
    [Tooltip("Uses Normals for Better Visuals")]
    public ClampedFloatParameter RoughnessInfluence = new ClampedFloatParameter(0.35f, 0,1, false);
    [Tooltip("Smooth Surfaces Wont Light Up")]
    public ClampedFloatParameter NormalBias = new ClampedFloatParameter(3, 0, 8, false);
    [Tooltip("Light Diffusion")]
    public ClampedFloatParameter Diffusion = new ClampedFloatParameter(1.5f, 1, 2, false);
    [Tooltip("Diffusion Distances")]
    public FloatRangeParameter MinMaxDistance = new FloatRangeParameter(new Vector2(30, 120), 0, 200, false);
    // [Tooltip("Remove Bilinear Sampling Artifacts +-0.2ms")]
    // public BoolParameter HQFiltering = new BoolParameter(true, true);
    // public 

    [Tooltip("Trilinear : 0.4ms | Triquadratic : 0.85ms" )]
    public FilteringQualityParameter Quality = new FilteringQualityParameter(FilteringQuality.Trilinear);
    // public ClampedIntParameter Steps = new ClampedIntParameter(2, 2, 10);

    Material m;

    public bool IsActive() => m != null & Intensity.value > 0f & active;
    // public bool IsActive() => active;
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterOpaqueAndSky;
    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/SSGIBeforeTransparent") != null) 
            m = new Material(Shader.Find("Hidden/Shader/SSGIBeforeTransparent"));
    }
    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (active == false)
        {
            return;
        }
        if (m == null) return;
        
        m.SetFloat("_Intensity", Intensity.value);
        m.SetFloat("_AOStrength", AOInfluence.value);
        m.SetFloat("_DiffuseIntensity", DiffuseIntensity.value);
        m.SetFloat("_RoughnessInfluence", RoughnessInfluence.value);
        m.SetFloat("_NormalBias", NormalBias.value);
        m.SetFloat("_Diffusion", Diffusion.value);
        m.SetVector("_MinMax", MinMaxDistance.value);
        m.SetInteger("_Filtering", (int)Quality.value);
        m.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m, destination);
    }
    public override void Cleanup() => CoreUtils.Destroy(m);
    
    [Serializable]
    public sealed class FilteringQualityParameter : VolumeParameter<FilteringQuality> {
        public FilteringQualityParameter(FilteringQuality value, bool overrideState = false) : base(value, overrideState) {}
    }
    public enum FilteringQuality {
        /// <summary>
        /// Default Filtering
        /// </summary>
        Trilinear = 0,
        
        /// <summary>
        /// HQ Filtering
        /// </summary>
        Biquadratic = 1,
        
        /// <summary>
        /// UHQ Filtering
        /// </summary>
        Triquadratic = 2
    }
}