
//Used to fuse or seperate objects
float3 KernelNormal(float2 uv, Gbuffer buffer, float maxdist, int fuse) {

	float3 worlda = buffer.world.xyz;
	float3 nTotal = 0.0;
	int obja = buffer.shader.y;
	float debug = 0.0;
	float dd = 0.0;
	
	for (int y = -2; y <= 2; y++)
	{
		for (int x = -2; x <= 2; x++)
		{
			float2 cuv = uv + float2(x, y) * screen.xy * 8.0;
			int objb = tex2D(shaderTex, cuv).y;

			if(objb != obja) debug += 1.0;

			float3 worldb = tex2D(worldTex, cuv).xyz;

			float d = distance(worlda, worldb);
			dd += d;
			if (d < maxdist) nTotal += tex2D(normalTex, cuv).xyz;
			//nTotal += tex2D(normalTex, cuv).xyz;
		}
	}

	if(debug == 0) return buffer.normal.xyz;

	nTotal = normalize(nTotal);
	if (fuse != 1) nTotal = -nTotal;
	return nTotal;

}

float3 CalculateLight(Gbuffer buffer, float3 reflections) {

	float3 color = float3(0, 0, 0);

	for (int i = 0; i < 20; i++)
	{
		if (i >= lightBuffer_Count) break;

		color += BRDFBasic(buffer, lightBuffer[i], reflections);
	}

	color = color;

	//color = floor(color * 12.0) / 12.0;
	return color;
}