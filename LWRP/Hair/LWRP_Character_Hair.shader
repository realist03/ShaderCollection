Shader "LWRP/Character_Hair"
{
    Properties
    {
        _BaseColorMap("BaseColor",2D) = "gray"{}
        _ShiftTangentMap("_ShiftTangentMap",2D) = "gray"{}
        _Metallic("Metallic",FLoat) = 0.3
        _Roughness("Roughness",FLoat) = 0.3
        _Transmission("Transmission",FLoat) = 0.3
        _Cutoff("Cutoff",Range(0,1)) = 0.333
        _ShiftT1("ShiftT1",Float) = 0.1
        _Power1("Power1",Float) = 100
        _Strength1("Strength1",Float) = 1
        _ShiftT2("ShiftT1",Float) = 0.1
        _Power2("Power1",Float) = 200
        _Strength2("Strength1",Float) = 1

        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 1

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
    }
}
