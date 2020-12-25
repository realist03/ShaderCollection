#ifndef HYBIRD_PBRINPUT_INCLUDED
#define HYBIRD_PBRINPUT_INCLUDED
#define PI 3.14159265358979323846
#define HALF_MIN 6.103515625e-5

//CBUFFER_START(UnityPerMaterial)
//Texture
TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

TEXTURE2D(_MixTex);
SAMPLER(sampler_MixTex);

TEXTURE2D(_RampTex);
SAMPLER(sampler_RampTex);

TEXTURE2D(_SpecularTex);
SAMPLER(sampler_SpecularTex);

TEXTURE2D(_TangentNoise);
SAMPLER(sampler_TangentNoise);
half4 _TangentNoise_ST;

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

TEXTURE2D(_MatCap);
SAMPLER(sampler_MatCap);

TEXTURE2D(_NonmetalMatCap);
SAMPLER(sampler_NonmetalMatCap);

TEXTURE2D(_FurNoise);
SAMPLER(sampler_FurNoise);
half4 _FurNoise_ST;

//Color
half3 _Tint;
half3 _ShadowTint;
half4 _Layer1Tint;
half4 _Layer2Tint;
half4 _Layer3Tint;
half3 _SpecularTint;
half3 _SubsurfaceTint;
half3 _SheenTint;
half4 _Iridescence;
half4 _Layer1ShininessTint;
half4 _Layer2ShininessTint;
half4 _Layer3ShininessTint;
half3 _SpecularTint1;
half3 _SpecularTint2;
half3 _ShadowColor;
half4 _RimLightColor;
//Paramter
half _Layer1Offset;
half _Layer2Offset;
half _Layer3Offset;
half _NormalScale;
half _RampSmooth;
half _Metallic;
half _Roughness;
half _IBLRoughness;
half _SpecularIntensity;
half _SubsurfaceIntensity;
half _SubsurfaceFalloff;
half _Anisotropic;
half _TangentDistortion;
half _Sheen;
half _ClearCoat;
half _ClearCoatGloss;
half _Cloth;
half _Layer1RoughnessX;
half _Layer1RoughnessY;
half _Layer2RoughnessX;
half _Layer2RoughnessY;
half _Layer3RoughnessX;
half _Layer3RoughnessY;
half _Layer1ShininessOffset;
half _Layer2ShininessOffset;
half _Layer3ShininessOffset;
half _Layer1ShininessDirection;
half _Layer2ShininessDirection;
half _Layer3ShininessDirection;
half _Layer1Shininess;
half _Layer2Shininess;
half _Layer3Shininess;
half _NormalSoftness;
half3 _EyeForward;

half _SpecularExponent1;
half _SpecularExponent2;
half _Shift1;
half _Shift2;
half _Specular1Intensity;
half _Specular2Intensity;
half _ShadowThreshold;
half _ShadowFeather;

half3 _RimLightViewDir;
half _RimLightExponent;
half _RimLightIntensity;
half _RimLightSmoothness;
half _HeightOffset;
half _DiffuseHeightOffset;
half _DiffuseOffsetSmooth;
half _RampHeightOffset;
half _RampOffsetSmooth;
half3 _ViewDirOffset;

half3 _LightDir;

//Fur
half _Opacity;
half _Offset;

//CBUFFER_END

float3 debug;

struct NPRInputData
{
    half3  positionWS;
    half3  normalWS;
	half3  tangentWS;
	half3  bitangentWS;
    half3  viewDirWS;
    half3  halfVecWS;
    half4  shadowCoord;
    half   fogCoord;
    half3  vertexLighting;
    half3  bakedGI;
    half2  screenUV;
    half3  clearCoatNormalWS;
};

struct NPRSurfaceData
{
    half3  baseColor;
    half3  shadowTint;
    half3  specular;
    half   metallic;
    half   roughness;
    half   subsurface;
    half   anisotropic;
    half4  tangentNoise;
    half   sheen;
    half   clearCoat;
    half   clearCoatGloss;
    half3  emission;
    half   occlusion;
    half   alpha;
    half3  normalTS;
    half4  iridescence;
    half   cloth;
};

struct BxDFContext
{
    half NoL;
    half NoV;
    half NoH;
    half LoH;
    half VoH;
    half VoL;

    half XoL;
    half YoL;
    half XoV;
    half YoV;
    half XoH;
    half YoH;
};

void InitializeBxDFContext(NPRInputData inputData, half3 L, out BxDFContext Context)
{
    Context = (BxDFContext)0;
    half3 N = inputData.normalWS;
    half3 V = inputData.viewDirWS;
    half3 X = inputData.tangentWS;
    half3 Y = inputData.bitangentWS;
    half3 H = normalize(L + V);

    //Context.VoL = dot(V, L);
	//float InvLenH = rsqrt( 2 + 2 * Context.VoL );

	Context.NoH = dot(N, H);
	Context.VoH = dot(V, H);
	Context.LoH = dot(L, H);
	Context.NoL = dot(N, L);
    Context.NoV = dot(N, V);
#ifdef _USENOV
    Context.NoL = dot(N, V + _ViewDirOffset);
#endif

//Anisotropic
#ifdef _SPECULARMODE_DISNEY
    Context.XoL = dot(L, X);
	Context.YoL = dot(L, Y);
	Context.XoV = dot(V, X);
	Context.YoV = dot(V, Y);
    Context.XoH = dot(X, H);
	Context.YoH = dot(Y, H);
#endif

}

half3 CustomUnpackNormalScale(half4 packedNormal, half scale)
{
    real3 normal;
    normal.xy = packedNormal.rg * 2.0 - 1.0;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    normal.xy *= scale;
    return normal;
}

void InitializeNPRSurfaceData(float2 uv, out NPRSurfaceData surfaceData)
{
	surfaceData = (NPRSurfaceData)1;
	half4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);
    surfaceData.baseColor = SRGBToLinear(mainTex.rgb) * _Tint;
	surfaceData.shadowTint = surfaceData.baseColor * _ShadowTint;
	surfaceData.subsurface = mainTex.a * _SubsurfaceIntensity;

	half4 mixTex = SAMPLE_TEXTURE2D(_MixTex,sampler_MixTex,uv);
	surfaceData.metallic = max(mixTex.b * _Metallic,HALF_MIN);
	surfaceData.roughness = max(mixTex.a * _Roughness,HALF_MIN);

	half4 normalTex = half4(mixTex.x,mixTex.y,1,1);
	surfaceData.normalTS = CustomUnpackNormalScale(normalTex, _NormalScale);

	half4 speTex = SAMPLE_TEXTURE2D(_SpecularTex,sampler_SpecularTex,uv);
	surfaceData.specular = SRGBToLinear(speTex.rgb) * _SpecularTint * _SpecularIntensity;
    surfaceData.occlusion = speTex.r;
	surfaceData.anisotropic = _Anisotropic;
	surfaceData.tangentNoise = SAMPLE_TEXTURE2D(_TangentNoise,sampler_TangentNoise,uv);
	surfaceData.tangentNoise.a *= _TangentDistortion;
	surfaceData.clearCoat = _ClearCoat * (1-sqrt(surfaceData.roughness));
	surfaceData.clearCoatGloss = _ClearCoatGloss * (1-sqrt(surfaceData.roughness));
	surfaceData.iridescence = _Iridescence;
	surfaceData.cloth = _Cloth;
}

#endif