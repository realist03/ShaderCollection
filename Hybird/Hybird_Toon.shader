Shader "Hybird/Toon" 
{
    Properties 
    {
        [space(5)][Header(Texture)]
		[NoScaleOffset]_MainTex("Diffuse(RGB:Color, A:SSS)", 2D) = "white" {}
        [NoScaleOffset]_MatCap ("MatCap", 2D) = "white" {}
        _TangentNoise("TangentNoise", 2D) = "white" {}

        _Tint ("Tint", Color) = (1,1,1,1)
        _ShadowTint("ShadowTint",Color) = (0.5,0.5,0.5,1)
        _ShadowThreshold("_ShadowThreshold",Range(0,1)) = 0.5
        _ShadowFeather("ShadowFeather",Range(0,1)) = 0
        _Frame("Frame",Float) = 0
    }
    SubShader
    {
		Tags { "Queue" = "Geometry" "IgnoreProjector" = "True" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        
		LOD 100

        Pass
        {
            Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward"}

			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma vertex HybirdBaseVertex
			#pragma fragment HybirdToonFragment
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
		    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHTS_FORWARD_PLUS

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "HybirdPBRInput.hlsl"
			#include "HybirdForwardPass.hlsl"

            ENDHLSL
        }

		Pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
		
			ZWrite On
			ZTest LEqual
			Cull Back
		
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			//#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
		
			// -------------------------------------
			// Material Keywords
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
		
			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
		
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
		
			#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
			ENDHLSL
		}

    }
}
 