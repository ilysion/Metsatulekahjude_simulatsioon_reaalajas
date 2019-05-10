Shader "JJ/CircleBurnAdvanced" 
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_BurningTex("BuringTex (RGB)", 2D) = "white" {}
		_NoiseTex("Noise (RGB)", 2D) = "gray" {}
		_FrequentNoiseTex("FreqNoise (RGB)", 2D) = "gray" {}
		_TexScale("Texture scale", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
		_WaterColor("Water Col", Color) = (1,1,1,1)
		_ShoreColor("Shore Col", Color) = (1,1,1,1)
		_MountainColor("Mountain Col", Color) = (1,1,1,1)
		_BurntColor("BurntColor", Color) = (1,1,1,1)
		_BurningColor("BurningColor", Color) = (1,1,1,1)


		_Delta("delta", Float) = 0.0
		_GivenSampleRadius("givenSampleRadius", Float) = 0.001
		_GivenSampleCount("givenSampleCount", Float) = 10.0
		_GivenColorBurnaway("givenColorBurnaway", Float) = 0.01
	    _RandomSeed("randomSeed", Float) = 0.01
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				// make fog work
				#pragma multi_compile_fog

				#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _NormalTex;
			sampler2D _BurningTex;
			sampler2D _NoiseTex;
			sampler2D _FrequentNoiseTex;

			uniform float4 _MainTex_TexelSize;
			uniform float4 _BurningTex_TexelSize;
			uniform half _TexScale;

			uniform fixed4 _Color;
			uniform fixed4 _WaterColor;
			uniform fixed4 _ShoreColor;
			uniform fixed4 _MountainColor;
			uniform fixed4 _BurntColor;
			uniform fixed4 _BurningColor;

			float _Delta;
			float _GivenSampleRadius;
			float _GivenSampleCount;
			float _GivenColorBurnaway;
			float _RandomSeed;

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					UNITY_FOG_COORDS(1)
					float4 vertex : SV_POSITION;
				};



				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					UNITY_TRANSFER_FOG(o,o.vertex);
					return o;
				}

				float2 calculatePointAt(float x, float y, float vahe, float radius)
				{
					float2 a = (radius * cos(1 * vahe) + x, radius * sin(1 * vahe) + y);
					return a;

				}

				float randomFrac(float2 uv)
				{
					return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453123);
				}


				fixed4 frag(v2f i) : SV_Target
				{

					// sample the texture
					fixed4 col = tex2D(_BurningTex, i.uv);
					half4 data = tex2D(_MainTex, i.uv);
					half4 burningData = tex2D(_BurningTex, i.uv);

					half4 noiseD1 = tex2D(_FrequentNoiseTex, i.uv * 0.21 + float2(0.3, 0.3));
					half4 noiseD2 = tex2D(_NoiseTex, i.uv * 0.271 + float2(0.3, 0.3));
					half2 noiseD = half2(noiseD1.x - 0.5 , noiseD2.x - 0.5);

					//CurrentPosition
					float myX = i.uv.x;
					float myY = i.uv.y;

					float4 mapPosCol = tex2Dlod(_MainTex, float4(float2(myX, myY), 0, 0));
					float4 currentPosColor = tex2Dlod(_BurningTex, float4(float2(myX, myY), 0, 0));

					float myPi = 3.14159;
					//Samplimiste arv ümber texli
					float pointCount = _GivenSampleCount;
					//vahemik kahe pointi vahel rad-ides
					float vahemik = (2.0 * myPi) / (pointCount - 1);
					//raadius, milles pointe samplida
					float radius = _GivenSampleRadius;
					//vahendaja kui palju iga matchinud point texeli värvi vähendab
					float vahendaja = _GivenColorBurnaway;

					//So called igintion point for color to affect nearby pixels
					//Basicly texel has to have atleast that ammount of "heat" to affect nearby pixels,
					//Otherwise it will be ignored / looked as there's no fire at that texel.
					float ignitionPoint = 0.5;

					float smallRandomSeed = _RandomSeed * 0.00000005;
					half4 noiseD5 = tex2D(_NoiseTex, (i.uv + smallRandomSeed) * noiseD.x + float2(0.1252, 0.1849));

					float randomNumber1 = _Time.y * 0.001 + (_Time.y * 0.0005);

					half4 noiseStronger = tex2D(_NoiseTex, float2(i.uv.x, i.uv.y) * noiseD.x + float2(0.3123, 0.3312));
					float4 randomFromNoise = tex2Dlod(_NoiseTex, float4(float2(myX + randomNumber1, myY + randomNumber1), 0, 0));
					float4 noiseStrongerColor = tex2Dlod(_FrequentNoiseTex, float4(float2(myX + smallRandomSeed + randomFromNoise.x * 0.1 , myY + smallRandomSeed + randomFromNoise.y * 0.1), 0, 0));

					if (col.r > ignitionPoint) 
					{
						for (int i = 1; i <= pointCount; i++)
						{
							//generating points
							float2 samplePointCoords = float2(radius * cos(i * vahemik) + myX, radius * sin(i * vahemik) + myY);
							//getting color for the point
							float4 samplePointColor = tex2Dlod(_BurningTex, float4(samplePointCoords, 0, 0));

							//mapPosCol less eq than 6 is water
							if (mapPosCol.g > 0.06) {
								//less/eq than 0.05 is shore, mainTex red value
								if (mapPosCol.r > 0.04) {
									//Removing color from the texel
									if (samplePointColor.r < ignitionPoint) {
										//Adding some noise from here--------------
										if (noiseStrongerColor.x > 0.45) {
											col.r -= vahendaja;
										}

										/*
										if (noiseD5.x > 0.25) {
											col.r -= vahendaja;
										}
										*/

										
									}
									//also remove very little without noise,
										//so there wont stay any holes
								}
							}
						}
					}
					//if the current point has ignited, remove a bit every render
					if (currentPosColor.r >= 0.0 & currentPosColor.r <= ignitionPoint) {
						//Add some noise
						half4 noiseD3 = tex2D(_NoiseTex, i.uv * noiseD.x + float2(0.1, 0.1));
						col.r -= 0.005;
						/*
						if (noiseD3.x > 0.05) {
							col.r = (currentPosColor.r - 0.005);
						}
						*/
					}
					

					// apply fog
					//UNITY_APPLY_FOG(i.fogCoord, col);

					return col;
				}
				ENDCG
		}
	}
}