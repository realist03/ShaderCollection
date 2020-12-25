#ifndef HYBIRD_BXDF_INCLUDED
#define HYBIRD_BXDF_INCLUDED
#include "HybirdPBRInput.hlsl"

half3 RampDiffuse(NPRSurfaceData surfaceData, half NoL, half rampHeightOffset)
{
	half rampSmooth = lerp(_RampSmooth,rampHeightOffset,saturate(rampHeightOffset));
	half _rampTex1 = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,1-half2(NoL+_Layer1Offset,rampSmooth)).r;
	half _rampTex2 = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,1-half2(NoL+_Layer2Offset,rampSmooth)).g;
	half _rampTex3 = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,1-half2(NoL+_Layer3Offset,rampSmooth)).b;

	half3 baseCol = surfaceData.baseColor;
	half3 layer1Ramp = lerp(_Layer1Tint.rgb*baseCol, baseCol,    _rampTex1);
	half3 layer2Ramp = lerp(_Layer2Tint.rgb*baseCol, layer1Ramp, _rampTex2);
	half3 layer3Ramp = lerp(_Layer3Tint.rgb*baseCol, layer2Ramp, _rampTex3);
	
	half3 mixLayer01 = lerp(baseCol,   layer1Ramp,_Layer1Tint.a);
	half3 mixLayer12 = lerp(mixLayer01,layer2Ramp,_Layer2Tint.a);
	half3 mixLayer23 = lerp(mixLayer12,layer3Ramp,_Layer3Tint.a);
debug = _rampTex3;
	return mixLayer23;
}

half3 MobilePBRSpecularTerm(NPRSurfaceData surfaceData, half NoH, half LoH)
{
	//Optimizing PBR
	half perceptualRoughness = surfaceData.roughness;
	half roughness = max(perceptualRoughness*perceptualRoughness, HALF_MIN);
	half roughness2 = roughness * roughness;
	half normalizationTerm = roughness * 4.0h + 2.0h;
	half roughness2MinusOne = roughness2 - 1.0h;
    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);
	half3 brdfSpecular = lerp(kDieletricSpec.rgb, surfaceData.baseColor, surfaceData.metallic);
	specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
	half3 color = specularTerm * brdfSpecular * surfaceData.specular;

	return color;
}

float sqr(float x) { return x*x; }

float3 Pow4(float3 x) { return x*x*x*x; }

float3 Pow5(float3 x) { return x*x*x*x*x; }

