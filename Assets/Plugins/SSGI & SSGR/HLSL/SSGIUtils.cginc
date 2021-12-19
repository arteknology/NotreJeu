// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl" 
// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl" 
// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"

// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
// #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl" //  Contains NormalBuffer

#ifndef SSGIUTILS_INCLUDED
#define SSGIUTILS_INCLUDED

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"


// #pragma target 4.5

float4 GetInBetweenValues(float2 minMax){
    const float step = abs(minMax.x - minMax.y) / 3;
    return float4(minMax.x, minMax.x + step, minMax.y - step, minMax.y);
}

float GetDepth(uint2 uv){
    return LOAD_TEXTURE2D_X(_CameraDepthTexture, clamp(uv, 0, _ScreenSize.xy-1)).x;
}

float GetDepthLinear(uint2 uv){
    return LinearEyeDepth(GetDepth(uv),_ZBufferParams);
}


float3 GetNormal(uint2 uv){
    if(GetDepth(uv) > 0){
        NormalData normalData;
        const float4 normalBuffer = LOAD_TEXTURE2D_X(_NormalBufferTexture, (float2)uv);
        DecodeFromNormalBuffer(normalBuffer, uv, normalData);  
        return normalData.normalWS;
    }
    return 0;
}

void GetBSDFData (BSDFData bsdfData, BuiltinData unused, float2 SSuv)
{
    DecodeFromGBuffer(SSuv, UINT_MAX, bsdfData, unused);
}



float2 GetNormalOffset(float3 normalVS, float normalBias){
    return _PostProcessScreenSize.zw * normalBias * normalVS.xy;
    // return rcp(_ScreenSize.xy) * normalBias.xx *  mul(_InvViewMatrix, GetNormal(uv)).xy;
}

float4 SampleBiquadratic(float2 coord, float LOD){
    float2 xy = coord * _PostProcessScreenSize.xy;
    float2 ic = floor(xy);
    float2 fc = frac(xy);
    float2 weights[2], offsets[2];
    BiquadraticFilter(1 - fc, weights, offsets); // Inverse-translate the filter centered around 0.5
    float2 size = rcp(_PostProcessScreenSize.xy / (exp2(LOD)));
    // Apply the viewport scale right at the end.
    const SamplerState smp = s_trilinear_clamp_sampler;
    return weights[0].x * weights[0].y * SAMPLE_TEXTURE2D_X_LOD(_ColorPyramidTexture, smp, (ic + float2(offsets[0].x, offsets[0].y)) * size, LOD)  // Top left
         + weights[1].x * weights[0].y * SAMPLE_TEXTURE2D_X_LOD(_ColorPyramidTexture, smp, (ic + float2(offsets[1].x, offsets[0].y)) * size, LOD)  // Top right
         + weights[0].x * weights[1].y * SAMPLE_TEXTURE2D_X_LOD(_ColorPyramidTexture, smp, (ic + float2(offsets[0].x, offsets[1].y)) * size, LOD)  // Bottom left
         + weights[1].x * weights[1].y * SAMPLE_TEXTURE2D_X_LOD(_ColorPyramidTexture, smp, (ic + float2(offsets[1].x, offsets[1].y)) * size, LOD); // Bottom right
}

float4 SampleTriquadratic(float2 coord, float LOD)
{
    const uint2 Lods = uint2(floor(LOD), ceil(LOD));
    const uint2 exps = exp2(Lods);
    return lerp( SampleBiquadratic(coord / exps.x, Lods.x), SampleBiquadratic(coord / exps.y, Lods.y), frac(LOD));
}

float3 GetCamColorLOD(float2 uv, float LOD, float FilteringBool){
    if(FilteringBool == 0) return SAMPLE_TEXTURE2D_X_LOD(_ColorPyramidTexture, s_trilinear_clamp_sampler, uv, LOD);
    if(FilteringBool == 1)  SampleBiquadratic(uv / exp2(LOD), LOD);
    return SampleTriquadratic(uv, LOD);
}

float SampleSSAO (float2 uv){
    return SAMPLE_TEXTURE2D_X(_AmbientOcclusionTexture, s_trilinear_clamp_sampler, uv).r;
}
float4 SampleAlbedo(float2 uv){
        return SAMPLE_TEXTURE2D_X(_GBufferTexture0, s_trilinear_clamp_sampler, uv);

}

float SampleRoughness(uint2 SSuv, float2 uv){
    if(GetDepth(SSuv) > 0){
        return SAMPLE_TEXTURE2D_X(_GBufferTexture1, s_trilinear_clamp_sampler, uv).w;
    }
    return 0;
}

