// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.

Shader "JJ/Simplex"
{
	Properties
	{
		_Delta("delta", Float) = 0.0
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

			float _Delta;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				float h = 0.5;
				
				for (int k = 0; k<9; k++) {				
					float factor = pow(2.0, float(k));
					h += simplexNoise((i.uv + _Delta)*factor / float2(1.0, 1.0)) / (pow(factor, 0.88) * 10.0);
				}
				h = clamp(h, 0.0, 1.0);
				
				return fixed4(h, h, h, 1.0);
			}
			ENDCG
		}
	}
}
