// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Character/Hair"
{
	Properties
	{
		_Tint("Tint", Color) = (1,1,1,1)
		_D("D", 2D) = "white" {}
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_AO("AO", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_Metallic("Metallic", Range( 0 , 1)) = 0.2
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.3
		[Toggle(_USEHAIRCUBEMAP_ON)] _UseHairCubeMap("UseHairCubeMap", Float) = 1
		_AS_TexStrength("AS_TexStrength", Range( 0 , 1)) = 0.2
		_ASCubeMap("ASCubeMap", CUBE) = "black" {}
		_Hair("Hair", 2D) = "white" {}
		_AS_Specular_Strength("AS_Specular_Strength", Range( 0 , 2)) = 1
		_SpecularColor1("SpecularColor1", Color) = (1,1,1,1)
		_SpecularColor2("SpecularColor2", Color) = (1,1,1,1)
		_Shift("Shift", Float) = 0.1
		_Shift_2("Shift_2", Float) = 0.1
		_SpecularPower1("SpecularPower1", Float) = 100
		_SpecularPower2("SpecularPower2", Float) = 100
		[Toggle(_USEDITHER_ON)] _UseDither("UseDither", Float) = 0
		_DitherStrength("DitherStrength", Float) = 10
		_Good64x64TilingNoiseHighFreq("Good64x64TilingNoiseHighFreq", 2D) = "white" {}
		_EdgeMaskMin("EdgeMaskMin", Float) = 1.5
		_EdgeMaskContrast("EdgeMaskContrast", Float) = 2
		_SSS("SSS", Range( 0 , 0.3)) = 1
		[Header(Translucency)]
		_Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.1
		_TransScattering("Scaterring Falloff", Range( 1 , 50)) = 2
		_TransDirect("Direct", Range( 0 , 1)) = 1
		_TransAmbient("Ambient", Range( 0 , 1)) = 0.2
		_TransShadow("Shadow", Range( 0 , 1)) = 0.9
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest+0" }
		Cull Off
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 2.0
		#pragma shader_feature _USEHAIRCUBEMAP_ON
		#pragma shader_feature _USEDITHER_ON
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float3 viewDir;
			float3 worldRefl;
			float2 uv2_texcoord2;
			float4 screenPos;
		};

		struct SurfaceOutputStandardCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			half3 Transmission;
			half3 Translucency;
		};

		uniform sampler2D _Normal;
		uniform float4 _Normal_ST;
		uniform float4 _Tint;
		uniform sampler2D _D;
		uniform float4 _D_ST;
		uniform float _AS_Specular_Strength;
		uniform float4 _SpecularColor1;
		uniform float _Shift;
		uniform sampler2D _Hair;
		uniform float4 _Hair_ST;
		uniform float _SpecularPower1;
		uniform float _Shift_2;
		uniform float _SpecularPower2;
		uniform float4 _SpecularColor2;
		uniform samplerCUBE _ASCubeMap;
		uniform float _AS_TexStrength;
		uniform sampler2D _AO;
		uniform float _Metallic;
		uniform float _Smoothness;
		uniform float _SSS;
		uniform half _Translucency;
		uniform half _TransNormalDistortion;
		uniform half _TransScattering;
		uniform half _TransDirect;
		uniform half _TransAmbient;
		uniform half _TransShadow;
		uniform sampler2D _Good64x64TilingNoiseHighFreq;
		uniform float _DitherStrength;
		uniform float _EdgeMaskMin;
		uniform float _EdgeMaskContrast;
		uniform float _Cutoff = 0.5;


		inline float2 MyCustomExpression141( float2 uv )
		{
			return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);;
		}


		float4 CalculateContrast( float contrastValue, float4 colorTarget )
		{
			float t = 0.5 * ( 1.0 - contrastValue );
			return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
		}

		inline half4 LightingStandardCustom(SurfaceOutputStandardCustom s, half3 viewDir, UnityGI gi )
		{
			#if !DIRECTIONAL
			float3 lightAtten = gi.light.color;
			#else
			float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, _TransShadow );
			#endif
			half3 lightDir = gi.light.dir + s.Normal * _TransNormalDistortion;
			half transVdotL = pow( saturate( dot( viewDir, -lightDir ) ), _TransScattering );
			half3 translucency = lightAtten * (transVdotL * _TransDirect + gi.indirect.diffuse * _TransAmbient) * s.Translucency;
			half4 c = half4( s.Albedo * translucency * _Translucency, 0 );

			half3 transmission = max(0 , -dot(s.Normal, gi.light.dir)) * gi.light.color * s.Transmission;
			half4 d = half4(s.Albedo * transmission , 0);

			SurfaceOutputStandard r;
			r.Albedo = s.Albedo;
			r.Normal = s.Normal;
			r.Emission = s.Emission;
			r.Metallic = s.Metallic;
			r.Smoothness = s.Smoothness;
			r.Occlusion = s.Occlusion;
			r.Alpha = s.Alpha;
			return LightingStandard (r, viewDir, gi) + c + d;
		}

		inline void LightingStandardCustom_GI(SurfaceOutputStandardCustom s, UnityGIInput data, inout UnityGI gi )
		{
			#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
				gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
			#else
				UNITY_GLOSSY_ENV_FROM_SURFACE( g, s, data );
				gi = UnityGlobalIllumination( data, s.Occlusion, s.Normal, g );
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardCustom o )
		{
			float2 uv_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			float3 tex2DNode169 = UnpackNormal( tex2D( _Normal, uv_Normal ) );
			o.Normal = tex2DNode169;
			float2 uv_D = i.uv_texcoord * _D_ST.xy + _D_ST.zw;
			float4 tex2DNode12 = tex2D( _D, uv_D );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 objectToTangentDir = normalize( mul( ase_worldToTangent, mul( unity_ObjectToWorld, float4( ase_vertexNormal, 0 ) ).xyz) );
			float3 normalizeResult60 = normalize( cross( objectToTangentDir , float3(1,0,0) ) );
			float2 uv_Hair = i.uv_texcoord * _Hair_ST.xy + _Hair_ST.zw;
			float temp_output_66_0 = ( tex2D( _Hair, uv_Hair ).r - 0.5 );
			float3 temp_cast_0 = (( _Shift + temp_output_66_0 )).xxx;
			float3 temp_output_1_0_g23 = ( normalizeResult60 + ( temp_cast_0 * objectToTangentDir ) );
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 worldToTangentDir = normalize( mul( ase_worldToTangent, ase_worldlightDir) );
			float3 normalizeResult48 = normalize( i.viewDir );
			float3 normalizeResult9_g23 = normalize( ( worldToTangentDir + normalizeResult48 ) );
			float dotResult2_g23 = dot( temp_output_1_0_g23 , normalizeResult9_g23 );
			float smoothstepResult3_g23 = smoothstep( -1.0 , 0.0 , dotResult2_g23);
			float dotResult18_g23 = dot( temp_output_1_0_g23 , normalizeResult9_g23 );
			float3 temp_cast_1 = (( _Shift_2 + temp_output_66_0 )).xxx;
			float3 temp_output_1_0_g22 = ( normalizeResult60 + ( temp_cast_1 * objectToTangentDir ) );
			float3 normalizeResult9_g22 = normalize( ( worldToTangentDir + normalizeResult48 ) );
			float dotResult2_g22 = dot( temp_output_1_0_g22 , normalizeResult9_g22 );
			float smoothstepResult3_g22 = smoothstep( -1.0 , 0.0 , dotResult2_g22);
			float dotResult18_g22 = dot( temp_output_1_0_g22 , normalizeResult9_g22 );
			#ifdef _USEHAIRCUBEMAP_ON
				float4 staticSwitch171 = ( texCUBE( _ASCubeMap, normalize( WorldReflectionVector( i , tex2DNode169 ) ) ) * _AS_TexStrength );
			#else
				float4 staticSwitch171 = ( _AS_Specular_Strength * ( tex2DNode12 * ( ( _SpecularColor1 * ( smoothstepResult3_g23 * ( pow( sqrt( ( 1.0 - ( dotResult18_g23 * dotResult18_g23 ) ) ) , _SpecularPower1 ) * 1.0 ) ) ) + ( ( smoothstepResult3_g22 * ( pow( sqrt( ( 1.0 - ( dotResult18_g22 * dotResult18_g22 ) ) ) , _SpecularPower2 ) * 1.0 ) ) * _SpecularColor2 ) ) ) );
			#endif
			o.Albedo = ( ( ( _Tint * tex2DNode12 ) + staticSwitch171 ) * tex2D( _AO, i.uv2_texcoord2 ).r ).rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			float temp_output_30_0 = _SSS;
			float3 temp_cast_3 = (temp_output_30_0).xxx;
			o.Transmission = temp_cast_3;
			float3 temp_cast_4 = (temp_output_30_0).xxx;
			o.Translucency = temp_cast_4;
			o.Alpha = 1;
			float4 temp_cast_5 = (1.0).xxxx;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float2 uv141 = ase_screenPos.xy;
			float2 localMyCustomExpression141 = MyCustomExpression141( uv141 );
			#ifdef _USEDITHER_ON
				float4 staticSwitch172 = tex2D( _Good64x64TilingNoiseHighFreq, ( localMyCustomExpression141 / _DitherStrength ) );
			#else
				float4 staticSwitch172 = temp_cast_5;
			#endif
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult177 = dot( ase_worldViewDir , ase_vertexNormal );
			float temp_output_179_0 = ( abs( dotResult177 ) * 1.5 );
			float4 temp_cast_7 = (temp_output_179_0).xxxx;
			float lerpResult182 = lerp( _EdgeMaskMin , 1.0 , CalculateContrast(_EdgeMaskContrast,temp_cast_7).r);
			float lerpResult200 = lerp( pow( tex2DNode12.a , 2.0 ) , 1.0 , lerpResult182);
			clip( ( staticSwitch172 * tex2DNode12.a * lerpResult200 ).r - _Cutoff );
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d11 glcore gles gles3 metal 
		#pragma surface surf StandardCustom keepalpha fullforwardshadows noshadow exclude_path:deferred novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.uv2_texcoord2;
				o.customPack1.zw = v.texcoord1;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : SV_POSITION
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv2_texcoord2 = IN.customPack1.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputStandardCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16800
233;185;1083;801;1682.642;148.7518;1.189134;True;False
Node;AmplifyShaderEditor.CommentaryNode;206;-4292.503,743.5088;Float;False;2983.514;1214.826;Specular;30;54;65;55;59;71;58;66;68;49;70;67;60;47;74;75;77;64;50;48;69;91;90;79;80;78;81;82;94;164;165;;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalVertexDataNode;54;-4194.503,1177.509;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;59;-3845.988,1351.335;Float;False;Constant;_Vector1;Vector 1;9;0;Create;True;0;0;False;0;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;55;-3906.502,1177.509;Float;False;Object;Tangent;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;65;-3877.988,1495.335;Float;True;Property;_Hair;Hair;11;0;Create;True;0;0;False;0;d100c48841344d24cabc13ab516e2b1d;d100c48841344d24cabc13ab516e2b1d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;66;-3477.988,1527.335;Float;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-3477.988,1431.335;Float;False;Property;_Shift;Shift;15;0;Create;True;0;0;False;0;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CrossProductOpNode;58;-3477.988,1239.335;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;71;-3493.988,1655.335;Float;False;Property;_Shift_2;Shift_2;16;0;Create;True;0;0;False;0;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;49;-4242.503,1001.509;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;47;-4210.503,793.5088;Float;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;70;-3253.988,1623.335;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;60;-3221.988,1239.335;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;-3253.988,1463.335;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;74;-2949.988,1351.335;Float;False;Property;_SpecularPower1;SpecularPower1;17;0;Create;True;0;0;False;0;100;100;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;69;-2965.988,1463.335;Float;False;ShiftTangent;-1;;20;6d4cd4aff4ef6c643a2918f9332ff52a;0;3;5;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;50;-3906.502,1001.509;Float;False;World;Tangent;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;48;-3906.502,793.5088;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-2757.988,1367.335;Float;False;Constant;_Float0;Float 0;13;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-2949.988,1623.335;Float;False;Property;_SpecularPower2;SpecularPower2;18;0;Create;True;0;0;False;0;100;100;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;64;-2965.988,1191.336;Float;False;ShiftTangent;-1;;21;6d4cd4aff4ef6c643a2918f9332ff52a;0;3;5;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;91;-2581.987,1495.335;Float;False;Specular;-1;;22;fff4cc61cfd25394a926a9f15edf323e;0;5;1;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;14;FLOAT;0;False;16;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;176;-2176,-96;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;175;-2176,-272;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;90;-2581.987,1111.336;Float;False;Specular;-1;;23;fff4cc61cfd25394a926a9f15edf323e;0;5;1;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;14;FLOAT;0;False;16;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;80;-2581.987,1751.335;Float;False;Property;_SpecularColor2;SpecularColor2;14;0;Create;True;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;79;-2581.987,855.3359;Float;False;Property;_SpecularColor1;SpecularColor1;13;0;Create;True;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;78;-2277.986,983.3359;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;177;-1952,-192;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-2261.987,1607.335;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;169;-1248,512;Float;True;Property;_Normal;Normal;5;0;Create;True;0;0;False;0;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenPosInputsNode;14;-1968,192;Float;False;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;82;-1941.987,1367.335;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;12;-656,0;Float;True;Property;_D;D;1;0;Create;True;0;0;False;0;None;9715bfdfb26182d4b897dbd1a1abb9f3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.AbsOpNode;178;-1808,-192;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldReflectionVector;26;-896,512;Float;False;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;-1648,-192;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;180;-2179.649,-482.2454;Float;False;Property;_EdgeMaskContrast;EdgeMaskContrast;24;0;Create;True;0;0;False;0;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-639.6062,740.8873;Float;False;Property;_AS_TexStrength;AS_TexStrength;9;0;Create;True;0;0;False;0;0.2;0.18;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;141;-1696,192;Float;False;frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123)@;2;False;1;True;uv;FLOAT2;0,0;In;;Float;False;My Custom Expression;True;False;0;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;165;-1837.75,1156.867;Float;False;Property;_AS_Specular_Strength;AS_Specular_Strength;12;0;Create;True;0;0;False;0;1;0.342;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;-1706,1255.582;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-1664,272;Float;False;Property;_DitherStrength;DitherStrength;21;0;Create;True;0;0;False;0;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;25;-640,480;Float;True;Property;_ASCubeMap;ASCubeMap;10;0;Create;True;0;0;False;1;;None;bdf645a822e3d96468ad4a083c1c8ca3;True;0;False;black;LockedToCube;False;Object;-1;Auto;Cube;6;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-1477.989,1175.336;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;181;-1456,-192;Float;False;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;160;-576,-192;Float;False;Property;_Tint;Tint;0;0;Create;True;0;0;False;0;1,1,1,1;0.7264151,0.7264151,0.7264151,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;183;-995.0018,-759.6882;Float;False;Property;_EdgeMaskMin;EdgeMaskMin;23;0;Create;True;0;0;False;0;1.5;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;147;-1408,192;Float;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-256,512;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;22;-1248,160;Float;True;Property;_Good64x64TilingNoiseHighFreq;Good64x64TilingNoiseHighFreq;22;0;Create;True;0;0;False;0;76fdce85f67af6e4ea0f9340057d60bf;76fdce85f67af6e4ea0f9340057d60bf;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;173;-1072,64;Float;False;Constant;_Float2;Float 2;25;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;182;-737.1865,-666.5762;Float;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;198;-950.9302,-201.1719;Float;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;159;-256,-80;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;161;-912,816;Float;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;171;-16,480;Float;False;Property;_UseHairCubeMap;UseHairCubeMap;8;0;Create;True;0;0;False;0;0;1;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;200;-553.6827,-666.2881;Float;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;162;-656,816;Float;True;Property;_AO;AO;4;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;172;-896,96;Float;False;Property;_UseDither;UseDither;20;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;182.5005,147.1249;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-915.2673,356.7025;Float;False;Property;_HairAlphaMipMapBias;HairAlphaMipMapBias;19;0;Create;True;0;0;False;0;-1;-1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;93;384,144;Float;False;Property;_Smoothness;Smoothness;7;0;Create;True;0;0;False;0;0.3;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;197;-1006.626,-675.5719;Float;False;True;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;191;-1726.626,-787.5719;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;193;-1390.626,-675.5719;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;190;-1886.626,-659.5719;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;432.8115,424.0187;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;185;-1902.626,-787.5719;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;92;384,48;Float;False;Property;_Metallic;Metallic;6;0;Create;True;0;0;False;0;0.2;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-25.17913,258.981;Float;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;196;-1182.626,-675.5719;Float;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;192;-1550.626,-739.5719;Float;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;13;-656,240;Float;True;Property;_A;A;3;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;MipBias;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;30;384,240;Float;False;Property;_SSS;SSS;25;0;Create;True;0;0;False;0;1;0.5;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;768,0;Float;False;True;0;Float;ASEMaterialInspector;0;0;Standard;Character/Hair;False;False;False;False;False;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Masked;0.5;True;True;0;False;TransparentCutout;;AlphaTest;ForwardOnly;False;True;True;True;True;True;False;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;2;26;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;55;0;54;0
WireConnection;66;0;65;1
WireConnection;58;0;55;0
WireConnection;58;1;59;0
WireConnection;70;0;71;0
WireConnection;70;1;66;0
WireConnection;60;0;58;0
WireConnection;67;0;68;0
WireConnection;67;1;66;0
WireConnection;69;5;55;0
WireConnection;69;2;60;0
WireConnection;69;6;70;0
WireConnection;50;0;49;0
WireConnection;48;0;47;0
WireConnection;64;5;55;0
WireConnection;64;2;60;0
WireConnection;64;6;67;0
WireConnection;91;1;69;0
WireConnection;91;8;48;0
WireConnection;91;6;50;0
WireConnection;91;14;77;0
WireConnection;91;16;75;0
WireConnection;90;1;64;0
WireConnection;90;8;48;0
WireConnection;90;6;50;0
WireConnection;90;14;74;0
WireConnection;90;16;75;0
WireConnection;78;0;79;0
WireConnection;78;1;90;0
WireConnection;177;0;175;0
WireConnection;177;1;176;0
WireConnection;81;0;91;0
WireConnection;81;1;80;0
WireConnection;82;0;78;0
WireConnection;82;1;81;0
WireConnection;178;0;177;0
WireConnection;26;0;169;0
WireConnection;179;0;178;0
WireConnection;141;0;14;0
WireConnection;94;0;12;0
WireConnection;94;1;82;0
WireConnection;25;1;26;0
WireConnection;164;0;165;0
WireConnection;164;1;94;0
WireConnection;181;1;179;0
WireConnection;181;0;180;0
WireConnection;147;0;141;0
WireConnection;147;1;146;0
WireConnection;28;0;25;0
WireConnection;28;1;29;0
WireConnection;22;1;147;0
WireConnection;182;0;183;0
WireConnection;182;2;181;0
WireConnection;198;0;12;4
WireConnection;159;0;160;0
WireConnection;159;1;12;0
WireConnection;171;1;164;0
WireConnection;171;0;28;0
WireConnection;200;0;198;0
WireConnection;200;2;182;0
WireConnection;162;1;161;0
WireConnection;172;1;173;0
WireConnection;172;0;22;0
WireConnection;158;0;159;0
WireConnection;158;1;171;0
WireConnection;197;0;196;0
WireConnection;191;0;185;0
WireConnection;191;1;185;0
WireConnection;193;0;192;0
WireConnection;193;1;190;0
WireConnection;193;2;179;0
WireConnection;190;0;180;0
WireConnection;163;0;158;0
WireConnection;163;1;162;1
WireConnection;185;1;180;0
WireConnection;41;0;172;0
WireConnection;41;1;12;4
WireConnection;41;2;200;0
WireConnection;196;0;193;0
WireConnection;192;0;191;0
WireConnection;192;2;185;0
WireConnection;13;2;174;0
WireConnection;0;0;163;0
WireConnection;0;1;169;0
WireConnection;0;3;92;0
WireConnection;0;4;93;0
WireConnection;0;6;30;0
WireConnection;0;7;30;0
WireConnection;0;10;41;0
ASEEND*/
//CHKSM=987AE963859F755FC165D0A19F9DCF5EF05F1ACE