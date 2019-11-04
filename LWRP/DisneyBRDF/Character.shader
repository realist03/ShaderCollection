Shader "Lightweight Render Pipeline/Unlit"
{
    Properties
    {
		metallic("Metallic",Range(0,1)) = 0
		subsurface("subsurface",Range(0,1)) = 0
		_specular("_specular",Range(0,1)) = 0
		roughness("roughness",Range(0,1)) = 0
		specularTint("specularTint",Range(0,1)) = 0
		anisotropic("anisotropic",Range(0,1)) = 0
		sheen("sheen",Range(0,1)) = 0
		sheenTint("sheenTint",Range(0,1)) = 0
		clearcoat("clearcoat",Range(0,1)) = 0
		clearcoatGloss("clearcoatGloss",Range(0,1)) = 0

    }
    SubShader
    {
        Tags {  "RenderPipeline"="LightweightPipeline" "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma vertex vert
            #pragma fragment frag

			#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
			#include "PBRInclude.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
				float3 normal			: NORMAL;
				float4 tangent : TANGENT;
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float fogCoord  : TEXCOORD1;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 viewDir : TEXCOORD2;
				half4 normalWS : TEXCOORD3;    // xyz: normal, w: viewDir.x
    			half4 tangentWS : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    			half4 bitangentWS : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

    			VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    			VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal,input.tangent);
    			half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

				output.uv = input.uv;
				output.vertex = vertexInput.positionCS;
				output.normal = input.normal;
				output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    			output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    			output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
				output.viewDir = viewDirWS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half2 uv = input.uv;
                half3 color = DisneyBRDF(_MainLightPosition.xyz,input.viewDir,input.normalWS,input.tangentWS,input.bitangentWS);

                return half4(color,1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}
