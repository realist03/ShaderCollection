#ifndef DISNEYBRDF_INCLUDE
#define DISNEYBRDF_INCLUDE

#include "CustomInput.cginc"

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
    return a2 / (UNITY_PI * t*t);
}

half GTR2_aniso(half NdotH, half HdotX, half HdotY, half ax, half ay)
{
    return 1 / (UNITY_PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
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

half FabricD (half NdotH, half roughness)
{
     return 0.96 * pow(1 - NdotH, 2) + 0.057;
}

// G GGX function for clearcoat
half G_GGX(half dotVN, half alphag)
{
		half a = alphag * alphag;
		half b = dotVN * dotVN;
		return 1.0 / (dotVN + sqrt(a + b - a * b));
}

half GGX_Mobile(half Roughness, half NoH, half3 H, half3 N)
{
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"

    // In mediump, there are two problems computing 1.0 - NoH^2
    // 1) 1.0 - NoH^2 suffers halfing point cancellation when NoH^2 is close to 1 (highlights)
    // 2) NoH doesn't have enough precision around 1.0
    // Both problem can be fixed by computing 1-NoH^2 in highp and providing NoH in highp as well

    // However, we can do better using Lagrange's identity:
    //      ||a x b||^2 = ||a||^2 ||b||^2 - (a . b)^2
    // since N and H are unit vectors: ||N x H||^2 = 1.0 - NoH^2
    // This computes 1.0 - NoH^2 directly (which is close to zero in the highlights and has
    // enough precision).
    // Overall this yields better performance, keeping all computations in mediump

#if MOBILE_GGX_USE_FP16
	half3 NxH = cross(N, H);
	half OneMinusNoHSqr = dot(NxH, NxH);
#else
    half OneMinusNoHSqr = 1.0 - NoH * NoH;
#endif

	half a = Roughness * Roughness;
	half n = NoH * a;
	half p = a / (OneMinusNoHSqr + n * n);
	half d = p * p;
	return saturate(d);
}

half Vis_Schlick( half a, half NoV, half NoL )
{
	half k = a * 0.5;
	half Vis_SchlickV = NoV * (1 - k) + k;
	half Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}

half Vis_SmithJointApprox( half a2, half NoV, half NoL )
{
	half a = sqrt(a2);
	half Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
	half Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
	return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
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
 	//half transVdotL = pow( saturate( dot( -(L+(N*_TransNormalDistortion)), V) ) , _TransScattering) * _TransDirect;
    //half3 translucency = (transVdotL * _TransDirect + _TransAmbient) * 
    //                    _Translucency * subsurface * transCol * 
    //                    _TransColor * lightCol * lerp(1,shadowAttenuation,_TransShadow);

    half3 lightDir = L + N * _TransNormalDistortion;
	half transVoL = pow( saturate( dot( V, -L ) ), _TransScattering );
	half3 trans = lerp(1,shadowAttenuation,_TransShadow) * (transVoL * _TransDirect + _TransAmbient) * _TransColor * subsurface;

	half3 translucency = transCol * trans * _Translucency;

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

half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    Roughness = max(0.1,Roughness);
	half4 r = Roughness * c0 + c1;
	half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate( 50.0 * SpecularColor.g );

	return SpecularColor * AB.x + AB.y;
}

//half3 EnvBRDF( half3 SpecularColor, half Roughness, half NoV )
//{
//	// Importance sampled preintegrated G * F
//	half2 AB = tex2D(_BRDFLUT, half2( NoV, Roughness )).rg;
//
//	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
//	half3 GF = SpecularColor * AB.x + saturate( 50.0 * SpecularColor.g ) * AB.y;
//	return GF;
//}


half LinearOneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = 1-0.04;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

half3 LinearDiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (half3(0.04,0.04,0.04), albedo, metallic);
    oneMinusReflectivity = LinearOneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

UnityIndirect CreateIndirectLight (CustomInputData customInputData, CustomSurfaceData customSurfaceData,
                                    half3 viewDir,half3 speCol)
{
    UnityIndirect indirectLight = (UnityIndirect)0;
    #if defined(FORWARD_BASE_PASS)
    indirectLight.diffuse = customInputData.sh * customSurfaceData.occlusion;
    half3 reflectionDir = reflect(-viewDir, customInputData.normalWS);

    Unity_GlossyEnvironmentData     envData ;
    envData.roughness  =  1-customSurfaceData.roughness * customSurfaceData.roughness;
    envData.roughness *= 1.7-0.7*envData.roughness;
    envData.reflUVW  =  reflectionDir;
    
    half mip = perceptualRoughnessToMipmapLevel(customSurfaceData.roughness);
	half4 envSample = (UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir,mip));

    indirectLight.specular = SRGBToLinear(half4(DecodeHDR(envSample, unity_SpecCube0_HDR ),1));
    half NoV = saturate(dot(customInputData.normalWS,viewDir));
    //half surfaceReductionMetal = 1-EnvBRDFApprox(customSurfaceData.roughness,speCol,NoV);
    half surfaceReduction = (0.6-0.08*customSurfaceData.roughness);
    surfaceReduction = 1.0 - customSurfaceData.roughness*customSurfaceData.roughness*customSurfaceData.roughness*surfaceReduction;

    //half surfaceReductionNoMetal = 1-EnvBRDFApproxNonmetal(customSurfaceData.roughness,NoV);
    //half surfaceReduction = lerp(surfaceReductionNoMetal,surfaceReductionMetal,customSurfaceData.metallic);
    //half surfaceReduction = 1.0 / (customSurfaceData.roughness + 1.0);
    //half surfaceReduction = max(0.1,1-customSurfaceData.roughness);
    //half3 surfaceReductionLUT = EnvBRDF(speCol,customSurfaceData.roughness,NoV);
    half oneMinusReflectivity = LinearOneMinusReflectivityFromMetallic(customSurfaceData.metallic);
    half grazingTerm = saturate(1-customSurfaceData.roughness*customSurfaceData.roughness + (1-oneMinusReflectivity));
    indirectLight.specular *= surfaceReduction * FresnelLerp(speCol,grazingTerm,NoV) * customSurfaceData.occlusion;
    //indirectLight.specular = surfaceReduction;
    #endif

    return indirectLight;
}

half3 DisneyBRDF(CustomInputData customInputData,CustomSurfaceData surfaceData, half3 L, half3 V, half3 N, half3 X, half3 Y, half shadowAttenuation)
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
    //half Fd90 = 0.5 + 2 * LdotH*LdotH * surfaceData.roughness;
    //half Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);

    // Based on Hanrahan-Krueger brdf approximation of isotroUNITY_PIc bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    half Fss90 = LdotH*LdotH*surfaceData.roughness;
    half Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    half ss = saturate(1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5));

    //half Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.
    //half3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : half3(1,1,1); // normalize lum. to isolate hue+sat
    half3 Cspec0 = lerp(0.04, Cdlin, surfaceData.metallic);
    ////// specular
    //half aspect = sqrt(1-surfaceData.anisotropic*.9);
    //half ax = max(.001, sqr(surfaceData.roughness)/aspect);
    //half ay = max(.001, sqr(surfaceData.roughness)*aspect);
    //half Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    //half FH = SchlickFresnel(LdotH);
    //half Fs = lerp(Cspec0.g, 1, FH);
    //half Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    //Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
    //half spe = Gs * Fs * Ds;

    half a = surfaceData.roughness*surfaceData.roughness;
    half Ds = GTR2(NdotH, a);
    //half Ds = GGX_Mobile(surfaceData.roughness,NdotH,H,N);
    half FH = SchlickFresnel(LdotH);
    half3 Fs = lerp(Cspec0, 1, FH);
    //half Gs  = (smithG_GGX(NdotV, surfaceData.roughness))*(smithG_GGX(NdotL, surfaceData.roughness))/ max(0.01,(4*NdotL*NdotV));
    half Vs = Vis_Schlick(a,NdotV,NdotL);
    half3 spe = max(0,Ds * Fs * Vs);

    ////specular
    //half a = sqr(surfaceData.roughness);    
    //half a2 = sqr(a);
    //half spe = a2 / sqr(sqr(NdotH) * (a2-1) + 1) * sqr(LdotH) * (surfaceData.roughness * 4 + 2);
    //half d = NdotH * NdotH * (a2-1) + 1;
