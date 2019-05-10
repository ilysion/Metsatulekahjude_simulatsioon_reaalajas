Shader "Custom/RimLightingStandard" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_RimColor("Rim Color", Color) = (1,0.140625,0,1)
		_RimPower("Rim Power", Range(0.01,8.0)) = 3
		_Emissive("Emission", 2D) = "black" {}
		_EmissiveColor("Emission Color", Color) = (1,1,1,1)
		_EmissiveIntensity("Emission Intensity", Range(0,10)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _Emissive;

		struct Input {
			float2 uv_MainTex;
			fixed3 viewDir;
			float2 uv_Emissive;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _RimColor;
		fixed _RimPower;
		float4 _EmissiveColor;
		float _EmissiveIntensity;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;

			float4 Tex2D1 = tex2D(_Emissive, (IN.uv_Emissive.xyxy).xy);
			float4 Multiply0 = Tex2D1 + _EmissiveColor;
			float4 Multiply2 = Multiply0 * _EmissiveIntensity.xxxx;
			o.Emission = Multiply2;

			/*
			fixed3 view = normalize(IN.viewDir);
			fixed3 nml = o.Normal;
			fixed VdN = dot(view, nml);
			fixed rim = 1.0 - saturate(VdN);
			*/
			//o.Emission = Multiply2 + (_RimColor.rgb) * pow(rim, _RimPower);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
