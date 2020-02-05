Shader "Character/Transmission_Hair"
{
    Properties
    {
        _D("BaseColor",2D) = "gray"{}
        _AOMap("AO",2D) = "white"{}
		[HideInInspector]_AOStrength("AOStrength", Range(0,1)) = 1.0
        [HideInInspector]_ShiftTangentMap("ShiftTangentMap",2D) = "gray"{}
        [HideInInspector]_DitherPattern("DitherPattern",2D) = "gray"{}
        _Roughness("Roughness",Range(0,1)) = 0.8
        _Transmission("Transmission",Float) = 1
        [Space(10)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 0
        [Toggle(_RECIVESHADOW)]_RECIVESHADOW("Recive Shadow",Float) = 1
        [Toggle(_ALPHATEST_ON)]_ALPHATEST_ON("AlphaTest",Float) = 1
        _Cutoff("Cutoff",Range(0,1)) = 0.333

        [Space(10)]
        _ShiftT("ShiftT",Float) = 0.1

        [Space(10)]
        _Power1("Power1",Float) = 100
        _Strength1("Strength1",Range(0,0.3)) = 0.02
        
        [Space(10)]
        _Power2("Power2",Float) = 200
        _Strength2("Strength2",Range(0,0.3)) = 0.05

        [Space(10)]
        _w("w",Range(0,1)) = 0.2
        _ScatterColor("ScatterColor",Color) = (0,0,0)

        [Space(10)]
        [Toggle(_USEDITHER)]_USEDITHER("Use Dither",Float) = 1
        _dither("DitherStrength",Range(0,1)) = 0.5
        _ditherThrohold("DitherThrohold",Range(0,1)) = 0.5
        _ditherTile("DitherTile",Float) = 1

        [Space(10)]
        _AOStrength("AO Strength",Range(0,1)) = 1

        _FresnelPower("FresnelPower",Range(1,10)) = 3
        _FresnelStrength("FresnelStrength",Range(0,2)) = 0.1
    }
    SubShader
    {
        Tags {"RenderType" = "AlphaTest"}
        
        Cull[_Cull]

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma target 2.0
            #pragma multi_compile_fwdbase
            #define FORWARD_BASE_PASS

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USEDITHER
            #pragma shader_feature _RECIVESHADOW
            //--------------------------------------

            #pragma vertex LitPassVertex
            #pragma fragment HairPassFragment

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #include "HairInput.cginc"
            #include "HairForwardPass.cginc"

            ENDCG
        }

        Pass
        {
            Tags{ "LightMode" = "ForwardAdd" }
            Blend One One
            CGPROGRAM
            #pragma target 2.0
            #pragma multi_compile_fwdbase_fullshadows

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USEDITHER
            #pragma shader_feature _RECIVESHADOW
            //--------------------------------------

            #pragma vertex LitPassVertex
            #pragma fragment HairPassFragment

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #include "HairInput.cginc"
            #include "HairForwardPass.cginc"

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

	        sampler2D _D;

	        struct v2f{
	        	V2F_SHADOW_CASTER;
	        	half2 uv:TEXCOORD2;
	        };

	        v2f vert(appdata_base v){
	        	v2f o;
	        	o.uv = v.texcoord.xy;
	        	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
	        	return o;
	        }

	        half4 frag( v2f i ) : SV_Target
	        {
	        	fixed alpha = tex2D(_D, i.uv).a;
	        	clip(alpha - 0.5);
	        	SHADOW_CASTER_FRAGMENT(i)
	        }

	        ENDCG
        }

    }
}
