// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/MrtStandard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_MaterialIndex ("Material index", float) = -1
		_Roughness ("Roughness", float) = 0.5
		_Metallic("Metallic", float) = 0.0
		[PerRendererData]_Color("Color", Color) = (1,1,1,1)
		[PerRendererData]_ObjectIndex("Object index", float) = -1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Gbuffer.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 normal : TEXCOORD1;
				float4 worldNormal : TEXCOORD3;
				float4 world : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _Color;
			float _MaterialIndex;
			float _ObjectIndex;
			float _Roughness;
			float _Metallic;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = normalize(v.normal); // mul(unity_ObjectToWorld, float4(v.normal.xyz, 0.0));
				float3 wn = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = normalize(float4(wn, 1));
				
				o.world = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.world.w = distance(_WorldSpaceCameraPos, o.world.xyz);


                return o;
            }

            pixelout frag (v2f i)
            {
				pixelout p;

				float4 color = _Color;

				p.color = _Color;
				p.normal = i.worldNormal;
				p.world = i.world;
				p.shader = float4(_MaterialIndex, _ObjectIndex, 0, 0);	//x materialID, y objectId

				return p;

            }
            ENDCG
        }
    }
}
