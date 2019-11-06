
struct Light
{
	int type;
	float3 position;
	float4 color;
};

struct Material {
	float4 color;
	float roughness;
	float metallic;
};

StructuredBuffer<Light> lightBuffer;
int lightBuffer_Count;

StructuredBuffer<Material>  materialBuffer;
int materialBuffer_Count;


