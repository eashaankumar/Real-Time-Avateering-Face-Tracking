Shader "Mixamo/GlossSpec" {
Properties {
  _Color ("Main Color", Color) = (1,1,1,1)
  _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
  _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
  _MainTex ("Base (RGB) Spec (A)", 2D) = "white" {}
  _BumpMap ("Normalmap", 2D) = "bump" {}
  _Gloss ("Gloss (RGB)", 2D) = "white" {}
  _SpecAmount ("Specular Amount", Range(0.0, 2.0)) = 1.0
  _GlossAmount ("Gloss Amount", Range(0.0, 2.0)) = 1.0
  _Specular ("Specular (RGB)", 2D) = "white" {}
}
SubShader { 
  Tags { "RenderType"="Opaque" }
  LOD 400
  
CGPROGRAM
#pragma surface surf BlinnPhong


sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _Gloss;
sampler2D _Specular;

fixed4 _Color;
half _Shininess;
half _SpecAmount;
half _GlossAmount;

struct Input {
  float2 uv_MainTex;
  float2 uv_BumpMap;
};

void surf (Input IN, inout SurfaceOutput o) {
  fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
  o.Albedo = tex.rgb * _Color.rgb;
  o.Gloss = tex2D(_Specular, IN.uv_MainTex).b * _SpecAmount;
  o.Alpha = tex.a * _Color.a;
  o.Specular = tex2D(_Gloss, IN.uv_MainTex).b * _GlossAmount * _Shininess;
  o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
}
ENDCG
}

FallBack "Specular"
}
