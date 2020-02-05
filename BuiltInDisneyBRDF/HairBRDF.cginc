#ifndef HAIRBRDF_INCLUDE
#define HAIRBRDF_INCLUDE

#include "HairInput.cginc"
#include "UnityPBSLighting.cginc"

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

half StrandSpecular ( half3 T, half3 V, half3 L, half exponent)
{
    half3 H = normalize(L + V);
    half dotTH = dot(T, H);
    half sinTH = sqrt(1 - dotTH * dotTH);
    half dirAtten = smoothstep(-1, 0, dotTH);
    return dirAtten * pow(sinTH, exponent);
}

half Dither(half4 scPos)
{
    half2 screenPos = scPos.xy/scPos.w;
    half2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
    half ditherValue = tex2D(_DitherPattern, ditherCoordinate*_ditherTile).r;
    return ditherValue;
}

half EnvBRDFApproxNonmetal( half Roughness, half NoV )
{

    // Same as EnvBRDFApprox( 0.04, Roughness, NoV )

    const half2 c0 = { -1, -0.0275 };

    const half2 c1 = { 1, 0.0425 };

    half2 r = Roughness * c0 + c1;

    return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;

}

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
                                    float3 viewDir,float3 speCol)
{
    UnityIndirect indirectLight = (UnityIndirect)0;
    #if defined(FORWARD_BASE_PASS)
    indirectLight.diffuse = customInputData.sh;
    float3 reflectionDir = reflect(-viewDir, customInputData.normalWS);

    Unity_GlossyEnvironmentData     envData ;
    envData.roughness  =  1-customSurfaceData.roughness * customSurfaceData.roughness;
    envData.roughness *= 1.7-0.7*envData.roughness;
    envData.reflUVW  =  reflectionDir;
    
    float mip = perceptualRoughnessToMipmapLevel(customSurfaceData.roughness);
	float4 envSample = (UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir,mip));

    indirectLight.specular = SRGBToLinear(float4(DecodeHDR(envSample, unity_SpecCube0_HDR ),1));
    float NoV = saturate(dot(customInputData.normalWS,viewDir));
    //float surfaceReductionMetal = 1-EnvBRDFApprox(customSurfaceData.roughness,speCol,NoV);
    half surfaceReduction = (0.6-0.08*customSurfaceData.roughness);
    surfaceReduction = 1.0 - customSurfaceData.roughness*customSurfaceData.roughness*customSurfaceData.roughness*surfaceReduction;

    //float surfaceReductionNoMetal = 1-EnvBRDFApproxNonmetal(customSurfaceData.roughness,NoV);
    //float surfaceReduction = lerp(surfaceReductionNoMetal,surfaceReductionMetal,customSurfaceData.metallic);
    //float surfaceReduction = 1.0 / (customSurfaceData.roughness + 1.0);
    //float surfaceReduction = max(0.1,1-customSurfaceData.roughness);
    //float3 surfaceReductionLUT = EnvBRDF(speCol,customSurfaceData.roughness,NoV);
    float oneMinusReflectivity = LinearOneMinusReflectivityFromMetallic(customSurfaceData.metallic);
    float grazingTerm = saturate(1-customSurfaceData.roughness*customSurfaceData.roughness + (1-oneMinusReflectivity));
    indirectLight.specular *= surfaceReduction * FresnelLerp(speCol,grazingTerm,NoV) * customSurfaceData.occlusion;
    //indirectLight.specular = surfaceReduction;
    #endif

    return indirectLight;
}

half4 HairBRDF(CustomInputData customInputData, CustomSurfaceData customSurfaceData,half2 uv)
{   
    half3 lightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(customInputData.positionWS));

    half shiftMap = tex2D(_ShiftTangentMap, uv).r - 0.5;

    half3 shiftT = ShiftTangent(customInputData.bitangentTS,customInputData.normalTS,shiftMap+_ShiftT);


    half spe1 = SpecularExponent(shiftT,customInputData.viewDirectionTS,
                customInputData.lightDirTS,_Power1,_Strength1);

    half spe2 = SpecularExponent(shiftT,customInputData.viewDirectionTS,
                customInputData.lightDirTS,_Power2,_Strength2);

    half spe = spe1 + spe2;
    
    //half3 H = customInputData.viewDirectionTS + lightDir;
    half NdotL = max(dot(customInputData.normalWS,lightDir),0);

    //half  diffuse = saturate(NdotL+_w)/(1+_w);
    //half3 scatterColor = customSurfaceData.albedo;
    //half3 scatterLight = saturate(_ScatterColor + (NdotL*diffuse));
    half3 color = spe * NdotL + customSurfaceData.albedo * NdotL;
    //half3  trans = customSurfaceData.albedo*scatterLight*_Transmission;
    //color += trans;
    

#ifdef _RECIVESHADOW
    color *= _LightColor0 * customInputData.atten;
#else
    color *= _LightColor0;
#endif

    color *= customSurfaceData.occlusion;
    
    float3 Cspec0 = lerp(0.04, customSurfaceData.albedo, customSurfaceData.metallic);

    UnityIndirect indirect = CreateIndirectLight(customInputData,customSurfaceData,customInputData.viewDirectionWS,Cspec0);
    
    half3 indirectCol = indirect.diffuse * customSurfaceData.albedo * customSurfaceData.occlusion;// + indirect.specular;

    color += indirectCol;

    float Fresnel = pow(1-max(0,dot(customInputData.normalWS,customInputData.viewDirectionWS)),_FresnelPower) * _FresnelStrength * 1;

    color += Fresnel * customSurfaceData.albedo;
    //return half4(indirect.diffuse,1);
    return half4(color,customSurfaceData.emission);
}

#endif
