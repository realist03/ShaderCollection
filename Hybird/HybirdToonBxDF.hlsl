#ifndef HYBIRD_TOONBXDF_INCLUDED
#define HYBIRD_TOONBXDF_INCLUDED
#include "HybirdPBRInput.hlsl"
half2 _uv;
half _Frame;

half3 Diffuse_Toon(half NoL, half NoV)
{
    float halfLambert = NoL * 0.5 + 0.5;
    float shadowStep = saturate(1.0 - (halfLambert - (_ShadowThreshold - _ShadowFeather)) / max(_ShadowFeather,HALF_MIN));
    half3 color = lerp(_Tint, _ShadowTint, shadowStep);
    return color;
}

half3 GGX_Toon(NPRInputData inputData, NPRSurfaceData surfaceData)
{
    //half3 specular = DisneyBRDF(surfaceData,N,L,V,H,X,Y);
}

half3 HybirdToonLit(NPRInputData inputData, NPRSurfaceData surfaceData, Light light)
{
    half3 N = inputData.normalWS;
	half3 L = light.direction;
	half3 V = inputData.viewDirWS;
	half3 X = inputData.tangentWS;
	half3 Y = inputData.bitangentWS;
	half3 H = normalize(L + V);

	half NoL = dot(N, L);
    half NoV = dot(N, V);
	half NoH = dot(N, H);
	half LoH = dot(L, H);
	half VoH = dot(V, H);

    half3 color = 0;
//Diffuse
    color += Diffuse_Toon(NoL,NoV) * surfaceData.baseColor;
//Specular
    //color += GGX_Toon();
    return color;
}

half4 HybirdToon(NPRInputData inputData, NPRSurfaceData surfaceData)
{
    Light light = GetMainLight(inputData.shadowCoord);

    return half4(HybirdToonLit(inputData,surfaceData,light),1);
}

#endif