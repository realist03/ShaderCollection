Shader "Character/Character_PBR_emission_Shadow"
{
    Properties
    {
        _Diffuse("BaseColor",2D) = "gray"{}
        [Toggle(_USECOLOR)]_USECOLOR("Use Color",Float) = 0
        _MainColor("MainColor",Color) = (1,1,1)
        _EmissionStrength("EmissionStrength",Range(0,10)) = 0
        [Toggle(_USEPROPERTY)]_USEPROPERTY("Use Property",Float) = 0
        _Metallic("Metallic",Range(0,1)) = 0.5
        _Roughness("Roughness",Range(0,1)) = 0.5
        _Multiply("M",2D) = "gray"{}
        _Normalmap("NormalMap",2D) = "bump"{}

        [Space(10)]
        [Toggle(_ALPHATEST_ON)]_ALPHATEST_ON("AlphaTest",Float) = 0
        _Cutoff("Cutoff",Range(0,1)) = 0.5
        
        _AOStrength("AOStrength",Range(0,1)) = 1
        [Space(10)]
        _TransColor("TransColor",Color) = (1,0.2,0.2)
		_Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.5
		_TransScattering("Scaterring Power", Range( 1 , 50)) = 1
		_TransDirect("Direct", Range( 0 , 1)) = .5
		_TransAmbient("Ambient", Range( 0 , 1 )) = 0.2
        _TransShadow("TransShadow",Range(0,1)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
        [HideInInspector]_BRDFLUT("_BRDFLUT",2D) = "gray"{}

    }
    SubShader
    {
		Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 200
        
        Cull[_Cull]

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma target 2.0
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USECOLOR
            #pragma shader_feature _USEPROPERTY
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            #pragma multi_compile_fwdbase
            #define FORWARD_BASE_PASS
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "CustomInput.cginc"
            #include "DisneyForwardPass.cginc"
            ENDCG
        }

        Pass
        {
            Tags{ "LightMode" = "ForwardAdd" }
            Blend One One
            CGPROGRAM
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USECOLOR
            #pragma shader_feature _USEPROPERTY
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            #pragma multi_compile_fwdadd_fullshadows
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "CustomInput.cginc"
            #include "DisneyForwardPass.cginc"
            ENDCG
        }

        Pass
        {
	        Tags { "LightMode"="ShadowCaster" }
	        CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
            #pragma shader_feature _ALPHATEST_ON
	        #pragma multi_compile_shadowcaster
	        #include "UnityCG.cginc"

	        sampler2D _Shadow;
            sampler2D _Normalmap;
            half _Cutoff;

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

	        fixed4 frag( v2f i ) : SV_Target
	        {
                
                #ifdef _ALPHATEST_ON
                    half alpha = tex2D(_Normalmap,i.uv).a;
                    clip(alpha - _Cutoff);
                #else
	        	    half alpha = tex2D(_Shadow, i.uv).a;
	        	    clip(alpha - _Cutoff);
                #endif
	        	SHADOW_CASTER_FRAGMENT(i)
	        }

	        ENDCG
        }

        //UsePass "Character/OutShadow/Shadow"

    }
    
    SubShader
    {
		Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100
        
        Cull[_Cull]

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma target 2.0
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment_OP
            #pragma multi_compile_fwdbase
            #define FORWARD_BASE_PASS
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USECOLOR
            #pragma shader_feature _USEPROPERTY

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "CustomInput.cginc"
            #include "DisneyForwardPass.cginc"
            ENDCG
        }

        Pass
        {
            Tags{ "LightMode" = "ForwardAdd" }
            Blend One One
            CGPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment_OP
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _USECOLOR
            #pragma shader_feature _USEPROPERTY

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "CustomInput.cginc"
            #include "DisneyForwardPass.cginc"
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

	        sampler2D _Diffuse;

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

	        fixed4 frag( v2f i ) : SV_Target
	        {
	        	fixed alpha = tex2D(_Diffuse, i.uv).a;
	        	clip(alpha - 0.5);
	        	SHADOW_CASTER_FRAGMENT(i)
	        }

	        ENDCG
        }
        //UsePass "Character/OutShadow/Shadow"

    }
    
}