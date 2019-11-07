
float PI;
float4 screen;
float4 dirs[4];

float3 ViewDir(float2 uv) {

	float3 a = lerp(dirs[0], dirs[1], uv.x);
	float3 b = lerp(dirs[2], dirs[3], uv.x);
	float3 c = lerp(a, b, uv.y);
	return c;
}