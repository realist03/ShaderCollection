#ifndef CUSTOMINPUT_INCLUDE
#define CUSTOMINPUT_INCLUDE
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"

half3 _EmissionColor;
half  _Translucency;
half  _TransNormalDistortion;
half  _TransScattering;
half  _TransDirect;
half  _TransAmbient;
half  _TransShadow;
half  _Cutoff;
half _Metallic;
half _Roughness;

sampler2D _Diffuse;
sampler2D _Normalmap;
sampler2D _Multiply;

struct appdata
{
    half4 vertex       : POSITION;
    half3 normalOS     : NORMAL;
    half4 tangentOS    : TANGENT;
    half2 texcoord     : TEXCOORD0;
};

struct v2f
{
    half2 uv                        : TEXCOORD0;
     
    half3 positionWS                : TEXCOORD1;

    half4 normalWS                  : TEXCOORD2;    // xyz: normal, w: viewDir.x
    half4 tangentWS                 : TEXCOORD3;    // xyz: tangent, w: viewDir.y
    half4 bitangentWS               : TEXCOORD4;    // xyz: bitangent, w: viewDir.z

    half3 sh                        : TEXCOORD5;
    SHADOW_COORDS(6)
    half4 pos                       : SV_POSITION;
};

struct CustomSurfaceData
{
    half3  albedo;
    half3  emission;
    half3  normalTS;
    half   metallic;
    half   roughness;
    half   subsurface;
    half   occlusion;
    half   specular;
    half3  specularTint;
    half   anisotropic;
    half   sheen;
    half3  sheenTint;
    half   clearcoat;
    half   clearcoatGloss;
};
half4 SRGBToLinear(half4 c)
{
    half3 linearRGBLo  = c.rgb / 12.92;
    half3 linearRGBHi  = pow((c.rgb + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
    half3 linearRGB    = (c.rgb <= 0.04045) ? linearRGBLo : linearRGBHi;
    return half4(linearRGB,c.a);
}

half4 LinearToSRGB(half4 c)
{
    half3 sRGBLo = c.rgb * 12.92;
    half3 sRGBHi = (pow(c.rgb, half3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
    half3 sRGB   = (c.rgb <= 0.0031308) ? sRGBLo : sRGBHi;
    return half4(sRGB,c.a);
}

void InitializeCustomSurfaceData(half2 uv, out CustomSurfaceData outCustomSurfaceData)
{
    half4 baseColorMap = SRGBToLinear(tex2D(_Diffuse,uv));
    outCustomSurfaceData.albedo = baseColorMap.rgb;
    outCustomSurfaceData.emission = baseColorMap.a;

    outCustomSurfaceData.normalTS = UnpackNormal(tex2D(_Normalmap,uv));
    
    half4 dataMap = tex2D(_Multiply,uv);

#if _USEPROPERTY
    outCustomSurfaceData.metallic = _Metallic;
    outCustomSurfaceData.roughness = _Roughness;
#else
    outCustomSurfaceData.metallic = dataMap.r;
    outCustomSurfaceData.roughness = dataMap.g;
#endif

    outCustomSurfaceData.subsurface = dataMap.b;
    outCustomSurfaceData.occlusion = dataMap.a;

    half smoothness = 1 - outCustomSurfaceData.roughness*outCustomSurfaceData.roughness;

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
    half3  positionWS;
    half3  normalWS;
    half3  tangentWS;
    half3  bitangentWS;
    half3  binormalWS;
    half3  viewDirectionWS;
    half4  atten;
    half3  sh;
};

inline void InitializeCustomInputData(v2f input, half3 normalTS, out CustomInputData customInputData)
{
    customInputData = (CustomInputData)0;

    customInputData.positionWS = input.positionWS;

    customInputData.binormalWS = cross(customInputData.normalWS,customInputData.tangentWS);
    customInputData.normalWS = normalize(mul(normalTS,
            half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));

    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    customInputData.tangentWS = input.tangentWS.xyz;
    customInputData.bitangentWS = input.bitangentWS.xyz;

    customInputData.viewDirectionWS = normalize(viewDirWS);
    customInputData.sh = input.sh;
}
#endif