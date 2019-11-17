#ifndef CUSTOMINPUT_INCLUDED
#define CUSTOMINPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

CBUFFER_START(UnityPerMaterial)
float3 _EmissionColor;
float  _Translucency;
float  _TransNormalDistortion;
float  _TransScattering;
float  _TransDirect;
float  _TransAmbient;
float  _TransShadow;
float  _Cutoff;
CBUFFER_END

TEXTURE2D(_BaseColorMap);            SAMPLER(sampler_BaseColorMap);
TEXTURE2D(_NormalMap);               SAMPLER(sampler_NormalMap);
TEXTURE2D(_DataMap);                 SAMPLER(sampler_DataMap);

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

    float4 normalWS                  : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangentWS                 : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS               : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    float4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

    float4 shadowCoord              : TEXCOORD7;

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct CustomSurfaceData
{
    float3  albedo;
    float3  emission;
    float3  normalTS;
    float   metallic;
    float   roughness;
    float   subsurface;
    float   occlusion;
    float   specular;
    float3  specularTint;
    float   anisotropic;
    float   sheen;
    float3  sheenTint;
    float   clearcoat;
    float   clearcoatGloss;
};

void InitializeCustomSurfaceData(float2 uv, out CustomSurfaceData outCustomSurfaceData)
{
    float4 baseColorMap = SRGBToLinear(SAMPLE_TEXTURE2D(_BaseColorMap,sampler_BaseColorMap,uv));
    outCustomSurfaceData.albedo = baseColorMap.rgb;
    outCustomSurfaceData.emission = baseColorMap.a;

    outCustomSurfaceData.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv));
    
    float4 dataMap = SAMPLE_TEXTURE2D(_DataMap,sampler_DataMap,uv);
    outCustomSurfaceData.metallic = dataMap.r;
    outCustomSurfaceData.roughness = dataMap.g;
    outCustomSurfaceData.subsurface = dataMap.b;
    outCustomSurfaceData.occlusion = dataMap.a;

    float smoothness = 1 - outCustomSurfaceData.roughness*outCustomSurfaceData.roughness;

    outCustomSurfaceData.specular = smoothness;
    outCustomSurfaceData.specularTint = outCustomSurfaceData.albedo;
    outCustomSurfaceData.anisotropic = dataMap.r;
    outCustomSurfaceData.sheen = dataMap.g;
    outCustomSurfaceData.sheenTint = outCustomSurfaceData.albedo;
    outCustomSurfaceData.clearcoat = dataMap.r;
    outCustomSurfaceData.clearcoatGloss = smoothness;


}

struct CustomInputData
{
    float3  positionWS;
    float3  normalWS;
    float3  tangentWS;
    float3  bitangentWS;
    float3  binormalWS;
    float3  viewDirectionWS;
    float4  shadowCoord;
    float   fogCoord;
    float3  vertexLighting;
    float3  bakedGI;
};

inline void InitializeCustomInputData(CustomVaryings input, float3 normalTS, out CustomInputData customInputData)
{
    customInputData = (CustomInputData)0;

    customInputData.positionWS = input.positionWS;

    customInputData.normalWS = TransformTangentToWorld(normalTS,
            float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));

    float3 viewDirWS = float3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    customInputData.tangentWS = input.tangentWS.xyz;
    customInputData.bitangentWS = input.bitangentWS.xyz;

    customInputData.normalWS = NormalizeNormalPerPixel(customInputData.normalWS);
    customInputData.binormalWS = cross(customInputData.normalWS,customInputData.tangentWS);
    customInputData.viewDirectionWS = normalize(viewDirWS);

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


