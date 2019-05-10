// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "JJ/MapTexture"
{
	Properties
	{
		_HeightTex("Heights (RGB)", 2D) = "white" {}
		_NormalsTex("Normals (RGB)", 2D) = "white" {}
		_AOIntensity("AO intensity", Float) = 1.0
		_RayLength("Ray Length", Float) = 1.0
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
			#include "Noise.cginc"

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
			sampler2D _NormalsTex;
			float _AOIntensity;
			float _RayLength;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float3 get(float2 uv) {
				float4 hv = tex2D(_HeightTex, uv);
				float h = hv.r;
				return float3(uv.x, h, uv.y);
			}

			float getNoise(float2 uv) {
				float n = tilableNoise(uv, 12.0);
				n += tilableNoise(uv, 7.0);
				n += tilableNoise(uv, 19.0);

				n = n * 0.5 + 0.5;
				n = saturate(n);
				 
				return n;
			}

			fixed4 frag (v2f i) : SV_Target
			{	
				float occlusion = 0.0;
				float3 pos = get(i.uv);
				float3 normal = tex2D(_NormalsTex, i.uv).xyz;
				normal = normal * 2.0 - 1.0;


				float3 tangent = normalize(cross(normal, float3(0.0, 0.0, 1.0)));
				float3 bitangent = normalize(cross(tangent, normal));
				float3x3 orthobasis = float3x3(tangent, normal, bitangent);

				for (int k = 1; k < 33; k++) {
					float s = float(k) / 32.0;
					float a = sqrt(s*512.0);
					float b = sqrt(s);
					float x = sin(a) * b * _RayLength;
					float y = cos(a) * b * _RayLength;
					float3 sample_uv = mul(orthobasis, float3(x, 0.0, y));
					float3 sample_pos = get(i.uv + float2(sample_uv.x, sample_uv.z));
					float3 sample_dir = normalize(sample_pos - pos);
					float lambert = clamp(dot(normal, sample_dir), 0.0, 1.0);
					float dist_factor = 0.23 / sqrt(length(sample_pos - pos));
					occlusion += dist_factor * lambert;
				}
				float incident = (1.0 - occlusion / _AOIntensity);
				float occl = clamp(incident, 0.5, 1.0);
				occl = occl * 2 - 0.7;
				

				//float sloap = 1.0 - dot(normal, float3(0.0, 1.0, 0.0));
				
				float noise = getNoise(i.uv);

				//return float4(occl, occl, occl, 1.0);
				return float4(occl, occl, occl, noise);
			}
			ENDCG
		}
	}
}
