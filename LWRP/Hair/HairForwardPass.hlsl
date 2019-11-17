#ifndef HAIRFORWARDPASS_INCLUDE
#define HAIRFORWARDPASS_INCLUDE
#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "HairBRDF.hlsl"
#include "HairInput.hlsl"
float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = input.texcoord;
	float3x3 worldToTangent = float3x3( normalInput.tangentWS, normalInput.bitangentWS, normalInput.normalWS );

    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    float3 viewDirTS = normalize(TransformWorldToTangent(viewDirWS,worldToTangent));
    output.normalWS = float4(normalInput.normalWS, viewDirTS.x);
    output.normalTS = float4(TransformWorldToTangent(output.normalWS.xyz,worldToTangent),viewDirTS.x);
    output.tangentTS = float4(TransformWorldToTangent(normalInput.tangentWS.xyz,worldToTangent),viewDirTS.y);
    output.bitangentTS = float4(TransformWorldToTangent(normalInput.bitangentWS.xyz,worldToTangent),viewDirTS.z);
    output.viewDirWS = normalize(viewDirWS);
    Light light = GetMainLight();
    output.lightDirTS = TransformWorldToTangent(light.direction,worldToTangent);

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);

#ifdef _ADDITIONAL_LIGHTS
    output.positionWS = vertexInput.positionWS;
#endif

    output.shadowCoord = GetShadowCoord(vertexInput);

    output.positionCS = vertexInput.positionCS;
    output.screenPosition = ComputeScreenPos(output.positionCS);
    return output;
}

// Used in Standard (Physically Based) shader
float4 HairPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);
    _alpha = customSurfaceData.emission;
    CustomInputData customInputData;
    InitializeCustomInputData(input, customInputData);

    float4 color = HairBRDF(customInputData, customSurfaceData,input.uv);


#ifdef _ALPHATEST_ON

    #ifdef _USEDITHER
        if(_alpha<_ditherThrohold)
        _alpha *= lerp(1,Dither(customInputData.screenPosition),_dither);
    #endif

    clip(_alpha - _Cutoff);
#endif

    color.rgb = MixFog(color.rgb, customInputData.fogCoord);
    color.rgb = ACESFilm(color.rgb);
    color = LinearToSRGB(color);

    return color;
}

#endif
