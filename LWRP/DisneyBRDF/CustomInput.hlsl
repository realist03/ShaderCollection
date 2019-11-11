#ifndef CUSTOMINPUT_INCLUDED
#define CUSTOMINPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
CBUFFER_START(UnityPerMaterial)

TEXTURE2D(_BaseMap);                 SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);               SAMPLER(sampler_NormalMap);
TEXTURE2D(_DataMap);                 SAMPLER(sampler_DataMap);
TEXTURE2D(_SkinLUT);                 SAMPLER(sampler_SkinLUT);
TEXTURE2D(_KelemenLUT);              SAMPLER(sampler_KelemenLUT);

float _Subfurface;
float SSS_Strength;
float3 SSS_Color;
float _sss;
float fd;
float SSS_Dir;
float _nl;
CBUFFER_END

struct CustomAttributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct CustomVaryings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    float3 positionWS               : TEXCOORD2;

    half4 normalWS                  : TEXCOORD3;    // xyz: normal, w: viewDir.x
    half4 tangentWS                 : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangentWS                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

    float4 shadowCoord              : TEXCOORD7;

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct CustomSurfaceData
{
    half3 albedo;
    half3 emission;
    half3 normalTS;
    half  metallic;
    half  roughness;
    half  subsurface;
    half  occlusion;
    half  specular;
    half  specularTint;
    half3 specularCol;
    half  anisotropic;
    half  sheen;
    half  sheenTint;
    half  clearcoat;
    half  clearcoatGloss;
};

void InitializeCustomSurfaceData(float2 uv, out CustomSurfaceData outCustomSurfaceData)
{
    half4 baseColorMap = SRGBToLinear(SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv));
    outCustomSurfaceData.albedo = baseColorMap.rgb;
    outCustomSurfaceData.emission = baseColorMap.a;

    outCustomSurfaceData.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv));
    
    half4 dataMap = SAMPLE_TEXTURE2D(_DataMap,sampler_DataMap,uv);
    outCustomSurfaceData.metallic = dataMap.r;
    outCustomSurfaceData.roughness = dataMap.g;
    outCustomSurfaceData.subsurface = dataMap.b;
    _Subfurface = outCustomSurfaceData.subsurface;
    outCustomSurfaceData.occlusion = dataMap.a;

    half smoothness = 1 - dataMap.g;

    outCustomSurfaceData.specular = smoothness;
    outCustomSurfaceData.specularTint = smoothness;
    outCustomSurfaceData.specularCol = baseColorMap.rgb;
    outCustomSurfaceData.anisotropic = dataMap.r*2;
    outCustomSurfaceData.sheen = dataMap.g*0.2;
    outCustomSurfaceData.sheenTint = dataMap.g;
    outCustomSurfaceData.clearcoat = smoothness;
    outCustomSurfaceData.clearcoatGloss = smoothness;


}

struct CustomInputData
{
    float3  positionWS;
    half3   normalWS;
    half3   tangentWS;
    half3   bitangentWS;
    half3   binormalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
};

inline void InitializeCustomInputData(CustomVaryings input, half3 normalTS, out CustomInputData customInputData)
{
    customInputData = (CustomInputData)0;

    customInputData.positionWS = input.positionWS;

#ifdef _NORMALMAP
    customInputData.normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
#else
    customInputData.normalWS = input.normalWS.xyz;
#endif

    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    customInputData.tangentWS = input.tangentWS.xyz;
    customInputData.bitangentWS = input.bitangentWS.xyz;

    customInputData.normalWS = NormalizeNormalPerPixel(customInputData.normalWS);

    viewDirWS = viewDirWS;

    customInputData.viewDirectionWS = normalize(viewDirWS);
    customInputData.shadowCoord = input.shadowCoord;
    customInputData.fogCoord = input.fogFactorAndVertexLight.x;
    customInputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    customInputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, customInputData.normalWS);
}

inline void InitializeBRDFData(half3 albedo, half metallic, half roughness,out BRDFData outBRDFData)
{
    outBRDFData = (BRDFData)0;
    //IBL
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(1 - roughness + reflectivity);
    outBRDFData.perceptualRoughness = roughness;
    outBRDFData.roughness = roughness;
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
    
}
#endif