float SchlickFresnel(float u)
{
    float m = clamp(1-u, 0, 1);
    float m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
    if (a >= 1) return 1/PI;
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (PI * t*t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

float smithG_GGX(float NdotV, float alphaG)
{
    float a = alphaG*alphaG;
    float b = NdotV*NdotV;
    return 1 / (NdotV + sqrt(a + b - a*b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
}

float3 Diffuse_Burley( NPRSurfaceData surfaceData, float NoV, float NoL, float VoH ,float LoH)
{
	float FD90 = 0.5 + 2 * VoH * VoH * surfaceData.roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	float3 FD = saturate(FdV * FdL);
    //float FL = SchlickFresnel(NoL), FV = SchlickFresnel(NoV);
    float Fss90 = LoH*LoH*surfaceData.roughness;
	float FsV = 1 + (Fss90 - 1) * Pow5( 1 - NoV );
	float FsL = 1 + (Fss90 - 1) * Pow5( 1 - NoL );
    //float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
	float Fss = saturate(FsV * FsL);
    float ss = 1.25 * (Fss * (1 / (NoL + NoV) - .5) + .5);
	ss = max(0,ss);
	float Fsheen = 0;

	return lerp(FD, ss, surfaceData.subsurface)*surfaceData.baseColor + Fsheen;
}

half3 Diffuse_Fabric(NPRSurfaceData surfaceData, half NoL)
{
	return surfaceData.baseColor * NoL * lerp(1, 0.5, surfaceData.roughness);
}

half3 Dterm_Fabric_Approach(half NoH)
{
	return 0.96 * pow(1-NoH,2) + 0.057;
}

float D_InvGGX( float a2, float NoH )
{
	float A = 4;
	float d = ( NoH - a2 * NoH ) * NoH + a2;
	return rcp( PI * (1 + A*a2) ) * ( 1 + 4 * a2*a2 / ( d*d ) );
}

float Vis_Cloth( float NoV, float NoL )
{
	return rcp( 4 * ( NoL + NoV - NoL * NoV ) );
}

float3 UE_F_Schlick( float3 SpecularColor, float VoH )
{
	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
	
}

float3 Hue( float H )
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate( float3(R,G,B) );
}

half3 Diffuse_Oren_nayar(NPRSurfaceData surfaceData, half NoV)
{
	half3 diffuse = lerp(1,pow(1 - saturate(NoV * 0.5),2) * 0.62,surfaceData.roughness);
	return diffuse * surfaceData.baseColor;
}

half3 ClothBxDF(NPRSurfaceData surfaceData, half3 spe1, half NoH, half NoV, half NoL, half VoH)
{
	half D2 = D_InvGGX(Pow4(surfaceData.roughness),NoH);
	half Vis2 = Vis_Cloth(NoV,NoL);
	half3 F2 = UE_F_Schlick(surfaceData.baseColor,VoH);
	half3 spe2 = NoL * (D2*Vis2) * F2;
	spe2 *= surfaceData.specular;
	return (lerp(spe1,spe2,surfaceData.cloth));
}

half3 Approach_ClothBxDF(NPRSurfaceData surfaceData, half NoH, half VoH, half NoL, half NoV)
{
	//D
	half3 D = Dterm_Fabric_Approach(NoH);
	//F
	half3 F = UE_F_Schlick(surfaceData.baseColor,NoV);
	//G
	float G = smithG_GGX(NoL, .25) * smithG_GGX(NoV, .25);

	return D * G * F;

}

void CalculateTangentRotateOffset(half rotation, half offset, half3 N, half3 oX, out half3 X, out half3 Y)
{
	half a = rotation / 180 * 3.1415926;
	half3x3 tangent_roate = float3x3(cos(a), sin(a), 0,
		                             sin(a), cos(a), 0,
		                                  0,      0, 1);
	X = mul(tangent_roate, oX);
	X = ShiftTangent(X,N,offset);
	Y = cross(N,X);
}

void CalculateAnisotropic(half aniso, half roughnessX, half roughnessY, out half ax, out half ay)
{
	half aspect = sqrt(1-aniso*.9);
    ax = max(.001, sqr(roughnessX)/aspect);
    ay = max(.001, sqr(roughnessX)*aspect);
}

void GetFTerm(NPRSurfaceData surfaceData, half LoH, out half3 Fs)
{
	float3 Cdlin = surfaceData.baseColor;
    float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.

    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
    float3 Cspec0 = lerp(surfaceData.specular*.08*lerp(float3(1,1,1), Ctint, surfaceData.specular), Cdlin, surfaceData.metallic);

    float FH = SchlickFresnel(LoH);
    Fs = lerp(Cspec0, float3(1,1,1), FH);

}

float Vis_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL)
{
	float Vis_SmithV = NoL * length(float3(ax * XoV, ay * YoV, NoV));
	float Vis_SmithL = NoV * length(float3(ax * XoL, ay * YoL, NoL));
	return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
}

half3 AnisotropicSpecular(NPRSurfaceData surfaceData, half3 V, half3 H, half3 X, half3 Y, 
						  half NoL, half NoH, half NoV, half LoH, half ax, half ay)
{

	half3 Fs;
	GetFTerm(surfaceData,LoH,Fs);

	//D
	half3 D = GTR2_aniso(NoH,dot(H,X),dot(H,Y),ax,ay);

	//F

	//G
	//half G = smithG_GGX_aniso(NoV,dot(V,X),dot(V,Y),ax,ay);
	//G *= smithG_GGX_aniso(NoL,dot(_LightDir,X),dot(_LightDir,Y),ax,ay);
	//return D * G * Fs;

	// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
	// Vis = G / (4*NoL*NoV)
	half Vis = Vis_SmithJointAniso(ax,ay,NoV,NoL,dot(X,V),dot(X,_LightDir),dot(Y,V),dot(Y,_LightDir));
	return D * Vis * Fs;
}

half3 TrippleClothBxDF(NPRSurfaceData surfaceData, half3 N, half3 X, half3 Y, half3 H, half3 V, 
					   half NoL, half NoH, half NoV, half LoH)
{
	half3 X1, Y1, X2, Y2, X3, Y3;
	CalculateTangentRotateOffset(_Layer1ShininessDirection,_Layer1ShininessOffset,N,X,X1,Y1);
	CalculateTangentRotateOffset(_Layer2ShininessDirection,_Layer2ShininessOffset,N,X,X2,Y2);
	CalculateTangentRotateOffset(_Layer3ShininessDirection,_Layer3ShininessOffset,N,X,X3,Y3);

	half ax1, ay1, ax2, ay2, ax3, ay3;
	CalculateAnisotropic(1-_Layer1RoughnessX*surfaceData.roughness,_Layer1RoughnessX*surfaceData.roughness,_Layer1RoughnessY,ax1,ay1);
	CalculateAnisotropic(1-_Layer2RoughnessX*surfaceData.roughness,_Layer2RoughnessX*surfaceData.roughness,_Layer2RoughnessY,ax2,ay2);
	CalculateAnisotropic(1-_Layer3RoughnessX*surfaceData.roughness,_Layer3RoughnessX*surfaceData.roughness,_Layer3RoughnessY,ax3,ay3);

	half3 spe1 = AnisotropicSpecular(surfaceData,V,H,X1,Y1,NoL,NoH,NoV,LoH,ax1,ay1) * _Layer1ShininessTint.rgb;
	half3 spe2 = AnisotropicSpecular(surfaceData,V,H,X2,Y2,NoL,NoH,NoV,LoH,ax2,ay2) * _Layer2ShininessTint.rgb;
	half3 spe3 = AnisotropicSpecular(surfaceData,V,H,X3,Y3,NoL,NoH,NoV,LoH,ax3,ay3) * _Layer3ShininessTint.rgb;

	//half3 spe1 = saturate(GTR2_aniso(NoH,dot(H,X1),dot(H,Y1),ax1,ay1)) * _Layer1ShininessTint;
	//half3 spe2 = saturate(GTR2_aniso(NoH,dot(H,X2),dot(H,Y2),ax2,ay2)) * _Layer2ShininessTint;
	//half3 spe3 = saturate(GTR2_aniso(NoH,dot(H,X3),dot(H,Y3),ax3,ay3)) * _Layer3ShininessTint;

	//half3 spe1 = D_KajiyaKay(X1,H,_Layer1Shininess) * _Layer1ShininessTint;
	//half3 spe2 = D_KajiyaKay(X2,H,_Layer2Shininess) * _Layer2ShininessTint;
	//half3 spe3 = D_KajiyaKay(X3,H,_Layer3Shininess) * _Layer3ShininessTint;

	half3 spe = spe1 + spe2 + spe3;

	return spe;
}

float3 DisneyBRDF(NPRSurfaceData surfaceData, float NoL, float NoV, float NoH, float LoH, 
				  float XoL, float YoL, float XoV, float YoV, float XoH, float YoH)
{
	float3 Cdlin = surfaceData.baseColor;
    float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.

    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
    float3 Cspec0 = lerp(surfaceData.specular*.08*lerp(float3(1,1,1), Ctint, surfaceData.specular), Cdlin, surfaceData.metallic);
    float3 Csheen = lerp(float3(1,1,1), Ctint, _SheenTint);
	//surfaceData.specular = Cspec0;
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    //float FL = SchlickFresnel(NoL), FV = SchlickFresnel(NoV);
    //float Fd90 = 0.5 + 2 * LoH*LoH * surfaceData.roughness;
    //float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    //float Fss90 = LoH*LoH*surfaceData.roughness;
    //float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    //float ss = 1.25 * (Fss * (1 / (NoL + NoV) - .5) + .5);
	//ss = max(0,ss);
    // specular
    float aspect = sqrt(1-surfaceData.anisotropic*.9);
    float ax = max(.001, sqr(surfaceData.roughness)/aspect);
    float ay = max(.001, sqr(surfaceData.roughness)*aspect);

    float Ds = GTR2_aniso(NoH, XoH, YoH, ax, ay);
	//float Ds = GTR2(NoH, surfaceData.roughness);

    float FH = SchlickFresnel(LoH);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);

    float Gs;
    Gs  = smithG_GGX_aniso(NoL, XoL, YoL, ax, ay);
    Gs *= smithG_GGX_aniso(NoV, XoV, YoV, ax, ay);
	//float Gs = smithG_GGX(NoV,surfaceData.roughness);
	//Gs *= smithG_GGX(NoL,surfaceData.roughness);

    // sheen
    //float3 Fsheen = FH * surfaceData.sheen * Csheen;

    // clearcoat (ior = 1.5 -> F0 = 0.04)
    //float Dr = GTR1(NoH, lerp(.1,.001,surfaceData.clearCoatGloss));
    //float Fr = lerp(.04, 1.0, FH);
    //float Gr = smithG_GGX(NoL, .25) * smithG_GGX(NoV, .25);

	//float3 diffuse = ((1/PI) * lerp(Fd, ss, surfaceData.subsurface)*Cdlin + Fsheen) * (1-surfaceData.metallic);
	float3 spe = saturate(Gs)*Fs*Ds * NoL;
	//float3 clearCoat = 0.25*surfaceData.clearCoat*Gr*Fr*Dr;
	float3 color = spe;

    return color;
}

half3 Iridescence(NPRSurfaceData surfaceData, half3 c, half NoV)
{
	half3 k = half3(1,1,1);
	half t = NoV * PI * 6;
	half3 v = c;
	c = v * cos(t) + cross(k,v) * sin(t) + k * dot(k,v) * (1 - cos(t));
	return lerp(1,c, surfaceData.iridescence.a * (1-surfaceData.roughness));
}

half3 EyesLit(half3 V, half2 screenUV)
{
	half3 offset = half3(dot(V,screenUV.x),dot(V,screenUV.y),dot(V,_EyeForward));
	return 1;
}

float fresnelReflectance( float VoH, float F0 ) 
{   
	float base = 1.0 - VoH;
	float exponential = pow( base, 5.0 );
	return exponential + F0 * ( 1.0 - exponential ); 
}

float GGXMulPI(float NOH, float Roughness)
{
     float a2 = Roughness * Roughness;
     float d = (NOH * a2 - NOH) * NOH + 1.0f; 
     return a2 / (d * d + 1e-7f); 
}

float KS_Skin_Specular(float3 H, float NoL, float NoH, float VoH, NPRSurfaceData surfaceData) // Specular brightness    
{
	float beckmannTex = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex,float2(NoH,surfaceData.roughness)).a;
	float PH = pow( 2.0*saturate(beckmannTex), 10.0 );
	float F = fresnelReflectance( VoH, 0.028);
	float frSpec = max( PH * F / dot( H, H ), 0 );
	//float result = NoL * (surfaceData.roughness) * frSpec; // BRDF * dot(N,L) * rho_s

	float GGXMul = GGXMulPI(NoH,surfaceData.roughness);
	return GGXMul * (_SpecularIntensity/50);
}

