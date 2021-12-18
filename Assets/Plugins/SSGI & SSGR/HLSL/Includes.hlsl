#include "Assets/Post Processing/SSGI/Library/SSGIUtils.cginc"

void SampleAlbedo_float(float2 SSuv, float2 uv, out float3 Out)
{
    Out = SampleAlbedo(SSuv, uv);
}

void GetCameraViewUpDir_float(out float3 Out)
{
    Out = GetViewUpDir();
}
//
// float3x3 GetFixedViewMatrix(float3 viewDir)
// {
//     return float3x3(normalize(cross(viewDir, GetViewUpDir())), GetViewUpDir(), viewDir); // Fixed View Transformation Matrix
// }
//
// void GetFixedViewNormal_float(float3 normalWS, float3 viewDir, out float3 Out)
// {
//     Out = normalize(mul(GetFixedViewMatrix(viewDir), normalWS)); // Fixes View Normals
// }