Shader "FinalCrownFire/TerrainTest1" {
	Properties {
		_MainTex("Main (RGB)", 2D) = "white" {}
		_LandTex("Land (RGB)", 2D) = "white" {}
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
		_GlowColor("GlowColor", Color) = (1,1,1,1)
		_GlowColor2("GlowColor2", Color) = (1,1,1,1)
		_FlashColor("FlashColor", Color) = (1,1,1,1)
		_FlashSpeed("FlashSpeed / 0 - Disabled" , Float) = 1.0
		_GlowSpeed("GlowSpeed / 0 - Disabled", Float) = 1.0
		_GlowIntensity("GlowIntensity", Range(0,3)) = 1.0
		_GlowColorIntensity("GlowColorIntensity", Range(0,3)) = 1.0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	    _Delta("delta", Float) = 0.0
	    _DeltaTime("deltaTime", Float) = 0.0
	    _DeltaTimeFast("deltaTimeFast", Float) = 0.0
				
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
		sampler2D _LandTex;
		sampler2D _NoiseTex;
		sampler2D _NoiseTex2;
		sampler2D _NoiseTex3;
		sampler2D _NormalTex;
		sampler2D _OcclusionMap;
		sampler2D _BurningTex;
		half _TexScale;

		half _GlowColorIntensity;
		half _GlowIntensity;
		half _Glossiness;
		half _Metallic;

		fixed4 _Color;
		fixed4 _WaterColor;
		fixed4 _ShoreColor;
		fixed4 _MountainColor;
		fixed4 _BurntColor;
		fixed4 _BurningColor;
		fixed4 _GlowColor;
		fixed4 _GlowColor2;
		fixed4 _FlashColor;

		float _Delta;
		float _DeltaTime;
		float _DeltaTimeFast;
		float _FlashSpeed;
		float _GlowSpeed;

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
			half4 landData = tex2D(_LandTex, IN.uv_MainTex);
			half4 dataD = tex2D(_MainTex, IN.uv_MainTex + noiseD * 0.02);
			half4 occl = tex2D(_OcclusionMap, IN.uv_MainTex);

			
			half4 noise1 = tex2D(_NoiseTex, IN.uv_MainTex * 31.0);
			half4 noise2 = tex2D(_NoiseTex, IN.uv_MainTex * 16.0);
			half4 noise3 = tex2D(_NoiseTex, IN.uv_MainTex * 5.0 + float2(0.3, 0.2));
			half4 noise4 = tex2D(_NoiseTex, IN.uv_MainTex * 9.0 + float2(0.2, 0.5));

			half4 noise = (noise1 + noise2) / 2.0;
			c = lerp(c, _WaterColor, (1.0 - data.x) * 5 - 5);
			c = tex2D(_LandTex, IN.uv_MainTex);

			//noise
			c = c + half4(noise3.x * 0.4, noise3.x * 0.3, -noise3.x * 0.7, 0.0) * 0.2;

			half water = scale(data.y, 0.06, 0.07); 
			half shore = scale(dataD.x, 0.02, 0.05);
			half4 cBefore = c;

			// ----------------------- Pulsing and flashing effect -------------------------------------------
			_DeltaTime = _DeltaTime * _GlowSpeed;
			_DeltaTimeFast = _DeltaTimeFast * _FlashSpeed;

			float deltaRand = _DeltaTime % 1;
			float deltaFastRand = _DeltaTimeFast % 1;

			_GlowColor = _GlowColor * (1 - deltaRand) + _GlowColor2 * (deltaRand);
			_BurningColor = _BurningColor * (1 - deltaRand) + _GlowColor * (deltaRand);
			_BurningColor = _BurningColor * (1 - deltaFastRand) + _FlashColor * (deltaFastRand);

			//Realistlikum variant!
			if (burningData.r < (1.0)) {
				//Põlenud osa
				c = lerp( c, _BurntColor * 0.6, 0.99 - burningData.r );
				if (landData.r < 0.15) {
					c = lerp(c, _BurntColor * 0.6, 1.1 - burningData.r);
				}

				//Hetkel põlev osa
				c = lerp( c  , _BurningColor * (1 + landData.r) * 25, burningData.r);
				if (landData.r > 0.15) {
					c = lerp(c, _BurningColor * (1 + landData.r) * 30, burningData.r );
				}

				// for glow multiplier:
				c = c * 5;

				//GlowAlasisene
				if (burningData.r > 0.3) {
					c = lerp(c, (_BurningColor * _GlowIntensity + _GlowColor * _GlowColorIntensity + cBefore) * 5,burningData.r - 0.3);
					if (landData.r < 0.2) {
					}
				}

				//Glowväline
				if (burningData.r > 0.6) {
					c = lerp(cBefore, (_BurningColor * _GlowIntensity + _GlowColor * _GlowColorIntensity + cBefore) * 5, 1 - burningData.r );
					if (landData.r < 0.2) {
					}
				}
			}
			
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness + data.a * 0.5;
			o.Occlusion = occl.x;
			o.Alpha = c.a;
			
		}
		ENDCG
	}
	FallBack "Diffuse"
}
