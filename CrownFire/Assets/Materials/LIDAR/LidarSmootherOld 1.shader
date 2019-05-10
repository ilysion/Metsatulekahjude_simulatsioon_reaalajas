Shader "LIDAR/SmootherOld" 
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_LidarMap("LidarMap (RGB)", 2D) = "white" {}
		_Noise("Noise (RGB)", 2D) = "white" {}
		_HeightScale("Skaalariba (RGB)", 2D) = "white" {}


		_TexScale("Texture scale", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
		_BurntColor("BurntColor", Color) = (1,1,1,1)
		_BurningColor("BurningColor", Color) = (1,1,1,1)


		_Delta("delta", Float) = 0.0
		_GivenSampleRadius("givenSampleRadius", Float) = 0.001
		_GivenSampleCount("givenSampleCount", Float) = 10.0
		_NoiseAmmount("noiseAmmount", Float) = 1.0
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
			sampler2D _LidarMap;
			sampler2D _Noise;
			sampler2D _HeightScale;

			uniform float4 _MainTex_TexelSize;
			uniform half _TexScale;

			uniform fixed4 _Color;
			uniform fixed4 _BurntColor;
			uniform fixed4 _BurningColor;

			float _Delta;
			float _GivenSampleRadius;
			float _GivenSampleCount;
			float _NoiseAmmount;
			

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

				//Finds the sum of red, green and blue.
				float calculateColorSum(float4 col)
				{
					return col.r + col.g + col.b;
				}


				fixed4 frag(v2f i) : SV_Target
				{

					//CurrentPosition
					float myX = i.uv.x;
					float myY = i.uv.y;

					// sample the texture
					fixed4 col = tex2D(_LidarMap, i.uv);

					float myPi = 3.14159;
					float quarter = myPi / 2;
					//Samplimiste arv ümber texli
					float pointCount = _GivenSampleCount;
					//vahemik kahe pointi vahel rad-ides
					float vahemik = (2.0 * myPi) / (pointCount - 1);
					//raadius, milles pointe samplida
					float radius = _GivenSampleRadius;

					//Hetke suurim värvide summa:
					float colSumMax = 255*3;
					float4 currentMaxCol;
					float4 totalSummedCol;
					float sampledPoints = 0;

					for (int i = 1; i <= pointCount; i++)
					{
						//generating points
						float2 samplePointCoords = float2(radius * cos(i * vahemik) + myX, radius * sin(i * vahemik) + myY);
						//float2 samplePointCoords = float2(radius * cos(i * vahemik) * i/pointCount + myX, radius * sin(i * vahemik) * i / pointCount + myY);
						
						float4 coordsNoise = tex2D(_Noise, float2(myX , myY ));
						radius = radius - coordsNoise.z * _NoiseAmmount * 0.1;
						//float2 noisyCoords = float2(samplePointCoords.x + coordsNoise.x * _NoiseAmmount, samplePointCoords.y + coordsNoise.y * _NoiseAmmount);
						float2 noisyCoords = float2(radius * cos(i * vahemik )  + myX, radius * sin(i * vahemik )  + myY);
						//float2 noisyCoords = float2(radius * cos(i * vahemik ) * i / pointCount + myX, radius * sin(i * vahemik ) * i / pointCount + myY);

						//getting color for the point
						float4 samplePointColor = tex2Dlod(_LidarMap, float4(noisyCoords, 0, 0));
						//LIDAR color range artifact filtering,
						//At least one of red green or blue has to be ~0 or this is just sampling error.
						if (samplePointColor.r < 0.02 || samplePointColor.g < 0.02 || samplePointColor.b < 0.02)
						{
							totalSummedCol += samplePointColor;

							float currentSum = calculateColorSum(samplePointColor);
							if (currentSum < colSumMax) {
								colSumMax = currentSum;
								currentMaxCol = samplePointColor;
							}
							sampledPoints += 1;
						}
					}
					float4 midCol = totalSummedCol / (sampledPoints);
					//col = midCol;
					col = currentMaxCol;
					//col = (midCol + currentMaxCol) / 2;
					//col = float4(1, 1, 1, 1);

					/*
					//------------------ RGB to Greyscale conversion --------------------------------
					float closest = 1;
					float currentDifference = 1000;
					
					for (int i = 1; i <= 255; i++)
					{
						float koht = (float(i)/255);
						if (koht > 0 && koht < 1) {
							float4 skaalaCol = tex2D(_HeightScale, float2(koht, 0.5));
							float diff = abs(col.r - skaalaCol.r) + abs(col.g - skaalaCol.g) + abs(col.b - skaalaCol.b);
							if (diff < currentDifference) {
								currentDifference = diff;
								closest = koht;
							}
						}

					}
					closest = 1 - closest;
					//float4 skaalaCol = tex2D(_HeightScale, float2(0.9, 0.5));
					col = float4(closest, closest, closest, 1);
					*/
					//------------------ RGB to Greyscale conversion END --------------------------------
					//col = skaalaCol;
					return col;
				}
				ENDCG
		}
	}
}