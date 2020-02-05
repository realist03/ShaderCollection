#ifndef HAIRFORWARDPASS_INCLUDE
#define HAIRFORWARDPASS_INCLUDE

#include "HairBRDF.cginc"
#include "HairInput.cginc"
#include "UnityCG.cginc"
#include "Assets/ArtResources/Shader/Res/Base/Color.cginc"

v2f LitPassVertex(appdata v)
{
    v2f o;

    o.positionWS = mul(unity_ObjectToWorld,v.vertex).xyz;

    o.uv = v.texcoord;
    o.uv2 = v.texcoord1;

    half3 viewDirWS = UnityWorldSpaceViewDir(o.positionWS);
    viewDirWS = normalize(viewDirWS);
    o.normalWS = half4(UnityObjectToWorldNormal(v.normalOS),viewDirWS.x);
    o.tangentWS = half4(UnityObjectToWorldDir(v.tangentOS),viewDirWS.y);
    half avertexTangentSign = v.tangentOS.w*unity_WorldTransformParams.w;
    o.bitangentWS = half4(cross(o.normalWS,o.tangentWS)*avertexTangentSign, viewDirWS.z);

    o.pos = UnityObjectToClipPos(v.vertex.xyz);

    o.screenPosition = ComputeScreenPos(o.pos);

    half3 sh01 = SHEvalLinearL0L1(half4(o.normalWS.xyz,1));
    half3 sh02 = SHEvalLinearL2(half4(o.normalWS.xyz,1));

    o.sh = sh01 + sh02;

	TRANSFER_SHADOW(o);

    return o;
}

// Used in Standard (Physically Based) shader
half4 HairPassFragment(v2f input) : SV_Target
{
    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, input.uv2, customSurfaceData);
    _alpha = customSurfaceData.emission;
    CustomInputData customInputData;
    InitializeCustomInputData(input, customInputData);

    half4 color = HairBRDF(customInputData, customSurfaceData,input.uv);


#ifdef _ALPHATEST_ON

    #ifdef _USEDITHER
        if(_alpha<_ditherThrohold)
        _alpha *= lerp(1,Dither(customInputData.screenPosition),_dither);
    #endif

    clip(_alpha - _Cutoff);
#endif

    color.rgb = ACESFilm(color.rgb);

    return color;
}

#endif
