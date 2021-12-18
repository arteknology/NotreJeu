using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;
using UnityEngine.Serialization;

[Serializable, VolumeComponentMenu("Lighting/SSGR")]
public class SSGR : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Intensity")]
    public ClampedFloatParameter Intensity = new ClampedFloatParameter(0, 0,1, true);
    [Tooltip("Smoother At SHarp Angles")]
    public ClampedFloatParameter FresnelReflection = new ClampedFloatParameter(0, 0,1, true);
    [Tooltip("External Reflection Distortion")]
    public ClampedFloatParameter Distortion = new ClampedFloatParameter(2, 0,3, true);
    [Tooltip("Internal Reflection Distortion")]
    public ClampedFloatParameter InnerDistortion = new ClampedFloatParameter(1, 0,3, true);
    [Tooltip("Make reflections appear More at sharp angles")]
    public ClampedFloatParameter FresnelPower = new ClampedFloatParameter(0, 0,2, true);
    [Tooltip("Transition Angle")]
    public ClampedFloatParameter EdgeAngle = new ClampedFloatParameter(0.5f, 0, 1, true);
    [Tooltip("Smooths Out UV Transitions")]
    public ClampedFloatParameter UVEdgeSoftness = new ClampedFloatParameter(0.5f, 0, 1, true);
    [Tooltip("MinMax Reflection Blur")]
    public FloatRangeParameter MinMaxBlur = new FloatRangeParameter(new Vector2(0, 1), 0, 1, true);

    [Tooltip("Removes Mirrored UVs")]
    public BoolParameter RemoveMirroredUVs = new BoolParameter(false, true); 
    [Tooltip("Removes Invisible Areas")]
    public BoolParameter RemoveInvisible = new BoolParameter(false, true);
    [Tooltip("Removes Unwanted Geometry")]
    public BoolParameter RemoveUnwanted = new BoolParameter(false, true);
    [Tooltip("Enable Back Reflections")]
    public BoolParameter BackReflections = new BoolParameter(false, true);

    Material m;

    public bool IsActive() => m != null && Intensity.value > 0f && active;
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.BeforeTAA;
    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/SSGR") != null) 
            m = new Material(Shader.Find("Hidden/Shader/SSGR"));
    }
    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m == null) return;
        
        m.SetFloat("_Intensity", Intensity.value);
        m.SetFloat("_FresnelReflection", FresnelReflection.value);
        m.SetFloat("_Distortion", Distortion.value);
        m.SetFloat("_InnerDistortion", InnerDistortion.value);
        m.SetFloat("_FresnelPower", FresnelPower.value);
        m.SetFloat("_SmoothEdge", EdgeAngle.value);
        m.SetFloat("_EdgeSoftness", UVEdgeSoftness.value);
        m.SetVector("_MinMaxBlur", MinMaxBlur.value);
        m.SetTexture("_InputTexture", source);
        m.SetFloat("_ClampUVs", RemoveMirroredUVs.value ? 1 : 0);
        m.SetFloat("_RemoveInvisible", RemoveInvisible.value ? 1 : 0);
        m.SetFloat("_RemoveUnwanted", RemoveUnwanted.value ? 1 : 0);
        m.SetFloat("_BackReflections", BackReflections.value ? 1 : 0);
        HDUtils.DrawFullScreen(cmd, m, destination);
    }
    public override void Cleanup() => CoreUtils.Destroy(m);
}