//
    //half LoH2 = LdotH * LdotH;
    //half specularTerm = a2 / ((d * d) * max(0.1, LoH2) * (a * 4 + 2));
    //half3 brdfSpe = lerp(half3(0.04,0.04,0.04), surfaceData.albedo, surfaceData.metallic);
    //spe = specularTerm * brdfSpe * NdotL;

    //// sheen
    //half3 Csheen = lerp(half3(1,1,1), Ctint, surfaceData.sheenTint);
    //half3 Fsheen = FH * surfaceData.sheen * Csheen * surfaceData.sheenTint;
 //
    //// clearcoat (ior = 1.5 -> F0 = 0.04)
    //half Dr = GTR1(NdotH, lerp(.1,.001,surfaceData.clearcoatGloss));
    //half Fr = lerp(.04, 1.0, FH);
    //half Gr = G_GGX(NdotL, .25) * G_GGX(NdotV, .25);
    //half clearcoat = max(0.0,0.25*surfaceData.clearcoat*Gr*Fr*Dr);
    half3 color;
    color = ((lerp(NdotL, ss, surfaceData.subsurface)*Cdlin) * (1-surfaceData.metallic) +
            spe)*NdotL*shadowAttenuation;

    UnityIndirect indirect = CreateIndirectLight(customInputData,surfaceData,customInputData.viewDirectionWS,Cspec0);
    
    half3 indirectCol = indirect.diffuse * surfaceData.albedo * (1-surfaceData.metallic) + indirect.specular;
    color *= _LightColor0;

    color += indirectCol;

    return color;
}

