
float sqr(float x) { return x*x; }

float SchlickFresnel(float u)
{
	float m = clamp(1.0 - u, 0.0, 1.0);
	float m2 = m*m;
	return m2*m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
	if (a >= 1.0) return 1.0 / PI;
	float a2 = a*a;
	float t = 1.0 + (a2 - 1.0)*NdotH*NdotH;
	return (a2 - 1) / (PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
	float a2 = a*a;
	float t = 1.0 + (a2 - 1)*NdotH*NdotH;
	return a2 / (PI * t*t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
	return 1 / (PI * ax*ay * sqr(sqr(HdotX / ax) + sqr(HdotY / ay) + NdotH*NdotH));
}

float smithG_GGX(float NdotV, float alphaG)
{
	float a = alphaG*alphaG;
	float b = NdotV*NdotV;
	return 1.0 / (NdotV + sqrt(a + b - a*b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
	return 1.0 / (NdotV + sqrt(sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV)));
}

float3 mon2lin(float3 vec)
{
	return pow(vec, 2.2);
}

float3 BRDFdisney(Gbuffer buffer, Light light)
{

	float3 N = normalize(buffer.normal.xyz);
	float3 V = normalize(_WorldSpaceCameraPos - buffer.world.xyz);
	float3 L = normalize(-light.position); //normalize(lightPositions[i] - WorldPos);
	float3 H = normalize(L + V);

	float3 X = normalize(cross(float3(0.0, 1.0, 0.0), N)); //tangent
	float3 Y = normalize(cross(N, X));			  //bitangent

	Material material = materialBuffer[floor(buffer.shader.r + 0.5)];

	float metallic = material.metallic;
	float roughness = material.roughness;
	float subsurface = 0;
	float specular = 0.5;
	float specularTint = 0.0;
	float anisotropic = 0;
	float sheen = 0;
	float sheenTint = 0;
	float clearcoat = 0;
	float clearcoatGloss = 0.5;

	float NdotL = saturate(dot(N, L));
	float NdotV = dot(N, V);
	if (NdotL < 0 || NdotV < 0) return 0;

	float NdotH = dot(N, H);
	float LdotH = dot(L, H);

	float3 Cdlin = mon2lin(buffer.color.xyz);
	float Cdlum = .3*Cdlin[0] + .6*Cdlin[1] + .1*Cdlin[2]; // luminance approx.

	float3 Ctint = Cdlum > 0.0 ? Cdlin / Cdlum : 1.0; // normalize lum. to isolate hue+sat
	float3 Cspec0 = lerp(specular*.08*lerp(1.0, Ctint, specularTint), Cdlin, metallic);
	float3 Csheen = lerp(1.0, Ctint, sheenTint);

	// Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
	// and lerp in diffuse retro-reflection based on roughness
	float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
	float Fd90 = 0.5 + 2.0 * LdotH*LdotH * roughness;
	float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);

	// Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
	// 1.25 scale is used to (roughly) preserve albedo
	// Fss90 used to "flatten" retroreflection based on roughness
	float Fss90 = LdotH*LdotH*roughness;
	float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
	float ss = 1.25 * (Fss * (1.0 / (NdotL + NdotV) - .5) + .5);

	// specular
	float aspect = sqrt(1.0 - anisotropic*.9);
	float ax = max(.001, sqr(roughness) / aspect);
	float ay = max(.001, sqr(roughness)*aspect);
	float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
	float FH = SchlickFresnel(LdotH);
	float3 Fs = lerp(Cspec0, 1.0, FH);
	float Gs;
	Gs = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
	Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);

	// sheen
	float3 Fsheen = FH * sheen * Csheen;

	// clearcoat (ior = 1.5 -> F0 = 0.04)
	float Dr = GTR1(NdotH, lerp(.1, .001, clearcoatGloss));
	float Fr = lerp(.04, 1.0, FH);
	float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);

	float3 result = ((1.0 / PI) * lerp(Fd, ss, subsurface)*Cdlin + Fsheen) * (1.0 - metallic) + Gs*Fs*Ds + .25*clearcoat*Gr*Fr*Dr;
	result = max(result, 0.0);

	// brightness
	result *= light.color.a * light.color.rgb;

	// exposure
	//result *= pow(2.0, exposure);

	// gamma
	result = pow(result, 1.0 / 2.2);


	return result * NdotL;
}

float3 BRDF(Gbuffer buffer, Light light) {


	float3 N = normalize(buffer.normal.xyz);
	float3 V = normalize(_WorldSpaceCameraPos - buffer.world.xyz);
	float3 L = normalize(-light.position); //normalize(lightPositions[i] - WorldPos);
	float3 H = normalize(V + L);


	float NdotL = dot(N, L);
	return NdotL;
}