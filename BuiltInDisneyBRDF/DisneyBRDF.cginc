#ifndef DISNEYBRDF_INCLUDE
#define DISNEYBRDF_INCLUDE

#include "CustomInput.cginc"
#include "UnityPBSLighting.cginc"
#define UNITY_UNITY_PI            3.14159265359f

//////////////////////////////
//							//
//		 Disney BRDF		//
//							//
//////////////////////////////

half sqr(half x)
{
    return x * x;
}

half SchlickFresnel(half u)
{
    half m = clamp(1-u, 0, 1);
    half m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

half2 LightingFuncGGX_FV(half dotLH, half roughness)
{
	half alpha = roughness*roughness;

	// F
	half F_a, F_b;
	half dotLH5 = pow(1.0f-dotLH,5);
	F_a = 1.0f;
	F_b = dotLH5;

	// V
	half vis;
	half k = alpha/2.0f;
	half k2 = k*k;
	half invK2 = 1.0f-k2;
	vis = rcp(dotLH*dotLH*invK2 + k2);

	return half2(F_a*vis,F_b*vis);
}

half GTR1(half NdotH, half a)
{
    if (a >= 1) return 1/3.14159265359f;
    half a2 = a*a;
    half t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (3.14159265359f*log(a2)*t);
}

half GTR2(half NdotH, half a)
{
    half a2 = a*a;
    half t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (UNITY_UNITY_PI * t*t);
}

half GTR2_aniso(half NdotH, half HdotX, half HdotY, half ax, half ay)
{
    return 1 / (UNITY_UNITY_PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
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

half Vis_Schlick( half a, half NoV, half NoL )
{
	half k = a * 0.5;
	half Vis_SchlickV = NoV * (1 - k) + k;
	half Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}

half3 mon2lin(half3 x)
{
    x = abs(x);
    return half3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}

// [Burley 2012, "Physically-Based Shading at Disney"]
half3 Diffuse_Burley( half3 DiffuseColor, half Roughness, half NoV, half NoL, half VoH )
{
	half FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	half FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	half FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return 1 * ( (1 / UNITY_PI) * FdL * FdV )*1;
}

half3 Diffuse_Burley_Frostbite( half3 DiffuseColor, half Roughness, half NoV, half NoL, half VoH )
{
    half bias = lerp(0,0,Roughness);
    half factor = lerp(1,1.51,Roughness);
	half FD90 = bias + 2 * VoH * VoH * Roughness;
	half FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	half FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return 1 * ( FdV * FdL ) * factor / UNITY_PI;
}

//half fresnelReflectance( half3 H, half3 V, half F0 )
//{
//	half base = 1.0 - dot( V, H );
//	half exponential = pow( base, 5.0 );
//	return exponential + F0 * ( 1.0 - exponential );
//}
//half Kelemen(half NdotH,half3 H, half3 V, half roughness)
//{
//    half4 kelemen = SAMPLE_TEXTURE2D(_KelemenLUT, sampler_KelemenLUT, half2(NdotH, 1-roughness));
//	half PH = pow(2.0 * kelemen.g, 10.0);
//	half F = fresnelReflectance(H, V, 0.028);
//	half specularColor = max(PH * F / dot(H, H), 0);
//    return specularColor;
//}

//half PreintergratedSSS(half NdotL)
//{
//    half curve = _Subfurface;
//    half4 sss = SAMPLE_TEXTURE2D(_SkinLUT,sampler_SkinLUT,half2(NdotL,curve));
//    return sss;
//}

half3 SkinTranslucency(half3 L, half3 N, half3 V, half3 transCol, half3 lightCol, half subsurface, half shadowAttenuation)
{
 	half transVdotL = pow( saturate( dot( -(L+(N*_TransNormalDistortion)), V) ) , _TransScattering) * _TransDirect;
    half3 translucency = (transVdotL * _TransDirect + _TransAmbient) * 
                        _Translucency * subsurface * transCol*transCol * 
                        lightCol * lerp(1,shadowAttenuation,_TransShadow);
    return translucency;
}

half EnvBRDFApproxNonmetal( half Roughness, half NoV )
{

    // Same as EnvBRDFApprox( 0.04, Roughness, NoV )

    const half2 c0 = { -1, -0.0275 };

    const half2 c1 = { 1, 0.0425 };

    half2 r = Roughness * c0 + c1;

    return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;

}

UnityIndirect CreateIndirectLight (CustomInputData customInputData, CustomSurfaceData customSurfaceData,
                                    float3 viewDir)
{
    UnityIndirect indirectLight = (UnityIndirect)0;
    #if defined(FORWARD_BASE_PASS)
    indirectLight.diffuse = customInputData.sh;
    float3 reflectionDir = reflect(-viewDir, customInputData.normalWS);
    half mip = perceptualRoughnessToMipmapLevel(customSurfaceData.roughness);
	float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir,mip);
	indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
    #endif

    return indirectLight;
}

half3 DisneyBRDF(CustomSurfaceData surfaceData, half3 L, half3 V, half3 N, half3 X, half3 Y, half shadowAttenuation)
{    
    half NdotL = max(dot(N,L),0.0);
    half NdotV = max(dot(N,V),0.0);
 
    half3 H = normalize(L+V);
    half NdotH = max(dot(N,H),0.0);
    half LdotH = max(dot(L,H),0.0);
    half VdotH = max(dot(V,H),0.0);

    half3 Cdlin = surfaceData.albedo;

    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and lerp in diffuse retro-reflection based on roughness
    half FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    half Fd90 = 0.5 + 2 * LdotH*LdotH * surfaceData.roughness;
    half Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV)*shadowAttenuation;

    // Based on Hanrahan-Krueger brdf approximation of isotroUNITY_PIc bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    half Fss90 = LdotH*LdotH*surfaceData.roughness;
    half Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    half ss = saturate(1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5));

    half Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.
    half3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : half3(1,1,1); // normalize lum. to isolate hue+sat
    half3 Cspec0 = lerp(surfaceData.specular*.08*lerp(half3(1,1,1), Ctint, surfaceData.specularTint), Cdlin, surfaceData.metallic);
    // specular
    half aspect = sqrt(1-surfaceData.anisotropic*.9);
    half ax = max(.001, sqr(surfaceData.roughness)/aspect);
    half ay = max(.001, sqr(surfaceData.roughness)*aspect);
    half Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    half FH = SchlickFresnel(LdotH);
    half Fs = lerp(Cspec0.g, 1, FH);
    half Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
    half spe = Gs * Fs * Ds * NdotL * surfaceData.occlusion;
    // sheen
    half3 Csheen = lerp(half3(1,1,1), Ctint, surfaceData.sheenTint);
    half3 Fsheen = FH * surfaceData.sheen * Csheen * surfaceData.sheenTint;
 
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    half Dr = GTR1(NdotH, lerp(.1,.001,surfaceData.clearcoatGloss));
    half Fr = lerp(.04, 1.0, FH);
    half Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);

    //return N;
    //return (lerp(Fd, ss, saturate(surfaceData.subsurface*(1-NdotL)+0.5)));
    return ((lerp(Fd, ss, saturate(surfaceData.subsurface*(1-NdotL)+0.5))*Cdlin*NdotL) * (1-surfaceData.metallic) +
            (spe)*UNITY_PI + UNITY_PI*0.25*surfaceData.clearcoat*Gr*Fr*Dr)*shadowAttenuation;
}

