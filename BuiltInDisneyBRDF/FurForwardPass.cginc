#ifndef FURWARDPASS_INCLUDE
#define FURWARDPASS_INCLUDE
#include "Assets/ArtResources/Shader/Res/Base/Color.cginc"
#include "UnityCG.cginc"
#include "CustomBRDF.cginc"

struct appdata_t 
{
	half4 vertex       : POSITION;
	half4 texcoord     : TEXCOORD0;
	half3 normal	    : NORMAL;
	half4 tangent		: TANGENT;
 	half4 vertexColor  : COLOR;
};
struct v2f_fur 
{
	half4 pos          : SV_POSITION;
	half4 vertexColor  : COLOR;
	half4 texcoord     : TEXCOORD0;
	half3 SH           : TEXCOORD1;
	half3 positionWS   : TEXCOORD2;
	half3 normalWS     : TEXCOORD3;
	half3 normalTS    : TEXCOORD4;
	half3 bitangentTS  : TEXCOORD5;
    half3 lightDirTS   : TEXCOORD6;
    half3 viewDirTS    : TEXCOORD7;

};

sampler2D _Albedo;
half4 _Albedo_ST;
sampler2D _NoiseTex;
half4 _NoiseTex_ST;
half4 _UVoffset;
half4 _SubTexUV;
half _Length;
half3 _Gravity;
half _GravityStrength;
half _CutoffStart;
half _CutoffEnd;
half _EdgeFade;
half _FresnelPower;
half _FresnelStrength;
sampler2D _ShiftTangentMap;
half _ShiftT;
half _Power1;
half _Strength1;
half _Power2;
half _Strength2;
half _WindSpeed;

v2f_fur vert_internal(appdata_t v, half FUR_OFFSET)
{
	half3 windDir;
	windDir.x = sin(_Time.x + v.vertex.x*0.05) * 0.2;
	windDir.y = cos(_Time.x*0.7 + v.vertex.y*0.04) * 0.2;
	windDir.z = sin(_Time.x*0.7 + v.vertex.y*0.04) * 0.2;
    half3 direction = lerp(v.normal, _Gravity * _GravityStrength * (sin(_Time.y*_WindSpeed)-1) * (1-v.vertex.y) + v.normal *
                    (1 - _GravityStrength) + windDir, FUR_OFFSET);
	half4 alpha = tex2Dlod(_Albedo,v.texcoord);
    v.vertex.xyz += direction * _Length/10 * FUR_OFFSET * alpha.a;

	v2f_fur o;

	o.pos = UnityObjectToClipPos(v.vertex);
	o.vertexColor = v.vertexColor;
	half2 uvoffset= _UVoffset.xy  * FUR_OFFSET;
	uvoffset *=  0.1;

	half2 uv1 = TRANSFORM_TEX(v.texcoord, _Albedo) + uvoffset * (half2(1,1)/_SubTexUV.xy);
	half2 uv2= TRANSFORM_TEX(v.texcoord.xy, _Albedo ) * _SubTexUV.xy + uvoffset;
	v.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy,_Albedo);
	o.texcoord = half4(v.texcoord.xy,uv2);
	o.positionWS = mul(unity_ObjectToWorld, v.vertex);
	o.normalWS = normalize(mul(unity_ObjectToWorld, half4(v.normal, 0)).xyz);

	half3 sh01 = SHEvalLinearL0L1(half4(o.normalWS,1));
    half3 sh2 = SHEvalLinearL2(half4(o.normalWS,1));

	o.SH = sh01 + sh2;

	TANGENT_SPACE_ROTATION;
	half avertexTangentSign = v.tangent.w * unity_WorldTransformParams.w;
	half3 bitangent = cross(v.normal,v.tangent)*avertexTangentSign;
	half3x3 objectToTangent = half3x3(v.tangent.xyz,bitangent,v.normal);
	o.normalTS = mul(rotation,v.normal);
	o.bitangentTS = mul(rotation,bitangent);
	o.lightDirTS = mul(rotation,ObjSpaceLightDir(half4(o.positionWS,0)));
	o.viewDirTS = normalize(mul(rotation,ObjSpaceViewDir(half4(o.positionWS,0))));
	return o;
}

fixed4 frag_internal(v2f_fur i, half FUR_OFFSET)
{
	half3 lightDir = UnityWorldSpaceLightDir(half4(i.positionWS,0));
    half3 viewDir = normalize(UnityWorldSpaceViewDir(i.positionWS));
    half3 albedo = SRGBToLinear(tex2D(_Albedo,i.texcoord.xy)).rgb;
    half4 color;
	half shiftT = tex2D(_ShiftTangentMap,i.texcoord.xy).r;
	color.rgb = FurBRDF(i.normalWS,lightDir,viewDir,_Roughness,_Metallic,albedo,i.SH,FUR_OFFSET,_FresnelStrength,_FresnelPower,
						_ShiftT,shiftT,i.normalTS,i.bitangentTS,i.lightDirTS,i.viewDirTS,
						_Power1,_Power2,_Strength1,_Strength2);
	half3 NoiseTex = tex2D(_NoiseTex, i.texcoord.zw);
	half Noise = lerp(NoiseTex.r,NoiseTex.g,NoiseTex.b);

	half alpha = tex2D(_NoiseTex, i.texcoord.zw).r;
	alpha = step(lerp(_CutoffStart, _CutoffEnd, FUR_OFFSET), Noise);

    color.a = 1 - FUR_OFFSET*FUR_OFFSET;
	color.a += dot(viewDir, i.normalWS) - _EdgeFade;
	color.a = max(0, color.a);
	color.a *= alpha;

    return color;
}

fixed4 frag_internal_SRGB(v2f_fur i, half FUR_OFFSET)
{
	half3 lightDir = UnityWorldSpaceLightDir(half4(i.positionWS,0));
    half3 viewDir = normalize(UnityWorldSpaceViewDir(i.positionWS));
    half3 albedo = SRGBToLinear(tex2D(_Albedo,i.texcoord.xy)).rgb;
    half4 color;
	half shiftT = tex2D(_ShiftTangentMap,i.texcoord.xy).r;
	color.rgb = FurBRDF(i.normalWS,lightDir,viewDir,_Roughness,_Metallic,albedo,i.SH,FUR_OFFSET,_FresnelStrength,_FresnelPower,
						_ShiftT,shiftT,i.normalTS,i.bitangentTS,i.lightDirTS,i.viewDirTS,
						_Power1,_Power2,_Strength1,_Strength2);
	half3 NoiseTex = tex2D(_NoiseTex, i.texcoord.zw);
	half Noise = lerp(NoiseTex.r,NoiseTex.g,NoiseTex.b);

	half alpha = tex2D(_NoiseTex, i.texcoord.zw).r;
	alpha = step(lerp(_CutoffStart, _CutoffEnd, FUR_OFFSET), Noise);

    color.a = 1 - FUR_OFFSET*FUR_OFFSET;
	color.a += dot(viewDir, i.normalWS) - _EdgeFade;
	color.a = max(0, color.a);
	color.a *= alpha;
	color = LinearToSRGB(color);
    return color;
}

#endif