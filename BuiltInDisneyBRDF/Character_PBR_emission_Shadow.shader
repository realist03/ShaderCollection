// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Character/Character_PBR_emission_Shadow"
{
	Properties
	{
		_Diffuse("Diffuse", 2D) = "gray" {}
		_Multiply("Multiply", 2D) = "black" {}
		_Normalmap("Normal map", 2D) = "bump" {}
		_Emissioncolor("Emission color", Color) = (0,0,0,0)
		_FresnelStrength("Fresnel Strength", Float) = 2
		_FresnelTint("Fresnel Tint", Color) = (1,1,1,1)
		_frsnelpower("frsnel power", Float) = 0.2
		_fresnelrange("fresnel range", Range( 0.5 , 3)) = 1.5
		_SSSColor("SSS Color", Color) = (0.9622642,0.5317581,0.3495016,1)
		[Header(Translucency)]
		_Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.1
		_TransScattering("Scaterring Falloff", Range( 1 , 50)) = 2
		_TransDirect("Direct", Range( 0 , 1)) = 1
		_TransAmbient("Ambient", Range( 0 , 1)) = 0.2
		_TransShadow("Shadow", Range( 0 , 1)) = 0.9
		_AOStrength("AO Strength", Range( 0 , 1)) = 1
		_NormalScale("NormalScale", Range( 0 , 2)) = 1
		ShadowHeight("Shadow Height",float) = -0.95
		_ShadowColor("Shadow Color", Color) = (0, 0, 0, 0.4)

		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 2.0
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
			half2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
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
			half3 Translucency;
		};

		uniform sampler2D _Normalmap;
		uniform half4 _Normalmap_ST;
		uniform half _NormalScale;
		uniform half4 _FresnelTint;
		uniform half _frsnelpower;
		uniform half _fresnelrange;
		uniform half _FresnelStrength;
		uniform sampler2D _Diffuse;
		uniform half4 _Diffuse_ST;
		uniform half4 _Emissioncolor;
		uniform sampler2D _Multiply;
		uniform half4 _Multiply_ST;
		uniform half _AOStrength;
		uniform half _Translucency;
		uniform half _TransNormalDistortion;
		uniform half _TransScattering;
		uniform half _TransDirect;
		uniform half _TransAmbient;
		uniform half _TransShadow;
		uniform half4 _SSSColor;


		inline float UnpackNormal13_g1( float2 NormalXY )
		{
			return sqrt(1.0 - saturate(dot(NormalXY, NormalXY)));
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

			SurfaceOutputStandard r;
			r.Albedo = s.Albedo;
			r.Normal = s.Normal;
			r.Emission = s.Emission;
			r.Metallic = s.Metallic;
			r.Smoothness = s.Smoothness;
			r.Occlusion = s.Occlusion;
			r.Alpha = s.Alpha;
			return LightingStandard (r, viewDir, gi) + c;
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
			float2 uv_Normalmap = i.uv_texcoord * _Normalmap_ST.xy + _Normalmap_ST.zw;
			float2 temp_output_7_0_g1 = ( ( ( tex2D( _Normalmap, uv_Normalmap ).rg * float2( 2,2 ) ) - float2( 1,1 ) ) * _NormalScale );
			float2 NormalXY13_g1 = temp_output_7_0_g1;
			float localUnpackNormal13_g1 = UnpackNormal13_g1( NormalXY13_g1 );
			float3 appendResult14_g1 = (half3(temp_output_7_0_g1 , localUnpackNormal13_g1));
			float3 temp_output_18_0 = appendResult14_g1;
			o.Normal = temp_output_18_0;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			float fresnelNdotV8 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode8 = ( 0.0 + _frsnelpower * pow( 1.0 - fresnelNdotV8, _fresnelrange ) );
			float2 uv_Diffuse = i.uv_texcoord * _Diffuse_ST.xy + _Diffuse_ST.zw;
			half4 tex2DNode1 = tex2D( _Diffuse, uv_Diffuse );
			o.Albedo = ( ( _FresnelTint * fresnelNode8 * UNITY_LIGHTMODEL_AMBIENT * _FresnelStrength ) + tex2DNode1 ).rgb;
			float4 temp_output_5_0 = ( tex2DNode1.a * _Emissioncolor );
			o.Emission = temp_output_5_0.rgb;
			float2 uv_Multiply = i.uv_texcoord * _Multiply_ST.xy + _Multiply_ST.zw;
			half4 tex2DNode2 = tex2D( _Multiply, uv_Multiply );
			o.Metallic = tex2DNode2.r;
			o.Smoothness = ( 1.0 - tex2DNode2.g );
			float lerpResult45 = lerp( 1.0 , tex2DNode2.a , _AOStrength);
			o.Occlusion = lerpResult45;
			o.Translucency = ( tex2DNode2.b * _SSSColor ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d11 glcore gles gles3 metal 
		#pragma surface surf StandardCustom keepalpha fullforwardshadows exclude_path:deferred novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa 

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
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
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
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
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
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
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
		UsePass "Character/OutShadow/Shadow"
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16800
318;286;1083;742;948.249;602.461;1.526487;True;False
Node;AmplifyShaderEditor.RangedFloatNode;9;-848.3965,-477.8959;Half;False;Property;_frsnelpower;frsnel power;8;0;Create;True;0;0;False;0;0.2;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-850.239,-351.0076;Half;False;Property;_fresnelrange;fresnel range;9;0;Create;True;0;0;False;0;1.5;1.5;0.5;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-538.1857,-626.2188;Float;False;Property;_FresnelTint;Fresnel Tint;7;0;Create;True;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FresnelNode;8;-557.9203,-425.1224;Float;False;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;40;-592.4907,-710.4321;Float;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-535.1594,-803.3834;Float;False;Property;_FresnelStrength;Fresnel Strength;6;0;Create;True;0;0;False;0;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;3;-547.5104,229.5266;Float;True;Property;_Normalmap;Normal map;2;0;Create;True;0;0;False;0;None;None;True;0;False;bump;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-62.42776,-328.0653;Float;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-880,192;Float;False;Property;_NormalScale;NormalScale;19;0;Create;True;0;0;False;0;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-544,848;Float;False;Property;_AOStrength;AO Strength;18;0;Create;True;0;0;False;0;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-752.346,-213.5532;Float;True;Property;_Diffuse;Diffuse;0;0;Create;True;0;0;False;0;None;07b9bb591c99f454a9fadfbe6a2e6ebd;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;4;-672,0;Float;False;Property;_Emissioncolor;Emission color;3;0;Create;True;0;0;False;0;0,0,0,0;0.3679245,0.3679245,0.3679245,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;7;-510.1596,657.9311;Float;False;Property;_SSSColor;SSS Color;10;0;Create;True;0;0;False;0;0.9622642,0.5317581,0.3495016,1;1,0,0.1732144,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-555.6182,444.0405;Float;True;Property;_Multiply;Multiply;1;0;Create;True;0;0;False;0;None;96f92dc483abeb9419c126a38c8a2c2a;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;30;-1583.281,-299.3739;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;32;-1613.126,-163.6077;Float;False;Property;_Specular;Specular;5;0;Create;True;0;0;False;0;0.3;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;18;-236.5376,163.0175;Float;False;UnpackNormal;-1;;1;f04551b6a758f9f44825805e6396c82e;0;2;4;FLOAT2;0,0;False;5;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;24;-2471.877,-328.772;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;28;-1758.836,-341.9589;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-1793.874,-210.7912;Float;False;Property;_Gloss;Gloss;4;0;Create;True;0;0;False;0;40;80;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;36;107.5049,-48.64185;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;25;-2256.58,-424.3767;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-1272.533,-230.374;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-1094.04,-294.2136;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;12;199.7954,-247.1366;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;-216.4961,576.2218;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;22;-2764.548,-231.4227;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-384,-80;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-895.0856,-20.34038;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;42;16,496;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;26;-2106.278,-423.2695;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;27;-1944.226,-318.5433;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;23;-2498.205,-483.1939;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LightColorNode;33;-1565.03,-711.1626;Float;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.LerpOp;45;-208,736;Float;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;35;-1204.793,129.9606;Float;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;541.2323,-164.1849;Half;False;True;0;Half;ASEMaterialInspector;0;0;Standard;Character/Character_PBR_emission_Shadow;False;False;False;False;False;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;False;True;True;True;True;True;False;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;Diffuse;-1;11;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;1;Below;Character/OutShadow/Shadow;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;8;2;9;0
WireConnection;8;3;13;0
WireConnection;11;0;10;0
WireConnection;11;1;8;0
WireConnection;11;2;40;0
WireConnection;11;3;41;0
WireConnection;30;0;28;0
WireConnection;30;1;29;0
WireConnection;18;4;3;0
WireConnection;18;5;39;0
WireConnection;24;0;22;0
WireConnection;28;1;27;0
WireConnection;36;0;5;0
WireConnection;25;0;23;0
WireConnection;25;1;24;0
WireConnection;31;0;30;0
WireConnection;31;1;32;0
WireConnection;34;0;33;0
WireConnection;34;1;31;0
WireConnection;12;0;11;0
WireConnection;12;1;1;0
WireConnection;6;0;2;3
WireConnection;6;1;7;0
WireConnection;5;0;1;4
WireConnection;5;1;4;0
WireConnection;37;0;34;0
WireConnection;37;1;2;1
WireConnection;42;0;2;2
WireConnection;26;0;25;0
WireConnection;27;0;26;0
WireConnection;27;1;35;0
WireConnection;45;1;2;4
WireConnection;45;2;44;0
WireConnection;35;0;18;0
WireConnection;0;0;12;0
WireConnection;0;1;18;0
WireConnection;0;2;5;0
WireConnection;0;3;2;1
WireConnection;0;4;42;0
WireConnection;0;5;45;0
WireConnection;0;7;6;0
ASEEND*/
//CHKSM=ADB093B23ADF1A1150D9A18F23ADB6367C8410C1