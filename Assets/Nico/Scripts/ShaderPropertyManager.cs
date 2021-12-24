using Properties;

using UnityEngine;
using SP = Properties.ShaderProperties;

[ExecuteAlways]
public class ShaderPropertyManager : MonoBehaviour
{


    [Header("Shader Properties")] 
    [Range(1, 100)]public int TesselationAmount = 4;

    void Start()
    {
        // var shit = RenderPipelineGlobalSettings.CreateInstance(RenderPipelineGlobalSettings);
        // GraphicsSettings.RegisterRenderPipelineSettings<>();
        // RenderPipelineManager.currentPipeline.defaultSettings.re
    }

    private void Update() {
        SP.TesselationFactor.SetProperty(TesselationAmount);
    }
}
