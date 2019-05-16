Shader "FinalCrownFire/HeightCalculationShader" 
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_HeightOutTex("_HeightOut (RGB)", 2D) = "white" {}
		_TexScale("Texture scale", Float) = 1.0

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
			sampler2D _HeightOutTex;
			float4 _MainTex_ST;

			uniform float4 _MainTex_TexelSize;
			uniform half _TexScale;
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

				fixed4 frag(v2f i) : SV_Target
				{

					// sample the texture
					half4 data = tex2D(_MainTex, i.uv);

					float4 white = (1.0, 0, 0, 0.0);
					float4 black = (1.0, 0.0, 0.0, 0.5);
					float4 grey = (1.0, 0.0, 0.0, 0.9);

					//CurrentPosition
					float myX = i.uv.x;
					float myY = i.uv.y;

					float4 mapPosCol = tex2Dlod(_MainTex, float4(float2(myX, myY), 0, 0));
					fixed4 col = tex2D(_MainTex, i.uv);

					return col;
				}
				ENDCG
		}
	}
}