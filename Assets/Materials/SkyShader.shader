Shader "Hidden/SkyShader"
{
    Properties
    {
       
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Common_Variables.cginc"
			#include "Gbuffer.cginc"
		
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

			float4 ZenithColor;
			float4 HorizonColor;

			float4 CalculateSky(float2 uv) {
				Gbuffer buffer = GetBufferAt(uv);

				//If the contents alpha value was 1 then no sky is showing through
				if (buffer.color.a == 1) return float4(0, 0, 0, 0);

				return float4(0, 1, 0, 1);

			}

            fixed4 frag (v2f i) : SV_Target
            {
				float4 sky = CalculateSky(i.uv);

                return sky;
            }
            ENDCG
        }
    }
}
