#ifndef DISNEYFORWARDPASS_INCLUDED
#define DISNEYFORWARDPASS_INCLUDED

#include "CustomBRDF.cginc"
#include "CustomInput.cginc"
#include "Assets/ArtResources/Shader/Res/Base/Color.cginc"
#include "UnityCG.cginc"

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

v2f LitPassVertex(appdata v)
{
    v2f o;

    o.positionWS = mul(unity_ObjectToWorld,v.vertex).xyz;

    float3 viewDirWS = UnityWorldSpaceViewDir(o.positionWS);
    o.normalWS = float4(UnityObjectToWorldNormal(v.normalOS),viewDirWS.x);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangentOS),viewDirWS.y);
    float avertexTangentSign = v.tangentOS.w*unity_WorldTransformParams.w;
    o.bitangentWS = float4(cross(o.normalWS,o.tangentWS)*avertexTangentSign, viewDirWS.z);

    o.uv = v.texcoord;
    o.pos = UnityObjectToClipPos(v.vertex.xyz);
    float3 sh01 = SHEvalLinearL0L1(float4(o.normalWS.xyz,1));
    float3 sh02 = SHEvalLinearL2(float4(o.normalWS.xyz,1));

    o.sh = sh01 + sh02;

	TRANSFER_SHADOW(o);

    return o;
}

float4 LitPassFragment(v2f input) : SV_Target
{
    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);
#ifdef _ALPHATEST_ON
    clip(customSurfaceData.alpha - _Cutoff);
#endif
    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);
    UNITY_LIGHT_ATTENUATION(atten, input, input.positionWS);
    customInputData.atten = atten;

    float4 color = DisneyBRDFFragment(customInputData, customSurfaceData);
    //color.rgb = ACESFilm(color.rgb);
    //color = LinearToSRGB(color);

    return color;
}

float4 LitPassFragment_OP(v2f input) : SV_Target
{
    CustomSurfaceData customSurfaceData;
    InitializeCustomSurfaceData(input.uv, customSurfaceData);
#ifdef _ALPHATEST_ON
    clip(customSurfaceData.alpha - _Cutoff);
#endif
    CustomInputData customInputData;
    InitializeCustomInputData(input, customSurfaceData.normalTS, customInputData);
    UNITY_LIGHT_ATTENUATION(atten, input, input.positionWS);
    customInputData.atten = atten;

    float4 color = DisneyBRDFFragment_OP(customInputData, customSurfaceData);
    //color.rgb = ACESFilm(color.rgb);
    //color = LinearToSRGB(color);
    return color;
}

#endif