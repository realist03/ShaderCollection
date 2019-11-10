#ifndef DISNEYBRDF_INCLUDED
#define DISNEYBRDF_INCLUDED

#include "CustomInput.hlsl"
//////////////////////////////
//							//
//		 Disney BRDF		//
//							//
//////////////////////////////

float sqr(float x)
{
    return x * x;
}

float Pow5(float x)
{
    return x*x*x*x*x;
}
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

float D_GGXaniso( float ax, float ay, float NoH, float3 H, float3 X, float3 Y )
{
	float XoH = dot( X, H );
	float YoH = dot( Y, H );
	float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
	return 1 / ( PI * ax*ay * d*d );
}

float3 mon2lin(float3 x)
{
    x = abs(x);
    return float3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}

// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return 1 * ( FdV * FdL );
}

float3 Diffuse_Burley_Frostbite( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
    float bias = lerp(0,0,Roughness);
    float factor = lerp(1,1.51,Roughness);
	float FD90 = bias + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return 1 * ( FdV * FdL ) * factor;
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

float PreintergratedSSS(float NdotL)
{
    float curve = _Subfurface;
    float4 sss = SAMPLE_TEXTURE2D(_SkinLUT,sampler_SkinLUT,float2(NdotL*0.5+0.5,curve));
    return sss;
}

float3 DisneyBRDF(CustomSurfaceData surfaceData, float3 L, float3 V, float3 N, float3 X, float3 Y)
{    
    Y = cross(N,X);

    float NdotL = max(dot(N,L),0.0);
    float NdotV = max(dot(N,V),0.0);
 
    float3 H = normalize(L+V);
    float NdotH = max(dot(N,H),0.0);
    float LdotH = dot(L,H);
    float VdotH = max(dot(V,H),0.0);

    float3 Cdlin = surfaceData.albedo;
    float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.
 
    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
    float3 Cspec0 = lerp(surfaceData.specular*.08*lerp(float3(1,1,1), Ctint, surfaceData.specularTint), Cdlin, surfaceData.metallic);
    float3 Csheen = lerp(float3(1,1,1), Ctint, surfaceData.sheenTint);
 
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and lerp in diffuse retro-reflection based on roughness
    float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5 + 2 * LdotH*LdotH * surfaceData.roughness;
    float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV) * NdotL;
    //float Fd = Diffuse_Burley(surfaceData.albedo,surfaceData.roughness,NdotV,NdotL,LdotH);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH*LdotH*surfaceData.roughness;
    float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    float ss = saturate(1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5)); 
 
    // specular
    float aspect = sqrt(1-surfaceData.anisotropic*.9);
    float ax = max(.001, sqr(surfaceData.roughness)/aspect);
    float ay = max(.001, sqr(surfaceData.roughness)*aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    float FH = SchlickFresnel(LdotH);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
    //float Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    //Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
    float Gs  = D_GGXaniso(ax, ay,NdotH, L, X, Y);
    Gs  *= D_GGXaniso(ax, ay,NdotH, V, X, Y);

    // sheen
    float3 Fsheen = FH * surfaceData.sheen * surfaceData.sheen;
 
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, lerp(.1,.001,surfaceData.clearcoatGloss));
    float Fr = lerp(.04, 1.0, FH);
    float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
    
    //PreintergratedSSS
    float sss = PreintergratedSSS(NdotL) * _Subfurface;
    //return sss.xxx;
    return ( /*(1/PI) * */lerp(Fd, ss, surfaceData.subsurface)*Cdlin + Fsheen + sss * float3(1,0,0) * SSS_Strength) * (1-surfaceData.metallic) + Gs*Fs*Ds*NdotL + .25*surfaceData.clearcoat*Gr*Fr*Dr;
}

float3 DisneyPBR(CustomSurfaceData surfaceData, Light light, float3 normalWS, float3 viewDirectionWS,
                float3 tangentWS, float binormalWS)
{
    //return half4(light.color,1);
    return light.color * light.distanceAttenuation * light.shadowAttenuation * DisneyBRDF(surfaceData, light.direction,viewDirectionWS,normalWS,tangentWS,binormalWS);
}

float4 DisneyBRDFFragment(CustomInputData customInputData, CustomSurfaceData customSurfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(customSurfaceData.albedo,customSurfaceData.metallic,customSurfaceData.roughness,brdfData);

    Light mainLight = GetMainLight(customInputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, customInputData.normalWS, customInputData.bakedGI, float4(0, 0, 0, 0));

    float3 color = DisneyPBR(customSurfaceData, mainLight,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.binormalWS);
    
    color += GlobalIllumination(brdfData, customInputData.bakedGI, customSurfaceData.occlusion, customInputData.normalWS, customInputData.viewDirectionWS);

        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            Light light = GetAdditionalLight(i, customInputData.positionWS);
            color += DisneyPBR(customSurfaceData, mainLight,
                        customInputData.normalWS, customInputData.viewDirectionWS,
                        customInputData.tangentWS, customInputData.binormalWS);
        }

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += customInputData.vertexLighting * brdfData.diffuse;
    #endif

    //color += emission;

    return float4(color,1);
}
#endif