half3 DisneyBRDF_OP(CustomSurfaceData surfaceData, half3 L, half3 V, half3 N, half3 X, half3 Y, half shadowAttenuation)
{    
    half NdotL = max(dot(N,L),0.0);
    half NdotV = max(dot(N,V),0.0);
 
    half3 H = normalize(L+V);
    half NdotH = max(dot(N,H),0.0);
    half LdotH = max(dot(L,H),0.0);
    half VdotH = max(dot(V,H),0.0);

    half3 Cdlin = surfaceData.albedo;

    half Fd = NdotL;
    half Ds = GTR2(NdotH,surfaceData.roughness);

	half2 FV_helper = LightingFuncGGX_FV(LdotH,surfaceData.roughness);
    half F0 = surfaceData.specularTint.g;
	half FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;

    half a = sqr(surfaceData.roughness);    
    half a2 = sqr(a);
    //half spe = a2 / sqr(sqr(NdotH) * (a2-1) + 1) * sqr(LdotH) * (surfaceData.roughness * 4 + 2);
    half d = NdotH * NdotH * (a2-1) + 1;

    half LoH2 = LdotH * LdotH;
    half specularTerm = a2 / ((d * d) * max(0.1, LoH2) * (a * 4 + 2));
    half3 brdfSpe = lerp(half3(0.04,0.04,0.04), surfaceData.albedo, surfaceData.metallic);
    //spe = saturate(spe - 6.103515625*2.718281828459-5);
    //return specularTerm*NdotL.xxx;
    //return brdfSpe * NdotL;
    return Fd * Cdlin * (1-surfaceData.metallic) + specularTerm*brdfSpe*NdotL;

}

