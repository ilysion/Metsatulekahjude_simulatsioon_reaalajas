Shader "JJ/Terrain2" {
	Properties {
		_MainTex("Main (RGB)", 2D) = "white" {}
		_NoiseTex("Noise (RGB)", 2D) = "gray"
		_NoiseTex2("Noise2 (RGB)", 2D) = "gray"
		_NoiseTex3("Noise3 (RGB)", 2D) = "gray"
		_NormalTex("Normal", 2D) = "bump" {}
		_OcclusionMap("Occlusion", 2D) = "white" {}
		_BurningTex("BuringTex (RGB)", 2D) = "white" {}

		_TexScale("Texture scale", Float) = 1.0
		
		_Color ("Color", Color) = (1,1,1,1)
		_WaterColor ("Water Col", Color) = (1,1,1,1)
		_ShoreColor("Shore Col", Color) = (1,1,1,1)
		_MountainColor("Mountain Col", Color) = (1,1,1,1)
		_BurntColor("BurntColor", Color) = (1,1,1,1)
		_BurningColor("BurningColor", Color) = (1,1,1,1)

		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

	    _Delta("delta", Float) = 0.0
				
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
		sampler2D _NoiseTex;
		sampler2D _NoiseTex2;
		sampler2D _NoiseTex3;
		sampler2D _NormalTex;
		sampler2D _OcclusionMap;
		sampler2D _BurningTex;
		half _TexScale;

		half _Glossiness;
		half _Metallic;

		fixed4 _Color;
		fixed4 _WaterColor;
		fixed4 _ShoreColor;
		fixed4 _MountainColor;
		fixed4 _BurntColor;
		fixed4 _BurningColor;

		float _Delta;

		struct Input {
			float2 uv_MainTex;
			fixed3 viewDir;
		};


		float scale(float v, float min, float max) {
			float ab = max - min;
			return saturate((v - min) / ab);
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {

			half4 noiseD1 = tex2D(_NoiseTex3, IN.uv_MainTex * 0.7 + float2(0.1, 0.1));
			half4 noiseD2 = tex2D(_NoiseTex3, IN.uv_MainTex * 0.7 + float2(0.3, 0.3));
			half2 noiseD = half2(noiseD1.x - 0.5, noiseD2.x - 0.5);


			half4 c = _Color;
			half4 data = tex2D(_MainTex, IN.uv_MainTex);
			half4 burningData = tex2D(_BurningTex, IN.uv_MainTex);
			half4 dataD = tex2D(_MainTex, IN.uv_MainTex + noiseD * 0.02);
			half4 occl = tex2D(_OcclusionMap, IN.uv_MainTex);

			
			half4 noise1 = tex2D(_NoiseTex, IN.uv_MainTex * 31.0);
			half4 noise2 = tex2D(_NoiseTex, IN.uv_MainTex * 16.0);
			half4 noise3 = tex2D(_NoiseTex, IN.uv_MainTex * 5.0 + float2(0.3, 0.2));
			half4 noise4 = tex2D(_NoiseTex, IN.uv_MainTex * 9.0 + float2(0.2, 0.5));

			half4 noise = (noise1 + noise2) / 2.0;

			c = lerp(c, _WaterColor, (1.0 - data.x) * 5 - 5);
			
			//noise
			c = c * noise;
			c = c + half4(noise3.x * 0.4, noise3.x * 0.3, -noise3.x * 0.7, 0.0);
			//end noise

			half water = scale(data.y, 0.06, 0.07); 
			half shore = scale(dataD.x, 0.02, 0.05);
			c = lerp(_ShoreColor, c, shore);

			c = lerp(_WaterColor, c, water);
			
			//data.y - heightmap pmst?
			
			/*
			//Fore movement when pressing T ---------------------------------------
			if (data.y < (0.01 + _Delta)) {
			    //c = _BurningColor;
				//c = lerp(_BurningColor, c, water);
				c = (1,1,1,1);
			}
			*/

			/*
			if (burningData.r < (1.0)) {
				c = (1,1,1,1);
			}
			*/
			
			//TAVALINE VÄRVIDEGA VARIANT
			
			/**/
			if (burningData.r < (0.89)) {
				c = _BurningColor;
			}
			if (burningData.r < 0.4) {
				c = _BurntColor;
			}
			if (burningData.r <= 0.01) {
				c = (1, 0, 0, 0);
			}
			
			







			/*
			//Working example with burningdataTexture
			//and???
			if(c.b != _WaterColor.b){
				if (c.r > _ShoreColor.r + 0.1 || c.r < _ShoreColor.r - 0.1) {
					if (burningData.r < (0.75)) {
						c = _BurningColor;
					}
					if (burningData.r < 0.5) {
						c = _BurntColor;
					}
					if (burningData.r <= 0.0) {
						c = (1, 0, 0, 0);
					}
				}
				
			}
			*/


			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness + data.a * 0.5;
			o.Occlusion = occl.x;
			o.Alpha = c.a;

			/*
			float3 normal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex * _TexScale * 0.5));
			o.Normal += normal;
			*/
			
		}
		ENDCG
	}
	FallBack "Diffuse"
}
