#ifndef COLOR_INCLUDE
#define COLOR_INCLUDE
float4 SRGBToLinear(float4 c)
{
    float3 linearRGBLo  = c.rgb / 12.92;
    float3 linearRGBHi  = pow((c.rgb + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
    float3 linearRGB    = (c.rgb <= 0.04045) ? linearRGBLo : linearRGBHi;
    return float4(linearRGB,c.a);
}

float4 LinearToSRGB(float4 c)
{
    float3 sRGBLo = c.rgb * 12.92;
    float3 sRGBHi = (pow(c.rgb, float3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
    float3 sRGB   = (c.rgb <= 0.0031308) ? sRGBLo : sRGBHi;
    return float4(sRGB,c.a);
}

float4 LinearToGamma(float4 c)
{
    return float4(pow(c.rgb,0.45),c.a);
}

float4 GammaToLinear(float4 c)
{
    return float4(pow(c.rgb,2.2),c.a);
}

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}
#endif