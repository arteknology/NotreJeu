Shader "Hidden/Shader/SSGI"
{
    
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
    
    #include "Assets/Plugins/SSGI & SSGR/HLSL/SSGIUtils.cginc"
    // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/ScreenSpaceLighting/GTAOCommon.hlsl"

    
 
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

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    // SSGI Properties
    float _Intensity = 1;
    float _AOStrength = 1;
    float _DiffuseIntensity = 0;
    float _RoughnessInfluence = 1;
    float _NormalBias = 4;
    float2 _MinMax;
    float _Diffusion = 1;
    uint _Filtering = 0;
    
    
    TEXTURE2D_X(_InputTexture);
    // Texture2D _NormalTex;
    // Texture2D _DepthTex;
    // TEXTURE2D_X(_MultiAmbientOcclusionTexture);
    

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        uint2 SSuv = input.texcoord * _PostProcessScreenSize .xy;
        // SSuv = ClampAndScaleUVPostProcessTextureForPoint(input.texcoord * _ScreenSize);

        const float depth = GetDepth(SSuv);
        const float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
        
        // SSuv = ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord, _PostProcessScreenSize);
        const float2 uv = input.texcoord * _RTHandleScale;
        const float4 inColor = float4(LOAD_TEXTURE2D_X(_InputTexture, SSuv).xyz, 1);
        // const float4 NormalColor = float4(SAMPLE_TEXTURE2D_X_LOD(_NormalTex, s_trilinear_clamp_sampler, input.texcoord * _RTHandleScaleHistory, _Intensity).xyz, 1);

        // return inColor;

        /// Testing -------------------------
        
        // float2 TheUVS = input.texcoord / _RTHandleScale;
        // float D0 = SampleTriquadraticTexture(_DepthTex, TheUVS, 0);
        // float D1 = SampleTriquadraticTexture(_DepthTex, TheUVS, 1);
        // float D2 = SampleTriquadraticTexture(_DepthTex, TheUVS, 2);
        // float D3 = SampleTriquadraticTexture(_DepthTex, TheUVS, 3);
        // float D4 = SampleTriquadraticTexture(_DepthTex, TheUVS, 4);
        // float D5 = SampleTriquadraticTexture(_DepthTex, TheUVS, 5);
        // float D6 = SampleTriquadraticTexture(_DepthTex, TheUVS, 6);
        // float D7 = SampleTriquadraticTexture(_DepthTex, TheUVS, 7);
        // // return D2 / 10;
        // float4 T = (linearDepth - float4(D1, D2, D3, D4)) * float4(1, 0.5, 0.25, 0.125) * 0.5;
        // float3 T2 = (linearDepth - float3(D5, D6, D7)) * float3(0.5, 0.25, 0.25) * 0.5 * 0.5;
        // float AO = (dot(max(T, 0), 1) + dot(max(T2, 0), 1));
        // // AO = max(max(T.x, T.y), max(T.z, T.w));
        // AO = 1 - ((tanh(AO)) * 0.5 + 0.5);

        /// -------------------------------------

        float4 CustomBuffer = SampleCustomColor(input.texcoord); // Works !
        float CustomDepth = LinearEyeDepth(SampleCustomDepth(input.texcoord), _ZBufferParams); // Works !

        // return CustomDepth;
        
        if(depth != 0) // Only display SSGI onto geometry
        {
            // Variables
        
            const uint MaxSceneLOD = _ColorPyramidLodCount - 1;

            const float2 MinMaxWeights = _MinMax * rcp(max(abs(log2(linearDepth +3)), 0.001)) * rcp(MaxSceneLOD);
            const float4 InBetweenValuesLOD = GetInBetweenValues(MinMaxWeights) * max(_ScreenSize.x, _ScreenSize.y)  * 0.001;
            const float4 LODWeights = min(InBetweenValuesLOD, MaxSceneLOD);
            const float4 InBetweenValuesOffset = InBetweenValuesLOD * InBetweenValuesLOD;

            // Used instead of sampling G Buffers for base color and roughness
            BSDFData bsdfData;

            BuiltinData unused;
            DecodeFromGBuffer(SSuv, UINT_MAX, bsdfData, unused);

            CustomBufferData data;
            GetCustomBufferData(CustomBuffer, CustomDepth, linearDepth, data);

            // return data.transparentMask > 0.5;

            // Get View Direction
            const float2 positionNDC = input.positionCS * _PostProcessScreenSize.zw + (0.5 * _PostProcessScreenSize.zw); // Should we precompute the half-texel bias? We seem to use it a lot.
            const float3 positionWS = ComputeWorldSpacePosition(positionNDC, linearDepth, UNITY_MATRIX_I_VP); // Jittered
            float3 viewDir = GetWorldSpaceNormalizeViewDir(positionWS);

            // View Normals Fix
            const float3x3 M2 = float3x3(normalize(cross(viewDir, GetViewUpDir())), GetViewUpDir(), viewDir); // Fixed View Transformation Matrix
            float3 normalVS = mul(M2, bsdfData.normalWS); // Fixes View Normals
            // float3 normalVSBad = TransformWorldToViewDir(bsdfData.normalWS); // Default View Normals // DO NOT USE // Causes bad reflections
            const float3 normalVSTransparent = data.normal;
            
            // Buffers
            float AO = SampleSSAO(uv);
            float3 Albedo = saturate(bsdfData.diffuseColor); // saturate(SampleAlbedo(uv, input));
            float Roughness = bsdfData.perceptualRoughness; // SampleRoughness(uv, input);


            // Fixes For Transparent Materials
            const bool IsTransParent = data.transparentMask;
            // GetStencilValue()


            // if (IsTransParent){
            //     // Albedo = saturate(GetCamColorLOD(uv, 5, 0));
            //     Albedo = 0.1;
            //
            //     normalVS = normalVSTransparent;
            //     Roughness = 0.95;
            //     AO = 0;
            // }
            // else{
            //     AO *= bsdfData.specularOcclusion;
            // }

            AO *= bsdfData.specularOcclusion;
            
            float2 NormalOffset = GetNormalOffset(normalVS, _NormalBias) * (0.5 * Roughness + 0.5); // Roughness influences the offset sampling vector // mimics reflections
            float4x2 offsets = {InBetweenValuesOffset.xx, InBetweenValuesOffset.yy, InBetweenValuesOffset.zz, InBetweenValuesOffset.ww};
            offsets *= float4x2(NormalOffset,NormalOffset,NormalOffset,NormalOffset);
            offsets += float4x2(uv,uv,uv,uv);

            //Color Matrix Building
            float4x3 ColorMatrix = {
                (GetCamColorLOD(offsets[0], LODWeights.x, _Filtering)),
                (GetCamColorLOD(offsets[1], LODWeights.y, _Filtering)),
                (GetCamColorLOD(offsets[2], LODWeights.z, _Filtering)),
                (GetCamColorLOD(offsets[3], LODWeights.w, _Filtering))
            };

            // ColorMatrix = pow(ColorMatrix, _Diffusion);
            // float3 GI = pow(mul(float4(1,1,1,1), ColorMatrix), rcp(_Diffusion)); // Add All Rows together
            float3 GI = mul(float(1).xxxx, ColorMatrix); // Add All Rows together

            // Final Compositing
            // GI = max(0, GI - inColor); // Removes Color Overshoot
            GI = max(GI, 0);
            GI *= 1 - _AOStrength * AO; // AO Influence


            GI *= _Intensity;
            // GI /= dot(GI+1, 1); // GI Remapping : atan function approximation
            // GI /= 4;
            // GI *= 2;
            GI *= Albedo;
            // GI *= Albedo * _Intensity; // Multiplying Bounced Light by Surface Color
            
            
            GI *= lerp(1, Roughness, _RoughnessInfluence); // Roughness Influence
            GI += Albedo * _DiffuseIntensity; //In case darkness is overwhelming
            
            
            return float4(inColor + GI * lerp(dot(GI, 1) , 1, _Diffusion-1), 1);


        }
        return inColor;
         
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "SSGI"

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
