Shader "LWRP/Character_Hair"
{
    Properties
    {
        _BaseColorMap("BaseColor",2D) = "gray"{}
        [HideInInspector]_ShiftTangentMap("ShiftTangentMap",2D) = "gray"{}
        [HideInInspector]_DitherPattern("DitherPattern",2D) = "gray"{}
        _Metallic("Metallic",FLoat) = 0.3
        _Roughness("Roughness",FLoat) = 0.3
        _Transmission("Transmission",FLoat) = 0.3
        [Space(10)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
        [Toggle(_RECIVESHADOW)]_RECIVESHADOW("Recive Shadow",FLoat) = 1
        [Toggle(_ALPHATEST_ON)]_ALPHATEST_ON("AlphaTest",Float) = 1
        _Cutoff("Cutoff",Range(0,1)) = 0.333

        [Space(10)]
        _ShiftT("ShiftT",Float) = 0.1

        [Space(10)]
        _Power1("Power1",Float) = 100
        _Strength1("Strength1",Range(0,0.3)) = 0.05
        
        [Space(10)]
        _Power2("Power2",Float) = 200
        _Strength2("Strength2",Range(0,0.3)) = 0.1

        _w("w",Range(0,1)) = 0.5
        _scatterColor("ScatterColor",Color) = (1,1,1)
        [Toggle(_USEDITHER)]_USEDITHER("Use Dither",Float) = 1
        _dither("DitherStrength",Range(0,1)) = 0.5
        _ditherThrohold("DitherThrohold",Range(0,1)) = 0.5
        _ditherTile("DitherTile",Float) = 1
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "LightweightPipeline" "IgnoreProjector" = "True"}
        
        Cull[_Cull]

        Pass
        {
            HLSLPROGRAM
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _USEDITHER
            #pragma shader_feature _RECIVESHADOW
            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ _OPTIMIZE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment HairPassFragment
            
            #include "HairInput.hlsl"
            #include "HairForwardPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            #include "HairInput.hlsl"

            float3 _LightDirection;

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = input.texcoord;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            float4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                #ifdef _ALPHATEST_ON
                    return SAMPLE_TEXTURE2D(_BaseColorMap,sampler_BaseColorMap,input.uv).a;
                #else
                    return 0;
                #endif
            }
            ENDHLSL
        }

    }
}
