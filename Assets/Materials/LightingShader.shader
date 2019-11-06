Shader "Hidden/LightingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
			#include "Common_Lighting.cginc"
			#include "BRDF.cginc"
			#include "Lighting.cginc"
		
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

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
             
				float4 result = 1;

				Gbuffer buffer = GetBufferAt(i.uv);
				if (buffer.color.a != 1.0) return 0.0;
				//buffer.normal.xyz = KernelNormal(i.uv, buffer, 0.01, 1);
			
				float3 lightColor = CalculateLight(buffer);
				result.xyz = lightColor;
				//result.xyz = buffer.shader.x;
                return result;
            }
            ENDCG
        }
    }
}
