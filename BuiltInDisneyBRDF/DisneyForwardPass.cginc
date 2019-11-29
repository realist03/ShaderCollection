#ifndef DISNEYFORWARDPASS_INCLUDED
#define DISNEYFORWARDPASS_INCLUDED

#include "DisneyBRDF.cginc"
#include "CustomInput.cginc"
#include "UnityCG.cginc"
///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////
half3 ACESFilm(half3 x)
{
    half a = 2.51f;
    half b = 0.03f;
    half c = 2.43f;
    half d = 0.59f;
    half e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

// Used in Standard (Physically Based) shader
v2f LitPassVertex(appdata v)
{
    v2f o;

    o.positionWS = mul(unity_ObjectToWorld,v.vertex).xyz;

    half3 viewDirWS = UnityWorldSpaceViewDir(o.positionWS);
    o.normalWS = half4(UnityObjectToWorldNormal(v.normalOS),viewDirWS.x);
    o.tangentWS = half4(UnityObjectToWorldDir(v.tangentOS),viewDirWS.y);
    half avertexTangentSign = v.tangentOS.w*unity_WorldTransformParams.w;
    o.bitangentWS = half4(cross(o.normalWS,o.tangentWS)*avertexTangentSign, viewDirWS.z);

    o.uv = v.texcoord;
    o.pos = UnityObjectToClipPos(v.vertex.xyz);
    o.sh = ShadeSH9(float4(o.normalWS.xyz, 1));

	TRANSFER_SHADOW(o);

    return o;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(v2f input) : SV_Target
{
    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);
#ifdef _ALPHATEST_ON
    clip(customSurfaceData.emission - _Cutoff);
#endif
    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);
    UNITY_LIGHT_ATTENUATION(atten, input, input.positionWS);
    customInputData.atten = atten;

    half4 color = DisneyBRDFFragment(customInputData, customSurfaceData);
    color.rgb = ACESFilm(color.rgb);
    //color = LinearToSRGB(color);

    return color;
}

half4 LitPassFragment_OP(v2f input) : SV_Target
{
    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);
#ifdef _ALPHATEST_ON
    clip(customSurfaceData.emission - _Cutoff);
#endif
    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);
    UNITY_LIGHT_ATTENUATION(atten, input, input.positionWS);
    customInputData.atten = atten;

    half4 color = DisneyBRDFFragment_OP(customInputData, customSurfaceData);
    color.rgb = ACESFilm(color.rgb);
    //color = LinearToSRGB(color);

    return color;
}

#endif