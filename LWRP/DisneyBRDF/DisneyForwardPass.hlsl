#ifndef DISNEYFORWARDPASS_INCLUDED
#define DISNEYFORWARDPASS_INCLUDED

#include "DisneyBRDF.hlsl"
#include "CustomInput.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
CustomVaryings LitPassVertex(CustomAttributes input)
{
    CustomVaryings output = (CustomVaryings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = input.texcoord;

    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
    
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#ifdef _ADDITIONAL_LIGHTS
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(CustomVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);

    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);
    
    half4 color = DisneyBRDFFragment(customInputData, customSurfaceData);
    color.rgb = MixFog(color.rgb, customInputData.fogCoord);
    color = LinearToSRGB(color);
    return color;
}
#endif