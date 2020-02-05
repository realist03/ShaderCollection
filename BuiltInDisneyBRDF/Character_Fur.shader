
Shader "Character/Character_Fur" 
{
	Properties 
	{
		_Albedo ("Base (RGB)", 2D) = "white" {}
		_NoiseTex("Noise", 2D) = "white" {}
		_ShiftTangentMap("ShiftT", 2D) = "white" {}
		_UVoffset("_UVoffset", Vector) = (0,0,0,0)
		_SubTexUV("SubTexUV",Vector) = (0,0,0,0)
		_Roughness("Roughness",Range(0,1)) = 0.5
		_Metallic("Metallic",Range(0,1)) = 0.5
		_Cutoff("Cutoff",Range(0,1)) = 0.5
		_Length("Length",Range(0,5)) = 0.5
		_CutoffStart("CutoffStart",Float) = 0.5
		_CutoffEnd("CutoffEnd",Float) = 0.5
		_EdgeFade("EdgeFade",Range(0,1)) = 0.5
		_Gravity("Gravity",Vector) = (0,-1,0)
		_GravityStrength("GravityStrength",Float) = 1
		_WindSpeed("WindSpeed",Float) = 3

		_FresnelPower("FresnelPower",Float) = 1
		_FresnelStrength("FresnelStrength",Float) = 0.5

		_ShiftT("_ShiftT",Range(0,1)) = 0.1
		_Power1("Power1",Float) = 200
		_Strength1("Strength1",Float) = 0.5
		_Power2("Power2",Float) = 100
		_Strength2("Strength2",Float) = 0.3
	}

	SubShader 
	{
		Tags{"RenderType" = "Transparent" "Queue" = "Transparent+200"}
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100
		CGINCLUDE
		#pragma multi_compile_fwdbase
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		#include "FurForwardPass.cginc"
		
		v2f_fur vert0(appdata_t v)
		{
			return vert_internal(v, 0.05);
		}

		v2f_fur vert1(appdata_t v)
		{
			return vert_internal(v, 0.1);
		}

		v2f_fur vert2(appdata_t v)
		{
			return vert_internal(v, 0.15);
		}

		v2f_fur vert3(appdata_t v)
		{
			return vert_internal(v, 0.2);
		}

		v2f_fur vert4(appdata_t v)
		{
			return vert_internal(v, 0.25);
		}

		v2f_fur vert5(appdata_t v)
		{
			return vert_internal(v, 0.3);
		}

		v2f_fur vert6(appdata_t v)
		{
			return vert_internal(v, 0.35);
		}

		v2f_fur vert7(appdata_t v)
		{
			return vert_internal(v, 0.4);
		}

		v2f_fur vert8(appdata_t v)
		{
			return vert_internal(v, 0.45);
		}

		v2f_fur vert9(appdata_t v)
		{
			return vert_internal(v, 0.5);
		}

		v2f_fur vert10(appdata_t v)
		{
			return vert_internal(v, 0.55);
		}

				
		v2f_fur vert11(appdata_t v)
		{
			return vert_internal(v, 0.6);
		}
		
		v2f_fur vert12(appdata_t v)
		{
			return vert_internal(v, 0.65);
		}
		
		v2f_fur vert13(appdata_t v)
		{
			return vert_internal(v, 0.7);
		}
		
		v2f_fur vert14(appdata_t v)
		{
			return vert_internal(v, 0.75);
		}		

		v2f_fur vert15(appdata_t v)
		{
			return vert_internal(v, 0.8);
		}	
		
		v2f_fur vert16(appdata_t v)
		{
			return vert_internal(v, 0.85);
		}		

		v2f_fur vert17(appdata_t v)
		{
			return vert_internal(v, 0.9);
		}

		v2f_fur vert18(appdata_t v)
		{
			return vert_internal(v, 0.95);
		}	
		
		v2f_fur vert19(appdata_t v)
		{
			return vert_internal(v, 1);
		}			

		float4 frag0(v2f_fur i) : SV_Target
		{				
			float4 color = SRGBToLinear(tex2D(_Albedo,i.texcoord.xy));
			float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
			//float3 lightDir = -normalize(_LightDir);

			float NoL =dot(lightDir,i.normalWS);

			float DirLight= saturate (NoL);

			color *= DirLight;

			return float4(color.rgb,1);

		}

		float4 frag1(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.1);
		}

		float4 frag2(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.15);
		}

		float4 frag3(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.2);
		}

		float4 frag4(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.25);
		}

		float4 frag5(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.3);
		}

		float4 frag6(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.35);
		}
		
		float4 frag7(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.4);
		}

		float4 frag8(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.45);
		}

		float4 frag9(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.5);
		}

		float4 frag10(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.55);
		}

		float4 frag11(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.6);
		}

		float4 frag12(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.65);
		}

		float4 frag13(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.7);
		}

		float4 frag14(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.75);
		}

		float4 frag15(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.8);
		}

		float4 frag16(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.85);
		}

		float4 frag17(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.9);
		}

		float4 frag18(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 0.95);
		}

		float4 frag19(v2f_fur i) : SV_Target
		{
			return frag_internal(i, 1);
		}

		ENDCG

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
		
			#pragma vertex vert0
			#pragma fragment frag0
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert1
			#pragma fragment frag1
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert2
			#pragma fragment frag2
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert3
			#pragma fragment frag3
		
			ENDCG
		 
		}
		
		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert4
			#pragma fragment frag4
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert5
			#pragma fragment frag5
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert6
			#pragma fragment frag6 
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert7
			#pragma fragment frag7
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert8
			#pragma fragment frag8
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert9
			#pragma fragment frag9
		
			ENDCG
		 
		}

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert10
			#pragma fragment frag10
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert11
			#pragma fragment frag11
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert12
			#pragma fragment frag12
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert13
			#pragma fragment frag13
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert14
			#pragma fragment frag14
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert15
			#pragma fragment frag15
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert16
			#pragma fragment frag16
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert17
			#pragma fragment frag17
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert18
			#pragma fragment frag18
		
			ENDCG
		 
		}	

		Pass { 
			Tags{"LightMode" = "ForwardBase"}
	
			CGPROGRAM
		
			#pragma vertex vert19
			#pragma fragment frag19
		
			ENDCG
		 
		}	

        Pass
        {
	        Tags { "LightMode"="ShadowCaster" }
	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
	        #pragma multi_compile_shadowcaster
	        #include "UnityCG.cginc"

	        sampler2D _Shadow;

	        struct v2fs{
	        	V2F_SHADOW_CASTER;
	        	float2 uv:TEXCOORD2;
	        };

	        v2fs vert(appdata_base v){
	        	v2fs o;
	        	o.uv = v.texcoord.xy;
	        	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
	        	return o;
	        }

	        float4 frag( v2fs i ) : SV_Target
	        {
	        	fixed alpha = tex2D(_Shadow, i.uv).a;
	        	clip(alpha - 0.5);
	        	SHADOW_CASTER_FRAGMENT(i)
	        }

	        ENDCG
        }
	}
    /*
	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true" "LightMode" = "ForwardBase"}
		Cull Back
		LOD 100
		Pass
		{
			CGPROGRAM

			#pragma vertex dif_vert
			#pragma fragment dif_frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			struct dif_appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
			struct dif_v2f_fur
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float3 sh : TEXCOORD3;
			};

			
			float _Fresnelpower;
			float _Fresnelrange;
			
			dif_v2f_fur dif_vert ( dif_appdata v )
			{
				dif_v2f_fur o;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldPos = worldPos;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				
				o.normal = v.normal;
				o.uv = v.uv;
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				
				o.sh = ShadeSH9(float4(worldNormal,1));
				return o;
			}
			
			float4 dif_frag (dif_v2f_fur i ) : SV_Target
			{
				float4 finalColor;
				float3 worldSpaceLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos));
				float NoL = dot( i.worldNormal , worldSpaceLightDir );
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float fresnelNdotV = dot( i.worldNormal, worldViewDir );
				float fresnel = ( 0.2 * pow( 1.0 - fresnelNdotV, 2 ) );
				float4 diffuse = tex2D( _Diffuse, i.uv );
				float4 fresnelCol = fresnel * UNITY_LIGHTMODEL_AMBIENT * diffuse;
				float4 lightColor = _LightColor0;
				float wrap = 0.3;
				float4 wrapNoL = pow(  saturate(NoL) * (1 - wrap) + wrap ,2 * wrap + 1);
				finalColor.rgb = wrapNoL * ( diffuse + fresnelCol )  * lightColor;
				finalColor.rgb += i.sh * diffuse;
				finalColor.a = 1;
				return finalColor;
			}

			ENDCG

		}
	}
    */

}
