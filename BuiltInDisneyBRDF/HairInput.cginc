#ifndef HAIRINPUT_INCLUDE
#define HAIRINPUT_INCLUDE
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "Assets/ArtResources/Shader/Res/Base/Color.cginc"

half _Transmission;
half _Cutoff;
half _ShiftT;
half _Power1;
half _Strength1;
half _Power2;
half _Strength2;
half _w;
half3 _ScatterColor;
half _alpha;
half _dither;
half _ditherTile;
half _ditherThrohold;
half _Roughness;
half _AOStrength;
half _FresnelPower;
half _FresnelStrength;

sampler2D _D;
sampler2D _AOMap;
sampler2D _ShiftTangentMap;
sampler2D _DitherPattern;
half4 _DitherPattern_TexelSize;

struct appdata
{
    half4 vertex       : POSITION;
    half3 normalOS     : NORMAL;
    half4 tangentOS    : TANGENT;
    half2 texcoord     : TEXCOORD0;
    half2 texcoord1    : TEXCOORD1;
};

struct v2f
{
    half2 uv                       : TEXCOORD0;
    half2 uv2                      : TEXCOORD1;
    half3 positionWS               : TEXCOORD2;
    half4 normalWS                 : TEXCOORD3;
    half4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    half3 sh                       : TEXCOORD6;
    half4 screenPosition           : TEXCOORD7;
    SHADOW_COORDS(11)
    half4 pos                      : SV_POSITION;
};

struct CustomSurfaceData
{
    half3  albedo;
    half   emission;
    half   metallic;
    half   roughness;
    half   subsurface;
    half   occlusion;
};

inline void InitializeCustomSurfaceData(half2 uv, half2 uv2, out CustomSurfaceData outCustomSurfaceData)
{
    outCustomSurfaceData = (CustomSurfaceData)0;
    half4 baseColorMap = SRGBToLinear(tex2D(_D,uv));
    outCustomSurfaceData.albedo = baseColorMap.rgb;
    outCustomSurfaceData.emission = baseColorMap.a;
    outCustomSurfaceData.metallic = 0;
    outCustomSurfaceData.roughness = _Roughness;
    outCustomSurfaceData.occlusion = lerp(1,tex2D(_AOMap,uv2).r,_AOStrength);
    half smoothness = 1 - outCustomSurfaceData.roughness*outCustomSurfaceData.roughness;
    outCustomSurfaceData.subsurface = _Transmission;
}

struct CustomInputData
{
    half3  positionWS;
    half3  normalWS;
    half3  tangentTS;
    half3  bitangentTS;
    half3  viewDirectionWS;
    half3  viewDirectionTS;
    half3  normalTS;
    half3  lightDirTS;
    half3  sh;
    half4  screenPosition;
    half atten;
};

inline void InitializeCustomInputData(v2f input, out CustomInputData customInputData)
{
    customInputData = (CustomInputData)0;

    customInputData.positionWS = input.positionWS;
    customInputData.normalWS = normalize(input.normalWS.xyz);
    half3 viewDirWS = half3(input.normalWS.w,input.tangentWS.w,input.bitangentWS.w);
    customInputData.viewDirectionWS = viewDirWS;
    customInputData.sh = input.sh;

	half3x3 worldToTangent = half3x3( input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz );

    customInputData.viewDirectionTS = normalize(mul(worldToTangent,viewDirWS));
    customInputData.normalTS = mul(worldToTangent,input.normalWS.xyz);
    customInputData.tangentTS = mul(worldToTangent,input.tangentWS.xyz);
    customInputData.bitangentTS = mul(worldToTangent,input.bitangentWS.xyz);

    half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(input.positionWS));

    customInputData.lightDirTS = mul(worldToTangent,lightDir);


#ifdef _RECIVESHADOW
    UNITY_LIGHT_ATTENUATION(atten, input, input.positionWS);
    customInputData.atten = atten;
#else
    customInputData.atten = 1;
#endif

    customInputData.screenPosition = input.screenPosition;
}

#endif