// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.

Shader "JJ/MapData2"
{
	Properties
	{
		_DeltaX("delta X", Float) = 0.0
		_DeltaY("delta Y", Float) = 0.0
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

			float riverNoise(float2 v, float thickness)
			{
				float t = 1.0 / thickness;
				return saturate(1.0 - (1.0 - abs(simplexNoise(v) * t)));
			}

			float h0(float2 pos) {
				float h = 0;		
				float factor = 20.0;
				float2 fp = pos*factor / float2(1.0, 1.0);
				//h += simplexNoise(fp) / (pow(factor, 0.88) * 10.0);
				float v = voronoiNoise(fp, 1.0, 0.8) / (pow(factor, 0.88));

				v = clamp(0.5 - abs(v), 0.48, 0.5);

				h = 1- v;
				return h;
			}

			float h1(float2 pos) {
				float h = 0.5;
				for (int k = 0; k<9; k++) {	 //<9			
					float factor = pow(2.0, float(k));
					h += billowNoise(pos*factor / float2(1.0, 1.0)) / (pow(factor, 0.88) * 10.0);
				}
				return h;
			}

			float hvoro(float2 pos) {
				float h = 0;
				h += 1.0 - voronoiDistance(pos * 7.0);
				h += 1.0 - voronoiDistance(pos * 17.0);
				h += 1.0 - voronoiDistance(pos * 15.0);
				h += 1.0 - voronoiDistance(pos * 4.0);
				h = h * 0.5 - 1.0;
				return h;
			}

			float mightBecomeRivers(float2 pos, float scale) {
				float h = 0;

				pos *= scale;
				
				float dx = simplexNoise(pos * 1.2) * 0.06;
				dx += simplexNoise(pos * 3) * 0.06;
				float dy = billowNoise(pos * 3 + float2(0.2, 0.3)) * 0.06;
				dy += simplexNoise(pos * 1.4) * 0.06;
				pos = pos + float2(dx, dy);

				float h1 = ridgedNoise(pos * 0.55);
				h1 = h1 * h1;
				float h2 = ridgedNoise(pos);
				h2 = h2 * h2;
				h = max(h1, h2);

				return h;
			}

			float mountainsRigid(float2 pos, float scale) {
				float h = 0;

				pos *= scale;

				float dx = ridgedNoise(pos * 4) * 0.03;
				float dy = ridgedNoise(pos * 4 + float2(0.2, 0.3)) * 0.03;
				pos = pos + float2(dx, dy);

				h += ridgedNoise(pos);
				h += ridgedNoise(pos * 2.1);
				h *= 0.5;
				
				return h;
			}

			float mountainsBillow(float2 pos, float scale) {
				float h = 0;

				pos *= scale;

				float dx = ridgedNoise(pos * 4) * 0.03;
				float dy = ridgedNoise(pos * 4 + float2(0.2, 0.3)) * 0.03;
				pos = pos + float2(dx, dy);

				h += billowNoise(pos);
				h += billowNoise(pos * 2.1);
				h *= 0.5;

				return h;
			}

			float mountains(float2 pos, float scale) {
				float h = 0;

				pos *= scale;

				float dx = ridgedNoise(pos * 4) * 0.03;
				float dy = ridgedNoise(pos * 4 + float2(0.2, 0.3)) * 0.03;
				pos = pos + float2(dx, dy);

				h += ridgedNoise(pos);
				h += ridgedNoise(pos * 2.1);
				h += ridgedNoise(pos * 0.7);
				h += ridgedNoise(pos * 0.55);
				h *= 0.3;
				return h;
			}

			float rivers(float2 pos, float scale) {
				float h = 0;

				pos *= scale;

				float dx = ridgedNoise(pos * 1.2) * 0.06;
				dx += ridgedNoise(pos * 3) * 0.06;
				float dy = ridgedNoise(pos * 3 + float2(0.2, 0.3)) * 0.06;
				dy += ridgedNoise(pos * 1.4) * 0.06;
				pos = pos + float2(dx, dy);

				h += billowNoise(pos * 0.55);
				h += billowNoise(pos);

				h *= 3;
				h *= h;
				h *= 0.2;

				h *= 0.5;
				return h;
			}

			float glob(float2 pos, float scale) {
				float h = 0;

				pos *= scale;

				float dx = ridgedNoise(pos * 3) * 0.06;
				float dy = ridgedNoise(pos * 3 + float2(0.2, 0.3)) * 0.06;
				pos = pos + float2(dx, dy);

				h += simplexNoise(pos * 0.55);
				h += simplexNoise(pos);

				h *= 2;
				h *= h;
				h *= 0.16;

				h *= 0.5;
				return h;
			}

			float2 gh2(float2 pos) {
				float h = 0;

				float g = glob(pos, 1.55);
				float g2 = glob(pos, 1.25);
				float g3 = glob(pos, 1.42);
				float g4 = glob(pos, 0.77);

				// lowground
				float gs = glob(pos, 8.1);
				gs += glob(pos, 6.1);
				gs += glob(pos, 4.1);
				gs = clamp(gs, 0, g);
				float smount = glob(pos, 3.3) * 0.5;
				smount += glob(pos, 5.3) * 0.5;
				gs += clamp(smount, 0, g*2.0);
				float plainmat = gs * 0.3;

				//Rivers, mountains
				float r = rivers(pos, 3.0);
				float m = mountains(pos, 3.0);
				float mixh = min(r, m);

				h += lerp(mixh, 0.3, g); 
				h = lerp(h, 0.5, g2);

					
				float r3 = r * 3;
				float rnew = saturate(2 * r3 - 0.5);
				plainmat = lerp(0.0, gs * 0.3, rnew);
				

				float plains = saturate(g3 * 4 - 0.3);
				 
				h = lerp(plainmat, h, plains);

				float mr = mightBecomeRivers(pos, 3.0);
				mr = (1 - mr);
				mr = saturate(mr + h * 2 - 0.2 + g3 + g4);

				//h = mr;
				//h = min(mr, h);

				float neg = saturate(1 - clamp(mr - h, 0, 0.1) * 10);

				h = (h + 0.05) - neg * 0.05;
				float h2 = lerp(h, 0.0, neg);
				h = (h + h2) * 0.5;


				//h = mr;

				//h = neg;

				//neg = max(0.9, h) * 10;
				//neg = clamp(1 - h, 0.0, 0.1) * 5;

				
				h = plainmat;
				return float2(h, neg);
			}

			half4 frag (v2f i) : SV_Target
			{		
				
				float2 pos = i.uv + float2(_DeltaX, _DeltaY);
				float2 h = saturate(gh2(pos));

				//float soil = saturate(0.3 - h);
				//float water = saturate(0.2 - h);

				float noise = billowNoise(pos * 0.98) * 2;


				return half4(h.x, noise, h.x, h.y);
			}
			ENDCG
		}
	}
}
