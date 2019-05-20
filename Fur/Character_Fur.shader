// Unlit shader. Simplest possible textured shader.
// - no lighting
// - no lightmap support
// - no per-material vertexColor

Shader "Character/Character_Fur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NoiseTex("Noise", 2D) = "white" {}
		_UVoffset("_UVoffset", Vector) = (0,0,0,0)
		_SubTexUV("SubTexUV",Vector) = (0,0,0,0)
		_FurMask("_FurMask", Range(0,10)) = 0.5
		_tming ("_tming ", Range(0,5)) = 0.5
		_FresnelLV("FresnelLV",Range(0,10)) = 1
		_OcclusionColor("OcclusionColor",COLOR) = (1,1,1,1)
		_DarkColor("DarkColor",COLOR) = (0,0,0,0)
		_TexLerp("TexLerp",Float) = 8
		_Length("Length",Float) = 2
		_OffSetMul("OffSetMul",Range(0,0.2)) = 0.1
		_LightFilter("平行光毛发穿透",  Range(-0.5,0.5)) = 0.0
		_FurDirLightExposure("_FurDirLightExposure",Float) = 1
		_aoP("aoP",Float) = 1
		_LightDir("LightDir",Vector) = (1,1,1)

	}

	SubShader {
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		struct appdata_t {
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
			float3 normal	: NORMAL;
			float4 vertexColor : COLOR;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			float4 vertexColor : COLOR;
			float4 texcoord : TEXCOORD0;
			UNITY_FOG_COORDS(1)
			float3 posWorld : TEXCOORD2;
			float3 worldNormal : TEXCOORD3;
			float3 SH : TEXCOORD4;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;

		sampler2D _NoiseTex;
		float4 _NoiseTex_ST;

		half4 _UVoffset;
		half4 _SubTexUV;

		float _FurMask;
		float _tming;
		float _FresnelLV;
		half3 _OcclusionColor;
		half3 _DarkColor;
		float _TexLerp;
		float _Length;
		float _OffSetMul;
		float _LightFilter;
		float _FurDirLightExposure;
		float _aoP;
		float3 _LightDir;
		v2f vert_internal(appdata_t v, half FUR_OFFSET)
		{
			FUR_OFFSET *= _OffSetMul;
			v2f o;
			float3 aNormal = (v.normal.xyz);
			aNormal.xyz += FUR_OFFSET;

			float3 n = aNormal * FUR_OFFSET * (FUR_OFFSET * saturate(v.vertexColor.r));

			//half3 direction = lerp(v.normal, _Gravity * _GravityStrength + v.normal * (1 - _GravityStrength), FUR_OFFSET);
			v.vertex.xyz += n * _Length;// * _FurLength * FUR_OFFSET * v.vertexColor.a;

			o.vertex = UnityObjectToClipPos(v.vertex);

			float2 uvoffset= _UVoffset.xy  * FUR_OFFSET;
			uvoffset *=  0.1;

			float2 uv1 = TRANSFORM_TEX(v.texcoord, _MainTex) + uvoffset * (float2(1,1)/_SubTexUV.xy);
			float2 uv2= TRANSFORM_TEX(v.texcoord.xy, _MainTex ) * _SubTexUV.xy + uvoffset;
			v.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
			o.texcoord = float4(v.texcoord.xy,uv2);
			o.posWorld = mul(unity_ObjectToWorld, v.vertex);
			o.worldNormal = normalize(mul(unity_ObjectToWorld, half4(v.normal, 0)).xyz);

			float3 normal = normalize(mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz);
			half3 SH = saturate(normal.y * 0.25 + 0.35);
			o.SH = SH;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}

		fixed4 frag_internal(v2f i, half FUR_OFFSET)
		{
			FUR_OFFSET *= _OffSetMul;
			half3 baseColor = tex2D(_MainTex,i.texcoord.xy);
			half3 NoiseTex = tex2D(_NoiseTex, i.texcoord.zw).rgb;
			half Noise = lerp(NoiseTex.r,NoiseTex.g,NoiseTex.b);

			half Occlusion =pow(saturate(FUR_OFFSET*FUR_OFFSET*+_aoP),1);
			Occlusion += 0.1;

			half3 SHL = lerp (_OcclusionColor*i.SH,i.SH,Occlusion) ;

			half3 V = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

			//half Fresnel = pow (1-max(0,dot(i.worldNormal,V)),2.2);
			half Fresnel = 1-max(0,dot(i.worldNormal,V));
			
			half RimLight = Fresnel * Occlusion;

			RimLight *= RimLight;

			RimLight *= _FresnelLV * i.SH * baseColor; 

			SHL += RimLight;


			half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
			//half3 lightDir = -normalize(_LightDir);

			half NoL =dot(lightDir,i.worldNormal);

			half DirLight= saturate (NoL+_LightFilter+ FUR_OFFSET ) ;

			DirLight *=_FurDirLightExposure;
			fixed4 color;
			color.rgb = DirLight * baseColor + SHL;
			//color.rgb = SHL;
			color.a = saturate((Noise*2-(FUR_OFFSET *FUR_OFFSET +(FUR_OFFSET*_FurMask*5)))*_tming);
			return fixed4(color.rgb,color.a);

		}
		

		v2f vert0(appdata_t v)
		{
			return vert_internal(v, 0);
		}

		
		v2f vert1(appdata_t v)
		{
			return vert_internal(v, 0.05);
		}
		
		v2f vert2(appdata_t v)
		{
			return vert_internal(v, 0.1);
		}
		
		v2f vert3(appdata_t v)
		{
			return vert_internal(v, 0.15);
		}
		
		v2f vert4(appdata_t v)
		{
			return vert_internal(v, 0.2);
		}		

		v2f vert5(appdata_t v)
		{
			return vert_internal(v, 0.25);
		}	
		
		v2f vert6(appdata_t v)
		{
			return vert_internal(v, 0.3);
		}		

		v2f vert7(appdata_t v)
		{
			return vert_internal(v, 0.35);
		}	
		
		v2f vert8(appdata_t v)
		{
			return vert_internal(v, 0.4);
		}	
		
		v2f vert9(appdata_t v)
		{
			return vert_internal(v, 0.45);
		}			

		v2f vert10(appdata_t v)
		{
			return vert_internal(v, 0.5);
		}	
		
		v2f vert11(appdata_t v)
		{
			return vert_internal(v, 0.55);
		}
		
		v2f vert12(appdata_t v)
		{
			return vert_internal(v, 0.6);
		}
		
		v2f vert13(appdata_t v)
		{
			return vert_internal(v, 0.65);
		}
		
		v2f vert14(appdata_t v)
		{
			return vert_internal(v, 0.7);
		}		

		v2f vert15(appdata_t v)
		{
			return vert_internal(v, 0.75);
		}	
		
		v2f vert16(appdata_t v)
		{
			return vert_internal(v, 0.8);
		}		

		v2f vert17(appdata_t v)
		{
			return vert_internal(v, 0.85);
		}

		v2f vert18(appdata_t v)
		{
			return vert_internal(v, 0.9);
		}	
		
		v2f vert19(appdata_t v)
		{
			return vert_internal(v, 0.95);
		}			

		v2f vert20(appdata_t v)
		{
			return vert_internal(v, 0.99);
		}	

		fixed4 frag0(v2f i) : SV_Target
		{				
			fixed4 color = tex2D(_MainTex,i.texcoord.xy);
			half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
			//half3 lightDir = -normalize(_LightDir);

			half NoL =dot(lightDir,i.worldNormal);

			half DirLight= saturate (NoL);

			color *= DirLight;
			return fixed4(color.rgb,1);

		}

		fixed4 frag1(v2f i) : SV_Target
		{
			return frag_internal(i, 0.05);
		}

		fixed4 frag2(v2f i) : SV_Target
		{
			return frag_internal(i, 0.1);
		}

		fixed4 frag3(v2f i) : SV_Target
		{
			return frag_internal(i, 0.15);
		}

		fixed4 frag4(v2f i) : SV_Target
		{
			return frag_internal(i, 0.2);
		}

		fixed4 frag5(v2f i) : SV_Target
		{
			return frag_internal(i, 0.25);
		}

		fixed4 frag6(v2f i) : SV_Target
		{
			return frag_internal(i, 0.3);
		}
		
		fixed4 frag7(v2f i) : SV_Target
		{
			return frag_internal(i, 0.35);
		}

		fixed4 frag8(v2f i) : SV_Target
		{
			return frag_internal(i, 0.4);
		}

		fixed4 frag9(v2f i) : SV_Target
		{
			return frag_internal(i, 0.45);
		}

		fixed4 frag10(v2f i) : SV_Target
		{
			return frag_internal(i, 0.5);
		}

		fixed4 frag11(v2f i) : SV_Target
		{
			return frag_internal(i, 0.55);
		}

		fixed4 frag12(v2f i) : SV_Target
		{
			return frag_internal(i, 0.6);
		}

		fixed4 frag13(v2f i) : SV_Target
		{
			return frag_internal(i, 0.65);
		}

		fixed4 frag14(v2f i) : SV_Target
		{
			return frag_internal(i, 0.7);
		}

		fixed4 frag15(v2f i) : SV_Target
		{
			return frag_internal(i, 0.75);
		}

		fixed4 frag16(v2f i) : SV_Target
		{
			return frag_internal(i, 0.8);
		}
		
		fixed4 frag17(v2f i) : SV_Target
		{
			return frag_internal(i, 0.85);
		}

		fixed4 frag18(v2f i) : SV_Target
		{
			return frag_internal(i, 0.9);
		}

		fixed4 frag19(v2f i) : SV_Target
		{
			return frag_internal(i, 0.95);
		}

		fixed4 frag20(v2f i) : SV_Target
		{
			return frag_internal(i, 0.99);
		}
		ENDCG

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert0
			#pragma fragment frag0
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert11
			#pragma fragment frag11
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert12
			#pragma fragment frag12
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert13
			#pragma fragment frag13
		
			ENDCG
		 
		}
		
		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert14
			#pragma fragment frag14
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert15
			#pragma fragment frag15
		
			ENDCG
		 
		}	

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert16
			#pragma fragment frag16 
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert17
			#pragma fragment frag17
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert18
			#pragma fragment frag18
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert19
			#pragma fragment frag19
		
			ENDCG
		 
		}

		Pass { 
	
			CGPROGRAM
		
			#pragma vertex vert20
			#pragma fragment frag20
		
			ENDCG
		 
		}	
	}
}