//half3 PreintegratedSkinSSS(NPRInputData inputData, NPRSurfaceData surfaceData, half NoL)
//{
//	half4 PIL = SAMPLE_TEXTURE2D(_SSSTex,sampler_SSSTex,half2(NoL,surfaceData.sss));
//	PIL.rgb *= surfaceData.baseColor;
//	return PIL.rgb;
//
//}

//half3 Scattering(NPRSurfaceData surfaceData,half3 N, half3 L, half3 V)
//{
//	float3 translightDir = L + N * _ScatterNormalDistortion;
//	float scattering = surfaceData.subsurface;
//	float transDot = pow(saturate(dot(-translightDir, V)) * scattering * scattering, _ScatteringPow) * _ScatteringScale;
//	float3 lightScattering = transDot * _SubsurfaceColor * 1;
//	return lightScattering;
//}

half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate( 50.0 * SpecularColor.g );

	return SpecularColor * AB.x + AB.y;
}

half2 CalculateIBLUV(half2 uv, half roughness)
{
    half tile = 4;
	half frame = floor(roughness*(tile*tile));
	float row = floor(frame/tile);
	float column = frame - row*tile;
	uv  = uv + half2(column,row);
	uv.x/=tile;
	uv.y/=tile;
	return uv;
}

half3 MatCapSample(half3 N, half3 V, half roughness, half metallic)
{
    half3 vN = mul(UNITY_MATRIX_V,half4(N,1)).xyz;
	half m = 2.82842712474619 * sqrt(vN.z + 1.0);//Magic!
	half2 magicUV = vN.xy/m + 0.5;
    half2 uv = CalculateIBLUV(magicUV,roughness);
    half3 metalmatcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, uv).rgb;//NtoV代表法线在视图空间的XY方向上的投影
	half3 nonmetalmatcap = SAMPLE_TEXTURE2D(_NonmetalMatCap, sampler_NonmetalMatCap, uv).rgb;
	half3 matcap = lerp(nonmetalmatcap,metalmatcap,metallic);
    return matcap;
}

