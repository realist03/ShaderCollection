Shader "Lightweight Render Pipeline/ShadowOnlyPlane"
{
    Properties
    {
        _ShadowStrength("ShadowStrength",Range(0,1)) = 0.5
        _Cutoff("Cutoff",Range(0,1)) = 0
    }
    SubShader
    {
        Tags {"RenderType" = "Transparent" "RenderQueue" = "Transparent" "RenderPipeline" = "LightweightPipeline" "IgnoreProjector" = "True"}
        ZWrite Off
        Blend One OneMinusSrcAlpha
        Pass
        {

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowOnlyVertex
            #pragma fragment ShadowOnlyFragment
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                float4 shadowCoord  : TEXCOORD1;
            };
            float _Cutoff;
            float _ShadowStrength;
            Varyings ShadowOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                return output;
            }

            half4 ShadowOnlyFragment(Varyings input):SV_Target
            {
                Light light = GetMainLight(input.shadowCoord);
                float shadow = light.shadowAttenuation;
                float shadowAlpha = (1 - shadow) * _ShadowStrength;
                clip(shadowAlpha - _Cutoff);
                return  half4(0,0,0,shadowAlpha);
            }

            ENDHLSL
        }

    }
    FallBack "Hidden/InternalErrorShader"
}
