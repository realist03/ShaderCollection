// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "BeachWater_high"
{
	Properties
	{
		_Color0("Color0", Color) = (0,0,0,0)
		_Color1("Color1", Color) = (0,0,0,0)
		_Length_0("Length_0", Float) = 1
		_WaveSpeed_0("WaveSpeed_0", Float) = 1
		_Am_0("Am_0", Float) = 1
		_WaveSpeed_1("WaveSpeed_1", Float) = 1
		_Length_1("Length_1", Float) = 1
		_Am_1("Am_1", Float) = 1
		_height_offset("height_offset", Float) = 0
		_opacity_pow("opacity_pow", Float) = 0
		_StylizedSpecualrColor("StylizedSpecualrColor", Color) = (1,1,1,1)
		_StylizedSpecular("StylizedSpecular", Float) = 1
		_SpeSpeed("SpeSpeed", Float) = 0.2
		_SpecularNormal("SpecularNormal", 2D) = "bump" {}
		_SpeNormalScale("SpeNormalScale", Float) = 1
		_FakeSun("FakeSun", Vector) = (0,0,0,0)
		_FakeView("FakeView", Vector) = (0,0,0,0)
		_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalSpeed("NormalSpeed", Float) = 0.2
		_NormalScale("NormalScale", Float) = 0
		_Gloss("Gloss", Range( 0 , 1)) = 0
		_SpecularStrength("SpecularStrength", Range( 0 , 1)) = 0
		_NormalTexSize("NormalTexSize", Float) = 10
		_SpeTexSize("SpeTexSize", Float) = 10
		_RefTex("RefTex", 2D) = "white" {}
		_ScaleStrength("ScaleStrength", Float) = 0
		_ScaleSpeed("ScaleSpeed", Float) = 0
		[Toggle(_USESTYLIZEDSPECULAR_ON)] _UseStylizedSpecular("Use Stylized Specular", Float) = 0
		_Opacity("Opacity", Float) = 0
		_TransFoamTiling("TransFoamTiling", Vector) = (0,0,0,0)
		_WhiteFoamSpeed("WhiteFoamSpeed", Float) = 0
		_WhiteFoamStrength("WhiteFoamStrength", Float) = 2
		_WhiteFoamTiling("WhiteFoamTiling", Vector) = (5,5,8,8)
		_WhiteFoamColor("WhiteFoamColor", Color) = (1,1,1,0)
		_Noise("Noise", 2D) = "white" {}
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha , SrcAlpha OneMinusSrcAlpha
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest Less
		
		

		Pass
		{
			Name "Unlit"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityStandardUtils.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#pragma shader_feature _USESTYLIZEDSPECULAR_ON


			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			uniform float _Am_0;
			uniform float _Length_0;
			uniform float _WaveSpeed_0;
			uniform float _Am_1;
			uniform float _Length_1;
			uniform float _WaveSpeed_1;
			uniform float _ScaleSpeed;
			uniform float _ScaleStrength;
			uniform sampler2D _RefTex;
			uniform float2 _TransFoamTiling;
			uniform float3 _FakeView;
			uniform float3 _FakeSun;
			uniform sampler2D _SpecularNormal;
			uniform float _SpeSpeed;
			uniform float _SpeTexSize;
			uniform float _SpeNormalScale;
			uniform float _StylizedSpecular;
			uniform float4 _StylizedSpecualrColor;
			uniform float4 _Color1;
			uniform float4 _Color0;
			uniform float _height_offset;
			uniform float _opacity_pow;
			uniform sampler2D _NormalMap;
			uniform float _NormalSpeed;
			uniform float _NormalTexSize;
			uniform float _NormalScale;
			uniform float _Gloss;
			uniform float _SpecularStrength;
			uniform float4 _WhiteFoamColor;
			uniform sampler2D _Noise;
			uniform float _WhiteFoamSpeed;
			uniform float4 _WhiteFoamTiling;
			uniform float _WhiteFoamStrength;
			uniform float _Opacity;
			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float Wave_0240 = ( _Am_0 * sin( ( ( ( 2.0 * UNITY_PI ) / _Length_0 ) * ( v.vertex.xyz.y - ( _WaveSpeed_0 * _Time.y ) ) ) ) );
				float Wave_1243 = ( _Am_1 * sin( ( ( ( 2.0 * UNITY_PI ) / _Length_1 ) * ( v.vertex.xyz.x - ( _WaveSpeed_1 * _Time.y ) ) ) ) );
				float temp_output_29_0 = ( Wave_0240 + Wave_1243 );
				float4 appendResult42 = (float4(temp_output_29_0 , temp_output_29_0 , abs( temp_output_29_0 ) , 0.0));
				float mulTime205 = _Time.y * _ScaleSpeed;
				float4 appendResult290 = (float4(v.vertex.xyz.x , v.vertex.xyz.y , v.vertex.xyz.z , 0.0));
				float4 ScaleWave247 = ( v.ase_color.r * ( ( sin( mulTime205 ) * appendResult290 ) * _ScaleStrength ) );
				
				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.ase_texcoord1.xyz = ase_worldPos;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				o.ase_texcoord2 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				
				v.vertex.xyz += ( appendResult42 + ScaleWave247 ).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				fixed4 finalColor;
				float2 uv144 = i.ase_texcoord.xy * float2( 4,10 ) + float2( 0,0 );
				float2 panner145 = ( 1.0 * _Time.y * float2( 0.09,0.05 ) + uv144);
				float2 uv179 = i.ase_texcoord.xy * float2( 4,10 ) + float2( 0.5,0.2 );
				float2 panner147 = ( 1.0 * _Time.y * float2( -0.08,-0.05 ) + uv179);
				float2 uv174 = i.ase_texcoord.xy * _TransFoamTiling + float2( 0,0 );
				float2 panner175 = ( 0.01 * _Time.y * float2( 1,1 ) + uv174);
				float smoothstepResult177 = smoothstep( 0.1 , 0.79 , tex2D( _Noise, panner175 ).r);
				float4 lerpResult155 = lerp( tex2D( _RefTex, panner145 ) , tex2D( _RefTex, panner147 ) , saturate( smoothstepResult177 ));
				float4 TransparentFoam233 = ( lerpResult155 * i.ase_color.r );
				float mulTime52 = _Time.y * _SpeSpeed;
				float temp_output_54_0 = ( mulTime52 * 0.3 );
				float3 ase_worldPos = i.ase_texcoord1.xyz;
				float2 temp_output_128_0 = (( ase_worldPos / _SpeTexSize )).xz;
				float2 panner57 = ( temp_output_54_0 * float2( 0.1,0 ) + temp_output_128_0);
				float2 panner131 = ( temp_output_54_0 * float2( -0.1,0 ) + temp_output_128_0);
				float4 appendResult65 = (float4(UnpackNormal( tex2D( _SpecularNormal, panner57 ) ).r , UnpackNormal( tex2D( _SpecularNormal, panner131 ) ).g , 1.0 , 0.0));
				float2 panner56 = ( temp_output_54_0 * float2( 0,0.1 ) + temp_output_128_0);
				float2 panner132 = ( temp_output_54_0 * float2( 0,-0.1 ) + temp_output_128_0);
				float4 appendResult64 = (float4(UnpackNormal( tex2D( _SpecularNormal, panner56 ) ).r , UnpackNormal( tex2D( _SpecularNormal, panner132 ) ).g , 1.0 , 0.0));
				float3 break67 = BlendNormals( appendResult65.xyz , appendResult64.xyz );
				float4 appendResult71 = (float4(break67.x , break67.y , 1.0 , 0.0));
				float3 StylizedSpecularNormal226 = UnpackScaleNormal( appendResult71, _SpeNormalScale );
				float dotResult88 = dot( _FakeView , reflect( ( _FakeSun * float3( -1,-1,-1 ) ) , StylizedSpecularNormal226 ) );
				float clampResult97 = clamp( pow( max( 0.0 , dotResult88 ) , _StylizedSpecular ) , 0.0 , 1.0 );
				float4 StylizedSpecular228 = ( clampResult97 * _StylizedSpecualrColor );
				#ifdef _USESTYLIZEDSPECULAR_ON
				float4 staticSwitch253 = StylizedSpecular228;
				#else
				float4 staticSwitch253 = float4( 0,0,0,0 );
				#endif
				float4 lerpResult188 = lerp( _Color1 , _Color0 , i.ase_color.b);
				float clampResult335 = clamp( ase_worldPos.y , 0.0 , 1.0 );
				float4 lerpResult336 = lerp( lerpResult188 , _Color0 , clampResult335);
				float4 transform30 = mul(unity_ObjectToWorld,float4( i.ase_texcoord2.xyz , 0.0 ));
				float clampResult32 = clamp( pow( ( 1.0 - ( _height_offset + transform30.y ) ) , _opacity_pow ) , 0.0 , 1.0 );
				float temp_output_168_0 = ( clampResult32 * ( 1.0 - i.ase_color.r ) );
				float4 temp_output_104_0 = ( staticSwitch253 + ( lerpResult336 * temp_output_168_0 ) );
				float mulTime70 = _Time.y * _NormalSpeed;
				float temp_output_75_0 = ( mulTime70 * 0.3 );
				float2 temp_output_160_0 = (( ase_worldPos / _NormalTexSize )).xz;
				float2 uv78 = i.ase_texcoord.xy * temp_output_160_0 + float2( 1.59,0 );
				float2 panner79 = ( temp_output_75_0 * float2( 0.1,0.1 ) + uv78);
				float2 panner133 = ( temp_output_75_0 * float2( -0.1,-0.1 ) + ( temp_output_160_0 + float2( 0.418,0.355 ) ));
				float4 appendResult91 = (float4(UnpackNormal( tex2D( _NormalMap, panner79 ) ).r , UnpackNormal( tex2D( _NormalMap, panner133 ) ).g , 1.0 , 0.0));
				float2 panner80 = ( temp_output_75_0 * float2( -0.1,0.1 ) + ( temp_output_160_0 + float2( 0.865,0.148 ) ));
				float2 panner134 = ( temp_output_75_0 * float2( 0.1,-0.1 ) + ( temp_output_160_0 + float2( 0.651,0.752 ) ));
				float4 appendResult92 = (float4(UnpackNormal( tex2D( _NormalMap, panner80 ) ).r , UnpackNormal( tex2D( _NormalMap, panner134 ) ).g , 1.0 , 0.0));
				float3 break96 = BlendNormals( appendResult91.xyz , appendResult92.xyz );
				float4 appendResult101 = (float4(break96.x , break96.y , 1.0 , 0.0));
				float3 Nomral236 = UnpackScaleNormal( appendResult101, _NormalScale );
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(ase_worldPos);
				ase_worldViewDir = Unity_SafeNormalize( ase_worldViewDir );
				float3 worldSpaceLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(ase_worldPos));
				float3 normalizeResult223 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult216 = dot( Nomral236 , ( normalizeResult223 * -1.0 ) );
				float Specualr250 = ( pow( max( 0.0 , dotResult216 ) , _Gloss ) * _SpecularStrength );
				float mulTime292 = _Time.y * _WhiteFoamSpeed;
				float temp_output_291_0 = sin( mulTime292 );
				float2 appendResult301 = (float2(_WhiteFoamTiling.x , _WhiteFoamTiling.y));
				float2 uv317 = i.ase_texcoord.xy * appendResult301 + float2( 30,20 );
				float2 panner318 = ( temp_output_291_0 * float2( 2,1 ) + uv317);
				float smoothstepResult320 = smoothstep( 0.26 , 0.55 , tex2D( _Noise, panner318 ).r);
				float2 uv255 = i.ase_texcoord.xy * appendResult301 + float2( 0,0 );
				float2 panner256 = ( temp_output_291_0 * float2( -1.2,-1.1 ) + uv255);
				float smoothstepResult262 = smoothstep( 0.24 , 0.52 , tex2D( _Noise, panner256 ).r);
				float2 appendResult302 = (float2(_WhiteFoamTiling.z , _WhiteFoamTiling.w));
				float2 uv313 = i.ase_texcoord.xy * appendResult302 + float2( 0,0 );
				float2 panner314 = ( temp_output_291_0 * float2( 0.4,0.2 ) + uv313);
				float smoothstepResult316 = smoothstep( -0.06 , 0.55 , tex2D( _Noise, panner314 ).r);
				float lerpResult321 = lerp( smoothstepResult320 , smoothstepResult262 , smoothstepResult316);
				float2 uv293 = i.ase_texcoord.xy * appendResult302 + float2( 20,20 );
				float2 panner294 = ( temp_output_291_0 * float2( 1,0.35 ) + uv293);
				float smoothstepResult296 = smoothstep( 0.28 , 1.33 , tex2D( _Noise, panner294 ).r);
				float2 uv306 = i.ase_texcoord.xy * appendResult302 + float2( 20,5 );
				float2 panner307 = ( temp_output_291_0 * float2( 0.5,0.28 ) + uv306);
				float smoothstepResult310 = smoothstep( 0.1 , 0.43 , tex2D( _Noise, panner307 ).r);
				float lerpResult312 = lerp( smoothstepResult296 , smoothstepResult310 , smoothstepResult310);
				float lerpResult303 = lerp( lerpResult321 , lerpResult312 , smoothstepResult316);
				float temp_output_265_0 = saturate( lerpResult303 );
				float4 WhiteFoam269 = ( _WhiteFoamColor * ( temp_output_265_0 * i.ase_color.g ) );
				float4 break339 = saturate( ( ( TransparentFoam233 + temp_output_104_0 ) + ( temp_output_104_0 * Specualr250 ) + ( WhiteFoam269 * _WhiteFoamStrength ) ) );
				float4 appendResult340 = (float4(break339.r , break339.g , break339.b , ( ( temp_output_168_0 * _Opacity ) + WhiteFoam269 ).r));
				
				
				finalColor = appendResult340;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=16100
1;23;1918;1026;539.3315;2115.301;1.553643;True;True
Node;AmplifyShaderEditor.CommentaryNode;227;-4093.254,-3451.487;Float;False;3104.922;997.2168;Stylized SpecularNomral;28;130;127;51;129;52;128;54;132;131;57;56;58;62;60;65;66;69;67;71;53;55;59;61;63;64;73;77;226;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-3875.459,-2933.686;Float;False;Property;_SpeSpeed;SpeSpeed;12;0;Create;True;0;0;False;0;0.2;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;130;-4015.833,-3236.425;Float;False;Property;_SpeTexSize;SpeTexSize;25;0;Create;True;0;0;False;0;10;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;127;-4043.254,-3401.487;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;129;-3814.715,-3327.667;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;52;-3717.043,-2930.514;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;128;-3648.589,-3333.16;Float;False;True;False;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;235;-4093.866,-4479.149;Float;False;3461.82;1002.099;Normal;34;158;157;68;159;135;160;136;70;137;75;78;140;138;139;133;79;134;80;86;89;84;87;83;85;91;92;95;96;99;101;102;103;74;236;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-3521.44,-2959.056;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;132;-3290.171,-2738.677;Float;False;3;0;FLOAT2;0,-1;False;2;FLOAT2;0,-0.1;False;1;FLOAT;0.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;157;-4043.866,-4257.32;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;158;-4016.446,-4092.258;Float;False;Property;_NormalTexSize;NormalTexSize;24;0;Create;True;0;0;False;0;10;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;56;-3294.755,-2937.154;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0.1;False;1;FLOAT;0.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;131;-3296.171,-3166.678;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.1,0;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;57;-3297.501,-3328.298;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;60;-2982.571,-3164.222;Float;True;Property;_TextureSample2;Texture Sample 2;13;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;62;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;62;-2982.571,-3356.221;Float;True;Property;_SpecularNormal;SpecularNormal;13;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;59;-2842.571,-2569.27;Float;False;Constant;_Float3;Float 3;19;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;61;-2984.577,-2963.902;Float;True;Property;_TextureSample3;Texture Sample 3;13;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;62;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;68;-3385.445,-3592.05;Float;False;Property;_NormalSpeed;NormalSpeed;19;0;Create;True;0;0;False;0;0.2;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;58;-2693.342,-3040.899;Float;False;Constant;_Float1;Float 1;19;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;63;-2981.779,-2764.255;Float;True;Property;_TextureSample5;Texture Sample 5;13;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;62;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;159;-3815.329,-4183.5;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;135;-3355.668,-4186.683;Float;False;Constant;_Vector0;Vector 0;34;0;Create;True;0;0;False;0;0.418,0.355;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;70;-3227.03,-3588.878;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;65;-2566.568,-3260.222;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;160;-3649.202,-4188.993;Float;False;True;False;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;137;-3352.495,-3942.243;Float;False;Constant;_Vector2;Vector 2;34;0;Create;True;0;0;False;0;0.651,0.752;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;64;-2568.574,-2851.902;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector2Node;136;-3354.612,-4066.05;Float;False;Constant;_Vector1;Vector 1;34;0;Create;True;0;0;False;0;0.865,0.148;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.BlendNormalsNode;66;-2408.685,-3061.638;Float;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-3069.963,-4082.981;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;78;-3093.194,-4401.195;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1.3,1.3;False;1;FLOAT2;1.59,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;138;-3069.964,-4203.613;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;140;-3072.08,-3959.174;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-3031.43,-3617.419;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;133;-2652.269,-4211.2;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.1,-0.1;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;80;-2651.997,-4006.797;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.1,0.1;False;1;FLOAT;0.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;134;-2652.34,-3808.232;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,-0.1;False;1;FLOAT;0.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;67;-2195.511,-3063.212;Float;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;69;-2106.676,-2939.455;Float;False;Constant;_Float5;Float 5;29;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;79;-2656.95,-4399.642;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.1;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;73;-1894.677,-2909.137;Float;False;Property;_SpeNormalScale;SpeNormalScale;14;0;Create;True;0;0;False;0;1;0.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;83;-2362.791,-3836.183;Float;True;Property;_TextureSample0;Texture Sample 0;18;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;86;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;84;-2362.59,-4038.831;Float;True;Property;_TextureSample1;Texture Sample 1;18;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;86;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;87;-2363.583,-4237.15;Float;True;Property;_TextureSample4;Texture Sample 4;18;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;white;Auto;True;Instance;86;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;85;-2223.582,-3642.197;Float;False;Constant;_Float6;Float 6;19;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;71;-1827.431,-3063.649;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;89;-2074.354,-4113.828;Float;False;Constant;_Float7;Float 7;19;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;86;-2363.583,-4429.149;Float;True;Property;_NormalMap;NormalMap;18;0;Create;True;0;0;False;0;ca55d5778fe9ad34fa7aa40b035af6e8;ca55d5778fe9ad34fa7aa40b035af6e8;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;92;-1949.586,-3924.83;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;289;-8114.459,-1439.85;Float;False;Property;_WhiteFoamSpeed;WhiteFoamSpeed;33;0;Create;True;0;0;False;0;0;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;229;-4093.426,-2394.17;Float;False;1853.618;518.798;Stylized Specular;13;72;76;81;88;90;94;98;97;100;93;82;228;230;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;300;-8460.973,-1574.882;Float;False;Property;_WhiteFoamTiling;WhiteFoamTiling;35;0;Create;True;0;0;False;0;5,5,8,8;2,3,1.5,0.2;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.UnpackScaleNormalNode;77;-1611.369,-3021.471;Float;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;91;-1947.58,-4333.15;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;226;-1304.332,-2861.87;Float;False;StylizedSpecularNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;301;-8139.976,-1547.037;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector3Node;72;-4043.426,-2331.701;Float;False;Property;_FakeSun;FakeSun;16;0;Create;True;0;0;False;0;0,0,0;60,60,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;302;-7976.415,-1236.93;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;292;-7864.262,-1434.831;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;95;-1821.423,-4119.152;Float;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;96;-1604.796,-4119.366;Float;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;99;-1509.795,-3977.578;Float;False;Constant;_Float8;Float 8;29;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;293;-7782.652,-1261.043;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;5,5;False;1;FLOAT2;20,20;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;-3831.846,-2325.935;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;-1,-1,-1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;230;-3948.68,-2056.481;Float;False;226;StylizedSpecularNormal;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;249;-6128.473,-2404.775;Float;False;1879.345;534.7649;Specular;14;105;106;250;237;224;220;219;216;217;223;218;215;214;213;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;255;-7774.446,-1562.713;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.2,0.2;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SinOpNode;291;-7685.897,-1435.963;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;317;-7771.519,-1812.375;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.1,0.1;False;1;FLOAT2;30,20;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;306;-7783.566,-1025.127;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;5,5;False;1;FLOAT2;20,5;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;234;-4093.035,-1786.45;Float;False;1898.942;716.2472;Transparent Foam;16;233;144;179;147;145;146;141;178;177;175;174;155;142;143;285;331;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;313;-7780.694,-773.631;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.2,0.2;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;81;-3640.659,-2344.17;Float;False;Property;_FakeView;FakeView;17;0;Create;True;0;0;False;0;0,0,0;0.29,0.41,0.84;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PannerNode;294;-7525.381,-1261.523;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0.35;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;214;-6078.473,-2187.77;Float;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ReflectOpNode;82;-3635.702,-2173.925;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PannerNode;314;-7509.623,-771.911;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.4,0.2;False;1;FLOAT;0.03;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;102;-1378.611,-3969.795;Float;False;Property;_NormalScale;NormalScale;20;0;Create;True;0;0;False;0;0;0.14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;318;-7495.248,-1813.785;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;2,1;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;256;-7498.175,-1562.721;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-1.2,-1.1;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;101;-1349.207,-4119.629;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PannerNode;307;-7526.296,-1025.607;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.5,0.28;False;1;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;285;-4019.545,-1474.272;Float;False;Property;_TransFoamTiling;TransFoamTiling;32;0;Create;True;0;0;False;0;0,0;0.1,0.1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;213;-6020.422,-2354.775;Float;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;327;-7315.198,-1589.431;Float;True;Property;_TextureSample9;Texture Sample 9;37;0;Create;True;0;0;False;0;None;e54229c1c76f46543a3361d4f4065ef3;True;0;False;white;Auto;False;Instance;326;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;215;-5787.145,-2281.686;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;329;-7334.008,-1054.876;Float;True;Property;_TextureSample10;Texture Sample 10;37;0;Create;True;0;0;False;0;None;e54229c1c76f46543a3361d4f4065ef3;True;0;False;white;Auto;False;Instance;326;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.UnpackScaleNormalNode;103;-1135.043,-4119.313;Float;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;328;-7326.545,-1296.445;Float;True;Property;_TextureSample6;Texture Sample 6;37;0;Create;True;0;0;False;0;None;e54229c1c76f46543a3361d4f4065ef3;True;0;False;white;Auto;False;Instance;326;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;330;-7324.225,-802.5828;Float;True;Property;_TextureSample11;Texture Sample 11;37;0;Create;True;0;0;False;0;None;e54229c1c76f46543a3361d4f4065ef3;True;0;False;white;Auto;False;Instance;326;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;88;-3400.381,-2260.842;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;174;-4043.035,-1322.543;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;6,6;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;326;-7307.225,-1839.772;Float;True;Property;_Noise;Noise;37;0;Create;True;0;0;False;0;e6c9e03838e350740b497a1c41d3d751;e6c9e03838e350740b497a1c41d3d751;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;239;-1385.442,-1495.451;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;310;-7022.307,-1026.193;Float;True;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;0.43;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;93;-3245.719,-2260.945;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;223;-5559.71,-2259.739;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;316;-7019.073,-776.8909;Float;True;3;0;FLOAT;0;False;1;FLOAT;-0.06;False;2;FLOAT;0.55;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;238;-6128.354,-4232.827;Float;False;1345.705;620.3129;Wave_0;14;4;14;13;12;11;10;6;7;8;3;2;1;5;240;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;236;-879.0829,-4055.892;Float;False;Nomral;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;242;-6129.023,-3560.588;Float;False;1343.955;627.5266;Wave_1;14;18;28;27;26;25;24;21;22;20;17;15;16;19;243;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;218;-5550.61,-2143.631;Float;False;Constant;_Float0;Float 0;30;0;Create;True;0;0;False;0;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;175;-3785.765,-1323.023;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,1;False;1;FLOAT;0.01;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;262;-7010.226,-1563.373;Float;True;3;0;FLOAT;0;False;1;FLOAT;0.24;False;2;FLOAT;0.52;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;296;-7017.432,-1266.217;Float;True;3;0;FLOAT;0;False;1;FLOAT;0.28;False;2;FLOAT;1.33;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;30;-1157.17,-1496.615;Float;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;320;-7007.299,-1813.035;Float;True;3;0;FLOAT;0;False;1;FLOAT;0.26;False;2;FLOAT;0.55;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-1152,-1648;Float;False;Property;_height_offset;height_offset;8;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-3264.471,-2148.877;Float;False;Property;_StylizedSpecular;StylizedSpecular;11;0;Create;True;0;0;False;0;1;2.18;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;3;-6027.087,-3825.762;Float;False;Property;_WaveSpeed_0;WaveSpeed_0;3;0;Create;True;0;0;False;0;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;15;-6055.826,-3486.727;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;217;-5374.693,-2214.953;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;321;-6654.385,-1674.786;Float;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;195;-911.7511,-1551.993;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;17;-6058.753,-3042.05;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;312;-6661.063,-1049.117;Float;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;237;-5414.653,-2327.219;Float;False;236;Nomral;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleTimeNode;2;-6053.978,-3719.787;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-6031.863,-3148.025;Float;False;Property;_WaveSpeed_1;WaveSpeed_1;5;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;331;-3593.755,-1348.291;Float;True;Property;_TextureSample12;Texture Sample 12;37;0;Create;True;0;0;False;0;None;e54229c1c76f46543a3361d4f4065ef3;True;0;False;white;Auto;False;Instance;326;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PiNode;1;-6078.355,-4158.965;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;94;-3100.334,-2220.853;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;144;-3609.918,-1707.72;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;4,10;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;179;-3612.009,-1514.137;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;4,10;False;1;FLOAT2;0.5,0.2;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;147;-3336.594,-1514.986;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.08,-0.05;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-5890.354,-4047.965;Float;False;Property;_Length_0;Length_0;2;0;Create;True;0;0;False;0;1;1.66;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-5842.025,-3786.22;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;19;-5713.826,-3492.727;Float;False;207;183;k;1;23;;1,1,1,1;0;0
Node;AmplifyShaderEditor.PosVertexDataNode;4;-6070.875,-3974.914;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;97;-2896.073,-2221.581;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-5867.826,-3375.727;Float;False;Property;_Length_1;Length_1;6;0;Create;True;0;0;False;0;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;177;-3278.816,-1323.203;Float;True;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;0.79;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;5;-5736.354,-4164.965;Float;False;207;183;k;1;9;;1,1,1,1;0;0
Node;AmplifyShaderEditor.PannerNode;145;-3347.803,-1708.029;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.09,0.05;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PosVertexDataNode;18;-6079.023,-3296.54;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;-5881.648,-4182.827;Float;False;2;2;0;FLOAT;2;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;303;-6344.685,-1370.825;Float;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-944,-1392;Float;False;Property;_opacity_pow;opacity_pow;9;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;98;-2906.482,-2082.372;Float;False;Property;_StylizedSpecualrColor;StylizedSpecualrColor;10;0;Create;True;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;254;-6133.483,-1788.639;Float;False;1908.835;729.4952;WhiteFoam;12;257;259;260;261;263;264;265;266;267;268;269;325;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;216;-5195.117,-2206.668;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;196;-783.7511,-1551.993;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-5846.801,-3108.483;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-5859.12,-3510.588;Float;False;2;2;0;FLOAT;2;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;36;-608,-1472;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;210;-1293.837,-1870.821;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;31;-1013.453,-1845.415;Float;False;Property;_Color0;Color0;0;0;Create;True;0;0;False;0;0,0,0,0;0,0.8666667,0.5070654,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;106;-5143.576,-2108.815;Float;False;Property;_Gloss;Gloss;22;0;Create;True;0;0;False;0;0;0.54;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;265;-5030.624,-1325.051;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;178;-2985.513,-1323.544;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;334;-740.5443,-1715.488;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;23;-5663.826,-3442.727;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;246;-6128.802,-2886.146;Float;False;1462.821;438.1068;Scale Wave;11;241;212;211;208;117;207;206;205;161;247;290;;1,1,1,1;0;0
Node;AmplifyShaderEditor.VertexColorNode;267;-4838.842,-1354.81;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;-2688.01,-2116.105;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;9;-5686.354,-4114.965;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;10;-5681.249,-3928.51;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;141;-3125.305,-1736.45;Float;True;Property;_RefTex;RefTex;26;0;Create;True;0;0;False;0;2342f8fec8f3b3847bd5094176a22254;8eb68afe9235e7a46a85a6ba3f3292b2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;146;-3125.883,-1543.808;Float;True;Property;_TextureSample7;Texture Sample 7;26;0;Create;True;0;0;False;0;2342f8fec8f3b3847bd5094176a22254;2342f8fec8f3b3847bd5094176a22254;True;0;False;white;Auto;False;Instance;141;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;24;-5628.862,-3270.338;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;167;-651.8547,-1308.112;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;219;-4996.896,-2227.471;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;187;-1055.972,-2027.065;Float;False;Property;_Color1;Color1;1;0;Create;True;0;0;False;0;0,0,0,0;0,0.2699529,0.4627451,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;335;-477.0697,-1729.158;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;228;-2501.808,-2122.293;Float;False;StylizedSpecular;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;325;-4656.9,-1685.685;Float;False;Property;_WhiteFoamColor;WhiteFoamColor;36;0;Create;True;0;0;False;0;1,1,1,0;0.5801887,1,0.8751913,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;142;-2793.731,-1353.303;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;188;-735.6558,-1904.637;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;169;-436.9585,-1320.25;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;155;-2783.85,-1563.869;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;268;-4608.687,-1469.412;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;32;-432,-1472;Float;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-5477.074,-4012.099;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-5451.931,-3294.863;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-5027.589,-2004.348;Float;False;Property;_SpecularStrength;SpecularStrength;23;0;Create;True;0;0;False;0;0;0.19;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;161;-6078.802,-2780.258;Float;False;Property;_ScaleSpeed;ScaleSpeed;29;0;Create;True;0;0;False;0;0;1.03;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;220;-4798.267,-2221.452;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;13;-5315.156,-4011.893;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;324;-4378.436,-1586.072;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-5327.696,-3392.721;Float;False;Property;_Am_1;Am_1;7;0;Create;True;0;0;False;0;1;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;241;-6089.567,-2652.846;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SinOpNode;27;-5303.968,-3294.657;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-325.8079,-1994.492;Float;False;228;StylizedSpecular;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleTimeNode;205;-5891.596,-2775.67;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-203.5361,-1402.91;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;336;-461.0774,-1911.104;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-4646.197,-2198.945;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-5338.885,-4109.958;Float;False;Property;_Am_0;Am_0;4;0;Create;True;0;0;False;0;1;0.02;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;143;-2563.576,-1467.905;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;233;-2450.993,-1605.195;Float;False;TransparentFoam;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SinOpNode;206;-5679.006,-2775.983;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-5148.962,-3343.689;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-5160.15,-4060.925;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;253;-30.50069,-2016.62;Float;False;Property;_UseStylizedSpecular;Use Stylized Specular;30;0;Create;True;0;0;False;0;0;0;1;True;;Toggle;2;Key0;Key1;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;250;-4483.003,-2065.827;Float;False;Specualr;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-63.26831,-1896.412;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;290;-5827.219,-2654.663;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;269;-4442.085,-1377.187;Float;False;WhiteFoam;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;251;435.8137,-1710.525;Float;False;250;Specualr;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;252;160.6814,-2116.43;Float;False;233;TransparentFoam;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;-5557.526,-2701.39;Float;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;288;587.2595,-1469.958;Float;False;Property;_WhiteFoamStrength;WhiteFoamStrength;34;0;Create;True;0;0;False;0;2;0.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;240;-5004.827,-3951.348;Float;False;Wave_0;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;243;-5009.052,-3239.926;Float;False;Wave_1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;104;295.9553,-1923.745;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;270;628.7088,-1625.351;Float;False;269;WhiteFoam;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-5602.452,-2585.064;Float;False;Property;_ScaleStrength;ScaleStrength;28;0;Create;True;0;0;False;0;0;0.07;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;225;676.3344,-1772.6;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;211;-5412.441,-2829.277;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;154;491.3351,-1946.912;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;208;-5396.532,-2641.808;Float;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;244;163.6814,-794.8478;Float;False;240;Wave_0;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;286;844.755,-1546.145;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;245;162.3816,-705.1486;Float;False;243;Wave_1;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;279;-221.2054,-1244.301;Float;False;Property;_Opacity;Opacity;31;0;Create;True;0;0;False;0;0;0.95;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;222;910.6851,-1797.001;Float;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;-5163.366,-2668.267;Float;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;29;386.8093,-766.067;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;278;0.8141613,-1402.09;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;247;-4918.497,-2673.957;Float;False;ScaleWave;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.AbsOpNode;44;553.8868,-667.4618;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;338;1092.314,-1696.779;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;273;16.60863,-1265.108;Float;False;269;WhiteFoam;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;42;699.1386,-775.047;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;339;1273.759,-1611.705;Float;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;271;263.9479,-1401.159;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;248;642.3852,-611.9095;Float;False;247;ScaleWave;1;0;OBJECT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PannerNode;260;-5381.705,-1516.493;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.08,-0.05;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;263;-5170.416,-1737.957;Float;True;Property;_WhiteFoam;WhiteFoam;27;0;Create;True;0;0;False;0;2342f8fec8f3b3847bd5094176a22254;8eb68afe9235e7a46a85a6ba3f3292b2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;74;-3371.822,-4382.168;Float;False;Property;_NormalTiling;NormalTiling;21;0;Create;True;0;0;False;0;1,1;3,3;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;264;-5170.994,-1545.315;Float;True;Property;_TextureSample8;Texture Sample 8;27;0;Create;True;0;0;False;0;2342f8fec8f3b3847bd5094176a22254;2342f8fec8f3b3847bd5094176a22254;True;0;False;white;Auto;False;Instance;141;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;257;-5655.029,-1709.227;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;4,10;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;53;-3891.315,-3058.659;Float;False;Property;_SpecularTiling;SpecularTiling;15;0;Create;True;0;0;False;0;1,1;3,3;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-3612.684,-3077.686;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1.3,1.3;False;1;FLOAT2;1.59,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;209;895.1667,-777.9835;Float;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;259;-5657.12,-1515.644;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;4,10;False;1;FLOAT2;0.5,0.2;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;340;1572.176,-1573.007;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PannerNode;261;-5392.914,-1709.536;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.09,0.05;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;266;-4828.961,-1565.376;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;337;1805.529,-1573.027;Float;False;True;2;Float;ASEMaterialInspector;0;1;BeachWater_high;0770190933193b94aaa3065e307002fa;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;2;5;False;-1;10;False;-1;True;0;False;-1;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;0;False;-1;True;1;False;-1;True;False;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;0
WireConnection;129;0;127;0
WireConnection;129;1;130;0
WireConnection;52;0;51;0
WireConnection;128;0;129;0
WireConnection;54;0;52;0
WireConnection;132;0;128;0
WireConnection;132;1;54;0
WireConnection;56;0;128;0
WireConnection;56;1;54;0
WireConnection;131;0;128;0
WireConnection;131;1;54;0
WireConnection;57;0;128;0
WireConnection;57;1;54;0
WireConnection;60;1;131;0
WireConnection;62;1;57;0
WireConnection;61;1;56;0
WireConnection;63;1;132;0
WireConnection;159;0;157;0
WireConnection;159;1;158;0
WireConnection;70;0;68;0
WireConnection;65;0;62;1
WireConnection;65;1;60;2
WireConnection;65;2;58;0
WireConnection;160;0;159;0
WireConnection;64;0;61;1
WireConnection;64;1;63;2
WireConnection;64;2;59;0
WireConnection;66;0;65;0
WireConnection;66;1;64;0
WireConnection;139;0;160;0
WireConnection;139;1;136;0
WireConnection;78;0;160;0
WireConnection;138;0;160;0
WireConnection;138;1;135;0
WireConnection;140;0;160;0
WireConnection;140;1;137;0
WireConnection;75;0;70;0
WireConnection;133;0;138;0
WireConnection;133;1;75;0
WireConnection;80;0;139;0
WireConnection;80;1;75;0
WireConnection;134;0;140;0
WireConnection;134;1;75;0
WireConnection;67;0;66;0
WireConnection;79;0;78;0
WireConnection;79;1;75;0
WireConnection;83;1;134;0
WireConnection;84;1;80;0
WireConnection;87;1;133;0
WireConnection;71;0;67;0
WireConnection;71;1;67;1
WireConnection;71;2;69;0
WireConnection;86;1;79;0
WireConnection;92;0;84;1
WireConnection;92;1;83;2
WireConnection;92;2;85;0
WireConnection;77;0;71;0
WireConnection;77;1;73;0
WireConnection;91;0;86;1
WireConnection;91;1;87;2
WireConnection;91;2;89;0
WireConnection;226;0;77;0
WireConnection;301;0;300;1
WireConnection;301;1;300;2
WireConnection;302;0;300;3
WireConnection;302;1;300;4
WireConnection;292;0;289;0
WireConnection;95;0;91;0
WireConnection;95;1;92;0
WireConnection;96;0;95;0
WireConnection;293;0;302;0
WireConnection;76;0;72;0
WireConnection;255;0;301;0
WireConnection;291;0;292;0
WireConnection;317;0;301;0
WireConnection;306;0;302;0
WireConnection;313;0;302;0
WireConnection;294;0;293;0
WireConnection;294;1;291;0
WireConnection;82;0;76;0
WireConnection;82;1;230;0
WireConnection;314;0;313;0
WireConnection;314;1;291;0
WireConnection;318;0;317;0
WireConnection;318;1;291;0
WireConnection;256;0;255;0
WireConnection;256;1;291;0
WireConnection;101;0;96;0
WireConnection;101;1;96;1
WireConnection;101;2;99;0
WireConnection;307;0;306;0
WireConnection;307;1;291;0
WireConnection;327;1;256;0
WireConnection;215;0;213;0
WireConnection;215;1;214;0
WireConnection;329;1;307;0
WireConnection;103;0;101;0
WireConnection;103;1;102;0
WireConnection;328;1;294;0
WireConnection;330;1;314;0
WireConnection;88;0;81;0
WireConnection;88;1;82;0
WireConnection;174;0;285;0
WireConnection;326;1;318;0
WireConnection;310;0;329;1
WireConnection;93;1;88;0
WireConnection;223;0;215;0
WireConnection;316;0;330;1
WireConnection;236;0;103;0
WireConnection;175;0;174;0
WireConnection;262;0;327;1
WireConnection;296;0;328;1
WireConnection;30;0;239;0
WireConnection;320;0;326;1
WireConnection;217;0;223;0
WireConnection;217;1;218;0
WireConnection;321;0;320;0
WireConnection;321;1;262;0
WireConnection;321;2;316;0
WireConnection;195;0;39;0
WireConnection;195;1;30;2
WireConnection;312;0;296;0
WireConnection;312;1;310;0
WireConnection;312;2;310;0
WireConnection;331;1;175;0
WireConnection;94;0;93;0
WireConnection;94;1;90;0
WireConnection;147;0;179;0
WireConnection;7;0;3;0
WireConnection;7;1;2;0
WireConnection;97;0;94;0
WireConnection;177;0;331;1
WireConnection;145;0;144;0
WireConnection;6;1;1;0
WireConnection;303;0;321;0
WireConnection;303;1;312;0
WireConnection;303;2;316;0
WireConnection;216;0;237;0
WireConnection;216;1;217;0
WireConnection;196;0;195;0
WireConnection;21;0;16;0
WireConnection;21;1;17;0
WireConnection;20;1;15;0
WireConnection;36;0;196;0
WireConnection;36;1;33;0
WireConnection;265;0;303;0
WireConnection;178;0;177;0
WireConnection;23;0;20;0
WireConnection;23;1;22;0
WireConnection;100;0;97;0
WireConnection;100;1;98;0
WireConnection;9;0;6;0
WireConnection;9;1;8;0
WireConnection;10;0;4;2
WireConnection;10;1;7;0
WireConnection;141;1;145;0
WireConnection;146;1;147;0
WireConnection;24;0;18;1
WireConnection;24;1;21;0
WireConnection;219;1;216;0
WireConnection;335;0;334;2
WireConnection;228;0;100;0
WireConnection;188;0;187;0
WireConnection;188;1;31;0
WireConnection;188;2;210;3
WireConnection;169;0;167;1
WireConnection;155;0;141;0
WireConnection;155;1;146;0
WireConnection;155;2;178;0
WireConnection;268;0;265;0
WireConnection;268;1;267;2
WireConnection;32;0;36;0
WireConnection;11;0;9;0
WireConnection;11;1;10;0
WireConnection;25;0;23;0
WireConnection;25;1;24;0
WireConnection;220;0;219;0
WireConnection;220;1;106;0
WireConnection;13;0;11;0
WireConnection;324;0;325;0
WireConnection;324;1;268;0
WireConnection;27;0;25;0
WireConnection;205;0;161;0
WireConnection;168;0;32;0
WireConnection;168;1;169;0
WireConnection;336;0;188;0
WireConnection;336;1;31;0
WireConnection;336;2;335;0
WireConnection;224;0;220;0
WireConnection;224;1;105;0
WireConnection;143;0;155;0
WireConnection;143;1;142;1
WireConnection;233;0;143;0
WireConnection;206;0;205;0
WireConnection;28;0;26;0
WireConnection;28;1;27;0
WireConnection;14;0;12;0
WireConnection;14;1;13;0
WireConnection;253;0;231;0
WireConnection;250;0;224;0
WireConnection;34;0;336;0
WireConnection;34;1;168;0
WireConnection;290;0;241;1
WireConnection;290;1;241;2
WireConnection;290;2;241;3
WireConnection;269;0;324;0
WireConnection;207;0;206;0
WireConnection;207;1;290;0
WireConnection;240;0;14;0
WireConnection;243;0;28;0
WireConnection;104;0;253;0
WireConnection;104;1;34;0
WireConnection;225;0;104;0
WireConnection;225;1;251;0
WireConnection;154;0;252;0
WireConnection;154;1;104;0
WireConnection;208;0;207;0
WireConnection;208;1;117;0
WireConnection;286;0;270;0
WireConnection;286;1;288;0
WireConnection;222;0;154;0
WireConnection;222;1;225;0
WireConnection;222;2;286;0
WireConnection;212;0;211;1
WireConnection;212;1;208;0
WireConnection;29;0;244;0
WireConnection;29;1;245;0
WireConnection;278;0;168;0
WireConnection;278;1;279;0
WireConnection;247;0;212;0
WireConnection;44;0;29;0
WireConnection;338;0;222;0
WireConnection;42;0;29;0
WireConnection;42;1;29;0
WireConnection;42;2;44;0
WireConnection;339;0;338;0
WireConnection;271;0;278;0
WireConnection;271;1;273;0
WireConnection;260;0;259;0
WireConnection;263;1;261;0
WireConnection;264;1;260;0
WireConnection;55;0;53;0
WireConnection;209;0;42;0
WireConnection;209;1;248;0
WireConnection;340;0;339;0
WireConnection;340;1;339;1
WireConnection;340;2;339;2
WireConnection;340;3;271;0
WireConnection;261;0;257;0
WireConnection;266;0;263;0
WireConnection;266;1;264;0
WireConnection;266;2;265;0
WireConnection;337;0;340;0
WireConnection;337;1;209;0
ASEEND*/
//CHKSM=1A038DA5DD818B100267FE5DA2C7B10D8C9466F1