float4 SampleGBuffer(Texture2DArray bufferTexture, float2 uv)
{
    return SAMPLE_TEXTURE2D_X(bufferTexture, s_trilinear_clamp_sampler, uv);
}

float FresnelEffect(float3 Normal, float3 ViewDir, float Power){
    return pow(1 - saturate(dot(normalize(Normal), normalize(ViewDir))), Power);
}

float2 PostProcessScreenPixelSize(){
    return rcp(_PostProcessScreenSize.xy);
}

float Squircle(float2 uv)
{
    uv = abs(uv * 2 - 1);
    uv = 1 - uv * uv;
    return saturate(uv.x * uv.y);
}

// Curvature -----------------

// multiplying a by a given factor, smooths/hardens the transition to 1
// Useful for GI intensity remapping for post processing After opaque and sky,
// which tends to accumulate using HDR values;
float ExpRemap01(float a)
{
    return saturate(1 - exp2(- a));
}

//Used For Curvature Computation;
float DDCrossLength(float3 a)
{
    return length(cross(ddx_fine(a), ddy_fine(a)));
}

// Bad Approximation, fails in some cases with negative curvature
float CurvatureDeprecated(float3 normal)
{
    const float dx = ddx(normal);
    const float dy = ddy(normal);
    return pow(max(dot(dx,dx), dot(dy,dy)), 0.5) * 10;
}


float RealCurvature(float3 normal, float3 position, float Pow)
{
    const float a = DDCrossLength(normal) / (DDCrossLength(position) + 0.00001);
    return pow(a, Pow);
}

float RealCurvature01(float3 normal, float3 position, float Pow)
{
    return ExpRemap01(RealCurvature(normal, position, Pow));
}

float SignedCurvature(float3 normal, float3 position, float Multiplier)
{
    const float3 a = ddx_fine(normal);
    const float3 b = ddy_fine(normal);
    const float c = length(cross(a, b));
    const float d = DDCrossLength(position) + 0.00001;
    const float sign = (a.x + b.y) >= 0 ? 1 : - 1;
    return clamp(tanh((c * sign / d) * Multiplier * 0.01), -1, 1);
}

// UV ------------------

// float2 MirrorUVDeprecated(float2 uv)
// {
//     return 1 - abs(frac(uv * 0.5) * 2 - 1);
// }
// Better Optimized !?
float2 MirrorUV(float2 uv)
{
    return abs(floor(uv) % 2 - frac(uv));
}

float SinAcos(float x) // returns sin(acos(x));
{
    return sqrt(1 - x * x);
}

float3 NormalReconstructZ(float2 In)
{
    return normalize(float3(In.xy, sqrt(1 - saturate(dot(In.xy, In.xy)))));
}

int GetTransparencyMask(float depth, float zPosition)
{
    return depth <= zPosition ? 1 : 0;
}

float sqr(float a) { return a*a; }
float2 sqr(float2 a){ return a*a; }
float3 sqr(float3 a){ return a*a; }
float4 sqr(float4 a){ return a*a; }

float cube(float a){ return a*a*a; }
float2 cube(float2 a){ return a*a*a; }
float3 cube(float3 a){ return a*a*a; }
float4 cube(float4 a){ return a*a*a; }



// TanH Approximations Approx
float SoftSign(float x)
{
    return x / (1 + abs(x));
}


float4 SampleBiquadraticTexture(Texture2D tex, float2 coord, float LOD){
    float2 xy = coord * _ScreenSize.xy;
    float2 ic = floor(xy);
    float2 fc = frac(xy);
    float2 weights[2], offsets[2];
    BiquadraticFilter(1 - fc, weights, offsets); // Inverse-translate the filter centered around 0.5
    float2 size = rcp(_ScreenSize.xy / (exp2(LOD) * _RTHandleScale));
    // Apply the viewport scale right at the end.
    const SamplerState smp = s_trilinear_clamp_sampler;
    return weights[0].x * weights[0].y * SAMPLE_TEXTURE2D_X_LOD(tex, smp, (ic + float2(offsets[0].x, offsets[0].y)) * size, LOD)  // Top left
         + weights[1].x * weights[0].y * SAMPLE_TEXTURE2D_X_LOD(tex, smp, (ic + float2(offsets[1].x, offsets[0].y)) * size, LOD)  // Top right
         + weights[0].x * weights[1].y * SAMPLE_TEXTURE2D_X_LOD(tex, smp, (ic + float2(offsets[0].x, offsets[1].y)) * size, LOD)  // Bottom left
         + weights[1].x * weights[1].y * SAMPLE_TEXTURE2D_X_LOD(tex, smp, (ic + float2(offsets[1].x, offsets[1].y)) * size, LOD); // Bottom right
}