half3 MatCapSample(half3 N, half3 V)
{
    half3 vN = mul(UNITY_MATRIX_V,half4(N,1)).xyz;
	// float m = 2. * sqrt(pow(vN.x, 2.) + pow(vN.y, 2.) + pow(vN.z + 1., 2.));
	half m = 2.82842712474619 * sqrt(vN.z + 1.0);//Magic!
    half2 magicUV = vN.xy/m + 0.5;
    half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, magicUV*0.5+0.5).rgb;
    return matcap;
}

half3 IndirectLighting(half3 SH, NPRInputData inputData, NPRSurfaceData surfaceData)
{
	half3 color = SH * (surfaceData.baseColor*(1-surfaceData.metallic)) * surfaceData.occlusion;
	half roughness = saturate(surfaceData.roughness * _IBLRoughness);
	half3 IBL = 0;
#ifdef _IBLMODE_IBL
    half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
	IBL = GlossyEnvironmentReflection(reflectVector,sqrt(roughness),surfaceData.occlusion);
	IBL = SRGBToLinear(IBL);
	//float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
	half3 indirectSpecular = lerp(kDieletricSpec.rgb, max(0.01,surfaceData.baseColor), surfaceData.metallic);
    //c += surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
	indirectSpecular = EnvBRDFApprox(indirectSpecular,roughness,saturate(dot(inputData.normalWS,inputData.viewDirWS))); 
	indirectSpecular *= IBL;
	color += indirectSpecular;
#elif _IBLMODE_MATCAPSHEET
	IBL = MatCapSample(inputData.normalWS,inputData.viewDirWS,roughness,surfaceData.metallic);
	IBL *= surfaceData.occlusion;
	color += IBL;
#elif _IBLMODE_MATCAP
	IBL = MatCapSample(inputData.normalWS,inputData.viewDirWS) * (1-roughness);
	IBL *= surfaceData.occlusion;
	color += IBL;
#endif

	return color;
}

