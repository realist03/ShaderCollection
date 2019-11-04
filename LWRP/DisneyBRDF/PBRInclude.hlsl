//////////////////////////////
//							//
//		 Disney BRDF		//
//							//
//////////////////////////////

static const half3 baseColor = half3(1, 1, 1);
half metallic, subsurface, _specular, roughness, specularTint, anisotropic, sheen,
            sheenTint, clearcoat, clearcoatGloss;
                       
static const half PI_ = 3.14159265358979323846;
//half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
//{
//    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
//    // Two schlick fresnel term
//    half lightScatter = (1 + (fd90 - 1) * Pow5(1 - NdotL));
//    half viewScatter = (1 + (fd90 - 1) * Pow5(1 - NdotV));
//
//    return lightScatter * viewScatter;
//}

half sqr(half x)
{
    return x * x;
}

half SchlickFresnel(half u)
{
    half m = clamp(1 - u, 0, 1);
    half m2 = m * m;
    return m2 * m2 * m; // pow(m,5)
}

half GTR1(half NdotH, half a)
{
    if (a >= 1)
        return 1 / PI_;
    half a2 = a * a;
    half t = 1 + (a2 - 1) * NdotH * NdotH;
    return (a2 - 1) / (PI_ * log(a2) * t);
}

half GTR2(half NdotH, half a)
{
    half a2 = a * a;
    half t = 1 + (a2 - 1) * NdotH * NdotH;
    return a2 / (PI_ * t * t);
}

half GTR2_aniso(half NdotH, half HdotX, half HdotY, half ax, half ay)
{
    return 1 / (PI_ * ax * ay * sqr(sqr(HdotX / ax) + sqr(HdotY / ay) + NdotH * NdotH));
}

half smithG_GGX(half NdotV, half alphaG)
{
    half a = alphaG * alphaG;
    half b = NdotV * NdotV;
    return 1 / (NdotV + sqrt(a + b - a * b));
}

half smithG_GGX_aniso(half NdotV, half VdotX, half VdotY, half ax, half ay)
{
    return 1 / (NdotV + sqrt(sqr(VdotX * ax) + sqr(VdotY * ay) + sqr(NdotV)));
}

half3 mon2lin(half3 x)
{
    return half3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}

half3 DisneyBRDF(half3 L, half3 V, half3 N, half3 X, half3 Y)
{
    half NdotL = max(dot(N, L), 0.0);
    half NdotV = max(dot(N, V), 0.0);
 
    half3 H = normalize(L + V);
    half NdotH = max(dot(N, H), 0.0);
    half LdotH = max(dot(L, H), 0.0);
 
    half3 Cdlin = mon2lin(baseColor);
    half Cdlum = .3 * Cdlin[0] + .6 * Cdlin[1] + .1 * Cdlin[2]; // luminance approx.
 
    half3 Ctint = Cdlum > 0 ? Cdlin / Cdlum : half3(1, 1, 1); // normalize lum. to isolate hue+sat
    half3 Cspec0 = lerp(_specular * .08 * lerp(half3(1, 1, 1), Ctint, specularTint), Cdlin, metallic);
    half3 Csheen = lerp(half3(1, 1, 1), Ctint, sheenTint);
 
                // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
                // and lerp in diffuse retro-reflection based on roughness
    half FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    half Fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
    half Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
 
                // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
                // 1.25 scale is used to (roughly) preserve albedo
                // Fss90 used to "flatten" retroreflection based on roughness
    half Fss90 = LdotH * LdotH * roughness;
    half Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    half ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);
 
                // specular
    half aspect = sqrt(1 - anisotropic * .9);
    half ax = max(.001, sqr(roughness) / aspect);
    half ay = max(.001, sqr(roughness) * aspect);
    half Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    half FH = SchlickFresnel(LdotH);
    half3 Fs = lerp(Cspec0, half3(1, 1, 1), FH);
    half Gs = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
 
                // sheen
    half3 Fsheen = FH * sheen * Csheen;
 
                // clearcoat (ior = 1.5 -> F0 = 0.04)
    half Dr = GTR1(NdotH, lerp(.1, .001, clearcoatGloss));
    half Fr = lerp(.04, 1.0, FH);
    half Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
 
    return ((1 / PI_) * lerp(Fd, ss, subsurface) * Cdlin + Fsheen) * (1 - metallic) + Gs * Fs * Ds + .25 * clearcoat * Gr * Fr * Dr;
}

