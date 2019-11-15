#ifndef HAIRINPUT_INCLUDE
#define HAIRINPUT_INCLUDE
#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

CBUFFER_START(UnityPerMaterial)
float _Metallic;
float _Roughness;
float _Transmission;
float _Cutoff;
float _ShiftT1;
float _Power1;
float _Strength1;
float _ShiftT2;
float _Power2;
float _Strength2;
CBUFFER_END

TEXTURE2D(_BaseColorMap);               SAMPLER(sampler_BaseColorMap);
TEXTURE2D(_ShiftTangentMap);            SAMPLER(sampler_ShiftTangentMap);

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#ifdef _ADDITIONAL_LIGHTS
    float3 positionWS               : TEXCOORD2;
#endif
    half4 normalWS                  : TEXCOORD3;
    half4 tangentTS                 : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangentTS               : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

    float4 shadowCoord              : TEXCOORD7;

    half4 normalTS                  : TEXCOORD8;    // xyz: normal, w: viewDir.x

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct CustomSurfaceData
{
    float3  albedo;
    float   emission;
    float   metallic;
    float   roughness;
    float   subsurface;
    float   anisotropic;
};

inline void InitializeCustomSurfaceData(float2 uv, out CustomSurfaceData outCustomSurfaceData)
{
    outCustomSurfaceData = (CustomSurfaceData)0;
    float4 baseColorMap = SRGBToLinear(SAMPLE_TEXTURE2D(_BaseColorMap,sampler_BaseColorMap,uv));
    outCustomSurfaceData.albedo = baseColorMap.rgb;
    outCustomSurfaceData.emission = baseColorMap.a;
    outCustomSurfaceData.metallic = _Metallic;
    outCustomSurfaceData.roughness = _Roughness;

    float smoothness = 1 - outCustomSurfaceData.roughness*outCustomSurfaceData.roughness;
    outCustomSurfaceData.subsurface = _Transmission;
}

struct CustomInputData
{
    float3  positionWS;
    float3  normalWS;
    float3  tangentTS;
    float3  bitangentTS;
    float3  viewDirectionTS;
    float3  normalTS;
    float4  shadowCoord;
    float   fogCoord;
    float3  vertexLighting;
    float3  bakedGI;
};

inline void InitializeCustomInputData(Varyings input, out CustomInputData customInputData)
{
    customInputData = (CustomInputData)0;

#ifdef _ADDITIONAL_LIGHTS
    customInputData.positionWS = input.positionWS;
#endif

    customInputData.normalTS = input.normalTS.xyz;

    float3 viewDirTS = float3(input.normalTS.w, input.tangentTS.w, input.bitangentTS.w);
    customInputData.tangentTS = input.tangentTS.xyz;
    customInputData.bitangentTS = input.bitangentTS.xyz;
    customInputData.normalWS = NormalizeNormalPerPixel(input.normalWS.xyz);
    customInputData.normalTS = input.normalTS.xyz;
    customInputData.viewDirectionTS = normalize(viewDirTS);

    customInputData.shadowCoord = input.shadowCoord;

    customInputData.fogCoord = input.fogFactorAndVertexLight.x;
    customInputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    customInputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, customInputData.normalWS);
}

inline void InitializeBRDFData(float3 albedo, float metallic, float roughness,out BRDFData outBRDFData)
{
    outBRDFData = (BRDFData)0;
    //IBL
    float oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    float reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(1 - roughness + reflectivity);
    outBRDFData.perceptualRoughness = roughness;
    outBRDFData.roughness = roughness;
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
    
}

#endif