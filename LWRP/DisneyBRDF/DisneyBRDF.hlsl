#ifndef DISNEYBRDF_INCLUDED
#define DISNEYBRDF_INCLUDED

#include "CustomInput.hlsl"
//////////////////////////////
//							//
//		 Disney BRDF		//
//							//
//////////////////////////////

half sqr(half x)
{
    return x * x;
}

half Pow5(half x)
{
    return x*x*x*x*x;
}
half SchlickFresnel(half u)
{
    half m = clamp(1-u, 0, 1);
    half m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

half3 F_Schlick1( half3 SpecularColor, half VoH )
{
	half Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
	
}

half GTR1(half NdotH, half a)
{
    if (a >= 1) return 1/PI;
    half a2 = a*a;
    half t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (PI*log(a2)*t);
}

half GTR2(half NdotH, half a)
{
    half a2 = a*a;
    half t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (PI * t*t);
}

half GTR2_aniso(half NdotH, half HdotX, half HdotY, half ax, half ay)
{
    return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

half smithG_GGX(half NdotV, half alphaG)
{
    half a = alphaG*alphaG;
    half b = NdotV*NdotV;
    return 1 / (NdotV + sqrt(a + b - a*b));
}

half smithG_GGX_aniso(half NdotV, half VdotX, half VdotY, half ax, half ay)
{
    return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
}

half D_GGXaniso( half ax, half ay, half NoH, half3 H, half3 X, half3 Y )
{
	half XoH = dot( X, H );
	half YoH = dot( Y, H );
	half d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
	return 1 / ( PI * ax*ay * d*d );
}

half3 mon2lin(half3 x)
{
    x = abs(x);
    return half3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}


half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter = 1 + (fd90 - 1) * Pow5(1 - NdotL);
    half viewScatter = 1 + (fd90 - 1) * Pow5(1 - NdotV);

    return lightScatter * viewScatter;
}

// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
    float bias = lerp(0,0,Roughness);
    float factor = lerp(1,1.51,Roughness);
	float FD90 = bias + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return DiffuseColor * ( (1 / PI) * FdV * FdL ) * factor;
}

float2 LightingFuncGGX_FV(float dotLH, float roughness)
{
	float alpha = roughness*roughness;

	// F
	float F_a, F_b;
	float dotLH5 = pow(1.0f-dotLH,5);
	F_a = 1.0f;
	F_b = dotLH5;

	// V
	float vis;
	float k = alpha/2.0f;
	float k2 = k*k;
	float invK2 = 1.0f-k2;
	vis = rcp(dotLH*dotLH*invK2 + k2);

	return float2(F_a*vis,F_b*vis);
}

float LightingFuncGGX_D(float dotNH, float roughness)
{
	float alpha = roughness*roughness;
	float alphaSqr = alpha*alpha;
	float pi = 3.14159f;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;

	float D = alphaSqr/(pi * denom * denom);
	return D;
}

float LightingFuncGGX_OPT3(float3 N, float3 V, float3 L, float roughness, float F0)
{
	float3 H = normalize(V+L);

	float dotNL = saturate(dot(N,L));
	float dotLH = saturate(dot(L,H));
	float dotNH = saturate(dot(N,H));

	float D = LightingFuncGGX_D(dotNH,roughness);
	float2 FV_helper = LightingFuncGGX_FV(dotLH,roughness);
	float FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;
	float specular = dotNL * D * FV;

	return specular;
}