half3 SubsurfaceBxDF(NPRSurfaceData surfaceData, half3 N, half3 L, half3 V, half3 H)
{
	half Opacity = 1-saturate(surfaceData.subsurface);
	// to get an effect when you see through the material
	// hard coded pow constant
	float InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, .1f, Opacity);
	// wrap around lighting, /(PI*2) to be energy consistent (hack do get some view dependnt and light dependent effect)
	// Opacity of 0 gives no normal dependent lighting, Opacity of 1 gives strong normal contribution
	float NormalContribution = saturate(dot(N, H) * Opacity + 1 - Opacity);
	float BackScatter = 1 * NormalContribution / (PI * 2);
	
	// lerp to never exceed 1 (energy conserving)
	half3 color = 1 * ( _SubsurfaceFalloff * surfaceData.subsurface * lerp(BackScatter, 1, InScatter) ) * _SubsurfaceTint;

	return color;
}

half3 RimLight(NPRSurfaceData surfaceData,half3 N, half3 V, half3 L)
{
	half NoL = saturate(dot(N,_RimLightViewDir));
	half rim = saturate(1-dot(N,V)) * (1-NoL);
	rim = pow(rim,_RimLightExponent);
	rim = smoothstep(0.02,_RimLightSmoothness,rim);
	half3 rimLight = rim * _RimLightColor.xyz * _RimLightIntensity * surfaceData.occlusion;
	return rimLight;
}

