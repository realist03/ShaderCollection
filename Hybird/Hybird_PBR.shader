Shader "Hybird/PBR"
{
	Properties
	{
		[Lable(_Diffuse)]_Diffuse("Diffuse",Float) = 0
		[KeywordEnum(Ramp,Disney,Lambert,Fabric,Orennayar)]_DiffuseMode("DiffuseMode",Float) = 0
		[Texture(_Tint)]_MainTex("BaseColor(RGB:Color, A:SSS)", 2D) = "white" {}
		[HideInInspector]_Tint("Tint",Color) = (1,1,1,1)


		[ShowIf(_DiffuseMode,0)]_RampTex("Ramp", 2D) = "white" {}
		[Texture]_MixTex("MixTex(R:Normal:r, G:Normal:g, B:Metallic, A:Roughness)", 2D) = "bump" {}
		[Toggle(_USENORMALMAP)]_UseNormalMap("Use NormalMap",Float) = 1
		_NormalScale("NormalScale",Range(0,3)) = 1

		[Texture]_SpecularTex("SpecularTex", 2D) = "white" {}
		[Texture]_MatCap("MatCap", 2D) = "black" {}
		[Texture]_NonmetalMatCap("NonmetalMatCap", 2D) = "black" {}
		[Toggle(_FIXTANGENT)]_FixTangent("FixTangent",Float) = 0
		[Toggle(_USEFLOWMAP)]_UseFlowMap("Use FlowMap",Float) = 0
		[Texture]_TangentNoise("TangentNoise", 2D) = "white" {}
		//[NoScaleOffset]_KelemenLUT("KelemenLUT", 2D) = "white" {}
		[Toggle(_DEBUG)]_DEBUG("Debug",Float) = 0

		[space(5)][Header(Diffuse)]
		[Toggle(_USENOV)]_UseNoV("Use NoV",Float) = 0
		_ViewDirOffset("View Direction Offset",Vector) = (0,0,0,0)
		_HeightOffset("HeightOffset",Range(0,1)) = 0
		_DiffuseHeightOffset("DiffuseHeightOffset",Range(0,1)) = 1
		_DiffuseOffsetSmooth("DiffuseOffsetSmooth",Float) = 1
		_RampHeightOffset("RampHeightOffset",Range(-1,1)) = 1
		_RampOffsetSmooth("RampOffsetSmooth",Float) = 1
		_ShadowTint("ShadowTint",Color) = (0.5,0.5,0.5,1)
		_ShadowColor("ShadowColor",Color) = (0,0,0,1)
		_RampSmooth("RampSmooth(UV.V)",Range(0,1)) = 0
		_Layer1Tint("Layer1Tint",Color) = (0.9,0.9,0.9,0.3)
		_Layer2Tint("Layer2Tint",Color) = (0.6,0.6,0.6,0.5)
		_Layer3Tint("Layer3Tint",Color) = (0.3,0.3,0.3,0.7)
		_Layer1Offset("Layer1Offset",Range(-0.5,0.5)) = 0
		_Layer2Offset("Layer2Offset",Range(-0.5,0.5)) = 0
		_Layer3Offset("Layer3Offset",Range(-0.5,0.5)) = 0

		[space(5)][Header(Subsurface)]
		_SubsurfaceTint("SubsurfaceTint", Color) = (1,1,1,1)
		_SubsurfaceIntensity("SubsurfaceIntensity",Range(0,5)) = 0
		_SubsurfaceFalloff("SubsurfaceFalloff",Range(0,5)) = 0

		[space(5)][Header(Specular)]
		[KeywordEnum(None,Ramp,Cel,Disney,Mobile,Skin,Hair,Cloth,BlinnPhong)]_SpecularMode("SpecularMode",Float) = 0
		[KeywordEnum(IBL,MatCapSheet,MatCap)]_IBLMode("IBL Mode",Float) = 0
		[Toggle(_PBRMETAL)]_PBRMetal("PBR Metal",Float) = 0
		_SpecularTint("SpecularTint",Color) = (1,1,1,1)
		_Metallic("Metallic",Range(0,1)) = 1
		_Roughness("Roughness",Range(0,1)) = 1
		_IBLRoughness("IBL Roughness",Range(0,10)) = 1
		_SpecularIntensity("SpecularIntensity",Range(0,5)) = 1
		_Iridescence("Iridescence",Color) = (0.5,0.5,0.5,0)
		_Anisotropic("Anisotropic",Range(0,1)) = 0
		_TangentDistortion("TangentDistortion",Range(0,10)) = 0
		_TangentRotation("TangentRotation",Range(0,360)) = 0
		
		[space(5)][Header(RimLight)]
		_RimLightViewDir("RimLightViewDir",Vector) = (1,1,1,1) 
		[HDR]_RimLightColor("RimLightColor",Color) = (1,1,1,1)
		_RimLightExponent("RimLightExponent",Float) = 1
		_RimLightIntensity("RimLightIntensity",Float) = 0
		_RimLightSmoothness("RimLightSmoothness",Range(0.02,1)) = 0

		[space(5)][Header(Cloth)]
		_Cloth("Cloth",Range(0,1)) = 0
		[HDR]_Layer1ShininessTint("Layer1ShininessTint",Color) = (0,0,0,1)
		_Layer1ShininessDirection("Layer1ShininessDirection",Range(-360,360)) = 0
		_Layer1RoughnessX("Layer1RoughnessX",Range(0,1)) = 1
		_Layer1RoughnessY("Layer1RoughnessY",Range(0,1)) = 1
		_Layer1ShininessOffset("Layer1ShininessOffset",Range(-1,1)) = 0
		_Layer1Shininess("Layer1Shininess",Range(0,1000)) = 0
		[space(1)][Header(_)]
		[HDR]_Layer2ShininessTint("Layer2ShininessTint",Color) = (0,0,0,1)
		_Layer2ShininessDirection("Layer2ShininessDirection",Range(-360,360)) = 0
		_Layer2RoughnessX("Layer2RoughnessX",Range(0,1)) = 1
		_Layer2RoughnessY("Layer2RoughnessY",Range(0,1)) = 1
		_Layer2ShininessOffset("Layer2ShininessOffset",Range(-1,1)) = 0
		_Layer2Shininess("Layer2Shininess",Range(0,1000)) = 0
		[space(1)][Header(_)]
		[HDR]_Layer3ShininessTint("Layer3ShininessTint",Color) = (0,0,0,1)
		_Layer3ShininessDirection("Layer3ShininessDirection",Range(-360,360)) = 0
		_Layer3RoughnessX("Layer3RoughnessX",Range(0,1)) = 1
		_Layer3RoughnessY("Layer3RoughnessY",Range(0,1)) = 1
		_Layer3ShininessOffset("Layer3ShininessOffset",Range(-1,1)) = 1
		_Layer3Shininess("Layer3Shininess",Range(0,1000)) = 0
		
		[space(5)][Header(Hair)]
		[HDR]_SpecularTint1("SpecularTint1",Color) = (1,1,1,1)
		_Specular1Intensity("Specular1 Intensity",Range(0,3)) = 1
		_SpecularExponent1("SpecularExponent1",Float) = 200
		_Shift1("Shift1",Range(-10,10)) = 0
		
		[HDR]_SpecularTint2("SpecularTint2",Color) = (1,1,1,1)
		_Specular2Intensity("Specular2 Intensity",Range(0,3)) = 1
		_SpecularExponent2("SpecularExponent2",Float) = 200
		_Shift2("Shift2",Range(-10,10)) = 0

		[space(5)][Header(ClearCoat)]
		[Toggle(_USECLEARCOAT)]_UseClearCoat("Use ClearCoat",Float) = 0
		_ClearCoat("ClearCoat",Range(0,1)) = 0
		_ClearCoatGloss("ClearCoatGloss",Range(0,1)) = 0

		_NormalSoftness("NormalSoftness",Float) = 0
		_EyeForward("EyeForward",Vector) = (0,0,0,0)
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
			#pragma fragment HybirdPBRFragment
			#pragma shader_feature _DIFFUSEMODE_RAMP _DIFFUSEMODE_DISNEY _DIFFUSEMODE_LAMBERT _DIFFUSEMODE_FABRIC _DIFFUSEMODE_ORENNAYAR
			#pragma shader_feature _SPECULARMODE_NONE _SPECULARMODE_RAMP _SPECULARMODE_CEL _SPECULARMODE_DISNEY _SPECULARMODE_MOBILE _SPECULARMODE_SKIN _SPECULARMODE_HAIR _SPECULARMODE_CLOTH _SPECULARMODE_BLINNPHONG
			#pragma shader_feature _IBLMODE_IBL _IBLMODE_MATCAPSHEET _IBLMODE_MATCAP
			#pragma shader_feature _USENOV
			#pragma shader_feature _PBRMETAL
			#pragma shader_feature _FIXTANGENT
			#pragma shader_feature _USEFLOWMAP
			#pragma shader_feature _USENORMALMAP
			#pragma shader_feature _USECLEARCOAT
			#pragma shader_feature _DEBUG
            #pragma multi_compile _ _SHADOWS_SOFT _SHADOWS_PCSS
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
	CustomEditor"HybirdGUI"
}