half3 DisneyBRDF(CustomSurfaceData surfaceData, half3 L, half3 V, half3 N, half3 X, half3 Y)
{
    half NdotL = max(dot(N,L),0.0);
    half NdotV = max(dot(N,V),0.0);
 
    half3 H = normalize(L+V);
    half NdotH = max(dot(N,H),0.0);
    half LdotH = max(dot(L,H),0.0);
    half VdotH = max(dot(V,H),0.0);

    half3 Cdlin = surfaceData.albedo;
    half Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.
 
    half3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : half3(1,1,1); // normalize lum. to isolate hue+sat
    half3 Cspec0 = lerp(surfaceData.specular*.08*lerp(half3(1,1,1), Ctint, surfaceData.specularTint), Cdlin, surfaceData.metallic);
    half3 Csheen = lerp(half3(1,1,1), Ctint, surfaceData.sheenTint);
 
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and lerp in diffuse retro-reflection based on roughness
    //half FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    //half Fd90 = 0.5 + 2 * LdotH*LdotH * roughness;
    //half Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
    //half Fd = DisneyDiffuse(NdotV,NdotL,VdotH,surfaceData.roughness);
    half Fd = Diffuse_Burley(surfaceData.albedo,surfaceData.roughness,NdotV,NdotL,VdotH);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    //half Fss90 = LdotH*LdotH*roughness;
    //half Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    //half ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);
 
    // specular
    half aspect = sqrt(1-surfaceData.anisotropic*.9);
    half ax = max(.001, sqr(surfaceData.roughness)/aspect);
    half ay = max(.001, sqr(surfaceData.roughness)*aspect);
    half Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    half FH = SchlickFresnel(LdotH);
    half3 Fs = lerp(Cspec0, half3(1,1,1), FH);

    //half Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    //Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
    half Gs = LightingFuncGGX_OPT3(N,V,L,surfaceData.roughness,NdotH);
    Gs *= Gs;
    //half Gs = D_GGXaniso(ax, ay, NdotH, H, X, Y);



    // sheen
    half3 Fsheen = FH * surfaceData.sheen * surfaceData.sheen;
 
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    half Dr = GTR1(NdotH, lerp(.1,.001,surfaceData.clearcoatGloss));
    half Fr = lerp(.04, 1.0, FH);
    half Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
    
    //half3 a = SchlickFresnel(VdotH);
    return ((1/PI) * pow(Fd,0.45)*Cdlin + Fsheen) + Gs*Fs*Ds + .25*surfaceData.clearcoat*Gr*Fr*Dr;
    //return half4(NdotL * surfaceData.albedo,1);
    //return (1-surfaceData.metallic).xxxx;
}

half3 DisneyPBR(CustomSurfaceData surfaceData, half3 lightColor, half3 lightDirectionWS,
                half lightAttenuation, half3 normalWS, half3 viewDirectionWS,
                half3 tangentWS, half bitangentWS)
{
    return lightColor * lightAttenuation * DisneyBRDF(surfaceData, lightDirectionWS,viewDirectionWS,normalWS,tangentWS,bitangentWS);
}

half4 DisneyBRDFFragment(CustomInputData customInputData, CustomSurfaceData customSurfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(customSurfaceData.albedo,customSurfaceData.metallic,customSurfaceData.roughness,brdfData);

    Light mainLight = GetMainLight(customInputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, customInputData.normalWS, customInputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = DisneyPBR(customSurfaceData, mainLight.color, _MainLightPosition.xyz, mainLight.distanceAttenuation,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.bitangentWS);
    
    color += GlobalIllumination(brdfData, customInputData.bakedGI, customSurfaceData.occlusion, customInputData.normalWS, customInputData.viewDirectionWS);
    //#ifdef _ADDITIONAL_LIGHTS
    //    int pixelLightCount = GetAdditionalLightsCount();
    //    for (int i = 0; i < pixelLightCount; ++i)
    //    {
    //        Light light = GetAdditionalLight(i, inputData.positionWS);
    //        color += DisneyPBR(brdfData, mainLight, customInputData.normalWS, customInputData.viewDirectionWS);
    //    }
    //#endif
//
    //#ifdef _ADDITIONAL_LIGHTS_VERTEX
    //    color += inputData.vertexLighting * brdfData.diffuse;
    //#endif
//
    //color += emission;
//
    return half4(color,1);
}
#endif
