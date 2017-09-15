// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Eye" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_SpecAmount ("Specular Amount", Float) = 0.0
		_SpecExponent ("Specular Exponent", Float) = 256
		_SpecCutoff ("Specular Cutoff", Float) = 0
		_SpecMap ("Specular Map (R)", 2D) = "white" {}
     	_BumpMap("Normal (RGB)", 2D) = "bump"
     	_AO ("Ambient Occlusion (RGB)", 2D) = "white" {}
     	_AOAmount ("AO Amount", Range(0, 1)) = 1
		_Ramp ("Ramp (RGB)", 2D) = "white" {}
		_LightCoefficient ("Lighting Coefficient", Float) = 1
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf RampLambert noambient noforwardadd vertex:vert
		//#pragma surface surf RampLambert novertexlights noforwardadd
		//#include "UnityShaderVariables.cginc"
		//#include "UnityCG.cginc"
		#include "Lighting.cginc"
		// novertexlights noforwardadd
		#pragma target 3.0


		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecMap;
		sampler2D _Ramp;
		half _SpecAmount;
		half _SpecExponent;
		half _SpecCutoff;
		half _LightCoefficient;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_SpecMap;
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
			
			// pre-shadow
			c.rgb = (s.Albedo * _LightColor0.rgb * ramp * 2 + highlight ) + s.Ambient;
			
			c.a = s.Alpha;
			
			return c;
      	}

		void surf (Input IN, inout MyOutput o) {
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap));
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.SpecularColor = tex2D(_SpecMap, IN.uv_SpecMap).rgb;
			o.Albedo = c.rgb;
			o.Ambient = (_LightCoefficient * IN.sphericalHarmonic * o.Albedo);
			o.Alpha = c.a;
		}
		ENDCG
		
		      Pass {
      	 Tags { "Queue"="Transparent" }
      	 Name "AO"    
            // pass for ambient occlusion
         Blend DstColor Zero // multiply 
 
         CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it does not contain a surface program or both vertex and fragment programs.
		 #pragma exclude_renderers gles
         #pragma fragment frag noforwardadd
 
 		 #include "UnityCG.cginc"
         // User-specified properties
         uniform float _AOAmount; 
         uniform sampler2D _AO;
 
         float4 frag(v2f_img input) : COLOR
         {
         	float4 c = lerp(float4(1), tex2D(_AO, input.uv), _AOAmount);
            return c;
         }
 
         ENDCG
      }
      
	  Pass {
      	 Tags { "Queue"="Transparent" "LightMode"="ForwardAdd" }
      	 Name "AO"    
            // pass for ambient occlusion
         Blend DstColor Zero // multiply 
 
         CGPROGRAM
		 #pragma exclude_renderers gles
         #pragma fragment frag
 
 		 #include "UnityCG.cginc"
         // User-specified properties
         uniform float _AOAmount; 
         uniform sampler2D _AO;
 
         float4 frag(v2f_img input) : COLOR
         {
         	float4 c = lerp(float4(1), tex2D(_AO, input.uv), _AOAmount);
            return c;
         }
 
         ENDCG
      }

	}
	FallBack "Diffuse"
}