half3 DisneyPBR(CustomSurfaceData surfaceData, half atten, half3 lightDir, half3 normalWS, half3 viewDirectionWS,
                half3 tangentWS, half3 binormalWS)
{
    //return half4(light.color,1);
    return _LightColor0 * DisneyBRDF(surfaceData, lightDir,viewDirectionWS,normalWS,tangentWS,binormalWS,atten);
}

half3 DisneyPBR_OP(CustomSurfaceData surfaceData, half atten, half3 lightDir, half3 normalWS, half3 viewDirectionWS,
                half3 tangentWS, half3 binormalWS)
{
    //return half4(light.color,1);
    return _LightColor0 * DisneyBRDF_OP(surfaceData, lightDir,viewDirectionWS,normalWS,tangentWS,binormalWS,atten);
}

half4 DisneyBRDFFragment(CustomInputData customInputData, CustomSurfaceData customSurfaceData)
{
    half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(customInputData.positionWS));
    half3 color = DisneyPBR(customSurfaceData, customInputData.atten, lightDir,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.bitangentWS);
    
    color += SkinTranslucency(lightDir,customInputData.normalWS,
                    customInputData.viewDirectionWS,customSurfaceData.albedo,
                    customSurfaceData.subsurface,_LightColor0,customInputData.atten);
    UnityIndirect indirect = CreateIndirectLight(customInputData,customSurfaceData,customInputData.viewDirectionWS);
    
    half surfaceReduction = EnvBRDFApproxNonmetal(customSurfaceData.roughness,saturate(dot(customInputData.normalWS,customInputData.viewDirectionWS)));
    half3 indirectCol = indirect.diffuse * customSurfaceData.albedo + indirect.specular * surfaceReduction;
    color += indirectCol;
    color += customSurfaceData.emission * _EmissionColor;
    //return surfaceReduction.xxxx;
    //return half4(indirectLight.specular,1);
    return half4(color,1);
}

half4 DisneyBRDFFragment_OP(CustomInputData customInputData, CustomSurfaceData customSurfaceData)
{
    half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(customInputData.positionWS));
    half3 color = DisneyPBR_OP(customSurfaceData, customInputData.atten, lightDir,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.bitangentWS);
    
    color += SkinTranslucency(lightDir,customInputData.normalWS,
                    customInputData.viewDirectionWS,customSurfaceData.albedo,
                    customSurfaceData.subsurface,_LightColor0,customInputData.atten);
    UnityIndirect indirect = CreateIndirectLight(customInputData,customSurfaceData,customInputData.viewDirectionWS);
    
    half surfaceReduction = EnvBRDFApproxNonmetal(customSurfaceData.roughness,saturate(dot(customInputData.normalWS,customInputData.viewDirectionWS)));
    half3 indirectCol = indirect.diffuse * customSurfaceData.albedo + indirect.specular * surfaceReduction;
    color += indirectCol;
    color += customSurfaceData.emission * _EmissionColor;
    //return surfaceReduction.xxxx;
    //return half4(indirectLight.specular,1);
    return half4(color,1);
}

#endif