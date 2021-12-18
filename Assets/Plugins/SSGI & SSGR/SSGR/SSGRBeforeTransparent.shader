Shader "Hidden/Shader/SSGRBeforeTransparent"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
    
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
    
    TEXTURE2D_X(_InputTexture);
    // Texture2D _NormalTex;
    // Texture2D customDepth;

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        UNITY_VBUFFER_INCLUDED

        uint2 SSuv = input.texcoord * _ScreenSize.xy;
        const float2 uv = input.texcoord * _RTHandleScale;
        const float4 inColor = float4(LOAD_TEXTURE2D_X(_InputTexture, SSuv).xyz, 1);

        const float depth = GetDepth(SSuv);
        float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
        
        float4 CustomBuffer = SampleCustomColor(input.texcoord);
        float CustomDepth = SampleCustomDepth(input.texcoord); // Don't forget to linearize the depth
        
        CustomBufferData data;
        GetCustomBufferData(CustomBuffer, CustomDepth, depth, data);


        
        // bool curvatureMask = pow(data.curvature, 0.25) > 0.1; //

        float3 BackNormals = data.normal;
        
        // return CustomBuffer.xyzz;
        // return data.curvatureMask;
        // return
        // return poi;
        BSDFData bsdfData;
        BuiltinData unused;
        DecodeFromGBuffer(SSuv, UINT_MAX, bsdfData, unused);

        const SSData ssData = GetScreenSpaceData(input.positionCS, SSuv, bsdfData);

        // return RealCurvature01(data.normal, ssData.positionWS, 4);
        bool CurvatureMask = RealCurvature01(data.normal, ssData.positionWS, 4) > 0.01;
        // return RealCurvature01(data.normal, ssda)
        // return data.curvature;
        if(data.opaqueBehindtransparentMask && CurvatureMask) // Only display onto geometry
        {
            const uint MaxSceneLOD = _ColorPyramidLodCount - 1;
            
            BSDFData bsdfData;
            BuiltinData unused;
            DecodeFromGBuffer(SSuv, UINT_MAX, bsdfData, unused);

            // Get View Direction
            const float2 positionNDC = input.positionCS * _ScreenSize.zw + (0.5 * _ScreenSize.zw); // Should we precompute the half-texel bias? We seem to use it a lot.
            const float3 positionWS = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP); // Jittered
            float3 viewDir = GetWorldSpaceNormalizeViewDir(positionWS);

            // View Normals Fix
            const float3x3 ViewMatrix = float3x3(cross(viewDir, GetViewUpDir()), - cross(viewDir, cross(GetViewUpDir(), GetViewForwardDir())), viewDir); // Fixed View Transformation Matrix
            float3 normalVS = normalize(mul(ViewMatrix, bsdfData.normalWS)); // Fixes View Normals
            // float3 normalVSBad = TransformWorldToViewDir(bsdfData.normalWS); // Default View Normals // DO NOT USE // Causes bad reflections

            
            
            // if (data.transparentMask) // Normals from transparent geometry are not in the sampled normal buffer, thus needing to be fetched from a custom pass
            // {
            //     // const float3 NormalColor = normalize(mul(ViewMatrix, SAMPLE_TEXTURE2D_X(_NormalTex, s_trilinear_clamp_sampler, input.texcoord)));
            //     normalVSBad = data.normal;
            //     normalVS = data.normal;
            // }
            
            float3 Albedo = saturate(bsdfData.diffuseColor); // saturate(SampleAlbedo(uv, input));
            float Roughness = bsdfData.roughnessB;
            const float SSAO = SampleSSAO(uv);
            const float SurfaceAO = bsdfData.specularOcclusion; // SpecularOcclusion instead of AmbientOcclusion in Deferred rendering
            
            const float FresnelReversed = saturate(normalVS.z);
            const float Fresnel = saturate(1- normalVS.z);
            
            float SpecularOcclusionSSAO = GetSpecularOcclusionFromAmbientOcclusion(FresnelReversed, 1 - SSAO, Roughness) * SurfaceAO;

            SpecularOcclusionSSAO *= bsdfData.specularOcclusion;

            const float MicroFacedMask = rcp(0.5f + 0.5f * sqrt(1 + Sq(Roughness) * (rcp(Sq(FresnelReversed + 0.001f)) - 1)));//  saturate(G_MaskingSmithGGX(FresnelReversed, Roughness));
            // const float GGX = D_GGX(FresnelReversed, Roughness);
            
            float p = length(normalVS.xy);
            float r = 1 - sqrt(1 - p*p);
            r *= 2;
            float q  = Sq(FresnelReversed);
            float2 NewUVs = uv + normalize(normalVS.xy) * q * rcp(linearDepth) * _Distortion * 800 * _ScreenSize.zw;
            float2 NewUVs2 = uv + normalize(normalVS.xy) * p * r * rcp(linearDepth) * _InnerDistortion * 800 * _ScreenSize.zw;

            
            float2 RemappingConstant = 800 * _ScreenSize.zw * rcp(linearDepth + 1);
            float Angle = (1 - length(normalVS.xy)) * HALF_PI;
            float AngleBack = (1 - length(BackNormals.xy)) * HALF_PI;
            float2 NormalDirection = normalize(normalVS.xy);
            float2 ExternalDistortionFactor = abs(sin(Angle) / cos(2 * Angle)) * _Distortion * RemappingConstant;
            float2 InternalDistortionFactor = abs(cos(Angle) * tan(2 * Angle)) * _InnerDistortion * RemappingConstant;
            float2 BackDistortionFactor = abs(cos(AngleBack) * tan(2 * AngleBack)) * _Distortion * RemappingConstant;
            InternalDistortionFactor = clamp(InternalDistortionFactor,-20, 20);
            NewUVs = uv + NormalDirection * ExternalDistortionFactor;
            NewUVs2 = uv + NormalDirection * InternalDistortionFactor;
            // float2 NewUVs3 = uv + normalize(NormalReconstructZ(CustomBuffer.xy)) * BackDistortionFactor;

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
            Reflectiveness *=
                smoothstep(0, _EdgeSoftness, float2(Squircle(NewUVs),Squircle(NewUVs2)))
                *  (_FresnelPower <= 0 ? 1 : pow(Fresnel, _FresnelPower));

            Reflectiveness *= MicroFacedMask;

            
            
            float Blur = lerp(Roughness, 0, lerp(0, pow(Fresnel, 2), _FresnelReflection)); // Apply  Fresnel Effect
            Blur = lerp(_MinMaxBlur.x, _MinMaxBlur.y, Blur) * (rcp(max(log2(linearDepth + 1), 0.001))+1); // Blur Remapping
            
            Blur *= MaxSceneLOD; // Max Scene View Texture Blur
            Blur = clamp(Blur, 0, MaxSceneLOD);
            InsideBlur = lerp(Blur, MaxSceneLOD, saturate(clamp(abs(cos(Angle) * tan(2 * Angle)),0, 2.5) * 0.4));
            
            if (_RemoveInvisible == 1){
                const float3 ReflectedNormals = normalize(mul(ViewMatrix, GetNormal(NewUVs * _PostProcessScreenSize)));
                const float3 ReflectedNormals2 = normalize(mul(ViewMatrix, GetNormal(NewUVs2 * _PostProcessScreenSize)));
                // Reflectiveness.x *= - saturate(dot(normalVS, ReflectedNormals) / 0.1);
                Reflectiveness.y *= saturate(- dot(normalVS, ReflectedNormals2) / 0.1);
            }
            
            if(_RemoveUnwanted){
                // Reflectiveness.x *= saturate( - (linearDepth - GetDepthLinear(NewUVs * _ScreenSize) - 0.002));
                Reflectiveness.y *= saturate((linearDepth - GetDepthLinear(NewUVs2 * _PostProcessScreenSize) - 0.002)) ; // -0.002 prevents self reflection
            }

            // return float4(VisibleFromReflection.xxx, 1);

            const float3 ReflectionSide = GetCamColorLOD(NewUVs, Blur, 0) * Reflectiveness.x; //* VisibleFromReflection; // Weigh by Roughness ?
            const float3 ReflectionFront = GetCamColorLOD(NewUVs2, InsideBlur, 0) * Reflectiveness.y; // Weigh by Roughness ?
            // const float3 ReflectionBack = GetCamColorLOD(NewUVs3, Blur, 0); // Weigh by Roughness ?
            float3 Reflections = lerp(ReflectionFront, ReflectionSide, smoothstep(_SmoothEdge, _SmoothEdge + 0.1, Fresnel));
            // Reflections += ReflectionBack * 0.5 * data.transparentMask;
            Reflections *= SpecularOcclusionSSAO;
            Reflections *= lerp(Albedo, 0.5, Fresnel) * _Intensity * 10;
            Reflections *= _Intensity * Sq(SpecularOcclusionSSAO);
            Reflections *= 2; // 0 - 1 Remapping Part 1
            Reflections /= Reflections + 1; // 0 - 1 Remapping Part 2
            
            return float4(inColor + Reflections, 1) ; // Final Blend // * cube(1-SampleSSAO(uv))

        }
        // return AbsCurvature;
        return inColor;
        
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "SSGRBeforeTransparent"

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
