#ifndef DISNEYFORWARDPASS_INCLUDED
#define DISNEYFORWARDPASS_INCLUDED

#include "DisneyBRDF.hlsl"
#include "CustomInput.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////
float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

// Used in Standard (Physically Based) shader
CustomVaryings LitPassVertex(CustomAttributes input)
{
    CustomVaryings output = (CustomVaryings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = input.texcoord;

    output.normalWS = float4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = float4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = float4(normalInput.bitangentWS, viewDirWS.z);
    
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);

    output.positionWS = vertexInput.positionWS;

    output.shadowCoord = GetShadowCoord(vertexInput);

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
float4 LitPassFragment(CustomVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);

#ifdef _ALPHATEST_ON
    clip(customSurfaceData.emission - _Cutoff);
#endif
    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);

    float4 color = DisneyBRDFFragment(customInputData, customSurfaceData);
    color.rgb = MixFog(color.rgb, customInputData.fogCoord);
    color.rgb = ACESFilm(color.rgb);
    color = LinearToSRGB(color);

    return color;
}
#endif