half3 DisneyBRDF_OP(CustomSurfaceData surfaceData, half3 L, half3 V, half3 N, half3 X, half3 Y, half shadowAttenuation)
{    
    half NdotL = max(dot(N,L),0.0);
 
    half3 H = normalize(L+V);
    half NdotH = max(dot(N,H),0.0);
    half LdotH = max(dot(L,H),0.0);

    half3 Cdlin = surfaceData.albedo;

    half Fd = NdotL;
    //half Ds = GTR2(NdotH,surfaceData.roughness);

	//half2 FV_helper = LightingFuncGGX_FV(LdotH,surfaceData.roughness);
    //half F0 = surfaceData.specularTint.g;
	//half FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;
    half a = sqr(surfaceData.roughness);   
    half a2 = sqr(a);
    half spe = a2 / (sqr(sqr(NdotH) * (a2-1) + 1) * sqr(LdotH) * (surfaceData.roughness + 0.5) * 4 * UNITY_PI);
    half d = NdotH * NdotH * (a2-1) + 1.00001f;

    half LoH2 = LdotH * LdotH;
    half3 brdfSpe = lerp(half3(0.04,0.04,0.04), surfaceData.albedo, surfaceData.metallic);
    //spe = saturate(spe - 6.103515625*2.718281828459-5);
    //return specularTerm*NdotL.xxx;
    //return brdfSpe * NdotL;
    return Fd * Cdlin * (1-surfaceData.metallic) + spe*brdfSpe*NdotL;

}

half3 DisneyPBR(CustomInputData customInputData,CustomSurfaceData surfaceData, half atten, half3 lightDir, half3 normalWS, half3 viewDirectionWS,
                half3 tangentWS, half3 binormalWS)
{
    half3 color = DisneyBRDF(customInputData,surfaceData, lightDir,viewDirectionWS,normalWS,tangentWS,binormalWS,atten);
    color += saturate(SkinTranslucency(lightDir,customInputData.normalWS,
                    customInputData.viewDirectionWS,surfaceData.albedo,
                    _LightColor0,surfaceData.subsurface,customInputData.atten));

    return color;
}

half3 DisneyPBR_OP(CustomSurfaceData surfaceData, half atten, half3 lightDir, half3 normalWS, half3 viewDirectionWS,
                half3 tangentWS, half3 binormalWS)
{
    return DisneyBRDF_OP(surfaceData, lightDir,viewDirectionWS,normalWS,tangentWS,binormalWS,atten);
}