half3 HairBxDF(NPRSurfaceData surfaceData, half3 X, half3 N, half3 H)
{
	half3 shitX1 = ShiftTangent(X,N,_Shift1 + surfaceData.tangentNoise.a);
	half3 spec1 = D_KajiyaKay(shitX1,H,_SpecularExponent1) * _SpecularTint1 * 1/3000 * _Specular1Intensity;
	
	half3 shitX2 = ShiftTangent(X,N,_Shift2 + surfaceData.tangentNoise.a);
	half3 spec2 = D_KajiyaKay(shitX2,H,_SpecularExponent2) * _SpecularTint2 * 1/3000 * _Specular2Intensity;

	return saturate(spec1 + spec2);
}

half3 ClearCoatBxDF(NPRSurfaceData surfaceData, half NoH, half LoH, half NoL, half NoV)
{
	float Dr = GTR1(NoH, lerp(.1,.001,surfaceData.clearCoatGloss));
	float FH = SchlickFresnel(LoH);
    float Fr = lerp(.04, 1.0, FH);
    float Gr = smithG_GGX(NoL, .25) * smithG_GGX(NoV, .25);
	float spec = Dr * Fr * Gr;

	return spec;
}

half3 ClearCoatIndirectLight(NPRInputData inputData, NPRSurfaceData surfaceData)
{
	NPRInputData clearCoatInput = inputData;
	clearCoatInput.normalWS = inputData.clearCoatNormalWS;

	NPRSurfaceData clearCoatData = surfaceData;
	clearCoatData.baseColor = 0;
	clearCoatData.roughness = 1 - surfaceData.clearCoatGloss;
	half3 indirectLighting = IndirectLighting(0,clearCoatInput,clearCoatData);
	return indirectLighting * surfaceData.clearCoat;
}

half HeightGradient(NPRInputData inputData,half heightOffset)
{
	half offset = saturate(inputData.positionWS.y/2 + heightOffset);
	return offset;
}

