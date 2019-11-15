#ifndef HAIRBRDF_INCLUDE
#define HAIRBRDF_INCLUDE

#include "HairInput.hlsl"

float SpecularExponent(float3 T, float3 V, float3 L, float power, float strength)
{
    float3 H = normalize(L+V);
    float TdotH = max(dot(T,H),0);
    return pow(sqrt(1-(TdotH*TdotH)),power)*strength*smoothstep(-1,0,TdotH);
}

float4 HairBRDF(CustomInputData customInputData, CustomSurfaceData customsurfaceData,float2 uv)
{   
    Light mainLight = GetMainLight();

    float shiftMap = SAMPLE_TEXTURE2D(_ShiftTangentMap,sampler_ShiftTangentMap,uv).r - 0.5;

    float3 shiftT1 = ShiftTangent(customInputData.tangentTS,customInputData.normalTS,shiftMap+_ShiftT1);

    float3 shiftT2 = ShiftTangent(customInputData.tangentTS,customInputData.normalTS,shiftMap+_ShiftT2);

    float spe1 = SpecularExponent(shiftT1,customInputData.viewDirectionTS,
                mainLight.direction,_Power1,_Strength1);

    float spe2 = SpecularExponent(shiftT2,customInputData.viewDirectionTS,
                mainLight.direction,_Power2,_Strength2);

    float spe = spe1 + spe2;
    
    float3 H = customInputData.viewDirectionTS + mainLight.direction;
    float Ka1 = D_KajiyaKay(shiftT1,H,1);
    float NdotL = max(dot(customInputData.normalWS,mainLight.direction),0);
    float3 D = spe + customsurfaceData.albedo * NdotL;
    return float4(D,1);
}

#endif
