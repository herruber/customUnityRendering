
sampler2D colorTex, normalTex, worldTex, shaderTex;


struct pixelout
{
	float4 color : SV_Target0;
	float4 world : SV_Target1;
	float4 normal : SV_Target2;
	float4 shader : SV_Target3;
};

struct Gbuffer
{
	float4 color;
	float4 world;
	float4 normal;
	float4 shader;
};

Gbuffer GetBufferAt(float2 uv) {

	Gbuffer buffer;
	buffer.color = tex2D(colorTex, uv);
	buffer.normal = tex2D(normalTex, uv);
	buffer.world = tex2D(worldTex, uv);
	buffer.shader = tex2D(shaderTex, uv);

	return buffer;
}