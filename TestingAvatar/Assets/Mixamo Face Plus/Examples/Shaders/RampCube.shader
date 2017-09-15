// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'glstate.matrix.modelview[0]' with 'UNITY_MATRIX_MV'
// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'
// Upgrade NOTE: replaced 'glstate.matrix.projection' with 'UNITY_MATRIX_P'

// Upgrade NOTE: replaced 'glstate.matrix.modelview[0]' with 'UNITY_MATRIX_MV'
// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'
// Upgrade NOTE: replaced 'glstate.matrix.projection' with 'UNITY_MATRIX_P'

Shader "Custom/RampCube" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Color ("RGB (RGB)", Color) = (1,1,1,1)
		_BumpMap ("Normal (RGB)", 2D) = "bump" {}
		_SpecAmount ("Specular Amount", Float) = 0.0
		_SpecExponent ("Specular Exponent", Float) = 256
		_SpecCutoff ("Specular Cutoff", Float) = 0
		_SpecMap ("Specular Map (R)", 2D) = "white" {}
		_GlowColor ("Glow Color (RGB)", Color) = (1,1,1,1)
		_GlowStrength ("Glow Amount", Float) = 0.0
		_GlowTex ("Glow (RGB)", 2D) = "black" {}
		_RampValues ("Ramp Values (RGB)", Color) = (0.83, 0.5, 0.0, 1.0)
		_RampThresholds ("Ramp Thresholds (RGB)", Color) = (0.83, 0.5, 0.0, 1.0)
		_RampBlend ("Ramp Blend", Float) = 0.08
		_LightCoefficient ("Light Coefficient", Float) = 1.0
		_Fresnel ("Fresnel Amount", Float) = 1.0
		_FresnelCutoff ("Fresnel Cutoff", Float) = 0.4
		_RimAmount ("Rim Amount", Float) = 0.0
		_AOAmount ("AO Amount", Range(0, 1)) = 1.0
		_AO ("Ambient Occlusion (RGB)", 2D) = "white"

//		_Upness ("Upness", Range(0, 1)) = 0.2
	}
	SubShader { 
		Tags { "RenderType"="Opaque" }
		LOD 200
		Name "RAMPCUBE"
		
		CGPROGRAM

		#pragma surface surf RampLambert nolightmap noambient noforwardadd vertex:vert

		#include "Lighting.cginc"

		#pragma target 3.0


		sampler2D _MainTex; 
		sampler2D _Ramp;
		sampler2D _GlowTex; 
		sampler2D _BumpMap;
		sampler2D _SpecMap;
		
		sampler2D _AO;
		half _AOAmount;
		//samplerCUBE _Cube;
		half4 _Color;
		half _SpecAmount;
		half _SpecExponent;
		half _SpecCutoff;

		half _GlowStrength;
		half _LightCoefficient;
		
		half4 _RampValues;
		half4 _RampThresholds;
		half _RampBlend;
		
		half _Fresnel;
		half _FresnelCutoff;

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
		    half Alpha;
		    half Gloss;
		};
		
		void vert (inout appdata_full v, out Input o) {
		#if (defined (SHADER_API_D3D11)) || (defined (SHADER_API_D3D11_9X))

			o = (Input)0;

		#endif

            // evaluate SH light
            float3 worldN = mul ((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
            o.worldNormal = worldN;
            o.sphericalHarmonic = ShadeSH9 (float4 (worldN, 1.0));
        }
		
		half4 LightingRampLambert (MyOutput s, half3 lightDir, half3 viewDir, half atten) {
			half NdotL = dot (s.Normal, lightDir);
			half diff = (NdotL * 0.5 + 0.5);
			
			// ramp 1
//			half3 ramp = tex2D (_Ramp, float2(diff, 0)).rgb;
//			half3 attenRamp = diff * atten;

			// ramp 2
			half rampScalar = _RampValues.b;
			half mixB = clamp((diff-_RampThresholds.g)/_RampBlend, 0.0, 1.0);
			half mixA = clamp((diff-_RampThresholds.r)/_RampBlend, 0.0, 1.0);
			rampScalar = lerp(rampScalar, _RampValues.g, mixB);
			half3 ramp = lerp(rampScalar, _RampValues.r, mixA);
			
			half4 c;
			
			// spec highlight
			half3 h = normalize (lightDir + viewDir);
         	float nh = max (0.0, dot (s.Normal, h));
          	float spec = smoothstep(_SpecCutoff, 1.0, pow (nh, _SpecExponent));
			half3 highlight = clamp(spec * atten * s.SpecularColor.rgb, 0.0, 1.0) * _SpecAmount;
			
			// ramp lighting
			c.rgb = (s.Albedo * _LightColor0.rgb * ramp * 2  + highlight) + s.Ambient;
			
			c.a = s.Alpha;
			
			return c;
      	}
      	
		void surf (Input IN, inout MyOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap));
			
			//half3 worldNorm = WorldNormalVector(IN, o.Normal);

			// rim coefficients
			half fresnel =_Fresnel * smoothstep(_FresnelCutoff, 1, (1 - min(pow(dot(o.Normal, normalize(IN.viewDir)), 2), 1)));
			half3 rim = fresnel * IN.sphericalHarmonic;
			// rim from cube map
			//half3 rim = fresnel * upness * texCUBE(_Cube, worldNorm).rgb;

			//o.Rim = rim;
			o.Albedo = _Color.rgb * c.rgb * lerp(1.0, tex2D(_AO, IN.uv_MainTex), _AOAmount); //texCUBE(_Cube, worldNorm).rgb;
			o.Emission = tex2D(_GlowTex, IN.uv_GlowTex).rgb * _GlowStrength;
			o.SpecularColor = tex2D(_SpecMap, IN.uv_SpecMap).rgb;
			o.Ambient = (_LightCoefficient * IN.sphericalHarmonic * o.Albedo) * lerp(1.0, tex2D(_AO, IN.uv_MainTex), _AOAmount) + rim;
			o.Alpha = c.a;
		}
		
		ENDCG
      


	}
}
