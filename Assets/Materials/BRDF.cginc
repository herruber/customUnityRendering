
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
	return 1.0 / (PI * ax*ay * sqr(sqr(HdotX / ax) + sqr(HdotY / ay) + NdotH*NdotH));
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
	return NdotL;
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


	return result *NdotL;
}

float Beckmann(float m, float t)
{
	float M = m*m;
	float T = t*t;
	return exp((T - 1.0) / (M*T)) / (M*T*T);
}

float Fresnel(float f0, float u)
{
	// from Schlick
	return f0 + (1.0 - f0) * pow(1.0 - u, 5.0);
}

float3 BRDFcookTorrance(Gbuffer buffer, Light light)
{
	Material material = materialBuffer[floor(buffer.shader.r + 0.5)];

	float3 N = normalize(buffer.normal.xyz);
	float3 V = normalize(_WorldSpaceCameraPos - buffer.world.xyz);
	float3 L = normalize(-light.position); //normalize(lightPositions[i] - WorldPos);
	float3 H = normalize(L + V);

	float3 X = normalize(cross(float3(0.0, 1.0, 0.0), N)); //tangent
	float3 Y = normalize(cross(N, X));			  //bitangent

	float NdotH = dot(N, H);
	float VdotH = dot(V, H);
	float NdotL = dot(N, L);
	float NdotV = dot(N, V);
	float oneOverNdotV = 1.0 / NdotV;

	float f0 = clamp(material.metallic, 0.0001, 1.0);
	float m = clamp(material.roughness, 0.0, 1.0);

	float D = Beckmann(m, NdotH);
	float F = Fresnel(f0, VdotH);

	NdotH = NdotH + NdotH;
	float G = (NdotV < NdotL) ?
		((NdotV*NdotH < VdotH) ?
			NdotH / VdotH :
			oneOverNdotV)
		:
		((NdotL*NdotH < VdotH) ?
			NdotH*NdotL / (VdotH*NdotV) :
			oneOverNdotV);

	//G = oneOverNdotV;
	float val = NdotH < 0 ? 0.0 : D * G;

	//val *= F;

	val = val * NdotL;
	return val;
}

float3 fresnelSchlick(float cosTheta, float3 F0)
{
	return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float DistributionGGX(float3 N, float3 H, float roughness)
{
	float a = roughness*roughness;
	float a2 = a*a;
	float NdotH = max(dot(N, H), 0.0);
	float NdotH2 = NdotH*NdotH;

	float num = a2;
	float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	denom = PI * denom * denom;

	return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = (roughness + 1.0);
	float k = (r*r) / 8.0;

	float num = NdotV;
	float denom = NdotV * (1.0 - k) + k;

	return num / denom;
}
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2 = GeometrySchlickGGX(NdotV, roughness);
	float ggx1 = GeometrySchlickGGX(NdotL, roughness);

	return ggx1 * ggx2;
}

float3 WrapNormal(float3 N, float3 L, float amount) {

	amount = amount / 4.0;
	amount *= amount;
	amount = saturate(amount);
	float NdotL = dot(N, L);
	float cosTheta = NdotL;
	float wrappedCosTheta = saturate((cosTheta + amount) / (1.0 + amount));
	float sinMaxAngle = amount;
	float sinMinAngle = 0.0;
	float sinPhi = lerp(sinMaxAngle, sinMinAngle, wrappedCosTheta);
	float cosPhi = sqrt(1.0 - sinPhi * sinPhi);
	return normalize(cosPhi * N + sinPhi * cross(cross(N, L), N));
}

float Band(float val, float steps) {

	val = floor(val * steps);
	return val / steps;
}

float3 BRDFBasic(Gbuffer buffer, Light light) {

	Material material = materialBuffer[floor(buffer.shader.r + 0.5)];

	float3 L = normalize(-light.position); //normalize(lightPositions[i] - WorldPos);
	float3 N = normalize(buffer.normal.xyz);
	N = WrapNormal(N, L, 1);

	float3 V = normalize(_WorldSpaceCameraPos - buffer.world.xyz);
	float3 H = normalize(V + L);
	
	float NdotL = saturate(dot(N, L));
	float NdotH = dot(N, H);
	float VdotH = saturate(dot(V, H));
	float NdotV = dot(N, V);
	float LdotH = dot(L, H);
	float3 F0 = 0.04;
	float NDF = DistributionGGX(N, H, material.roughness);
	float G = GeometrySmith(N, V, L, material.roughness);
	float3 F = fresnelSchlick(VdotH, F0);
	
	F0 = lerp(F0, material.color.rgb, material.metallic);
	float3 kS = F;
	float3 kD = 1.0 - kS;
	kD *= 1.0 - material.metallic;

	float3 numerator = NDF * G * F;

	float denominator = 4.0 * max(NdotV, 0.0) * max(NdotL, 0.0);
	
	float3 specular = numerator / max(denominator, 0.001);
	
	float3 Lo = (kD * material.color.rgb / PI + specular) * light.color.w * NdotL;

	
	return Lo;
}

