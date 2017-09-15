// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'glstate.matrix.modelview[0]' with 'UNITY_MATRIX_MV'
// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'
// Upgrade NOTE: replaced 'glstate.matrix.projection' with 'UNITY_MATRIX_P'

// Upgrade NOTE: replaced 'glstate.matrix.modelview[0]' with 'UNITY_MATRIX_MV'
// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'
// Upgrade NOTE: replaced 'glstate.matrix.projection' with 'UNITY_MATRIX_P'

Shader "Custom/Dial" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Color ("RGB (RGB)", Color) = (1,1,1,1)
		_BumpMap ("Normal (RGB)", 2D) = "bump" {}
		_SpecAmount ("Specular Amount", Float) = 0.0
		_SpecExponent ("Specular Exponent", Float) = 256
		_SpecCutoff ("Specular Cutoff", Float) = 0
		_SpecMap ("Specular Map (R)", 2D) = "white" {}
		_GlowColor ("Glow Color (RGB)", Color) = (1,1,1,1)
		_GlowCutoff ("Glow Cutoff", Float) = 0.0
		_GlowCutoffTex ("Glow Cutoff Map", 2D) = "white" {}
		_GlowStrength ("Glow Amount", Float) = 0.0
		_GlowTex ("Glow (RGB)", 2D) = "black" {}
		_Ramp ("Ramp (RGB)", 2D) = "white" {}
		_LightCoefficient ("Light Coefficient", Float) = 1.0
		//_Cube ("Light Cube", CUBE) = "" { Texgen CubeNormal }
		//_Fresnel ("Fresnel Amount", Range(0, 1)) = 1.0
		//_FresnelCutoff ("Fresnel Cutoff", Range(-1, 1)) = 0.4
		//_Upness ("Upness", Range(0, 1)) = 0.2
	}
	SubShader { 
		Tags { "RenderEffect"="Glow11" "RenderType"="Glow11" }
		LOD 200
		Name "RAMPCUBE"
		
		CGPROGRAM

		#pragma surface surf RampLambert nolightmap noambient noforwardadd vertex:vert
		//#pragma surface surf RampLambert novertexlights noforwardadd
		//#include "UnityShaderVariables.cginc"
		//#include "UnityCG.cginc"
		#include "Lighting.cginc"
		// novertexlights noforwardadd
		#pragma target 3.0


		sampler2D _MainTex; 
		sampler2D _Ramp;
		sampler2D _GlowTex; 
		sampler2D _BumpMap;
		sampler2D _SpecMap;
		sampler2D _GlowCutoffTex;
		//samplerCUBE _Cube;
		half4 _Color;
		half _SpecAmount;
		half _SpecExponent;
		half _SpecCutoff;
		//half _Fresnel;
		half _GlowCutoff;
		half _GlowStrength;
		half _LightCoefficient;
		//half _FresnelCutoff;
		//half _Upness;

		struct Input {
			float2 uv_MainTex;
			float2 uv_GlowTex;
			float2 uv_BumpMap;
			float2 uv_SpecMap;
			float3 worldRefl;
			float3 viewDir;
			float3 worldNormal;
			float3 sphericalHarmonic;
			INTERNAL_DATA
		};
		
		struct MyOutput {
		    half3 Albedo;
		    half3 Normal;
		    half3 Emission;
		    half3 Ambient;
		    half Specular;
		    half3 SpecularColor;
		    half Gloss;
		    half Alpha;
		    half3 Rim;
		};
		
		void vert (inout appdata_full v, out Input o) {
            // evaluate SH light
            float3 worldN = mul ((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
            o.sphericalHarmonic = ShadeSH9 (float4 (worldN, 1.0));
        }
		
		half4 LightingRampLambert (MyOutput s, half3 lightDir, half3 viewDir, half atten) {
			half NdotL = dot (s.Normal, lightDir);
			half diff = (NdotL * 0.5 + 0.5);
			half3 ramp = tex2D (_Ramp, float2(diff, 0)).rgb;
			half3 attenRamp = diff * atten;
			half4 c;
			
			// spec highlight
			half3 h = normalize (lightDir + viewDir);
         	float nh = max (0, dot (s.Normal, h));
          	float spec = smoothstep(_SpecCutoff, 1.0, pow (nh, _SpecExponent));
			
			// realistic highlight
			half3 highlight = clamp(spec * atten * s.SpecularColor.rgb, half3(0), half3(1)) * _SpecAmount;
			
			// toony highlight
			// half3 highlight = smoothstep( 0.3, 0.5, spec * atten)*_SpecAmount*s.SpecularColor;
			
			// standard lambert 
			// c.rgb = s.Albedo * _LightColor0.rgb * NdotL * atten * 2;
			
			// pre-shadow
			c.rgb = (s.Albedo * _LightColor0.rgb * ramp * 2 + highlight ) + s.Ambient; // + s.Rim; //* ramp * 2
			
			// add spherical harmonic
			// c.rgb = c.rgb + c.rgb*s.SphericalHarmonic*_LightCoefficient;
			
			// shadow map v1
			// c.rgb = s.Albedo * _LightColor0.rgb * 2 * lerp(s.Shadow, half3(1), ramp) + s.Rim;
			
			c.a = s.Alpha;
			
			return c;
      	}
      	
		void surf (Input IN, inout MyOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap));
			
			half3 worldNorm = WorldNormalVector(IN, o.Normal);
			

			
			// rim coefficients
			//half fresnel = _Fresnel * smoothstep(_FresnelCutoff, 1, (1 - min(pow(dot(o.Normal, IN.viewDir), 2), 1)));
			//half upness = smoothstep(_Upness, 1, worldNorm.g);
			// rim based off of ramp: 
			// half3 rim = fresnel * upness * tex2D(_Ramp, float2(texCUBE(_Cube, worldNorm).b)).rgb;
			o.SpecularColor = tex2D(_SpecMap, IN.uv_SpecMap).rgb;
			// rim from cube map
			// half3 rim = fresnel * upness * texCUBE(_Cube, worldNormal).rgb;
			o.Albedo = _Color.rgb * c.rgb; //texCUBE(_Cube, worldNorm).rgb;
			// o.Emission = _GlowStrength * tex2D(_GlowTex, IN.uv_GlowTex).rgb;
			//o.Rim = rim;
			o.Emission = step(1-_GlowCutoff, 1-tex2D(_GlowCutoffTex, IN.uv_GlowTex)) * tex2D(_GlowTex, IN.uv_GlowTex).rgb * _GlowStrength;
			o.Ambient = (_LightCoefficient * IN.sphericalHarmonic * o.Albedo);
			o.Alpha = c.a;
		}
		
		ENDCG
		
	}
	FallBack "Diffuse"
	CustomEditor "GlowMatInspector"
}
