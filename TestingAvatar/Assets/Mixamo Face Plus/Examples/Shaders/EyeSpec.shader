
Shader "Custom/EyeSpec" {
Properties
 {
     _Color("Color", Color) = (0,1,0,1)
     _Attenuation("Attenuation", Float) = 3.0
     _SpecBrightness("Specular Brightness", Float) = 48.0
     _SpecMap("Specular (RGB)", 2D) = "white"
     _BumpMap("Normal (RGB)", 2D) = "bump"
     _Overcrank("Overcrank", Float) = 1.0
 }
    
 SubShader
 {
     Tags
    {
         "Queue"="Transparent"
         "RenderType"="Transparent"
    }
 
 	Cull Back
 	Blend One One
   
   CGPROGRAM
   #pragma surface surf Spec novertexlights noambient

   fixed4 _Color;
   sampler2D _BumpMap;
   sampler2D _SpecMap;
   float _Attenuation;
   float _SpecBrightness;
   float _Overcrank;
   float3 _LightDir;

   struct Input {
     float4 screenPos;
     float3 viewDir;
     float3 lightDir;
     float2 uv_Texture;
     float2 uv_BumpMap;
     float2 uv_SpecMap;
   };
   
   struct MyOutput {
    half3 Albedo;
    half3 Normal;
    half3 Emission;
    half Specular;
    half3 SpecularColor;
    half Alpha;
  };
	
  half4 LightingSpec (MyOutput s, half3 lightDir, half3 viewDir, half atten) {
          half3 h = normalize (lightDir + viewDir);

          float nh = max (0, dot (s.Normal, h));
          float spec = pow (nh, _SpecBrightness);

		  half4 c;
		  half highlight = smoothstep( 0.5, 1.0, (spec) * (atten * 2.0));
		  
		  // for deferred, blend on alpha, set albedo to color, and using alpha as highlight channel
		  c.rgb = _Color.rgb * clamp(smoothstep(0.6, 1.0, s.Alpha * highlight), 0.0, 10.0) * _LightColor0.rgb * s.SpecularColor * _Overcrank; 
		  c.a = 1; 
		  return c;
   }

   void surf (Input IN, inout MyOutput o) 
   {
	 o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap));
     o.Alpha = _Color.a;
     o.Albedo = 0.0;
     o.SpecularColor = tex2D(_SpecMap, IN.uv_SpecMap);
   }
   ENDCG
 }
 Fallback "Diffuse"
}
