#include "UnityCG.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};
struct v2f
{
	float2 uv : TEXCOORD0;
	float4 vertex : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	return o;
}

sampler2D _MainTex;
float4 _MainTex_TexelSize;

//Common
half4 Sample(float2 uv)
{
    return tex2D(_MainTex,uv);
}

//Fliter
half4 DualFilterDown(float2 uv,half2 delta)
{
	half4 sum = Sample(uv) * 4;

	sum += Sample(uv - delta.xy);
	sum += Sample(uv + delta.xy);
	sum += Sample(uv + half2(delta.x,-delta.y));
	sum += Sample(uv - half2(delta.x,-delta.y));

	return sum / 8;
}
half4 DualFilterUp(float2 uv,half2 delta)
{
	half4 sum = Sample(uv + half2(-delta.x * 2, 0));

	sum += Sample(uv + half2(-delta.x,delta.y)) * 2;
	sum += Sample(uv + half2(0,delta.y * 2));
	sum += Sample(uv + delta) * 2;
	sum += Sample(uv + half2(delta.x * 2,0));
	sum += Sample(uv + half2(delta.x,-delta.y)) * 2;
	sum += Sample(uv + half2(0,-delta.y * 2));
	sum += Sample(uv + half2(-delta.x,-delta.y)) * 2;

	return sum / 12;
}


//Bloom
sampler2D _SourceTex;
half4 _Filter;
half _Intensity;

half4 SampleBox (float2 uv, float delta) 
{
	float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
	half4 s =
		Sample(uv + o.xy) + Sample(uv + o.zy) +
		Sample(uv + o.xw) + Sample(uv + o.zw);
	return s * 0.25f;
}

half3 Prefilter (half3 c) 
{
	half brightness = max(c.r, max(c.g, c.b));
	half soft = brightness - _Filter.y;
	soft = clamp(soft, 0, _Filter.z);
	soft = soft * soft * _Filter.w;
	half contribution = max(soft, brightness - _Filter.x);
	contribution /= max(brightness, 0.00001);
	return c * contribution;
}

half3 Bloom(half3 col,float2 uv)
{
	col.rgb = col;
	col.rgb += _Intensity * SampleBox(uv, 0.5);
	return col;			

}
//Saturate
float _Saturation;

half4 Saturate(half4 col)
{
	float luminance = 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b;
	float3 luminanceColor = float3(luminance,luminance,luminance);
	col.rgb = lerp(luminanceColor,col,_Saturation);
	return col;

}

//Blur
struct v2f_blur
{
	half4 vertex : POSITION;
	half2 uv[5] : TEXCOORD0;
};

half _BlurSize;
float _Alpha;

v2f_blur vert_blur_hon(appdata v)
{
	v2f_blur o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv[0] = v.uv;
	o.uv[2] = v.uv - float2(_MainTex_TexelSize.x, 0) * _BlurSize * 1.407333;
	o.uv[3] = v.uv + float2(_MainTex_TexelSize.x, 0) * _BlurSize * 3.294215;
	o.uv[1] = v.uv + float2(_MainTex_TexelSize.x, 0) * _BlurSize * 1.407333;
	o.uv[4] = v.uv - float2(_MainTex_TexelSize.x, 0) * _BlurSize * 3.294215;
	return o;
}

v2f_blur vert_blur_ver(appdata v)
{
	v2f_blur o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv[0] = v.uv;
	o.uv[1] = v.uv + float2(0, _MainTex_TexelSize.y) * _BlurSize * 1.407333;
	o.uv[2] = v.uv - float2(0, _MainTex_TexelSize.y) * _BlurSize * 1.407333;
	o.uv[3] = v.uv + float2(0, _MainTex_TexelSize.y) * _BlurSize * 3.294215;
	o.uv[4] = v.uv - float2(0, _MainTex_TexelSize.y) * _BlurSize * 3.294215;
	return o;
}

half4 Blur(v2f_blur i,half blurSize)
{
	half4 col;
	col = tex2D(_MainTex,i.uv[0]) * 0.204164;
	col += tex2D(_MainTex,i.uv[1])* 0.304005;
	col += tex2D(_MainTex,i.uv[2]) * 0.304005;
	col += tex2D(_MainTex,i.uv[3]) * 0.093913;
	col += tex2D(_MainTex,i.uv[4]) * 0.093913;
	half4 srcCol = tex2D(_SourceTex,i.uv[0]);
	col = lerp(srcCol,col,_Alpha);
	return col;
}

half4 Vignette(float4 col, float2 uv)
{
	float vignette = 1 - dot(uv-0.5,uv-0.5);
	return col * vignette;
}

half3 ACESFilm(half3 x)
{
    half a = 2.51f;
    half b = 0.03f;
    half c = 2.43f;
    half d = 0.59f;
    half e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

half4 LinearToSRGB(half4 c)
{
    half3 sRGBLo = c.rgb * 12.92;
    half3 sRGBHi = (pow(c.rgb, half3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
    half3 sRGB   = (c.rgb <= 0.0031308) ? sRGBLo : sRGBHi;
    return half4(sRGB,c.a);
}

half4 GammaCorrection(half4 col)
{
	return LinearToSRGB(col);
}

half4 ToneMapping(half4 col)
{
	return LinearToSRGB(half4(ACESFilm(col.rgb),col.a));
}

half _EV;

half4 Exposure(half4 col)
{
	col = col * pow(2,_EV);
	return col;
}