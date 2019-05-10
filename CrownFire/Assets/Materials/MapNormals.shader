// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "JJ/MapNormals"
{
	Properties
	{
		_HeightTex("Heights (RGB)", 2D) = "white" {}
		_Radius("Radius", Float) = 128.0
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

			sampler2D _HeightTex;
			float _Radius;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float3 get(float2 uv) {
				float4 hv = tex2D(_HeightTex, uv);
				float h = hv.x;
				return float3(uv.x, h, uv.y);
			}
			
			float3 getn(float2 uv, float3 pos) {
				float3 v = get(uv) - pos;
				float3 prep = cross(float3(0.0, 1.0, 0.0), v);
				return normalize(cross(v, prep));
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				//fixed4 col = tex2D(_HeightTex, i.uv);
				float step = 1.0 / _Radius;

				float3 pos = get(i.uv);
				
				float3 normal = normalize((
						getn(i.uv + float2(-step, -step), pos) +
						getn(i.uv + float2(-step, 0.0), pos) +
						getn(i.uv + float2(-step, step), pos) +
						getn(i.uv + float2(0.0, -step), pos) +
						getn(i.uv + float2(0.0, step), pos) +
						getn(i.uv + float2(step, -step), pos) +
						getn(i.uv + float2(step, 0.0), pos) +
						getn(i.uv + float2(step, step), pos)
					)/8.0);

					//normal = saturate(normal);

					normal = (normal / 2.0) + 0.5;

				return fixed4(normal, 1.0);
			}
			ENDCG
		}


	}
}
