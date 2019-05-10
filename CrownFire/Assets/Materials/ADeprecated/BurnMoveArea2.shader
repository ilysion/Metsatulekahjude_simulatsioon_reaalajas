Shader "JJ/MoveBurnArea2" 
{
	Properties
	{
		_MainTex("Main (RGB)", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_BurningTex("BuringTex (RGB)", 2D) = "white" {}
		_NoiseTex("Noise (RGB)", 2D) = "gray" {}
		_TexScale("Texture scale", Float) = 1.0

		_Color("Color", Color) = (1,1,1,1)
		_WaterColor("Water Col", Color) = (1,1,1,1)
		_ShoreColor("Shore Col", Color) = (1,1,1,1)
		_MountainColor("Mountain Col", Color) = (1,1,1,1)
		_BurntColor("BurntColor", Color) = (1,1,1,1)
		_BurningColor("BurningColor", Color) = (1,1,1,1)


		_Delta("delta", Float) = 0.0
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

		uniform float4 _MainTex_TexelSize;
		uniform float4 _BurningTex_TexelSize;
		uniform half _TexScale;

		uniform fixed4 _Color;
		uniform fixed4 _WaterColor;
		uniform fixed4 _ShoreColor;
		uniform fixed4 _MountainColor;
		uniform fixed4 _BurntColor;
		uniform fixed4 _BurningColor;

		float _Delta;

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
		    fixed4 col = tex2D(_BurningTex, i.uv);
			half4 data = tex2D(_MainTex, i.uv);
			half4 burningData = tex2D(_BurningTex, i.uv);

			half4 noiseD1 = tex2D(_NoiseTex, i.uv * 0.21 + float2(0.1, 0.1));
			half4 noiseD2 = tex2D(_NoiseTex, i.uv * 0.271 + float2(0.3, 0.3));
			half2 noiseD = half2(noiseD1.x - 0.5 , noiseD2.x - 0.5);


			float4 white = (1.0, 0, 0, 0.0);
			float4 black = (1.0, 0.0, 0.0, 0.6);
			float4 grey = (1.0, 0.0, 0.0, 0.9);
			
			float texSize = 1024;
			//CurrentPosition
			float myX = i.uv.x;
			float myY = i.uv.y;

			//Texel sizes for burning texture
			float burnTexelSizeX = _BurningTex_TexelSize.x;
			float burnTexelSizeY = _BurningTex_TexelSize.y;

			//Data for texel at position
			float4 currentPosColor = tex2Dlod(_BurningTex, float4(float2(myX, myY), 0, 0));
			//z-neg
			float4 myPixelData2 = tex2Dlod(_BurningTex, float4(float2(myX, myY + burnTexelSizeY), 0, 0));
			//z-pos
			float4 myPixelData3 = tex2Dlod(_BurningTex, float4(float2(myX, myY - burnTexelSizeY), 0, 0));
			//x-neg
			float4 myPixelData4 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY), 0, 0));
			//x-neg
			float4 myPixelData5 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY), 0, 0));

			//Diagonals
			float4 diagonally1 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY + burnTexelSizeY), 0, 0));
			float4 diagonally2 = tex2Dlod(_BurningTex, float4(float2(myX + burnTexelSizeX, myY - burnTexelSizeY), 0, 0));
			float4 diagonally3 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY + burnTexelSizeY), 0, 0));
			float4 diagonally4 = tex2Dlod(_BurningTex, float4(float2(myX - burnTexelSizeX, myY - burnTexelSizeY), 0, 0));
			
			float4 mapPosCol = tex2Dlod(_MainTex, float4(float2(myX, myY), 0, 0));



			if (mapPosCol.g > 0.06) {

				//less/eq than 0.05 is shore, mainTex red value
				if (mapPosCol.r > 0.04) {

					//Straight movement with noise
					if (myPixelData2.r < 0.8) {
						if (noiseD1.x > 0.32) {
							col = black;
						}
					}
					if (myPixelData3.r < 0.8) {
						if (noiseD1.x > 0.33) {
							col = black;
						}
					}
					if (myPixelData4.r < 0.8) {
						if (noiseD1.x > 0.31) {
							col = black;
						}
					}
					if (myPixelData5.r < 0.8) {
						if (noiseD1.x > 0.34) {
							col = black;
						}
					}

					//Diagnoal movement with noise
					if (diagonally1.r < 0.8) {
						if (noiseD1.x > 0.62) {
							col = (black);
						}
					}
					if (diagonally2.r < 0.8) {
						if (noiseD1.x > 0.66) {
							col = (black);
						}
					}
					if (diagonally3.r < 0.8) {
						if (noiseD2.x > 0.64) {
							col = (black);
						}
					}
					if (diagonally4.r < 0.8) {
						if (noiseD2.x > 0.65) {
							col = (black);
						}
					}

					//Diagnoal movement without noise (very little noise)
					if (diagonally1.r < 0.3) {
						if (noiseD1.x > 0.03) {
							col = currentPosColor.r - 0.025;
						}
					}
					if (diagonally2.r < 0.3) {
						if (noiseD1.x > 0.04) {
							col = currentPosColor.r - 0.025;
						}
					}
					if (diagonally3.r < 0.3) {
						if (noiseD2.x > 0.06) {
							col = currentPosColor.r - 0.025;
						}
					}
					if (diagonally4.r < 0.3) {
						if (noiseD2.x > 0.03) {
							col = currentPosColor.r - 0.025;
						}
					}

					if (currentPosColor.r >= 0.0 & currentPosColor.r < 1.0) {
						half4 noiseD3 = tex2D(_NoiseTex, i.uv * noiseD.x + float2(0.1, 0.1));
						if (noiseD3.x > 0.05) {
							col.r = (currentPosColor.r - 0.025);
						}
						
					}

				}
			}

			// apply fog
			//UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}
		ENDCG
	}
	}
}