// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Scene/FakeVolumetric"
{
	Properties
	{
		_Fresnel("Fresnel", Range( 0 , 10)) = 1
		_RGBNoise("RGB Noise", 2D) = "white" {}
		_Opacity("Opacity", Range( 0 , 1)) = 0.5
		_WaveStrength("WaveStrength", Range( 0 , 0.1)) = 0.01
		_Fade("Fade", Range( 0 , 10)) = 0
		_Color("Color", Color) = (0.8117648,0.6627451,0.3529412,1)
		_Ambient("Ambient", Range( 0 , 1)) = 1
		_Intensity("Intensity", Range( 0 , 2)) = 2
		_Smooth("Smooth", Range( 0 , 2)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 2.0
		#pragma exclude_renderers xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf Unlit alpha:fade keepalpha noshadow exclude_path:deferred novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc 
		struct Input
		{
			half2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
		};

		uniform sampler2D _RGBNoise;
		uniform half _WaveStrength;
		uniform half _Intensity;
		uniform half _Ambient;
		uniform half4 _Color;
		uniform half _Smooth;
		uniform half _Fade;
		uniform half _Opacity;
		uniform half _Fresnel;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_vertex3Pos = v.vertex.xyz;
			float2 uv_TexCoord2 = v.texcoord.xy * float2( 2,2 );
			float2 panner1 = ( -1.0 * _Time.y * float2( 0.1,0.1 ) + uv_TexCoord2);
			half4 tex2DNode13 = tex2Dlod( _RGBNoise, half4( panner1, 0, 0.0) );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 normalizeResult46 = normalize( ase_vertexNormal );
			v.vertex.xyz += ( half4( ase_vertex3Pos , 0.0 ) + ( ( tex2DNode13 * half4( normalizeResult46 , 0.0 ) ) * _WaveStrength ) ).rgb;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 uv_TexCoord2 = i.uv_texcoord * float2( 2,2 );
			float2 panner1 = ( -1.0 * _Time.y * float2( 0.1,0.1 ) + uv_TexCoord2);
			half4 tex2DNode13 = tex2D( _RGBNoise, panner1 );
			half4 temp_cast_0 = (_Smooth).xxxx;
			float4 temp_output_76_0 = pow( saturate( ( ( ( ( tex2DNode13.b * _Intensity ) + _Ambient ) + ( ( ( tex2DNode13.g * _Intensity ) + _Ambient ) + ( ( tex2DNode13.r * _Intensity ) + _Ambient ) ) ) * _Color ) ) , temp_cast_0 );
			float4 break86 = temp_output_76_0;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_worldNormal = i.worldNormal;
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float dotResult37 = dot( ase_worldViewDir , mul( unity_ObjectToWorld, half4( ase_vertexNormal , 0.0 ) ).xyz );
			float4 temp_output_75_0 = ( temp_output_76_0 * ( saturate( pow( ( 1.0 - ( uv_TexCoord2.y / 2.0 ) ) , _Fade ) ) * ( _Opacity * pow( saturate( dotResult37 ) , _Fresnel ) ) ) );
			float4 appendResult85 = (half4(break86.r , break86.g , break86.b , temp_output_75_0.r));
			o.Emission = appendResult85.xyz;
			o.Alpha = temp_output_75_0.r;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16100
-1460;195;1453;812;-447.3785;352.5933;1;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-1000.707,-97.42368;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;2,2;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;1;-728.4141,-97.14446;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.1;False;1;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-508.7077,73.92853;Float;False;Property;_Intensity;Intensity;7;0;Create;True;0;0;False;0;2;0.688;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;13;-528.5013,-124.2658;Float;True;Property;_RGBNoise;RGB Noise;1;0;Create;True;0;0;False;0;None;e76e4b35f6318b648a46f0e7c13bea67;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;69;-147.4138,-214.3618;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-246.1189,147.2365;Float;False;Property;_Ambient;Ambient;6;0;Create;True;0;0;False;0;1;0.11;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;52;-148.1935,-95.23018;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;67;-843.9558,810.8943;Float;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.NormalVertexDataNode;58;-824.5339,883.1596;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;70;55.90749,-214.3716;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;55.12776,-95.24004;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;-133.8043,-449.8533;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;57;-597.934,666.5594;Float;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;-559.9562,839.8943;Float;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;71;217.8563,-171.3582;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;59.517,-320.863;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;78;-481.0843,245.3761;Float;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;37;-338.2517,671.2759;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;74;588.2626,-324.233;Float;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-322.2311,809.2545;Float;False;Property;_Fresnel;Fresnel;0;0;Create;True;0;0;False;0;1;6.8;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-508.2221,562.6685;Float;False;Property;_Fade;Fade;4;0;Create;True;0;0;False;0;0;1.02;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;41;-398.592,417.4722;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;38;-193.2407,669.5266;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;51;591.1541,-63.56831;Float;False;Property;_Color;Color;5;0;Create;True;0;0;False;0;0.8117648,0.6627451,0.3529412,1;0.7924528,0.547013,0.3999644,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;39;-29.24066,674.5266;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-140.7994,576.1143;Float;False;Property;_Opacity;Opacity;2;0;Create;True;0;0;False;0;0.5;0.75;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;42;-203.2224,454.6687;Float;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;901.6817,-125.2361;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;33;-494.8822,1383.255;Float;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;44;-33.22278,454.6687;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;156.389,619.3066;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;59;1070.977,-91.12507;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;46;-287.3862,1381.49;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;77;1056.73,-11.06774;Float;False;Property;_Smooth;Smooth;8;0;Create;True;0;0;False;0;1;0.78;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;340.9181,596.3222;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;76;1342.746,-64.32719;Float;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-69.35295,1313.943;Float;False;Property;_WaveStrength;WaveStrength;3;0;Create;True;0;0;False;0;0.01;0.003;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-79.75583,1188.784;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;30;-502.6221,1034.259;Float;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;1641.158,269.9542;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;165.3439,1189.004;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;86;1534.181,-63.67966;Float;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;85;1899.488,56.62789;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;32;383.2605,1034.465;Float;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;90;1950.412,331.8808;Half;False;True;0;Half;ASEMaterialInspector;0;0;Unlit;Scene/FakeVolumetric;False;False;False;False;False;True;True;True;True;True;True;True;False;False;True;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;ForwardOnly;True;True;True;True;True;True;True;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;Legacy Shaders/Diffuse;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;1;0;2;0
WireConnection;13;1;1;0
WireConnection;69;0;13;2
WireConnection;69;1;55;0
WireConnection;52;0;13;1
WireConnection;52;1;55;0
WireConnection;70;0;69;0
WireConnection;70;1;56;0
WireConnection;54;0;52;0
WireConnection;54;1;56;0
WireConnection;72;0;13;3
WireConnection;72;1;55;0
WireConnection;65;0;67;0
WireConnection;65;1;58;0
WireConnection;71;0;70;0
WireConnection;71;1;54;0
WireConnection;73;0;72;0
WireConnection;73;1;56;0
WireConnection;78;0;2;2
WireConnection;37;0;57;0
WireConnection;37;1;65;0
WireConnection;74;0;73;0
WireConnection;74;1;71;0
WireConnection;41;0;78;0
WireConnection;38;0;37;0
WireConnection;39;0;38;0
WireConnection;39;1;16;0
WireConnection;42;0;41;0
WireConnection;42;1;43;0
WireConnection;49;0;74;0
WireConnection;49;1;51;0
WireConnection;44;0;42;0
WireConnection;40;0;11;0
WireConnection;40;1;39;0
WireConnection;59;0;49;0
WireConnection;46;0;33;0
WireConnection;45;0;44;0
WireConnection;45;1;40;0
WireConnection;76;0;59;0
WireConnection;76;1;77;0
WireConnection;28;0;13;0
WireConnection;28;1;46;0
WireConnection;75;0;76;0
WireConnection;75;1;45;0
WireConnection;34;0;28;0
WireConnection;34;1;35;0
WireConnection;86;0;76;0
WireConnection;85;0;86;0
WireConnection;85;1;86;1
WireConnection;85;2;86;2
WireConnection;85;3;75;0
WireConnection;32;0;30;0
WireConnection;32;1;34;0
WireConnection;90;2;85;0
WireConnection;90;9;75;0
WireConnection;90;11;32;0
ASEEND*/
//CHKSM=CEE5DCBDA2029C682DD55DEDD882957A83735B84