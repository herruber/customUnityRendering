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
			#pragma target 5.0
            #include "UnityCG.cginc"
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

            sampler2D _MainTex;


			float4 zenithColor;
			float4 horizonColor;
			float tod;

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

			//incomming intensity, wavelength, distance to particle, particle position, light dir, particle to camera dir
			

			float4 GetSkyColorAt(Ray ray, float2 uv) {

				float d = 1000.0;

				Sphere dome;
				dome.c = 0.0;
				dome.r = 500.0;

				Hit hit = RaycastSphere(ray, dome);
				float3 skypos = hit.pos;

				Light light = lightBuffer[0];
				float3 L = -normalize(light.position.xyz);

				float3 sunpos = L * dome.r;

				float dii = distance(skypos, sunpos);

				//Mie mask

				float radius = 0.29 * pow(10.0, -2.0); //Gas
				float size = 2.0 * PI * radius;
				float ior = 1.003;

				float scatterRay = -ray.dir;
				float scatterAngle = (L * scatterRay) / (abs(L) * abs(scatterRay)); // acos(dot(L, scatterRay));
				return scatterAngle;
				float w = 600.0 * pow(10.0, -9.0);
				float b = pow(2.0 * PI / w, 4.0);
				float n = pow((ior * ior - 1.0) / (ior * ior + 2.0), 2.0);
				float r = pow(radius, 6.0);
			
				float aa = (1.0 + scatterAngle) / (2.0 * dome.r * dome.r);

				float sun = aa * b * n * r;
				
				//*((0.5 + 1.0 * pow(L.y, 0.4)) * ((1.5 * dome.r - skypos.y) / dome.r) + pow(sun, 5.2)
				//	* L.y * (5.0 + 15.0 * L.y)), 1.0);

				return float4(lerp(float3(0.3984, 0.5117, 0.7305), float3(0.7031, 0.4687, 0.1055), sun), 1.0);
			}

			float4 TraceSkyReflectance(Ray ray, Gbuffer buffer) {

				Hit closest = ClosestHit(ray);

				//We hit another geometry
				if (closest.valid)
				{
					int id = closest.materialId;

					ray.origin = closest.pos - ray.dir * 0.001;
					ray.dir = reflect(ray.dir, closest.normal);
					Hit closestB = ClosestHit(ray);

					if(closestB.valid) return float4(materialBuffer[id].color.rgb, 1.0);


				}
				
				return GetSkyColorAt(ray, 0);

			}

			float4 CalculateSky(float2 uv, Gbuffer buffer) {
				
				Ray ray;
				float d = 1000;
				float r = 500;
				//If no sky visible at this pixel, reflect the light
				if (buffer.color.a == 1) {
				/*	
					ray.origin = buffer.world.xyz + buffer.normal.xyz * 0.02;
					ray.dir = -normalize(lightBuffer[0].position.xyz);
					return	TraceSkyReflectance(ray, buffer);*/
				}
				//If sky is visible compute the skycolor 
				else
				{
					ray.dir = ViewDir(uv);
					ray.origin = _WorldSpaceCameraPos;
					
				}

				return GetSkyColorAt(ray, uv);
			}


            fixed4 frag (v2f i) : SV_Target
            {
             
				float4 result = 1;
				float4 sky = 1;

				Gbuffer buffer = GetBufferAt(i.uv);
				
				//return materialBuffer[0].color;
				sky = CalculateSky(i.uv, buffer);
				
				return sky;
			
				float3 color = CalculateLight(buffer);
				result.xyz = color; // lerp(sky, color, buffer.color.a);
				
				//result.xyz = buffer.shader.x;
                return result;
            }
            ENDCG
        }
    }
}
