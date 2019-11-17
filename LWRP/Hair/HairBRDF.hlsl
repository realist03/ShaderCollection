#ifndef HAIRBRDF_INCLUDE
#define HAIRBRDF_INCLUDE

#include "HairInput.hlsl"

float SpecularExponent(float3 T, float3 V, float3 L, float power, float strength)
{
    float3 H = normalize(L+V);
    float TdotH = dot(T,H);
    return pow(sqrt(1-(TdotH*TdotH)),power)*strength*smoothstep(-1,0,TdotH);
}

float StrandSpecular ( float3 T, float3 V, float3 L, float exponent)
{
    float3 H = normalize(L + V);
    float dotTH = dot(T, H);
    float sinTH = sqrt(1 - dotTH * dotTH);
    float dirAtten = smoothstep(-1, 0, dotTH);
    return dirAtten * pow(sinTH, exponent);
}

float Dither(float4 scPos)
{
    float2 screenPos = scPos.xy/scPos.w;
    float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
    float ditherValue = SAMPLE_TEXTURE2D(_DitherPattern, sampler_DitherPattern,ditherCoordinate*_ditherTile).r;
    return ditherValue;
}

float4 HairBRDF(CustomInputData customInputData, CustomSurfaceData customsurfaceData,float2 uv)
{   
    Light mainLight = GetMainLight(customInputData.shadowCoord);

    float shiftMap = SAMPLE_TEXTURE2D(_ShiftTangentMap,sampler_ShiftTangentMap,uv).r - 0.5;

    float3 shiftT = ShiftTangent(customInputData.bitangentTS,customInputData.normalTS,shiftMap+_ShiftT);


    float spe1 = SpecularExponent(shiftT,customInputData.viewDirectionTS,
                customInputData.lightDirTS,_Power1,_Strength1);

    float spe2 = SpecularExponent(shiftT,customInputData.viewDirectionTS,
                customInputData.lightDirTS,_Power2,_Strength2);

    float spe = spe1 + spe2;
    
    float3 H = customInputData.viewDirectionTS + mainLight.direction;
    float NdotL = max(dot(customInputData.normalWS,mainLight.direction),0);

    float  diffuse = saturate(NdotL+_w)/(1+_w);
    float3 scatterColor = customsurfaceData.albedo;
    float3 scatterLight = saturate(_scatterColor + (NdotL*diffuse));
    float3  trans = customsurfaceData.albedo*scatterLight;
    float3 color = trans + spe * NdotL;
    color *= mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    
    BRDFData brdfData;
    InitializeBRDFData(customsurfaceData.albedo,customsurfaceData.metallic,customsurfaceData.roughness,brdfData);
    color += GlobalIllumination(brdfData, customInputData.bakedGI, customsurfaceData.occlusion, customInputData.normalWS, customInputData.viewDirectionWS);
    
    //return a_alpha.xxxx;
    return float4(color,customsurfaceData.emission);
}

#endif