half3 MixBRDF(NPRSurfaceData surfaceData, NPRInputData inputData, BxDFContext Context, half3 H)
{
	half3 N = inputData.normalWS;
	half3 X = inputData.tangentWS;
	half3 Y = inputData.bitangentWS;
	half3 V = inputData.viewDirWS;

	half NoV = Context.NoV;
	half NoH = Context.NoH;
	half LoH = Context.LoH;
	half VoH = Context.VoH;
	half NoL = Context.NoL;

	half heightOffset =  HeightGradient(inputData,1-_HeightOffset);

	half diffuseHeightGradient = HeightGradient(inputData,-_DiffuseHeightOffset);
	half diffuseOffset = pow(1 - diffuseHeightGradient,_DiffuseOffsetSmooth);

	half rampHeightOffset =  HeightGradient(inputData,-_RampHeightOffset);
	half rampOffset = pow(1 - rampHeightOffset,_RampOffsetSmooth);

	NoL = NoL * diffuseOffset + (1-diffuseOffset);
debug = NoL;
//DiffuseTerm
	half3 diffuse = NoL;
#ifdef _DIFFUSEMODE_RAMP
	diffuse = RampDiffuse(surfaceData,NoL,1-rampOffset);
#elif  _DIFFUSEMODE_DISNEY
	diffuse = Diffuse_Burley(surfaceData,NoV,NoL,VoH,LoH) * NoL;
#elif  _DIFFUSEMODE_LAMBERT
	diffuse = surfaceData.baseColor * NoL;
#elif _DIFFUSEMODE_FABRIC
	diffuse = Diffuse_Fabric(surfaceData,NoL);
#elif _DIFFUSEMODE_ORENNAYAR
	diffuse = Diffuse_Oren_nayar(surfaceData,NoV);
#endif
	diffuse *= (1/PI) * surfaceData.occlusion;
	#ifdef _PBRMETAL
	  diffuse *= max(1-surfaceData.metallic,HALF_MIN);
	#endif

	diffuse *= heightOffset;

//SpecularTerm
	half3 specular = 0;
#ifdef _SPECULARMODE_NONE
#elif  _SPECULARMODE_RAMP
#elif  _SPECULARMODE_CEL
#elif  _SPECULARMODE_DISNEY
	half XoL = Context.XoL;
	half YoL = Context.YoL;
	half XoV = Context.XoV;
	half YoV = Context.YoV;
	half XoH = Context.XoH;
	half YoH = Context.YoH;

	specular = DisneyBRDF(surfaceData,NoL,NoV,NoH,LoH,XoL,YoL,XoV,YoV,XoH,YoH);
#elif  _SPECULARMODE_MOBILE
	specular = MobilePBRSpecularTerm(surfaceData,NoH,LoH);
#elif  _SPECULARMODE_SKIN
	specular = KS_Skin_Specular(H,NoL,NoH,VoH,surfaceData) * surfaceData.specular;
#elif  _SPECULARMODE_CLOTH
	specular = TrippleClothBxDF(surfaceData,N,X,Y,H,V,NoL,NoH,NoV,LoH);
	//specular = ClothBxDF(surfaceData,specular,NoH,NoV,NoL,VoH);
	//specular = Approach_ClothBxDF(surfaceData,NoH,VoH,NoL,NoV);
#elif  _SPECULARMODE_BLINNPHONG
#elif  _SPECULARMODE_HAIR
	specular = HairBxDF(surfaceData,Y,N,H);
#endif

	#ifdef _USECLEARCOAT
		specular += ClearCoatBxDF(surfaceData,NoH,LoH,NoL,NoV);
	#endif

	specular *= NoL * surfaceData.occlusion;
	specular *= Iridescence(surfaceData,half3(surfaceData.iridescence.rgb),NoV);
	
	half3 color = diffuse + specular;

	return saturate(color);
}

half3 HybirdPBRLit(NPRInputData inputData, NPRSurfaceData surfaceData, Light light)
{
	BxDFContext Context;
	InitializeBxDFContext(inputData,light.direction,Context);

	half3 N = inputData.normalWS;
	half3 L = light.direction;
	half3 V = inputData.viewDirWS;
	half3 H = normalize(L + V);
	_LightDir = L;
	half3 finalColor = 0;

  //DirectLight
	half3 directColor = MixBRDF(surfaceData, inputData, Context, H);
	finalColor += directColor;
	finalColor *= light.color*PI;

  //Shadow 提高阴影饱和度
	half3 radiance = light.shadowAttenuation;
	radiance *= light.distanceAttenuation;
	half3 lightTerm = finalColor * radiance;
	half3 darkTerm = surfaceData.baseColor * _ShadowColor * (1-radiance);
	finalColor = lightTerm + darkTerm;

  //Transmission
	half3 transmission = SubsurfaceBxDF(surfaceData,N,L,V,H) * 1;
	finalColor += transmission;

  //RimLight
	half3 rimLight = RimLight(surfaceData,N,V,L);
	finalColor += rimLight;
	//color = lerp(color,color*(1-rimLight)+rimLight,_RimLightColor.a);

	return finalColor;
}

half4 HybirdPBR(NPRInputData inputData, NPRSurfaceData surfaceData)
{
//DirectLight
	Light light = GetMainLight(inputData.shadowCoord);
	half4 color = half4(HybirdPBRLit(inputData,surfaceData,light),1);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color +=  half4(HybirdPBRLit(inputData,surfaceData,light),1);
    }
#endif

//IndirectLight
	half3 indirectColor = IndirectLighting(inputData.bakedGI,inputData,surfaceData);
	color.rgb += indirectColor;

	#ifdef _USECLEARCOAT
		color.rgb += ClearCoatIndirectLight(inputData,surfaceData);
	#endif

	return color;
}

#endif