Shader "Hidden/LightingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_SunSize("Sun size", Range(0.0, 1.0)) = 0.1
		_HaloSize("Halo size", Range(0.0, 1.0)) = 0.1
		_HaloArea("Halo area", Range(0.01, 1.0)) = 0.1
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
			#pragma target 5.0
            #include "UnityCG.cginc"
			#include "Constants.cginc"
			#include "Common_Variables.cginc"
			#include "Gbuffer.cginc"
			#include "Common_Lighting.cginc"
			#include "BRDF.cginc"
			#include "Lighting.cginc"
			#include "Raycaster.cginc"
		
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

            sampler2D _MainTex, _ReflTex;


			float4 zenithColor;
			float4 horizonColor;
			float tod, _HaloSize, _SunSize, _HaloArea;

			Hit ClosestHit(Ray ray) {

				Hit closest;
				closest.valid = false;
				closest.t = 999999.9;
			
				for (int i = 0; i < 40; i++)
				{
					if (i >= objectBuffer_Count) break;
					Tri tri = objectBuffer[i];

				
					Hit hit;
				
					if (tri.type == 0) {
						hit = RaycastTri(ray, tri);
					}
					else if (tri.type == 1) {
						Sphere s;
						s.c = tri.a;
						s.r = tri.b.r;
						hit = RaycastSphere(ray, s);
						hit.materialId = tri.materialId;
						hit.objectId = tri.objectId;
					}
						
						
						
					

					if (hit.valid && hit.t < closest.t) closest = hit;

				}

				return closest;
			}

			float3 GetSky(float3 wpos) {
			
				float3 color = 0;

				Light sun = lightBuffer[0];
		
				// Normalized screen space coordinates of the sun controlled by mouse
				wpos = normalize(wpos);
				float3 sunPosition = -normalize(sun.position.xyz);

				float saty = saturate(sunPosition.y);
				// Interpolate between midday and evening sky colors based on sun height
				float3 sky_horizonColor = lerp(float3(0.8, 0.4, 0.1), float3(0.6, 0.6, 1.0), pow(saty, 0.3));
				float3 sky_Color = lerp(float3(0.1, 0.1, 0.3), float3(0.2, 0.2, 0.7), pow(saty, 0.3));

				// Sky gradient
				float3 skyGradient = lerp(sky_horizonColor, sky_Color, pow(wpos.y, 0.5));

				// Simple sun disc
				float3 sun_color = sun.color.rgb * sun.color.a;
				float3 sunDisc = sun_color * (length(wpos - sunPosition) < _SunSize ? 1.0 : 0.0);
				sunDisc = sunDisc;// saturate(sunDisc);

				// Compute sun halo for horizon and zenit
				float sunHaloFactor = saturate(length(wpos - sunPosition) - _HaloSize) / length(wpos);
				
				float sunHaloPoly = (1.0 - pow(sunHaloFactor, 0.15 + (1.0 - sunPosition.y)*0.2)) * (1.0 - wpos.y);
				float sunHaloExp = exp(-pow(sunHaloFactor, 2.0) / (2.0*pow(_HaloArea, 2.0)));
				// Interpolate sun halo
				float3 sunHalo = sun_color * lerp(sunHaloPoly, sunHaloExp, pow(saturate(sunPosition.y), 0.6));
			
				// Combine sky gradient, sun disc and sun halo for final color
				color = skyGradient + sunDisc + sunHalo;

				// Debugging
				//fragColor = float4(sunHalo,1.0);


				return color;
			}

			float3 GetSky(float2 uv) {

				Light light = lightBuffer[0];
				float3 viewDir = ViewDir(uv);

				float3 L = -normalize(light.position.xyz);
				float3 W = _WorldSpaceCameraPos + viewDir * 1000.0;
				
				return GetSky(W);

			}

			float3 GetReflections(float2 uv, Gbuffer buffer) {


				Light light = lightBuffer[0];
		

				float3 viewDir = ViewDir(uv);
				float3 L = -normalize(lightBuffer[0].position.xyz);
				float3 N = WrapNormal(buffer.normal, L, buffer.normal.xyz); // normalize(buffer.normal.xyz);
				Ray ray;
				ray.origin = buffer.world.xyz + N * 0.01;
				ray.dir = reflect(viewDir, N);
			

				Hit closest;
				closest.valid = false;
				closest.t = 99999.9;

				for (int i = 0; i < 50; i++)
				{
					if (i >= objectBuffer_Count) break;

					Tri tri = objectBuffer[i];
					Hit hit;

					//geo
					if(tri.type == 0)  hit = RaycastTri(ray, tri);
					//Sphere
					else if (tri.type == 1) {
						Sphere s;
						s.c = tri.a.xyz;
						s.r = tri.b.x;
						hit = RaycastSphere(ray, s);
					}

					if (hit.valid && hit.t < closest.t) closest = hit;
					
				}
			
				if (closest.valid)
				{
					int matid = closest.materialId;
					Material mat = materialBuffer[matid];
					return mat.color.xyz;
				}


				Sphere dome;
				dome.c = 0;
				dome.r = 1000.0;

				Hit hit = RaycastSphere(ray, dome);


				return GetSky(hit.pos);

			}

			float4 GetObjectColor(float2 uv, Gbuffer buffer) {

				float4 color = 1.0;

				color.rgb = GetReflections(uv, buffer);


				color.rgb = CalculateLight(buffer, color);

				return color;
			}

            fixed4 frag (v2f i) : SV_Target
            {
             
				float4 result = 1;
				float4 sky = 1;

				//Gbuffer buffer = GetBufferAt(i.uv);

				return tex2D(_ReflTex, i.uv);

			/*	
				if (buffer.color.a == 0) return float4(GetSky(i.uv), 1.0);
				else return GetObjectColor(i.uv, buffer);
*/
				//return materialBuffer[0].color;
				//sky = CalculateSky(i.uv, buffer);

				//float3 color = CalculateLight(buffer);
				//result.xyz = color; // lerp(sky, color, buffer.color.a);
				//
				//result.xyz = buffer.shader.x;
                return result;
            }
            ENDCG
        }
    }
}
