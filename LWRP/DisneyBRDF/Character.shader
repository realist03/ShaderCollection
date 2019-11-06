Shader "Lightweight Render Pipeline/Character"
{
    Properties
    {
        _BaseColorMap("BaseColor",2D) = "white"{}
        [Toggle(_NORMALMAP)] _NORMALMAP("_NORMALMAP", Int) = 1.0
        _NormalMap("NormalMap",2D) = "bump"{}
        _DataMap("M",2D) = "gray"{}
        _SkinLUT("SkinLUT",2D) = "black"{}

    }
    SubShader
    {
        Tags {  "RenderPipeline"="LightweightPipeline" "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP

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

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

			#include "DisneyBRDF.hlsl"
            #include "DisneyForwardPass.hlsl"

            ENDHLSL
        }
    }
}
