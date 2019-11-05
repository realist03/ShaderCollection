//////////////////////////////
//							//
//		 Disney BRDF		//
//							//
//////////////////////////////
float3 baseColor;
float metallic, subsurface, _specular, roughness, specularTint, anisotropic, sheen,
            sheenTint, clearcoat, clearcoatGloss;
float4 speCol;

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

float3 F_Schlick1( float3 SpecularColor, float VoH )
{
	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
	
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


float DisneyDiffuse1(float NdotV, float NdotL, float LdotH, float perceptualRoughness)
{
    float fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    float lightScatter = 1 + (fd90 - 1) * Pow5(1 - NdotL);
    float viewScatter = 1 + (fd90 - 1) * Pow5(1 - NdotV);

    return lightScatter * viewScatter;
}

float3 DisneyBRDF(float3 L, float3 V, float3 N, float3 X, float3 Y)
{
    float NdotL = max(dot(N,L),0.0);
    float NdotV = max(dot(N,V),0.0);
 
    float3 H = normalize(L+V);
    float NdotH = max(dot(N,H),0.0);
    float LdotH = max(dot(L,H),0.0);
    float VdotH = max(dot(V,H),0.0);

    float3 Cdlin = mon2lin(baseColor);
    float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.
 
    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
    float3 Cspec0 = lerp(_specular*.08*lerp(float3(1,1,1), Ctint, specularTint), Cdlin, metallic);
    float3 Csheen = lerp(float3(1,1,1), Ctint, sheenTint);
 
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and lerp in diffuse retro-reflection based on roughness
    //float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    //float Fd90 = 0.5 + 2 * LdotH*LdotH * roughness;
    //float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
    float Fd = DisneyDiffuse1(NdotV,NdotL,VdotH,roughness*roughness);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    //float Fss90 = LdotH*LdotH*roughness;
    //float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    //float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);
 
    // specular
    float aspect = sqrt(1-anisotropic*.9);
    float ax = max(.001, sqr(roughness)/aspect);
    float ay = max(.001, sqr(roughness)*aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    float FH = SchlickFresnel(LdotH);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
    float Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
 
    // sheen
    float3 Fsheen = FH * sheen * Csheen;
 
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, lerp(.1,.001,clearcoatGloss));
    float Fr = lerp(.04, 1.0, FH);
    float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
    
    //float3 a = SchlickFresnel(VdotH);
    return ((1/PI) * lerp(Fd,1,subsurface)*Cdlin + Fsheen) * (1-metallic) + Gs*Fs*Ds + .25*clearcoat*Gr*Fr*Dr;
    //return float4(a,1);
}

