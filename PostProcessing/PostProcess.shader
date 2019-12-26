Shader "PostProcessing/Combine"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//0 Combine
		Pass
		{
			CGPROGRAM
			#include "PostProcessing.cginc"
			#include "FXAA311.cginc"

			#pragma shader_feature _USEBLUR
			#pragma shader_feature _USEFXAA
			#pragma shader_feature _USEBLOOM
			#pragma shader_feature _USESATURATE
			#pragma shader_feature _USEVIGNETTE
			#pragma shader_feature _USEEXPOSURE
			#pragma shader_feature _GAMMACORRECTION
			#pragma shader_feature _TONEMAPPING

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 finalCol;
				finalCol = tex2D(_SourceTex,i.uv);
				#ifdef _USEFXAA
					float4 uvAux;

					uvAux.xy = i.uv + float2( -_MainTex_TexelSize.x, +_MainTex_TexelSize.y ) * 0.5f;
					uvAux.zw = i.uv + float2( +_MainTex_TexelSize.x, -_MainTex_TexelSize.y ) * 0.5f;
					finalCol = FxaaPixelShader_Quality(i.uv,uvAux,_SourceTex,_rcpFrame.xy,_rcpFrameOpt );
				#else 
					finalCol = tex2D(_SourceTex,i.uv);
				#endif

				#ifdef _USEBLOOM
					finalCol = float4(Bloom(finalCol.rgb,i.uv),1);
				#else
					finalCol = finalCol;
				#endif

				#ifdef _USESATURATE
					finalCol = Saturate(finalCol);
				#else
					finalCol = finalCol;
				#endif

				#ifdef _USEVIGNETTE
					finalCol = Vignette(finalCol,i.uv);
				#else
					finalCol = finalCol;
				#endif

				#ifdef _USEEXPOSURE
					finalCol = Exposure(finalCol);
				#else
					finalCol = finalCol;
				#endif

				#ifdef _GAMMACORRECTION
					finalCol = GammaCorrection(finalCol);
				#else
					finalCol = finalCol;
				#endif

				#ifdef _TONEMAPPING
					finalCol = ToneMapping(finalCol);
				#else
					finalCol = finalCol;
				#endif


				return finalCol;
			}
			ENDCG
		}

		//1 bloom prefilter
		Pass
		{
			CGPROGRAM
			#include "PostProcessing.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			
			fixed4 frag (v2f i) : SV_Target
			{
				return half4(Prefilter(SampleBox(i.uv, 1)), 1);
			}
			ENDCG
		}

		//2 bloom downsample
		Pass
		{
			CGPROGRAM
			#include "PostProcessing.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 frag (v2f i) : SV_Target
			{
				return SampleBox(i.uv, 1);
			}
			ENDCG
		}

		//3 bloom upsample
		Pass
		{
			Blend One One

			CGPROGRAM
			#include "PostProcessing.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 frag (v2f i) : SV_Target
			{
				return SampleBox(i.uv, 0.5);
			}
			ENDCG
		}

		//4 blur_hon
		Pass
		{
			CGPROGRAM
			#include "PostProcessing.cginc"

			#pragma vertex vert_blur_hon
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 frag (v2f_blur i) : SV_Target
			{
				return Blur(i,_BlurSize);
			}
			ENDCG
		}

		//5 blur_ver
		Pass
		{
			CGPROGRAM
			#include "PostProcessing.cginc"

			#pragma vertex vert_blur_ver
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 frag (v2f_blur i) : SV_Target
			{
				return Blur(i,_BlurSize);
			}
			ENDCG
		}

	}
}
