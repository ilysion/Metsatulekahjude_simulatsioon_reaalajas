Shader "FinalCrownFire/AdvancedBurn1"
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_BurningTex("BuringTex (RGB)", 2D) = "white" {}
		_NoiseTex("Noise (RGB)", 2D) = "gray" {}
		_HumidityTex("HumidityTex (RGB)", 2D) = "white" {}
		_TemperatureTex("TemperatureTex (RGB)", 2D) = "white" {}
		_WindspeedTex("WindspeedTex (RGB)", 2D) = "white" {}
		_HeightTex("HeightTex (RGBA)", 2D) = "white" {}


		_TexScale("Texture scale", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
		_BurntColor("BurntColor", Color) = (1,1,1,1)
		_BurningColor("BurningColor", Color) = (1,1,1,1)


		_Delta("delta", Float) = 0.0
		_GivenSampleRadius("givenSampleRadius", Float) = 0.001
		_GivenSampleCount("givenSampleCount", Float) = 10.0
		_GivenColorBurnaway("givenColorBurnaway", Float) = 0.01
		_BurnAmmount("burnAmmount", Float) = 0.01
		_WindStrength("WindStrength m/s", Float) = 0
		_WindDirection("WindDirection 0-1", Range(0, 1)) = 0.01
		_WindDirectionVector("WindDirectionVector", Vector) = (0, 0, 0, 0)

		_DisableBurnTopography("BurnTopography 0/1", Range(0, 1)) = 0
		_DisableWinds("DisableWinds 0/1", Range(0, 1)) = 0
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
			sampler2D _HumidityTex;
			sampler2D _TemperatureTex;
			sampler2D _WindspeedTex;
			sampler2D _HeightTex;

			uniform float4 _MainTex_TexelSize;
			uniform float4 _BurningTex_TexelSize;
			uniform half _TexScale;

			uniform fixed4 _Color;
			uniform fixed4 _BurntColor;
			uniform fixed4 _BurningColor;

			float _Delta;
			float _GivenSampleRadius;
			float _GivenSampleCount;
			float _GivenColorBurnaway;
			float _BurnAmmount;
			float _WindDirection;
			float _WindStrength;
			float _DisableBurnTopography;
			float _DisableWinds;
			float4 _WindDirectionVector;


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


				fixed4 frag(v2f i) : SV_Target
				{

					// sample the texture
					fixed4 col = tex2D(_BurningTex, i.uv);
					half4 data = tex2D(_MainTex, i.uv);
					half4 burningData = tex2D(_BurningTex, i.uv);

					half4 noiseD1 = tex2D(_NoiseTex, i.uv * 0.21 + float2(0.1, 0.1));
					half4 noiseD2 = tex2D(_NoiseTex, i.uv * 0.271 + float2(0.3, 0.3));
					half2 noiseD = half2(noiseD1.x - 0.5 , noiseD2.x - 0.5);


					float4 white = (1.0, 0, 0, 0.0);
					float4 black = (1.0, 0.0, 0.0, 0.5);
					float4 grey = (1.0, 0.0, 0.0, 0.9);

					//CurrentPosition
					float myX = i.uv.x;
					float myY = i.uv.y;

					float4 mapPosCol = tex2Dlod(_MainTex, float4(float2(myX, myY), 0, 0));
					float4 currentPosColor = tex2Dlod(_BurningTex, float4(float2(myX, myY), 0, 0));
					/*
					def circle_points(r, n):
					circles = []
					for r, n in zip(r, n):
						t = np.linspace(0, two_pi, n)
						x = r * np.cos(t)
						y = r * np.sin(t)
						circles.append(np.c_[x, y])
					return circles
					-------------------------------------
					np.linspace paneb punktid vahemikku, pmst:
					two_pi - 0 / n-1 = iga punkti vahe, esimene on null jne

					r - 0.1
					n = 10
					*/
					//_BurnAmmount

					float myPi = 3.14159;
					float quarter = myPi * 0.5;
					//Samplimiste arv ümber texli
					float pointCount = _GivenSampleCount;
					//vahemik kahe pointi vahel rad-ides
					float vahemik = (2.0 * myPi) / (pointCount - 1);
					//raadius, milles pointe samplida
					float radius = _GivenSampleRadius;
					//vahendaja kui palju iga matchinud point texeli värvi vähendab

					//Ajaliselt oleks enam vähem aga aeg kõigub ikkagi palju
					//float vahendaja = _GivenColorBurnaway * _BurnAmmount*0.865;

					//Frame'de kaudu paika
					// 717 1x, 354 2x, 237 3x, 180 4x, 146 5x, 107 7x, 80 10x
					//X = (If(t < 0.499199965242, 0.37589317271t³ + 0t² + 1.7092119347483t + 0.1, t < 0.7569668592458, 26.249821092712t³ - 38.7487917550147t² + 21.05260743202t - 3.1187407866332, t < 0.840051470003, 404.1345275921514t³ - 896.8873900627615t² + 670.6350869906601t - 167.0228772441761, t < 0.8805333381499, 263.1898935376626t³ - 541.6851489832219t² + 372.2469222234203t - 83.4690717627706, t < 0.9046871425485, 12349.8176538561493t³ - 32469.7212152898974t² + 28485.9471002599093t - 8335.1524936003862, t < 0.9324173927025, -21418.9104668174987t³ + 59180.6812376778325t² - 54428.9936083350331t + 16668.8744344784027, t < 0.9517080509176, 272506.1822874692734t³ - 763001.9246696939226t² + 712188.3681171583012t - 221600.2461057046021, -103792.7193488316552t³ + 311378.1580464949948t² - 310307.8063493899535t + 102772.367651726614), If(t < 0.499199965242, 0.1613505305678t³ + 0t² - 1408.2935118311932t + 1420, t < 0.7569668592458, -2.084682197521t³ + 3.3636583793828t² - 1409.9726499772669t + 1420.2794085680521, t < 0.840051470003, 54.2797548941066t³ - 124.6343743758439t² - 1313.0823811328971t + 1395.8318344018501, t < 0.8805333381499, -587.333233088276t³ + 1492.3294268070772t² - 2671.4151992583056t + 1776.1883279417186, t < 0.9046871425485, 5577.6321790212596t³ - 14793.0432949039914t² + 11668.3984064058095t - 2432.7063196060399, t < 0.9324173927025, -17434.0707179621895t³ + 47662.1319222366365t² - 44833.9955981547173t + 14606.290140105677, t < 0.9517080509176, 121823.1348288122827t³ - 341875.3896106393077t² + 318377.5645893208566t - 98281.9685096979811, -41033.6513375865834t³ + 123100.9540127597575t² - 124144.1651233113225t + 42101.8624481381412))
					//y = 37.74869 + (1466.494 - 37.74869)/(1 + (x/0.9240277)^1.534914)
					//x multiplier
					//Valemisse: (37.74869 + (1466.494 - 37.74869)/(1 + (x/0.9240277)^1.534914)) * 0.0014107

					float vahendaja = _GivenColorBurnaway * (1 / ((37.74869 + (1466.494 - 37.74869) / (1 + pow((_BurnAmmount / 0.9240277), 1.534914))) * 0.0014107));
					//Add delta time and other multipliers:

					/*
					TemperatureTex logic:
					Temperature tex red color manages fire speed,
					100 in red channel is 0 degrees.
					y = 482299.4 + (0.6207151 - 482299.4)/(1 + pow((x/456.8377), 10.97225))
					for x 80 to 150 means -20 to 50 degrees
					*/
					float4 TemperatureTexCol = tex2Dlod(_TemperatureTex, float4(float2(myX, myY), 0, 0)) * 255;
					float tempMuutuja = 482299.4 + (0.6207151 - 482299.4) / (1 + pow((TemperatureTexCol.r / 456.8377), 10.97225));

					/*
					HumidityTex logic:
					Humidity tex red color manages fire speed,
					0-1 in channel is moisture content from 0 to 1
					y = -0.05451366 + 1.55724366/(1 + pow((x/0.1674447),1.337622))
					*/
					float4 HumidityTexCol = tex2Dlod(_HumidityTex, float4(float2(myX, myY), 0, 0));
					float niiskusMuutuja = -0.05451366 + 1.55724366 / (1 + pow((HumidityTexCol.r / 0.1674447), 1.337622));
					//vahendaja = vahendaja * ((_Delta + tempMuutuja + niiskusMuutuja) / 3);
					//float konstantsedMultiplierid = ((_Delta + tempMuutuja + niiskusMuutuja) / 3);

					/*
					WindSpeed & direction logic:
					_WindDirection * pi
					*/
					float tuuleTugevus = length(_WindDirectionVector);
					float tuuleKordajaConst = 50749390 + (1.175058 - 50749390) / (1 + pow((_WindStrength / 106128.2), 1.769543));
					
					/*
					Topography logic:
					*/
					float korgusKordaja;

					/*
					TextureHeight flame movement logic:
					r - up
					g - right
					b - down
					a - left
					0 - 0.5 is downhill
					0.5 - 1 is uphill
					for %, downhill * 2, for uphill (number - 0.5) * 2
					*/
					float4 HeightTexCol = tex2Dlod(_HeightTex, float4(float2(myX, myY), 0, 0));
					
					//Edaspidi loogika allpool******************************************************

					//So called igintion point for color to affect nearby pixels
					//Basicly texel has to have atleast that ammount of "heat" to affect nearby pixels,
					//Otherwise it will be ignored / looked as there's no fire at that texel.
					float ignitionPoint = 0.5;

					half4 noiseD5 = tex2D(_NoiseTex, i.uv * noiseD.x + float2(0.1252, 0.849));
					half4 noiseStronger = tex2D(_NoiseTex, i.uv * noiseD.x + float2(0.3123, 0.3312));


					if (col.r > ignitionPoint)
					{
						for (int i = 1; i <= pointCount; i++)
						{

							//generating points
							float2 offset = float2(radius * cos(i * vahemik), radius * sin(i * vahemik));
							float2 samplePointCoords = offset + float2(myX, myY);
							
							
							//getting color for the point
							float4 samplePointColor = tex2Dlod(_BurningTex, float4(samplePointCoords, 0, 0));

							//**************************************************

							//Getting right multiplied values for every direction 
							float hcr = HeightTexCol.r;
							float hcg = HeightTexCol.g;
							float hcb = HeightTexCol.b;
							float hca = HeightTexCol.a;


							if (hcr > 0.5) { hcr = 1.0 - (hcr - 0.5)*0.5; }
							else { hcr = hcr * 0.5 + 1.0; }

							if (hcg > 0.5) { hcg = 1.0 - (hcg - 0.5)*0.5; }
							else { hcg = hcg * 0.5 + 1.0; }

							if (hcb > 0.5) { hcb = 1.0 - (hcb - 0.5)*0.5; }
							else { hcb = hcb * 0.5 + 1.0; }

							if (hca > 0.5) { hca = 1.0 - (hca - 0.5)*0.5; }
							else { hca = hca * 0.5 + 1.0; }


							float tuuleKordaja = 1;
							
							float tuuleSuunaMuutuja = dot(normalize(offset), normalize(_WindDirectionVector.xy));
							tuuleSuunaMuutuja = pow(saturate(tuuleSuunaMuutuja), 20);
							tuuleKordaja = max((tuuleKordajaConst - 1.17) * (tuuleSuunaMuutuja), 1 ) ;
							//tuuleKordaja = tuuleKordajaConst * (saturate(tuuleSuunaMuutuja) + 1);


							/*
							if (float(i * vahemik) < quarter)
							{

								//paremale ja alla
								korgusKordaja = ((i * vahemik) / myPi) * hcg + ((myPi - (i * vahemik)) / myPi) * hcb;

								if (0.75 < _WindDirection) {
									if (_WindDirection <= 1.0) {
										tuuleKordaja = tuuleKordajaConst * (1 - float((i * vahemik) / (quarter)));
									}
								}
								if (0.0 <= _WindDirection) {
									if (_WindDirection <= 0.25) {
										tuuleKordaja = tuuleKordajaConst * ( float((i * vahemik) / (quarter)));
									}
								}
							}

							if (quarter <= float(i * vahemik))
							{
								if (float(i * vahemik) < float(quarter * 2))
								{
									//alla ja vasakule
									korgusKordaja = (((i * vahemik) - myPi) / myPi) * hcb + ((2 * myPi - (i * vahemik)) / myPi) * hca;

									if (0.0 <= _WindDirection) {
										if (_WindDirection <= 0.25) {
											tuuleKordaja = tuuleKordajaConst * (1 - float((i * vahemik - quarter) / quarter));
										}
									}
									if (0.25 < _WindDirection) {
										if (_WindDirection <= 0.5) {
											tuuleKordaja = tuuleKordajaConst * ( float((i * vahemik - quarter) / quarter));
										}
									}
								}
							}

							if (float(2 * quarter) <= float(i * vahemik))
							{
								if (float(i * vahemik) < float(quarter * 3))
								{
									//vasakule ja ules
									korgusKordaja = (((i * vahemik) - 2 * myPi) / myPi) * hca + ((3 * myPi - (i * vahemik)) / myPi) * hcr;

									if (0.25 < _WindDirection) {
										if (_WindDirection <= 0.5) {
											tuuleKordaja = tuuleKordajaConst * (1 - float((i * vahemik - 2 * quarter) / (quarter)));
										}
									}
									if (0.5 < _WindDirection) {
										if (_WindDirection <= 0.75) {
											tuuleKordaja = tuuleKordajaConst * ( float((i * vahemik - 2 * quarter) / (quarter)));
										}
									}
								}
							}

							if (float(3 * quarter) <= float(i * vahemik))
							{
								//ules ja paremale
								korgusKordaja = (((i * vahemik) - 3 * myPi) / myPi) * hcr + ((4 * myPi - (i * vahemik)) / myPi) * hcg;

								if (0.5 < _WindDirection) {
									if (_WindDirection <= 0.75) {
										tuuleKordaja = tuuleKordajaConst * (1 - float((i * vahemik - 3 * quarter) / (quarter)));
									}
								}
								if (0.75 < _WindDirection) {
									if (_WindDirection <= 1.0) {
										tuuleKordaja = tuuleKordajaConst * ( float((i * vahemik - 3 * quarter) / (quarter)));
									}
								}

							}
							*/
							//**************************************************

							if (_DisableBurnTopography == 0) {
								korgusKordaja = 1;
							}
							else {
								//korgusKordaja = 97.41277 + (1.485698 - 97.41277) / (1 + pow((tousuProtsent / 150.3879), 2.566629))
								korgusKordaja = 1 + korgusKordaja;
							}

							if (_DisableWinds == 0) {
								tuuleKordaja = 1;
							}

							float loplikVahendaja = vahendaja * _Delta * tempMuutuja * niiskusMuutuja * tuuleKordaja * korgusKordaja;
							/*
							loplikVahendaja += vahendaja * _Delta;
							loplikVahendaja += vahendaja * tempMuutuja;
							loplikVahendaja += vahendaja * niiskusMuutuja;
							loplikVahendaja += vahendaja * korgusKordaja;
							*/

							if (samplePointColor.r < ignitionPoint) {
								//Adding some noise from here--------------
								//vahendaja = vahendaja + (vahendaja * (korgusKordaja));
								//vahendaja = vahendaja * ( tuuleKordaja );
								col.r -= loplikVahendaja;
								//col.g = abs(korgusKordaja);
							}
							/*
							Default generationiga kasutada seda, lidari versioonis on greyscale, see ei sobi siin
							//mapPosCol less eq than 0.06 is water
							if (mapPosCol.g > 0.07) {
								//less/eq than 0.05 is shore, mainTex red value
								if (mapPosCol.r > 0.04) {
									//Removing color from the texel
									if (samplePointColor.r < ignitionPoint) {
										//Adding some noise from here--------------

										korgusKordaja = abs(korgusKordaja);
										//vahendaja = vahendaja + (vahendaja * (korgusKordaja));
										col.r -= vahendaja;
										//col.g = abs(korgusKordaja);
									}
								}
							}
							*/
						}
					}


					//if the current point has ignited, remove a bit every render
					if (currentPosColor.r >= 0.0 & currentPosColor.r <= 0.5) {
						//Add some noise
						/*
						half4 noiseD3 = tex2D(_NoiseTex, i.uv * noiseD.x + float2(0.1, 0.1));
						if (noiseD3.x > 0.05) {
							col.r = (currentPosColor.r - 0.005);
						}
						*/
						col.r = (currentPosColor.r - 0.005);

					}



					// apply fog
					//UNITY_APPLY_FOG(i.fogCoord, col);

					return col;
				}
				ENDCG
		}
		}
}