Shader "Mixamo/NewShadier" {
Properties {
  _MainTex ("Base and Alpha (RGBA)", 2D) = "white" {}
  _Specular ("Specular", 2D) = "black" {}
  _SpecAmount ("Specular Amount", Range(0.0, 1.0)) = 0.0
  _BumpMap ("BumpMap", 2D) = "bump" {}
  _Emission ("Emission", 2D) = "black" {}
  _Color ("Main Color", Color) = (1,1,1,1)
  _RimColor ("Rim Color", Color) = (0.2, 0.2, 0.2, 0.0)
  _RimPower ("Rim Power", Range(0.5, 8.0)) = 2.5
}
 
SubShader {
  Tags { "RenderType"="Transparent" "Queue"="AlphaTest"}
  LOD 200
 
  // It's unfortunate that you cannot name a surface shader pass,
  // as the 4 passes in this shader are pretty much identical 
  // (with the exception of the rim being disabled on rear facing geo)
  // If we could name the passes, we could re-use them. Using a
  // .cginc might be one solution.
 
  // rear polygon core pass - renders back faces above 0.9 alpha
  ZWrite On
  Cull Front
  AlphaTest GEqual 0.9
  Blend SrcAlpha OneMinusSrcAlpha
 
  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd
 
  half4 LightingSimpleBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
    half3 h = normalize (lightDir + viewDir);
    half diff = saturate(dot (s.Normal, lightDir));
 
    float nh = max (0, dot (s.Normal, h));
    float spec = pow (nh, s.Specular * 128.0) * s.Gloss;
 
    half4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
    c.a = s.Alpha;
    return c;
  }
 
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
    o.Gloss = tex2D (_Specular, IN.uv_Specular).r;
    o.Specular = _SpecAmount;
    half rim = 0.0; // 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
    o.Emission = clamp(tex2D (_Emission, IN.uv_Emission).rgb + _RimColor.rgb * min(pow(rim, _RimPower), 0.9), half3 (0, 0, 0), half3 (1, 1, 1));
  }
 
  ENDCG
 
  // CORE PASS - this is the main pass, renders front faces above 0.9 alpha
  ZWrite On
  Cull Back
  AlphaTest GEqual 0.9
  Blend SrcAlpha OneMinusSrcAlpha
 
  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd
 
  half4 LightingSimpleBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
    half3 h = normalize (lightDir + viewDir);
    half diff = saturate(dot (s.Normal, lightDir));
 
    float nh = max (0, dot (s.Normal, h));
    float spec = pow (nh, s.Specular * 128.0) * s.Gloss;
 
    half4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
    c.a = s.Alpha;
    return c;
  }
 
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
    o.Gloss = tex2D (_Specular, IN.uv_Specular).r;
    o.Specular = _SpecAmount;
    half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
    o.Emission = clamp(tex2D (_Emission, IN.uv_Emission).rgb + _RimColor.rgb * min(pow(rim, _RimPower), 0.9), half3 (0, 0, 0), half3 (1, 1, 1));
  }
 
  ENDCG
 
  // fringe back face pass - just the alpha details, don't write depth
  ZWrite Off
  ZTest Less
  Cull Front
  AlphaTest Less 0.9
  Blend SrcAlpha OneMinusSrcAlpha
  
  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd
 
  half4 LightingSimpleBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
    half3 h = normalize (lightDir + viewDir);
    half diff = saturate(dot (s.Normal, lightDir));
 
    float nh = max (0, dot (s.Normal, h));
    float spec = pow (nh, s.Specular * 128.0) * s.Gloss;
 
    half4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
    c.a = s.Alpha;
    return c;
  }
 
 
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
    o.Gloss = tex2D (_Specular, IN.uv_Specular).r;
    o.Specular = _SpecAmount;
    half rim = 0.0; // - saturate(dot (normalize(IN.viewDir), o.Normal));
    o.Emission = clamp(tex2D (_Emission, IN.uv_Emission).rgb + _RimColor.rgb * min(pow(rim, _RimPower), 0.9), half3 (0, 0, 0), half3 (1, 1, 1));
  }
 
  ENDCG
 
  // fringe alpha pass, just the front details ([0-0.9] alpha)
  ZWrite Off
  ZTest Less
  Cull Back
  AlphaTest Less 0.9
  Blend SrcAlpha OneMinusSrcAlpha
 
  CGPROGRAM
  #pragma surface surf SimpleBlinnPhong noforwardadd
  
  half4 LightingSimpleBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
    half3 h = normalize (lightDir + viewDir);
    half diff = saturate(dot (s.Normal, lightDir));
  
    float nh = saturate(dot (s.Normal, h));
    float spec = pow (nh, s.Specular * 128.0) * s.Gloss;
 
    half4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
    c.a = s.Alpha;
    return c;
  }
  
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
    o.Gloss = tex2D (_Specular, IN.uv_Specular).r;
    o.Specular = _SpecAmount;
    half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
    o.Emission = clamp(tex2D (_Emission, IN.uv_Emission).rgb + _RimColor.rgb * min(pow(rim, _RimPower), 0.9), half3 (0, 0, 0), half3 (1, 1, 1));
  }
 
  ENDCG
}
 
  FallBack "Bumped Diffuse"
}