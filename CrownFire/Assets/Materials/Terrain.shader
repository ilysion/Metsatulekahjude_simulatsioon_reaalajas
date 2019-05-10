Shader "JJ/Terrain" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}

		_RockTex("Rock (RGB)", 2D) = "white" {}
		_Soil1Tex("Soil1 (RGB)", 2D) = "white" {}
		_Soil2Tex("Soil2 (RGB)", 2D) = "white" {}
		_Soil3Tex("Soil3 (RGB)", 2D) = "white" {}

		_WaterTex("Water (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_OcclusionMap ("Occlusion", 2D) = "white" {}
		_TexScale ("Texture scale", Float) = 1.0
		_NoiseTex ("Noise (RGB)", 2D) = "gray"
		_NormalTex("Normal", 2D) = "bump" {}
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
		sampler2D _OcclusionMap;
		sampler2D _RockTex;
		sampler2D _Soil1Tex;
		sampler2D _Soil2Tex;
		sampler2D _Soil3Tex;
		sampler2D _WaterTex;
		sampler2D _NoiseTex;

		sampler2D _NormalTex;

		struct Input {
			float2 uv_MainTex;
			fixed3 viewDir;
		};

		half _Glossiness;
		half _Metallic;
		half _TexScale;
		fixed4 _Color;

		static const fixed4 black = fixed4(0.0, 0.0, 0.0, 1.0);
		static const fixed4 col1 = fixed4(0.8, 0.4, 0.2, 1.0); //lower
		static const fixed4 col2 = fixed4(0.2, 0.8, 0.9, 1.0); //upper
		static const fixed4 col3 = fixed4(0.4, 0.4, 0.4, 1.0); //rock


		fixed4 addColor(fixed4 source, fixed4 dest, fixed amount) {
			return dest * amount + source * (1.0 - amount);
		}
		/*
		void surf (Input IN, inout SurfaceOutputStandard o) {

			half4 data = tex2D(_MainTex, IN.uv_MainTex);

			fixed4 rock = tex2D(_RockTex, IN.uv_MainTex * _TexScale);
			fixed4 soil = tex2D(_SoilTex, IN.uv_MainTex * _TexScale);
			fixed4 water0 = tex2D(_WaterTex, IN.uv_MainTex * _TexScale * 2);
			fixed4 water1 = tex2D(_WaterTex, IN.uv_MainTex * _TexScale * 3 + _Time.r * 0.4);
			fixed4 water2 = tex2D(_WaterTex, IN.uv_MainTex * _TexScale * 3.5 + fixed2(-_Time.r, _Time.r) * 0.4);
			fixed4 noiseTex = tex2D(_NoiseTex, IN.uv_MainTex * _TexScale * 0.78433);
			noiseTex += fixed4(0.5, 0.5, 0.5, 0.5);

			fixed4 water = water0 * 0.2 + water1 * 0.3 + water2 * 0.3;

			half wh = max(0.0, 0.3 - data.b * 8.0);
			water += wh;

			half4 color = rock;
			color = addColor(color, soil, saturate(data.g * 80.0 * noiseTex.x));
			color = addColor(color, water, saturate(data.b * 80.0 * noiseTex.x));

			// Albedo comes from a texture tinted by color
			fixed4 c = color * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Occlusion = tex2D(_OcclusionMap, IN.uv_MainTex);
			o.Alpha = c.a;
		}*/
		/*
		float lr(float val, float noise) {

			//float res = saturate(val * noise);

			float res = 0;

			res = val;

			res = (1.0 - res) * 2.0 - 1.0;
			res = res * res * res;
			res = res * res * res;
			res = res * res * res;
			res = res * res * res;
			res = (res + 1.0) * 0.5;
			res = 1.0 - res;

			return res;
		}*/


		float amplify(float val, float amount) {
			return saturate(val * amount - amount * 0.5);
		}

		float lr(float val, float noise) {
			float res = 0;

			res = val;
			float add = abs(val - 0.5);
			res += (add * noise - 0.3);

			res = amplify(res, 5);
			//res = amplify(res, 50);

			return res;
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {


			half4 data = tex2D(_MainTex, IN.uv_MainTex);	
			fixed4 tex = tex2D(_OcclusionMap, IN.uv_MainTex);

			/*
			float noise = tex2D(_OcclusionMap, IN.uv_MainTex * 12.0).b;


			fixed4 soil1 = tex2D(_Soil1Tex, IN.uv_MainTex * _TexScale);
			fixed4 soil2 = tex2D(_Soil2Tex, IN.uv_MainTex * _TexScale);
			fixed4 soil3 = tex2D(_Soil3Tex, IN.uv_MainTex * _TexScale);
			fixed4 rockt = tex2D(_RockTex, IN.uv_MainTex * _TexScale);

			float sloap = tex.g;
			float sloap2 = saturate(sloap * sloap * 3);

			c1 = lerp(soil1, soil3, data.r);
			c2 = soil3;
			c3 = rockt;

			fixed4 c = lerp(c1, soil2, lr(sloap2, noise));

			//sloap			
			fixed rock = saturate(sloap*5 - 3);
			c = lerp(c, c3, lr(rock, noise));

			//Water
			fixed ab = saturate(1.0 - data.a * 10);
			fixed4 absc = fixed4(ab, ab, ab, ab);
			fixed4 cw = fixed4(0.1, 0.4, 1.0, 1.0); //water
			cw += absc;
			c = lerp(c, cw, lr(data.a, noise));
			*/

			//fixed4 c = lerp(col1, col2, data.r);
			fixed4 c = fixed4(0.0, 0.0, 0.0, 1.0);

			//Remove water AO
			float occl = saturate(tex.x);

			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness + data.a * 0.5;
			o.Occlusion = occl;
			o.Alpha = c.a;

			/*
			float3 normal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex * _TexScale * 0.5));
			o.Normal += normal;*/
			
		}
		ENDCG
	}
	FallBack "Diffuse"
}
