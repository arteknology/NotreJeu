Shader "Hidden/Shader/AO"
{
    
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
    
    #include "Assets/Plugins/SSGI & SSGR/HLSL/SSGIUtils.cginc"
    #include "Assets/Plugins/SSGI & SSGR/HLSL/BoxOcclusion.cginc"

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

    float3 BoxCoords[8];
    int numTriangles = 10;
    float3 TrisA[10];
    float3 TrisB[10];
    float3 TrisC[10];
    float3 N;
    
    
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
        
        // SSuv = ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord, _PostProcessScreenSize);
        const float2 uv = input.texcoord * _RTHandlePostProcessScale;
        const float4 inColor = float4(LOAD_TEXTURE2D_X(_InputTexture, SSuv).xyz, 1);
        // const float4 NormalColor = float4(SAMPLE_TEXTURE2D_X_LOD(_NormalTex, s_trilinear_clamp_sampler, input.texcoord * _RTHandleScaleHistory, _Intensity).xyz, 1);



        float4 CustomBuffer = SampleCustomColor(input.texcoord); // Works !
        float CustomDepth = SampleCustomDepth(input.texcoord); // Works !

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
            GetCustomBufferData(CustomBuffer, CustomDepth, depth, data);

            // return data.transparentMask > 0.5;

            // Get View Direction
            const float2 positionNDC = input.positionCS * _ScreenSize.zw + (0.5 * _ScreenSize.zw); // Should we precompute the half-texel bias? We seem to use it a lot.
            float3 positionWS = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP); // Jittered
            float3 positionWS2 = GetAbsolutePositionWS(positionWS);
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

            // return bsdfData.normalWS.xyzz;
            // return positionWS2.xyzz;

            float occ = 0;
            for (int i = 0; i < numTriangles; i++)
            {
                occ = max(occ, triOcclusion(positionWS2, bsdfData.normalWS, TrisA[i], TrisB[i], TrisC[i]));
            }
            return occ;


            
            return saturate(triOcclusion(positionWS2, bsdfData.normalWS, float3(0,0,0), float3(1,0,0), float3(0.5,1,1)));
            // return 1 -OtherBoxOcclusion(positionWS2, bsdfData.normalWS, N, BoxCoords );
            // return NewBoxOcclusion(positionWS2, bsdfData.normalWS, float3(1,2,3), float3(0,0,-1), float3(0.3,1,0.5));

            return 1 -FinalBoxOcclusion(positionWS2, bsdfData.normalWS, float3(0,1,0), float3(1,1,0), float3(1,0,0));


            // float ao = 0;
            // [loop]
            // for (int i = 0; i < 16; i++)
            // {
            //     float2 r = input.texcoord;
            //     r = mad(InitRandom(r), 2, 1);
            //     
            //
            //     
            //     // ao += shit
            // }

            // Generate Sample Kernel

            // int kernelSize = 16;
            // float3 kernel[16];
            // int noiseSize = 16;
            // float3 noise[16];
            // float uNoiseScale = 1;
            // float uRadius = 1;
            //
            // for (int i = 0; i < kernelSize; ++i) {
            //     kernel[i] = float3(
            //     GenerateHashedRandomFloat(i) * 2 - 1,
            //     GenerateHashedRandomFloat(i + kernelSize) * 2 - 1,
            //     GenerateHashedRandomFloat(i + kernelSize * 2) * 2 - 1);
            //     normalize(kernel[i]);
            //     kernel[i] *= GenerateHashedRandomFloat(i + kernelSize * 3);
            //
            //     float scale = i / kernelSize;
            //     scale = lerp(0.1f, 1, scale * scale);
            //     kernel[i] *= scale;
            // }
            //
            //
            // // Generate Texture Noise
            // for (int i = 0; i < noiseSize; ++i) {
            //     noise[i] = float3(
            //     GenerateHashedRandomFloat(i) * 2 - 1,
            //     GenerateHashedRandomFloat(i + kernelSize) * 2 - 1,
            //         0
            //     );
            //     normalize(noise[i]);
            // }
            //
            // // SSAO
            //
            // float3 origin = viewDir * linearDepth;
            // float3 normal = bsdfData.normalWS;
            // normal = normalize(normal);
            //
            // // float3 rvec = texture(uTexRandom, input.texcoord * uNoiseScale).xyz * 2.0 - 1.0;
            // float3 rvec = float3(GenerateHashedRandomFloat(SSuv.x), GenerateHashedRandomFloat(SSuv.y), GenerateHashedRandomFloat(SSuv.x + SSuv.y)) * 2 - 1;
            // float3 tangent = normalize(rvec - normal * dot(rvec, normal));
            // float3 bitangent = cross(normal, tangent);
            // float3x3 tbn = float3x3(tangent, bitangent, normal);
            //
            // float occlusion = 0;
            // for (int i = 0; i < kernelSize; ++i) {
            // // get sample position:
            //    float3 sample = mul(tbn, kernel[i]);
            //    sample = sample * uRadius + origin;
            //   
            // // project sample position:
            //    float4 offset = float4(sample, 1);
            //    offset = mul(UNITY_MATRIX_I_VP, offset);
            //     // return offset;
            //    offset.xy /= offset.w;
            //    offset.xy = offset.xy * 0.5f + 0.5f;
            //   
            // // get sample depth:
            //    float sampleDepth = LinearEyeDepth( GetDepth( offset.xy ),_ZBufferParams).r; 
            //   
            // // range check & accumulate:
            //    float rangeCheck= abs(origin.z - sampleDepth) < uRadius ? 1 : 0; 
            //    occlusion += (sampleDepth <= sample.z ? 1 : 0) * rangeCheck;
            // }
            //
            // return occlusion;

            

            
            


            // Fixes For Transparent Materials
            const bool IsTransParent = data.transparentMask;
            // GetStencilValue()

            if (IsTransParent){
                // Albedo = saturate(GetCamColorLOD(uv, 5, 0));
                Albedo = 0.2;

                normalVS = normalVSTransparent;
                Roughness = 0.95;
                AO = 0;
            }
            else{
                AO *= bsdfData.specularOcclusion;
            }
            
            // Displacement
            float2 NormalOffset = GetNormalOffset(normalVS, _NormalBias) * Roughness; // Roughness influences the offset sampling vector // mimics reflections
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
            float3 GI = mul(float(2).xxxx, ColorMatrix); // Add All Rows together

            // Final Compositing
            GI = max(0, GI - inColor); // Removes Color Overshoot
            GI *= 1 - _AOStrength * AO; // AO Influence


            GI *= _Intensity;
            GI /= dot(GI+1, 1); // GI Remapping : atan function approximation
            GI *= 2;
            GI *= Albedo;
            // GI *= Albedo * _Intensity; // Multiplying Bounced Light by Surface Color
            
            
            GI *= lerp(1, Roughness, _RoughnessInfluence); // Roughness Influence
            GI += Albedo * _DiffuseIntensity; //In case darkness is overwhelming
            
            return float4(((inColor) + (GI)) * lerp((dot((GI), 1)) , 1, _Diffusion-1), 1);


        }
        return inColor;
         
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "AO"

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