half4 DisneyBRDFFragment(CustomInputData customInputData, CustomSurfaceData customSurfaceData)
{
    half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(customInputData.positionWS));
    half3 color = DisneyPBR(customInputData,customSurfaceData, customInputData.atten, lightDir,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.bitangentWS);

    color += customSurfaceData.emission * customSurfaceData.albedo * _EmissionStrength;
    //return half4(indirect.specular,1);
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
    color *= _LightColor0 * customInputData.atten;

    half3 Cspec0 = lerp(0.04, customSurfaceData.albedo, customSurfaceData.metallic);

    UnityIndirect indirect = CreateIndirectLight(customInputData,customSurfaceData,customInputData.viewDirectionWS,Cspec0);
    
    half3 indirectCol = indirect.diffuse * customSurfaceData.albedo * (1-customSurfaceData.metallic) + indirect.specular;
    indirectCol *= customSurfaceData.occlusion;
    color += indirectCol;
    color += customSurfaceData.emission * customSurfaceData.albedo * _EmissionStrength;

    return half4(color,1);
}

half FabricScatterFresnelLerp(half nv, half scale)
{
     half t0 = Pow4 (1 - nv);
     half t1 = 0.4 * (1 - nv);
     return (t1 - t0) * scale + t0; 
}

half3 ShiftTangent(half3 T, half3 N, half shift)
{
    return normalize(T + N * shift);
}

half SpecularExponent(half3 T, half3 V, half3 L, half power, half strength)
{
    half3 H = normalize(L+V);
    half TdotH = dot(T,H);
    return pow(sqrt(1-(TdotH*TdotH)),power)*strength*smoothstep(-1,0,TdotH);
}

half3 FurBRDF(half3 N, half3 L ,half3 V , half roughness, half metallic, half3 albedo, half3 sh, half FUR_OFFSET, half _FresnelStrength,half _FresnelPower, 
            half _ShiftT, half shiftTMap, half3 normalTS, half3 bitangentTS, half3 lightDirTS, half3 viewDirectionTS, half _Power1, half _Power2, half _Strength1, half _Strength2 )
{
    half3 H = normalize(L + V);

    half NoV = saturate(dot(N,V));
    half NoL = saturate(dot(N,L));
    half NoH = saturate(dot(N,H));
    half LoV = saturate(dot(L,V));
    half LoH = saturate(dot(L,H));

    half4 color;

    //diffuse
    half diffuseTerm = NoL;
    //specular
    half a = sqr(roughness);    
    half a2 = sqr(a);
    half spe = a2 / sqr(sqr(NoH) * (a2-1) + 1) * sqr(LoH) * (roughness * 4 + 2);
    half dGGX = NoH * NoH * (a2-1) + 1;
    half dFabric = FabricD (NoH, roughness);
    half d = FabricD (NoH, roughness);
    half LoH2 = LoH * LoH;
    half specularTerm = a2 / ((d * d) * max(0.1, LoH) * (a * 4 + 2));
    half3 brdfSpe = lerp(half3(0.04,0.04,0.04), albedo, metallic);
    color.rgb = diffuseTerm * (1-metallic) * albedo + specularTerm*brdfSpe*NoL;
    //occlusion
    half occlusion = FUR_OFFSET;
    half3 SHL = sh * occlusion * albedo*0.5;
    half Fresnel = pow(1-max(0,dot(N,V)),_FresnelPower);
    half RimLight = Fresnel * occlusion;
    RimLight *= RimLight;
    RimLight *= _FresnelStrength;
    color.rgb += RimLight;
    color.rgb *= _LightColor0;

    //color *= occlusion;
    color.rgb += SHL;

    half shiftMap = shiftTMap - 0.5;

    half3 shiftT = ShiftTangent(bitangentTS,normalTS,shiftMap+_ShiftT);


    half spe1 = SpecularExponent(shiftT,viewDirectionTS,
                lightDirTS,_Power1,_Strength1);

    half spe2 = SpecularExponent(shiftT,viewDirectionTS,
                lightDirTS,_Power2,_Strength2);

    half speH = spe1 + spe2;
    color.rgb += speH;
    return color;

}

#endif