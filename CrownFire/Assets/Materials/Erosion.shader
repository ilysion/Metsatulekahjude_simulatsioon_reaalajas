// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "JJ/Erosion"
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

			
			half2 exchange(half4 col, half height, half4 neig) {		
				
				half neigh = neig.r + neig.g + neig.b;	
				float diff = (neigh - height) * 0.25;

				half sdiff = clamp(diff, -col.b * 0.25, neig.b  * 0.25);

				float diff2 = (neig.r + neig.g - (col.r + col.g)) * 0.25;
				half sdiff2 = clamp(diff2, -col.g * 0.25, neig.g  * 0.25);
				//sdiff2 = clamp(sdiff * sdiff2, -sdiff2, sdiff2) * sdiff;
				sdiff2 = abs(sdiff2) * sdiff;
				 
				return half2(sdiff, sdiff2);
			}
			
			half4 frag (v2f i) : SV_Target
			{	
				float step = 1.0 / _Radius;

				half4 cols = tex2D(_HeightTex, i.uv);
				half4 col = cols;
				col.b += 0.0001;

				half height = col.r + col.g + col.b;

				half4 wl = tex2D(_HeightTex, i.uv + float2(-step, 0.0));
				half4 wr = tex2D(_HeightTex, i.uv + float2(step, 0.0));
				half4 wu = tex2D(_HeightTex, i.uv + float2(0.0, step));
				half4 wd = tex2D(_HeightTex, i.uv + float2(0.0, -step));
				/*half lh = wl.r + wl.g + wl.b;
				half rh = wr.r + wr.g + wr.b;
				half uh = wu.r + wu.g + wu.b;
				half dh = wd.r + wd.g + wd.b;*/


				half2 e1 = exchange(col, height, wl);
				half2 e2 = exchange(col, height, wr);
				half2 e3 = exchange(col, height, wu);
				half2 e4 = exchange(col, height, wd);
				

				half output =
					max(-e1.x, 0.0) + max(-e2.x, 0.0) +
					max(-e3.x, 0.0) + max(-e4.x, 0.0);

				half input = 
					max(e1.x, 0.0) + max(e2.x, 0.0) +
					max(e3.x, 0.0) + max(e4.x, 0.0);

				half erosion = min(output, col.r); 


				half res = e1.x + e2.x + e3.x + e4.x;
				half res2 = e1.y + e2.y + e3.y + e4.y;

				col.b += res;
				col.b *= 0.999;

				col.r -= erosion;
				col.g += erosion;
				col.g += res2;

				//col.b -= 0.00005;
				
				return col;
				//return cols * 0.99;
			}
			ENDCG
		}
	}
}
