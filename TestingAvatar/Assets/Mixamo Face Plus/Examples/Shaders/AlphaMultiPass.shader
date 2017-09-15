Shader "Mixamo/AlphaMultiPass" {
Properties {
  _MainTex ("Base and Alpha (RGBA)", 2D) = "white" {}
  _Specular ("Specular", 2D) = "black" {}
  _Gloss ("Gloss", 2D) = "white" {}
  _SpecAmount ("Specular Amount", Range(0.0, 1.0)) = 0.0
  _BumpMap ("BumpMap", 2D) = "bump" {}
  _Emission ("Emission", 2D) = "black" {}
  _Color ("Main Color", Color) = (1,1,1,1)
  _RimColor ("Rim Color", Color) = (0.2, 0.2, 0.2, 0.0)
  _RimPower ("Rim Power", Range(0.5, 8.0)) = 2.5
}

CGINCLUDE

  sampler2D _MainTex;
  sampler2D _Specular;
  sampler2D _Gloss;
  sampler2D _BumpMap;
  sampler2D _Emission;
  float4 _Color;
  float4 _RimColor;
  float _RimPower;
  float _GlossAmount;
  float _SpecAmount;
  
  half4 LightingSimpleBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
    half3 h = normalize (lightDir + viewDir);
    half diff = saturate(dot (s.Normal, lightDir));

    float nh = max (0, dot (s.Normal, h));
    float spec = pow (nh, s.Gloss * 128.0) * s.Specular;

    half4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
    c.a = s.Alpha;
    return c;
  }

  struct Input {
    float2 uv_MainTex;
    float2 uv_Specular;
    float2 uv_Gloss;
    float2 uv_BumpMap;
    float2 uv_Emission;
    float3 viewDir;
  };

  void surf (Input IN, inout SurfaceOutput o) {
    half4 c = tex2D (_MainTex, IN.uv_MainTex);
    
    o.Albedo = c.rgb * _Color.rgb;
    o.Alpha = c.a;
    o.Normal = UnpackNormal(tex2D (_BumpMap, IN.uv_BumpMap));
    o.Specular = tex2D (_Specular, IN.uv_Specular).r;
    o.Gloss = tex2D (_Gloss, IN.uv_Gloss).r;
    half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
    o.Emission = clamp(tex2D (_Emission, IN.uv_Emission).rgb + _RimColor.rgb * min(pow(rim, _RimPower), 0.9), half3 (0, 0, 0), half3 (1, 1, 1));
  }

ENDCG

SubShader {
  Tags { "RenderType"="Transparent" "Queue"="AlphaTest"}
  LOD 200

  // prime the alpha values
  ZWrite On
  ZTest Less
  Cull Off
  AlphaTest Equal 1
  Blend SrcAlpha OneMinusSrcAlpha
  ColorMask A

  CGPROGRAM
  #pragma surface alphaPass Lambert noforwardadd alpha

  void alphaPass(Input IN, inout SurfaceOutput o) {
    half4 c = tex2D (_MainTex, IN.uv_MainTex);
    o.Albedo = c.rgb * _Color.rgb;
    o.Alpha = c.a;
  }

  ENDCG

  // CORE PASS - this is the main pass
  ZWrite Off
  ZTest Equal
  Cull Back
  AlphaTest Off
  Blend SrcAlpha OneMinusSrcAlpha
  ColorMask RGBA

  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd 

  ENDCG

  // fringe back face pass
  ZWrite Off
  ZTest Less
  Cull Front
  AlphaTest Off
  Blend SrcAlpha OneMinusSrcAlpha
  
  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd 

  ENDCG

  // fringe alpha pass, just the front details
  ZWrite On
  ZTest Less
  Cull Back
  AlphaTest Off
  Blend SrcAlpha OneMinusSrcAlpha

  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd 

  ENDCG
  
}

  FallBack "Bumped Diffuse"
}