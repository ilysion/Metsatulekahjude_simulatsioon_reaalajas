Shader "JJ/MoveBurnArea" {
	Properties {
		_MainTex("Main (RGB)", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_BurningTex("BuringTex (RGB)", 2D) = "white" {}
		_NoiseTex("Noise (RGB)", 2D) = "gray" {}
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
		sampler2D _NormalTex;
		sampler2D _BurningTex;
		sampler2D _NoiseTex;
		float4 _MainTex_TexelSize;
		float4 _BurningTex_TexelSize;
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
			float3 worldPos;
		};


		float scale(float v, float min, float max) {
			float ab = max - min;
			return saturate((v - min) / ab);
		}

		/*
		void fragment()
		{

			vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
			for (int y = -1; y <= 1; y++)
				for (int x = -1; x <= 1; x++)
				{
					vec2 pixel_off = vec2(float(x), float(y));
					vec4 tex = texture(TEXTURE, UV + pixel_off * pixel_size);
					if (tex.rgba == vec4(1.0, 0.0, 0.0, 1.0))
					{
						COLOR = vec4(0.0, 1.0, 0.0, 1.0);
						break;
					}
				}
		}
		*/

		void surf(Input IN, inout SurfaceOutputStandard o) {



			half4 c = _Color;
			half4 data = tex2D(_MainTex, IN.uv_MainTex);
			half4 burningData = tex2D(_BurningTex, IN.uv_MainTex);
			//noise
			//c = c + half4(1, 1, 1, 0.0);
			//end noise
			
			half4 noiseD1 = tex2D(_NoiseTex, IN.uv_MainTex * 0.7 + float2(0.1, 0.1));
			half4 noiseD2 = tex2D(_NoiseTex, IN.uv_MainTex * 0.7 + float2(0.3, 0.3));
			half2 noiseD = half2(noiseD1.x - 0.5, noiseD2.x - 0.5);
			
			//if (IN.uv_MainTex.x < 0.5) { - pool ekraani ühel pool
			//abgr
			float4 white = (1.0, 0, 0, 1.0);
			float4 black = (1.0, 0.0, 0.0, 0.0);
			float4 grey = (1.0, 0.0, 0.0, 0.1);
			
			float texSize = 1024;
			//CurrentPosition
			float myX = IN.uv_MainTex.x;
			float myY = IN.uv_MainTex.y;

			//Texel sizes for burning texture
			float burnTexelSizeX = _BurningTex_TexelSize.x;
			float burnTexelSizeY = _BurningTex_TexelSize.y;

			//Data for texel at position
			float4 currentPosColor = tex2Dlod(_BurningTex, float4(float2(myX, myY), 0, 0));
			//z-neg
			float4 myPixelData2 = tex2Dlod(_BurningTex, float4(float2(myX, myY + burnTexelSizeY), 0, 0));
			//z-pos
			float4 myPixelData3 = tex2Dlod(_BurningTex, float4(float2(myX, myY - burnTexelSizeY), 0, 0));
			//x-neg
			float4 myPixelData4 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY), 0, 0));
			//x-neg
			float4 myPixelData5 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY), 0, 0));

			//Diagonals
			float4 diagonally1 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY + burnTexelSizeY), 0, 0));
			float4 diagonally2 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY - burnTexelSizeY), 0, 0));
			float4 diagonally3 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY + burnTexelSizeY), 0, 0));
			float4 diagonally4 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY - burnTexelSizeY), 0, 0));
			
			//Not sure where the texture gets beige-ish color???
			//c = white;
			float4 mapPosCol = tex2Dlod(_MainTex, float4(float2(myX, myY), 0, 0));
			//less/eq than 0.07 is water, mainTex green value
			if (mapPosCol.g > 0.06) {

				//less/eq than 0.05 is shore, mainTex red value
				if (mapPosCol.r > 0.04) {

					if (myPixelData2.r < 0.8) {
						if (noiseD1.x > 0.2) {
							c = black;
						}
					}
					if (myPixelData3.r < 0.8) {
						if (noiseD1.x > 0.2) {
							c = black;
						}
					}
					if (myPixelData4.r < 0.8) {
						if (noiseD1.x > 0.2) {
							c = black;
						}
					}
					if (myPixelData5.r < 0.8) {
						if (noiseD1.x > 0.2) {
							c = black;
						}
					}


					if (diagonally1.r < 0.8) {
						if (noiseD1.x > 0.7) {
							c = (currentPosColor - grey);
						}
					}
					if (diagonally2.r < 0.8) {
						if (noiseD1.x > 0.6) {
							c = (currentPosColor - grey);
						}
					}
					if (diagonally3.r < 0.8) {
						if (noiseD2.x > 0.6) {
							c = (currentPosColor - grey);
						}
					}
					if (diagonally4.r < 0.8) {
						if (noiseD2.x > 0.7) {
							c = (currentPosColor - grey);
						}
					}

					/**
					if (currentPosColor.r >= 0.01 & currentPosColor.r < 0.8) {
						if (currentPosColor.r < 0.1) {
							//c.r = 0.001;
						}
						else {
							c.r = (currentPosColor.r - grey.r);
						}
					}
					*/
				}
			}

		


			

			/*
			if (data.x < 0.9) {
				c = (1, 1, 1, 1);
			}
			if (data.x >= 0.9) {
				c = (0, 0, 0, 0);
			}
			*/

			//c = (1, 1, 1, 1);
			//c = (0, 0, 0, 0);

			/*
			CurrentWorkingSolution
			half towat = scale(dataD.x, (2.0 - _Delta), 0.1);
			c = lerp(half4(0, 0, 0, 1), c, towat);
			*/

			/*
			if (tex2D(_MainTex, IN.uv_MainTex).x < 0.5) {
				c = (0, 0, 0, 0);
			}
			*/


			/*
			half4 colorHere = tex2D(_MainTex, IN.uv_MainTex);
			if (colorHere.x < 0.1) {
				c = (0, 0, 0, 0);
			}
			*/

			//data.y - heightmap pmst?
			
			/*
			//Fore movement when pressing T ---------------------------------------
			if (burningData.x < (0.90 + _Delta)) {
			    //c = _BurningColor;
				//c = lerp(_BurningColor, c, water);
				c = (1,1,1,1);
			}
			*/

			/*
			//Working example with burningdataTexture
			if (burningData.x < (0.5)) {
				c = (1, 1, 1, 1);
			}
			*/

	
			o.Albedo = c;
			//o.Metallic = _Metallic;
			//o.Smoothness = _Glossiness + data.a * 0.5;
			//o.Occlusion = occl.x;
			//o.Alpha = c.a;
			

			/*
			float3 normal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex * _TexScale * 0.5));
			o.Normal += normal;
			*/
			
		}
		ENDCG
	}
}
