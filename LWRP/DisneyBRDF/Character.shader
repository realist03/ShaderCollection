Shader "Lightweight Render Pipeline/Character"
{
    Properties
    {
        _BaseColor("BaseColor",2D) = "white"{}
        _M("M",2D) = "black"{}
        _NormalMap("Normal",2D) = "bump"{}
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
        speCol("SpeCol",Color) = (1,1,1,1)

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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"

			#include "BRDFInclude.hlsl"

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
				float4 normalWS : TEXCOORD3;    // xyz: normal, w: viewDir.x
    			float4 tangentWS : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    			float4 bitangentWS : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

            };
			TEXTURE2D(_BaseColor);		SAMPLER(sampler_BaseColor);
			TEXTURE2D(_M);		SAMPLER(sampler_M);
			TEXTURE2D(_NormalMap);		SAMPLER(sampler_NormalMap);

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

    			VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    			VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal,input.tangent);
    			float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

				output.uv = input.uv;
				output.vertex = vertexInput.positionCS;
				output.normal = input.normal;
				output.normalWS = float4(normalInput.normalWS, viewDirWS.x);
    			output.tangentWS = float4(normalInput.tangentWS, viewDirWS.y);
    			output.bitangentWS = float4(normalInput.bitangentWS, viewDirWS.z);
				output.viewDir = normalize(viewDirWS);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 BaseColorMap = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor , input.uv );
                BaseColorMap = LinearToSRGB(BaseColorMap);
                baseColor = BaseColorMap.rgb;
                float3 normalMap = UnpackNormalScale(SAMPLE_TEXTURE2D( _NormalMap, sampler_NormalMap , input.uv ),1);
                input.normalWS.xyz = normalize(TransformTangentToWorld(normalMap, float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
                float4 mMap = SAMPLE_TEXTURE2D( _M, sampler_M , input.uv );
                //metallic = mMap.r;
                //roughness = mMap.g;
                //subsurface = mMap.b;
                //_specular = 1 - roughness;
                float ao = mMap.a;

                float3 color = SampleSH(float3(input.normalWS) + )_MainLightColor.rgb * ao * DisneyBRDF(_MainLightPosition.xyz,input.viewDir.xyz,input.normalWS.xyz,input.tangentWS.xyz,input.bitangentWS.xyz);
                //float3 color = (mMap.r,mMap.r,mMap.r);

                return float4(color,1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}