float4 SampleTriquadraticTexture(Texture2D tex, float2 coord, float LOD)
{
    const uint2 Lods = uint2(floor(LOD), ceil(LOD));
    const uint2 exps = exp2(Lods);
    return lerp( SampleBiquadraticTexture(tex, coord / exps.x, Lods.x), SampleBiquadraticTexture(tex, coord / exps.y, Lods.y), frac(LOD));
}

/// Returns 1 if inside UV Square
float InsideUVSquare(float2 uv) 
{
    return uv.x <= 1 & uv.y <= 1 & uv.x >= 0 & uv.y >= 0;
}

struct CustomBufferData
{
    float3 normal;
    float curvature;
    bool curvatureMask;
    bool transparentMask;
    bool visibleTransparentMask;
    bool transparentMaskAll;
    bool opaqueMask;
    bool opaqueBehindtransparentMask;
};

struct SSData
{
    float depth;
    float linearDepth;
    float3 positionWS;
    float3 viewDirWS;
    float3x3 worldToViewNormalFixMatrix; // For Better Reflections
    float3 normalVSFixed;
    float3 normalVS;
};

void GetCustomBufferData(float4 customBuffer, float customDepth, float depth, out CustomBufferData data)
{
    float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
    float linearCustomDepth = LinearEyeDepth(customDepth, _ZBufferParams);
    data.normal = NormalReconstructZ(customBuffer.xy);
    data.curvature = abs(customBuffer.z);
    data.transparentMaskAll = customDepth != 0;
    data.visibleTransparentMask = linearDepth > min(linearCustomDepth, linearDepth);
    data.transparentMask = linearDepth > max(linearCustomDepth, 0);
    data.opaqueMask = depth != 0;
    data.opaqueBehindtransparentMask = data.opaqueMask && data.visibleTransparentMask;
    data.curvatureMask = pow(data.curvature, 0.25) > 0.1;
}

SSData GetScreenSpaceData(float2 positionCS, float2 SSuv, BSDFData bsdfData)
{
    SSData data;
    data.depth = GetDepth(SSuv);
    data.linearDepth = LinearEyeDepth(data.depth, _ZBufferParams);
    data.normalVS = TransformWorldToViewDir(bsdfData.normalWS);
    const float2 positionNDC = positionCS * _ScreenSize.zw + (0.5 * _ScreenSize.zw); // Should we precompute the half-texel bias? We seem to use it a lot.
    data.positionWS = ComputeWorldSpacePosition(positionNDC, data.depth, UNITY_MATRIX_I_VP); // Jittered
    data.viewDirWS = GetWorldSpaceNormalizeViewDir(data.positionWS);
    data.worldToViewNormalFixMatrix = float3x3(cross(data.viewDirWS, GetViewUpDir()), - cross(data.viewDirWS, cross(GetViewUpDir(), GetViewForwardDir())), data.viewDirWS); // Fixed View Transformation Matrix
    data.normalVSFixed = normalize(mul(data.worldToViewNormalFixMatrix, bsdfData.normalWS));
    return data;
}


float unlerp(float A, float B, float T)
{
    return (T - A)/(B - A);
}
float2 unlerp(float2 A, float3 B, float T)
{
    return (T - A)/(B - A);
}
float3 unlerp(float3 A, float3 B, float T)
{
    return (T - A)/(B - A);
}
float4 unlerp(float4 A, float4 B, float T)
{
    return (T - A)/(B - A);
}



// float3 ComputeNormalsFromDepth(float2 uv, float radius, float depth)
// {
//     float realRadius = radius / depth;
//     realRadius = 10;
//     float a = LinearEyeDepth(SampleCustomDepth(uv - float2(_ScreenSize.z * realRadius, 0)), _ZBufferParams);
//     float b = LinearEyeDepth(SampleCustomDepth(uv - float2(0, _ScreenSize.w * realRadius)), _ZBufferParams);
//     float c = LinearEyeDepth(SampleCustomDepth(uv + float2(_ScreenSize.z * realRadius, 0)),_ZBufferParams);
//     float d = LinearEyeDepth(SampleCustomDepth(uv + float2(0, _ScreenSize.w * realRadius)), _ZBufferParams);
//     float2 dx = float2(a, b) - float2(c, d);
//     dx /= realRadius * depth;
//     float3 normal = normalize(cross(float3(_ScreenSize.z, 0 ,dx.x), float3(0, _ScreenSize.w, dx.y)));
//     return normal;
// }


#endif // SSGIUTILS_INCLUDED