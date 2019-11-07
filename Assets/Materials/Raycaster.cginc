
struct Ray
{
	float3 origin;
	float3 dir;
};

struct Tri
{
	int type;
	int materialId; //materialindex
	int objectId;
	float3 a;
	float3 b;
	float3 c;
};

struct Hit
{
	bool valid;
	float t;
	float3 pos;
	float3 normal;
	int materialId; //materialindex
	int objectId;
};

struct Plane
{
	Tri t0;
	Tri t1;
};

struct Sphere {
	float3 c;
	float r;
};

struct Bvh {
	int refCount;
	float4 ref0;
	float4 ref1;
	float4 ref2;
	float4 ref3;
	float4 ref4;
};

StructuredBuffer<Tri> objectBuffer;
int objectBuffer_Count;

Hit RaycastTri(Ray ray, Tri tri)
{
	Hit hit;
	hit.valid = false;
	hit.materialId = tri.materialId;
	hit.objectId = tri.objectId;

	float EPSILON = 0.00001;
	float3 vertex0 = tri.a;
	float3 vertex1 = tri.b;
	float3 vertex2 = tri.c;

	float3 edge1, edge2, h, s, q;
	float a, f, u, v;
	edge1 = vertex1 - vertex0;
	edge2 = vertex2 - vertex0;
	h = cross(ray.dir, edge2);
	hit.normal = normalize(cross(edge1, edge2));
	a = dot(edge1, h);
	if (abs(a) < EPSILON)
	{
		return hit;    // This ray is parallel to this triangle.
	}

	f = 1.0 / a;
	s = ray.origin - vertex0;
	u = f * dot(s, h);
	if (u < 0.0 || u > 1.0) {
		return hit;
	}

	q = cross(s, edge1);
	v = f * dot(ray.dir, q);
	if (v < 0.0 || u + v > 1.0)
	{
		return hit;
	}

	// At this stage we can compute t to find out where the intersection point is on the line.
	float t = f * dot(edge2, q);
	if (t > EPSILON && t < 1 / EPSILON) // ray intersection
	{
		hit.valid = true;
		hit.pos = ray.origin + ray.dir * t;
		hit.t = t;
	
		return hit;
	}
	else // This means that there is a line intersection but not a ray intersection.
		return hit;
}

Hit RaycastSphere(Ray r, Sphere s) {

	Hit hit;
	hit.materialId = -1;
	hit.objectId = -1;
	hit.valid = false;
	float3 p = r.origin;
	float3 d = r.dir;

	float3 m = p - s.c;
	float b = dot(m, d);
	float c = dot(m, m) - s.r * s.r;

	// Exit if r’s origin outside s (c > 0) and r pointing away from s (b > 0) 
	if (c > 0.0 && b > 0.0) return hit;
	float discr = b*b - c;

	// A negative discriminant corresponds to ray missing sphere 
	if (discr < 0.0) return hit;

	// Ray now found to intersect sphere, compute smallest t value of intersection
	float t = -b - sqrt(discr);

	// If t is negative, ray started inside sphere so clamp t to zero 
	if (t < 0) t = -t;

	hit.valid = true;
	hit.t = t;
	hit.pos = p + t * d;
	hit.normal = normalize(hit.pos - s.c);

	return hit;
	
}
