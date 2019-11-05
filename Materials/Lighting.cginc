
float3 CalculateLight(Gbuffer buffer) {

	float3 color = float3(0, 0, 0);

	for (int i = 0; i < 20; i++)
	{
		if (i >= lightBuffer_Count) break;

		color += BRDFdisney(buffer, lightBuffer[i]);
	}

	color = color + float3(0.2, 0.2, 0.23);

	//color = floor(color * 12.0) / 12.0;
	return color;
}