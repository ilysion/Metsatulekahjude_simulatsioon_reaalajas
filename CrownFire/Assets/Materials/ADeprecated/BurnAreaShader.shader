// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "JJ/BurnArea"
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_DeltaX("delta X", Float) = 0.0
		_DeltaY("delta Y", Float) = 0.0
		_Scale("scale", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Noise.cginc"
			#include "UnityCG.cginc"
			sampler2D _MainTex;

			struct Input {
				float2 uv_MainTex;
			};

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			float _DeltaX;
			float _DeltaY;
			float _Scale;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}	

			float billowNoise(float2 v)
			{
				return abs(simplexNoise(v));
			}

			float ridgedNoise(float2 v)
			{
				return 1.0 - abs(simplexNoise(v)); 
			}

			float billowNoiseMinus(float2 v)
			{
				return abs(simplexNoise(v)) * 2.0 - 1.0;
			}

			float ridgedNoiseMinus(float2 v)
			{
				return (1.0 - abs(simplexNoise(v))) * 2.0 - 1.0;
			}

			float mountains(float2 v) {
				float h = 0.0;
				
				float dx1 = ridgedNoise(v * 13);
				float dy1= ridgedNoise(v * 13 + float2(2.1, 3.7));
				float2 v1 = v + float2(dx1, dy1) * 0.01;

				float dx2 = ridgedNoise(v1 * 7);
				float dy2 = ridgedNoise(v1 * 7 + float2(0.7, 0.7));
				float2 v2 = v + float2(dx2, dy2) * 0.02;
				
				float dx3 = ridgedNoise(v2 * 4);
				float dy3 = ridgedNoise(v2 * 4 + float2(0.2, 0.3));
				float2 v3 = v + float2(dx3, dy3) * 0.03;

				h += ridgedNoise(v3);
				h += ridgedNoise(v3 * 2.1);
				h *= 0.5;
				return h;
			}

			float rivers(float2 v) {
				float h = 0.0;

				float dx1 = ridgedNoise(v * 5);
				float dy1 = ridgedNoise(v * 5 + float2(2.1, 3.7));
				float2 v1 = v + float2(dx1, dy1) * 0.03;

				float dx = simplexNoise(v1 * 4);
				float dy = simplexNoise(v1 * 4 + float2(0.2, 0.3));
				float2 vn = v + float2(dx, dy) * 0.03;

				float h1 = billowNoise(vn * 0.7);
				//float h2 = billowNoise(vn * 2.1);
				
				//h = min(h1, h2);
				h = h1;

				return h;
			}

			float scale(float v, float min, float max) {
				float ab = max - min;
				return saturate((v - min) / ab);
			}

			float plains(float2 v) {
				float h = simplexNoise(v * 2.7);
				h += simplexNoise(v * 5.7 + float2(0.2, 10.3)) * 0.5;
				h += simplexNoise(v * 9.7 + float2(20.1, 0.1)) * 0.2;

				float h2 = simplexNoise(v * 2.1 + float2(10.2, 8.3));
				float h3 = simplexNoise(v * 2.1 + float2(3.2, 18.3));
				h = clamp(h, -h3, h2);
				
				//fields
				float fm = simplexNoise(v * 0.3 + float2(1.6, 30.6));
				fm += simplexNoise(v * 0.45 + float2(2.6, 30.6));
				float fms = scale(fm, 0.0, 0.9);
				h = lerp(h, 0.0, fms);


				h *= 0.3;
				return h * 0.2 + 0.1;
			}

			float biomes(float2 v) {

				float dx1 = simplexNoise(v * 2);
				float dy1 = simplexNoise(v * 2 + float2(2.1, 3.7));
				float2 v1 = v + float2(dx1, dy1) * 0.08;

				float h = simplexNoise(v1);
				h += simplexNoise(v * 0.628);
				h = h * 0.5;

				h = h * 0.5 + 0.5;
				return h;
			}

			float lakes(float2 v) {

				float dx1 = simplexNoise(v * 4.5);
				float dy1 = simplexNoise(v * 3.2 + float2(2.1, 3.7));
				float2 v1 = v + float2(dx1, dy1) * 0.08;

				float h = simplexNoise(v1);
				h += simplexNoise(v * 1.8);
				h += simplexNoise(v * 0.7);
				h = h * 0.4;
				h = h * 0.5 + 0.5;
				return h;
			}

			float3 gh(float2 v) {

				float b = biomes(v * 0.33);
				float b1 = scale(b, 0.4, 0.7);

				float nonriver = biomes(v * 0.19 + float2(22.1, 32.7));
				float nonriver1 = scale(nonriver, 0.5, 0.6);

				//mapping
				float m = mountains(v);;
				float r = rivers(v);
				r = lerp(r, 0.7, nonriver1);

				float erosion = r * r;
				float mr = m * erosion * 1.5 + 0.2;
				mr = mr * r;

				
				//Lakes
				float l = lakes(v);
				float l1 = scale(l, 0.70, 0.83);
				l1 += scale(l, 0.50, 0.83);
				l1 *= 0.5;


				//Planes with lakes and rivers
				float p = plains(v);
				float pr = r * 0.4;
				pr = clamp(pr, 0.0, p);
				float prl = lerp(pr, 0.0, l1);


				float h = lerp(mr,prl, b1);

				//flatten
				float h1 = clamp(h, 0.02, 1);
				//water
				float h2 = h * 15.0;
				
				return float3(h1, h2, h1);
			}

			half4 frag (v2f i) : SV_Target
			{		
				float offset = (_Scale - 1.0) / 2.0;
				float2 pos = i.uv * _Scale + float2(_DeltaX, _DeltaY) - float2(offset, offset);

				//float3 h = gh(pos * 1);
				float3 h;


				//Sets 1/10 of the center of the screen as burn start area

				
				if (pos.x > float2(0.5, 0.5).x 
					&& pos.x < float2(0.6, 0.6).x
					&& pos.y > float2(0.5, 0.5).y
					&& pos.y < float2(0.6, 0.6).y
					) {
					h = (0.0, 0.0, 0.0);
				}
				else {
					h = (0.0, 0.0, 1.0);
				}

				
				
				
				


				return half4(h, 1.0);
			}
			ENDCG
		}
	}
}
