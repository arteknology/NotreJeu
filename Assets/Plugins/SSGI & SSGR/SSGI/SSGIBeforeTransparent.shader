Shader "Hidden/Shader/SSGIBeforeTransparent"
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
        uint2 SSuv = input.texcoord * _ScreenSize.xy;

        const float depth = GetDepth(SSuv);
        const float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
        
        const float2 uv = input.texcoord * _RTHandlePostProcessScale;
        const float4 inColor = float4(LOAD_TEXTURE2D_X(_InputTexture, SSuv).xyz, 1);

        /// -------------------------------------

        float4 CustomBuffer = SampleCustomColor(input.texcoord); // Works !
        float CustomDepth = SampleCustomDepth(input.texcoord); // Works !

        CustomBufferData data;
        GetCustomBufferData(CustomBuffer, CustomDepth, depth, data);
        // return data.opaqueBehindtransparentMask;
        
        if(data.opaqueBehindtransparentMask) // Only display SSGI Behind Transparent
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
            // Albedo *= saturate(GetCamColorLOD(uv, 0, 0));


            // Fixes For Transparent Materials
            // const bool IsTransParent = data.transparentMask;
            // GetStencilValue()

            // if (IsTransParent){
            //     Albedo = saturate(GetCamColorLOD(uv, 5, 0));
            //
            //     normalVS = normalVSTransparent;
            //     Roughness = 0.95;
            //     AO = 0;
            // }
            // else{
            //     AO *= bsdfData.specularOcclusion;
            // }

            AO *= bsdfData.specularOcclusion;
            // return AO;
            
            // Displacement
            float2 NormalOffset = GetNormalOffset(normalVS, _NormalBias) * Roughness; // Roughness influences the offset sampling vector // mimics reflections
            float4x2 offsets = {InBetweenValuesOffset.xx, InBetweenValuesOffset.yy, InBetweenValuesOffset.zz, InBetweenValuesOffset.ww};
            offsets *= float4x2(NormalOffset,NormalOffset,NormalOffset,NormalOffset);
            offsets += float4x2(uv,uv,uv,uv);

             // // Color Matrix Building
             // float4x3 ColorMatrix = {
             //     (GetCamColorLOD(offsets[0], LODWeights.x, _Filtering)),
             //     (GetCamColorLOD(offsets[1], LODWeights.y, _Filtering)),
             //     (GetCamColorLOD(offsets[2], LODWeights.z, _Filtering)),
             //     (GetCamColorLOD(offsets[3], LODWeights.w, _Filtering))
             // };

            float4x3 ColorMatrix = 0;
            for (int i = 0; i< 4; i++){
                ColorMatrix[i] = GetCamColorLOD(offsets[i], LODWeights[i], _Filtering) * 2;
            }

            float3 GI = mul(float(2).xxxx, ColorMatrix); // Add All Rows together
            // float3 GI = poop;

            // Final Compositing
            GI = max(0, GI - inColor); // Removes Color Overshoot
            GI *= 1 - _AOStrength * AO; // AO Influence


            GI *= _Intensity;
            GI /= dot(GI+1, 1); // GI Remapping : atan function approximation
            // GI = saturate(GI);
            // GI *= 4;
            // GI *= Albedo * saturate(GetCamColorLOD(uv, 0, 0));
            GI *= Albedo;
            // GI *= Albedo * _Intensity; // Multiplying Bounced Light by Surface Color
            
            
            GI *= lerp(1, Roughness, _RoughnessInfluence); // Roughness Influence
            GI += Albedo * _DiffuseIntensity; //In case darkness is overwhelming
            return float4(inColor + GI * lerp((dot((GI), 1)) , 1, _Diffusion-1), 1);


        }
        return inColor;
         
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "SSGIBeforeTransparent"

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
