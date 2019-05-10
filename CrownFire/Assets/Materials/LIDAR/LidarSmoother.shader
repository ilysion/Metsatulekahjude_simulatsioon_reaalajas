Shader "LIDAR/Smoother1" 
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

		_GivenCoils("givenCoilsCount", Float) = 2
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
			float _GivenCoils;
			

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
					//raadius, milles pointe samplida
					float radius = _GivenSampleRadius;

					//Hetke suurim värvide summa:
					float colSumMax = 255*3;
					float4 currentMaxCol;
					float4 totalSummedCol;
					float sampledPoints = 0;

					float coils = _GivenCoils;
					//*****************************************************************************************
					//https://stackoverflow.com/questions/13894715/draw-equidistant-points-on-a-spiral
					//*****************************************************************************************
					// value of theta corresponding to end of last coil
					float thetaMax = coils * 2 * myPi;

					// How far to step away from center for each side.
					float awayStep = radius / thetaMax;

					// distance between points to plot
					float chord = 0.001;

					float rotation = 1;
					// For every side, step around and away from center.
					// start at the angle corresponding to a distance of chord
					// away from centre.
					for (float theta = chord / awayStep; theta <= thetaMax; ) {
						//
						// How far away from center
						float away = awayStep * theta;
						//
						// How far around the center.
						float around = theta + rotation;
						//
						// Convert 'around' and 'away' to X and Y.
						float x = myX + cos(around) * away;
						float y = myY + sin(around) * away;
						//
						// Now that you know it, do it.
						float4 samplePointColor = tex2Dlod(_LidarMap, float4(float2(x, y), 0, 0));
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
						// to a first approximation, the points are on a circle
						// so the angle between them is chord/radius
						theta += chord / away;

					}
					float4 midCol = totalSummedCol / (sampledPoints);
					col = midCol;

					//col = currentMaxCol;
					//col = (midCol + currentMaxCol) / 2;
					
					/**/
					//------------------ RGB to Greyscale conversion --------------------------------
					float closest = 1;
					float currentDifference = 1000;
					
					for (int i = 1; i <= 255; i++)
					{
						float greyAmmount = (float(i)/255);
						if (greyAmmount > 0 && greyAmmount < 1) {
							float4 spectrumCol = tex2D(_HeightScale, float2(greyAmmount, 0.5));
							float diff = abs(col.r - spectrumCol.r) + abs(col.g - spectrumCol.g) + abs(col.b - spectrumCol.b);
							if (diff < currentDifference) {
								currentDifference = diff;
								closest = greyAmmount;
							}
						}

					}
					closest = 1 - closest;
					//float4 skaalaCol = tex2D(_HeightScale, float2(0.9, 0.5));
					col = float4(closest, closest, closest, 1);
					


					//------------------ RGB to Greyscale conversion END --------------------------------
					//col = skaalaCol;
					return col;
				}
				ENDCG
		}
	}
}