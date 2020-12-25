#ifndef HYBIRD_FORWARDPASS_INCLUDED
#define HYBIRD_FORWARDPASS_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "./HybirdPBRInput.hlsl"
#include "./HybirdInput.hlsl"
#include "./HybirdBxDF.hlsl"
#include "./HybirdToonBxDF.hlsl"
#include "./ShadingModels.hlsl"

struct Attributes
{
	float3 positionOS   : POSITION;
	float2 uv           : TEXCOORD0;
#ifdef _FIXTANGENT
	float2 uv2			: TEXCOORD1;
#endif
	float3 normalOS		: NORMAL;
	float4 tangentOS	: TANGENT;
	float4 color		: COLOR;
};

struct Varyings
{
	float4 positionCS   : SV_POSITION;
	float4 color		: COLOR;
	float2 uv           : TEXCOORD0;
	float3 positionWS	: TEXCOORD1;
	float3 normalWS		: TEXCOORD2;
	float4 tangentWS	: TEXCOORD3;
	float3 bitangentWS	: TEXCOORD4;
	//float4 projPos	: TEXCOORD5;
	half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
	float4 shadowCoord              : TEXCOORD7;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 8);
#ifdef _FIXTANGENT
	float2 uv2			: TEXCOORD9;
#endif
};

void InitializeNPRInputData(Varyings input, half3 normalTS, half4 tangentNoise, out NPRInputData inputData)
{
    inputData = (NPRInputData)0;
	float3x3 m_tangentToWorld = float3x3(input.tangentWS.xyz, input.bitangentWS, input.normalWS);
#ifdef _USENORMALMAP
	float3 normalTexWS = TransformTangentToWorld(normalTS, m_tangentToWorld);
#else
	float3 normalTexWS = input.normalWS;
#endif

    inputData.positionWS = input.positionWS;
	inputData.normalWS = NormalizeNormalPerPixel(normalTexWS);

#ifdef _USEFLOWMAP
	half3 tangenTex = CustomUnpackNormalScale(tangentNoise.xyzz,1);
	tangenTex = TransformTangentToWorld(tangenTex,m_tangentToWorld);
	inputData.tangentWS = normalize(tangenTex);
	inputData.bitangentWS = normalize(cross(inputData.normalWS,inputData.tangentWS));
#else
	inputData.tangentWS.xyz = input.tangentWS.xyz;
	inputData.bitangentWS = input.bitangentWS;
#endif

#ifdef _USEREFRACTION
	inputData.screenUV = ComputeScreenPos(input.positionCS);
#endif

#ifdef _USECLEARCOAT
	inputData.clearCoatNormalWS = input.normalWS;
#endif

    inputData.viewDirWS = normalize(GetCameraPositionWS() - inputData.positionWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    inputData.bakedGI = (SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS));

}

Varyings HybirdBaseVertex(Attributes input)
{
	Varyings output = (Varyings)0;

#ifdef _FIXTANGENT
	output.uv = input.uv;
	output.uv2 = TRANSFORM_TEX(input.uv2,_TangentNoise);
#else
	output.uv = TRANSFORM_TEX(input.uv,_TangentNoise);
#endif

#ifdef _FUR
	output.uv = TRANSFORM_TEX(input.uv,_FurNoise);
    half noise = SAMPLE_TEXTURE2D_LOD(_FurNoise,sampler_FurNoise,output.uv,0).r;
    input.positionOS.xyz += _Offset * noise * input.normalOS;
#endif

	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
	//half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    output.positionWS = vertexInput.positionWS;
	output.positionCS = vertexInput.positionCS;

    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
	output.normalWS = normalInput.normalWS;
    output.tangentWS.xyz = normalInput.tangentWS;
	output.tangentWS.w = input.tangentOS.w * GetOddNegativeScale();
	output.bitangentWS = normalInput.bitangentWS;
	output.color = input.color;
	half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
	//output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
	output.shadowCoord = GetShadowCoord(vertexInput);
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

	return output;
}

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return ((x*(a*x+b))/(x*(c*x+d)+e));
}

half4 HybirdPBRFragment(Varyings input) : SV_Target
{
	NPRSurfaceData surfaceData;
	half2 uv;
#ifdef _FIXTANGENT
	uv = input.uv2;
#else
	uv = input.uv;
#endif
    InitializeNPRSurfaceData(uv, surfaceData);

    NPRInputData inputData;
    InitializeNPRInputData(input, surfaceData.normalTS, surfaceData.tangentNoise, inputData);

	half4 color = HybirdPBR(inputData,surfaceData);
	//color.rgb = ACESFilm(color.rgb);
	color.rgb = LinearToGamma22(color.rgb);
	
#ifdef _FUR
	color.a *= SAMPLE_TEXTURE2D(_FurNoise,sampler_FurNoise,uv) * saturate(_Opacity);
#endif

#ifdef _DEBUG
	return LinearToGamma22(debug.xyzz);
#endif
	return color;
}

half4 HybirdToonFragment(Varyings input) : SV_Target
{
	NPRSurfaceData surfaceData;
	half2 uv;
#ifdef _FIXTANGENT
	uv = input.uv2;
#else
	uv = input.uv;
#endif
    InitializeNPRSurfaceData(uv, surfaceData);

    NPRInputData inputData;
    InitializeNPRInputData(input, surfaceData.normalTS, surfaceData.tangentNoise, inputData);

	half4 color = HybirdToon(inputData,surfaceData);
	//color.rgb = ACESFilm(color.rgb);
	//color.rgb = LinearToGamma22(color.rgb);
#ifdef _DEBUG
	return debug.xyzz;
#endif
	return color;

}

#endif