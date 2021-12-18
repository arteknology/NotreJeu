Shader "Hidden/Shader/SSGR"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    // #include "UnityCG.cginc"
    // #include "Packages/com.unity.render-pipelines.high-dynamic/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Assets/Plugins/SSGI & SSGR/HLSL/SSGIUtils.cginc"


    // #pragma vertex Vert

    #define ATTRIBUTES_NEED_NORMAL
    #define VARYINGS_NEED_NORMAL_WS
    
 
    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct SurfaceDescriptionInputs
    {
        float3 WorldSpaceNormal;
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    CBUFFER_START(UnityPerMaterial)
    CBUFFER_END
    
    // Properties
    float _Intensity = 1;
    float _FresnelReflection = 0.25;
    float2 _MinMaxBlur = float2(0, 1);
    float _Distortion = 1;
    float _InnerDistortion = 1;
    float _FresnelPower = 3;
    float _SmoothEdge = 4;
    float _EdgeSoftness = 0.5;
    float _Filtering;
    float _ClampUVs = 0;
    float _RemoveInvisible = 0;
    float _RemoveUnwanted = 0;
    float _BackReflections = 1;
    
    TEXTURE2D_X(_InputTexture);
    Texture2D _NormalTex;
    Texture2D customDepth;

    StructuredBuffer<float4> _PoopTexture;
    

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        UNITY_VBUFFER_INCLUDED

        uint2 SSuv = input.texcoord * _ScreenSize.xy;
        float2 uv = input.texcoord * _RTHandleScale;
        //uv = ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord) * 0.5f;
        const float4 inColor = float4(LOAD_TEXTURE2D_X(_InputTexture, SSuv).xyz, 1);

        const float depth = GetDepth(SSuv);
        float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
        
        float4 CustomBuffer = SampleCustomColor(input.texcoord);
        float CustomDepth = LinearEyeDepth(SampleCustomDepth(input.texcoord), _ZBufferParams); // Don't forget to linearize the depth

        CustomBufferData data;
        GetCustomBufferData(CustomBuffer, CustomDepth, linearDepth, data);

        // return data.opaqueMask; // Shitty
        // return data.opaqueBehindtransparentMask;
        if(data.curvatureMask) // Only display onto geometry
        {
            const uint MaxSceneLOD = _ColorPyramidLodCount - 1;
            
            BSDFData bsdfData;
            BuiltinData unused;
            DecodeFromGBuffer(SSuv, UINT_MAX, bsdfData, unused);

            const SSData ssData = GetScreenSpaceData(input.positionCS, SSuv, bsdfData);
            

            // ViewDirWS Normals
            float3 normalVS = ssData.normalVSFixed; // Best For Randomly Curved Objects
            // float3 normalVSRaw = ssData.normalVS; // Best For Single Axis Curved Surfaces like Cylinders
            
            float3 normalBackFace = data.normal; // Backface Normals using custom pass before transparent // Helps with rendering bottles
            
            if (data.transparentMask) // Normals from transparent geometry are not in the sampled normal buffer, thus needing to be fetched from a custom pass
            {
                // normalVSRaw = data.normal;
                normalVS = data.normal;
                // normalVS = bsdfData.normalWS;
                // return normalVS.xyzz;
            }
            
            float3 Albedo = saturate(bsdfData.diffuseColor); // saturate(SampleAlbedo(uv, input));
            float Roughness = bsdfData.perceptualRoughness;
            const float SSAO = SampleSSAO(uv);
            const float SurfaceAO = bsdfData.specularOcclusion; // SpecularOcclusion instead of AmbientOcclusion in Deferred rendering

            const float FresnelReversed = saturate(normalVS.z);
            const float Fresnel = saturate(1- normalVS.z);

            
            
            float SpecularOcclusionSSAO = GetSpecularOcclusionFromAmbientOcclusion(FresnelReversed, 1 - SSAO, Roughness) * SurfaceAO;
            
            if (data.transparentMask){
                Albedo = (GetCamColorLOD(uv, 0, 0));

                // normalVS = normalVSTransparent;
                Roughness = 0.05;
                SpecularOcclusionSSAO = 1;
            }
            else{
                SpecularOcclusionSSAO *= bsdfData.specularOcclusion;
            }

            const float MicroFacedMask = rcp(0.5f + 0.5f * sqrt(1 + Sq(Roughness) * (rcp(Sq(FresnelReversed + 0.001f)) - 1)));//  saturate(G_MaskingSmithGGX(FresnelReversed, Roughness));
            const float GGX = D_GGX(FresnelReversed, Roughness);

            float p = length(normalVS.xy);
            float r = 1 - sqrt(1 - p*p);
            r *= 2;
            float q  = Sq(FresnelReversed);
            
            float2 RemappingConstant = 800 * _ScreenSize.zw; //* rcp(linearDepth + 1);
            float Angle = (1 - length(normalVS.xy)) * HALF_PI;
            float AngleBack = (1 - length(normalBackFace.xy)) * HALF_PI;
            float2 NormalDirection = normalize(normalVS.xy);
            float2 ExternalDistortionFactor = abs(sin(Angle) / cos(2 * Angle)) * _Distortion * RemappingConstant;
            float2 InternalDistortionFactor = abs(cos(Angle) * tan(2 * Angle)) * _InnerDistortion * RemappingConstant;
            float2 BackDistortionFactor = abs(cos(AngleBack) * tan(2 * AngleBack)) * _Distortion * RemappingConstant;
            InternalDistortionFactor = clamp(InternalDistortionFactor,-20, 20);

            float2 NewUVs = uv + normalize(normalVS.xy) * q * rcp(linearDepth) * _Distortion * 800 * _ScreenSize.zw;
            float2 NewUVs2 = uv + normalize(normalVS.xy) * p * r * rcp(linearDepth) * _InnerDistortion * 800 * _ScreenSize.zw;
            NewUVs = uv + NormalDirection * ExternalDistortionFactor;
            NewUVs2 = uv + NormalDirection * InternalDistortionFactor;
            
            float2 NewUVs3 = uv + normalize(NormalReconstructZ(CustomBuffer.xy)) * BackDistortionFactor;

            float InsideBlur =  (1 - InsideUVSquare(NewUVs2)) * (1 + clamp(abs(cos(Angle) * tan(2 * Angle)), 0, 10) * 10 * _InnerDistortion);
            InsideBlur = clamp(InsideBlur, 5, 10);
            
            
            
            float2 Reflectiveness = 1;
            
            if(_ClampUVs == 1){
                Reflectiveness.x = InsideUVSquare(NewUVs);
                Reflectiveness.y = InsideUVSquare(NewUVs2);
            } else {
                NewUVs = MirrorUV(NewUVs);
                NewUVs2 = MirrorUV(NewUVs2);
            }

            

            // Softens UV Edges
            Reflectiveness *= smoothstep(0, _EdgeSoftness, float2(Squircle(NewUVs),Squircle(NewUVs2)))
                                * (_FresnelPower <= 0 ? 1 : pow(Fresnel, _FresnelPower))
                                * MicroFacedMask;
            
            
            float Blur = lerp(Roughness, 0, lerp(0, pow(Fresnel, 2), _FresnelReflection)); // Apply  Fresnel Effect
            Blur = lerp(_MinMaxBlur.x, _MinMaxBlur.y, Blur) * (rcp(max(log2(linearDepth + 1), 0.001))+1); // Blur Remapping
            
            Blur *= MaxSceneLOD; // Max Scene View Texture Blur
            Blur = clamp(Blur, 0, MaxSceneLOD);
            InsideBlur = lerp(Blur, MaxSceneLOD, saturate(clamp(abs(cos(Angle) * tan(2 * Angle)),0, 2.5) * 0.4));
            
            if (_RemoveInvisible == 1){
                const float3 ReflectedNormals = normalize(mul(ssData.worldToViewNormalFixMatrix, GetNormal(NewUVs * _PostProcessScreenSize)));
                const float3 ReflectedNormals2 = normalize(mul(ssData.worldToViewNormalFixMatrix, GetNormal(NewUVs2 * _PostProcessScreenSize)));
                // Reflectiveness.x *= - saturate(dot(normalVS, ReflectedNormals) / 0.1);
                Reflectiveness.y *= saturate(- dot(normalVS, ReflectedNormals2) / 0.1);
            }
            
            if(_RemoveUnwanted){
                // Reflectiveness.x *= saturate( - (linearDepth - GetDepthLinear(NewUVs * _ScreenSize) - 0.002));
                Reflectiveness.y *= saturate((linearDepth - GetDepthLinear(NewUVs2 * _PostProcessScreenSize) - 0.002)) ; // -0.002 prevents self reflection
            }

            const float3 ReflectionSide = GetCamColorLOD(NewUVs, Blur, 0) * Reflectiveness.x; //* VisibleFromReflection; // Weigh by Roughness ?
            const float3 ReflectionFront = GetCamColorLOD(NewUVs2, InsideBlur, 0) * Reflectiveness.y; // Weigh by Roughness ?
            const float3 ReflectionBack = GetCamColorLOD(NewUVs3, Blur, 0); // Weigh by Roughness ?
            float3 Reflections = lerp(ReflectionFront, ReflectionSide, smoothstep(_SmoothEdge, _SmoothEdge + 0.1, Fresnel));
            if(_BackReflections > 0.5) // Could Be Optimized Further
            {
                Reflections += ReflectionBack * 0.5 * data.transparentMask;
            }

            Reflections *= SpecularOcclusionSSAO;
            Reflections *= lerp(Albedo, 0.5, Fresnel) * _Intensity * 10; 
            
            return float4(inColor + Reflections * _Intensity * (Sq(SpecularOcclusionSSAO)), 1) ; // Final Blend // * cube(1-SampleSSAO(uv))

        }
        // return AbsCurvature;
        return inColor;
        
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "SSGR"

            ZWrite off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}
