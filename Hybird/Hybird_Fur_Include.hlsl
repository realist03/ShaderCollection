#ifndef HYBIRD_FUR_INCLUDED
#define HYBIRD_FUR_INCLUDED

TEXTURE2D(_Noise);
SAMPLER(sampler_Noise);

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _BaseColor;
CBUFFER_END

half _Opacity;
half _Offset;

struct a2v 
{
    float4 positionOS   : POSITION;
    float4 color        : COLOR;
    float3 normalOS     : NORMAL;
    float2 uv           : TEXCOORD0;
};
struct v2f 
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
};

v2f vert_Internal(a2v v, half _Offset)
{
    v2f o;
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    half noise = SAMPLE_TEXTURE2D_LOD(_Noise,sampler_Noise,o.uv,0).r;
    v.positionOS.xyz += _Offset * noise * v.normalOS;
    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
    o.color = v.color;
    return o;
}

half4 frag_Internal(v2f i) : SV_Target
{
    half noise = SAMPLE_TEXTURE2D(_Noise,sampler_Noise,i.uv).r;
    half4 color = _BaseColor;
    color.a = noise * saturate(_Opacity);
    return color;
}

v2f vert0(a2v v)
{
    return vert_Internal(v,_Offset);
}

half4 frag0(v2f i) : SV_Target 
{
    return frag_Internal(i);
}

#endif