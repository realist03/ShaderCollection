#ifndef CUSTOMINPUT_INCLUDE
#define CUSTOMINPUT_INCLUDE
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "Assets/ArtResources/Shader/Res/Base/Color.cginc"

half3 _MainColor;
half _EmissionStrength;
half3 _TransColor;
half  _Translucency;
half  _TransNormalDistortion;
half  _TransScattering;
half  _TransDirect;
half  _TransAmbient;
half  _TransShadow;
half  _Cutoff;
half _Metallic;
half _Roughness;
half _AOStrength;
half3 specol;
half3 _ChangeColorR;
half3 _ChangeColorG;
half3 _ChangeColorB;
sampler2D _Diffuse;
sampler2D _Normalmap;
sampler2D _Multiply;
sampler2D _ChangeMask;

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
    half  specularTint;
    half   anisotropic;
    half   sheen;
    half3  sheenTint;
    half   clearcoat;
    half   clearcoatGloss;
    half   alpha;
};

void InitializeCustomSurfaceData(half2 uv, out CustomSurfaceData outCustomSurfaceData)
{
    half4 baseColorMap = SRGBToLinear(tex2D(_Diffuse,uv));
    outCustomSurfaceData.emission = baseColorMap.a;

    half4 normalMap = tex2D(_Normalmap,uv);
    outCustomSurfaceData.normalTS = UnpackNormal(normalMap);
    
    half4 dataMap = tex2D(_Multiply,uv);

#if _USECOLOR
    outCustomSurfaceData.albedo = _MainColor;
#else
    outCustomSurfaceData.albedo = baseColorMap.rgb;
#endif

#if _CHANGECOLOR
    half4 colorMask = tex2D(_ChangeMask, uv);
    half3 colorR = colorMask.r * (half3(1, 1, 1) - _ChangeColorR.rgb);
    half3 colorG = colorMask.g * (half3(1, 1, 1) - _ChangeColorG.rgb);
    half3 colorB = colorMask.b * (half3(1, 1, 1) - _ChangeColorB.rgb);
    half3 changeColor = half3(1, 1, 1) - (colorR + colorG + colorB);
    outCustomSurfaceData.albedo.rgb = changeColor.rgb * outCustomSurfaceData.albedo.rgb;
#endif

#if _USEPROPERTY
    outCustomSurfaceData.metallic = _Metallic;
    outCustomSurfaceData.roughness = _Roughness;
#else
    outCustomSurfaceData.metallic = dataMap.r;
    outCustomSurfaceData.roughness = dataMap.g;
#endif

    outCustomSurfaceData.subsurface = dataMap.b;
    outCustomSurfaceData.occlusion = lerp(1,dataMap.a,0.5);

    half smoothness = 1 - outCustomSurfaceData.roughness;

    outCustomSurfaceData.specular = smoothness;
    outCustomSurfaceData.specularTint = outCustomSurfaceData.metallic;
    outCustomSurfaceData.anisotropic = 0;
    outCustomSurfaceData.sheen = dataMap.g;
    outCustomSurfaceData.sheenTint = outCustomSurfaceData.albedo;
    outCustomSurfaceData.clearcoat = dataMap.r;
    outCustomSurfaceData.clearcoatGloss = smoothness;
    outCustomSurfaceData.alpha = normalMap.a;

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

    customInputData.normalWS = normalize(mul(normalTS,
            half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
    customInputData.binormalWS = cross(customInputData.normalWS,customInputData.tangentWS);
    customInputData.tangentWS = cross(customInputData.normalWS,half4(1,0,0,0));
    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    customInputData.tangentWS = input.tangentWS.xyz;
    customInputData.bitangentWS = input.bitangentWS.xyz;

    customInputData.viewDirectionWS = normalize(viewDirWS);
    customInputData.sh = input.sh;
}
#endif