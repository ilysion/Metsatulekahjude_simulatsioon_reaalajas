//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.


float3 mod289(float3 x)
{
	return x - floor(x / 289.0) * 289.0;
}

float2 mod289(float2 x)
{
	return x - floor(x / 289.0) * 289.0;
}

float3 permute(float3 x)
{
	return mod289((x * 34.0 + 1.0) * x);
}

float3 taylorInvSqrt(float3 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float3 hash3(float2 i) {
	float3 p = float3(i.x, i.y, dot(i.x, i.y));
	p = float3(dot(p, float3(127.1, 311.7, 74.7)),
		dot(p, float3(269.5, 163.3, 226.1)),
		dot(p, float3(113.5, 271.9, 124.6)));

	return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float3 hash(float3 p) {
	p = float3(dot(p, float3(127.1, 311.7, 74.7)),
		dot(p, float3(269.5, 163.3, 226.1)),
		dot(p, float3(113.5, 271.9, 124.6)));

	return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float2 random2f(float2 uv) {
	float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
	return abs(noise.x + noise.y) * 0.5;
}

float simplexNoise(float2 v)
{
	const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
		0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
		-0.577350269189626,  // -1.0 + 2.0 * C.x
		0.024390243902439); // 1.0 / 41.0
							// First corner
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);

	// Other corners
	float2 i1;
	i1.x = step(x0.y, x0.x);
	i1.y = 1.0 - i1.x;

	// x1 = x0 - i1  + 1.0 * C.xx;
	// x2 = x0 - 1.0 + 2.0 * C.xx;
	float2 x1 = x0 + C.xx - i1;
	float2 x2 = x0 + C.zz;

	// Permutations
	i = mod289(i); // Avoid truncation effects in permutation
	float3 p =
		permute(permute(i.y + float3(0.0, i1.y, 1.0))
			+ i.x + float3(0.0, i1.x, 1.0));

	float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	m = m * m;
	m = m * m;

	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;

	// Normalise gradients implicitly by scaling m
	m *= taylorInvSqrt(a0 * a0 + h * h);

	// Compute final noise value at P
	float3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.y = a0.y * x1.x + h.y * x1.y;
	g.z = a0.z * x2.x + h.z * x2.y;
	return 130.0 * dot(m, g);
}

float voronoiNoise(float2 x, float u, float v)
{
	float2 p = floor(x);
	float2 f = frac(x);

	float k = 1.0 + 63.0  *pow(1.0 - v, 4.0);
	float va = 0.0;
	float wt = 0.0;
	for (int j = -2; j <= 2; j++)
		for (int i = -2; i <= 2; i++)
		{
			float2  g = float2(float(i), float(j));

			float3  o = hash3(p + g) * float3(u, u, 1.0);
			//float2  o2 = random2f(p + g) * float2(u, u)

			float2  r = g - f + o.xy;
			float d = dot(r, r);
			float w = pow(1.0 - smoothstep(0.0, 1.414, sqrt(d)), k);
			va += w*o.z;
			wt += w;
		}

	return va / wt;
}

//Source: https://www.shadertoy.com/view/Xsl3Dl
float noisePerlin(in float3 p) {
	float3 i = floor(p);
	float3 f = frac(p);

	//float3 u = f*f*(3.0-2.0*f);
	float3 u = f*f*(3.0 - 2.0*f);

	return lerp(lerp(lerp(dot(hash(i + float3(0.0, 0.0, 0.0)), f - float3(0.0, 0.0, 0.0)),
		dot(hash(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0)), u.x),
		lerp(dot(hash(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0)),
			dot(hash(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0)), u.x), u.y),
		lerp(lerp(dot(hash(i + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0)),
			dot(hash(i + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0)), u.x),
			lerp(dot(hash(i + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0)),
				dot(hash(i + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

float voronoiDistance(in float2 x)
{
	float2 p = float2(floor(x));
	float2  f = frac(x);

	float2 mb;
	float2 mr;

	float res = 8.0;
	for (int j = -1; j <= 1; j++)
		for (int i = -1; i <= 1; i++)
		{
			float2 b = float2(i, j);
			float2  r = float2(b) + random2f(p + b) - f;
			float d = dot(r, r);

			if (d < res)
			{
				res = d;
				mr = r;
				mb = b;
			}
		}
	res = 8.0;
	for (int k = -2; k <= 2; k++)
		for (int l = -2; l <= 2; l++)
		{
			float2 b = mb + float2(l, k);
			float2  r = float2(b) + random2f(p + b) - f;
			float d = dot(0.5*(mr + r), normalize(r - mr));
			res = min(res, d);
		}
	return res;
}


//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

float4 mod289(float4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float mod289(float x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
	return mod289(((x*34.0) + 1.0)*x);
}

float permute(float x) {
	return mod289(((x*34.0) + 1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float4 grad4(float j, float4 ip)
{
	const float4 ones = float4(1.0, 1.0, 1.0, -1.0);
	float4 p, s;

	p.xyz = floor(frac(float3(j, j, j) * ip.xyz) * 7.0) * ip.z - 1.0;
	p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
	//s = float4(lessThan(p, float4(0.0)));

	s = float4(
		saturate(-p.x * 10000.0),
		saturate(-p.y * 10000.0),
		saturate(-p.z * 10000.0),
		saturate(-p.w * 10000.0)
		);
	p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

	return p;
}

// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451

float simplexNoise(float4 v)
{
	const float4  C = float4(0.138196601125011,  // (5 - sqrt(5))/20  G4
		0.276393202250021,  // 2 * G4
		0.414589803375032,  // 3 * G4
		-0.447213595499958); // -1 + 4 * G4

							 // First corner
	float4 i = floor(v + dot(v, float4(F4, F4, F4, F4)));
	float4 x0 = v - i + dot(i, C.xxxx);

	// Other corners

	// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
	float4 i0;
	float3 isX = step(x0.yzw, x0.xxx);
	float3 isYZ = step(x0.zww, x0.yyz);
	//  i0.x = dot( isX, float3( 1.0 ) );
	i0.x = isX.x + isX.y + isX.z;
	i0.yzw = 1.0 - isX;
	//  i0.y += dot( isYZ.xy, float2( 1.0 ) );
	i0.y += isYZ.x + isYZ.y;
	i0.zw += 1.0 - isYZ.xy;
	i0.z += isYZ.z;
	i0.w += 1.0 - isYZ.z;

	// i0 now contains the unique values 0,1,2,3 in each channel
	float4 i3 = clamp(i0, 0.0, 1.0);
	float4 i2 = clamp(i0 - 1.0, 0.0, 1.0);
	float4 i1 = clamp(i0 - 2.0, 0.0, 1.0);

	//  x0 = x0 - 0.0 + 0.0 * C.xxxx
	//  x1 = x0 - i1  + 1.0 * C.xxxx
	//  x2 = x0 - i2  + 2.0 * C.xxxx
	//  x3 = x0 - i3  + 3.0 * C.xxxx
	//  x4 = x0 - 1.0 + 4.0 * C.xxxx
	float4 x1 = x0 - i1 + C.xxxx;
	float4 x2 = x0 - i2 + C.yyyy;
	float4 x3 = x0 - i3 + C.zzzz;
	float4 x4 = x0 + C.wwww;

	// Permutations
	i = mod289(i);
	float j0 = permute(permute(permute(permute(i.w) + i.z) + i.y) + i.x);
	float4 j1 = permute(permute(permute(permute(
		i.w + float4(i1.w, i2.w, i3.w, 1.0))
		+ i.z + float4(i1.z, i2.z, i3.z, 1.0))
		+ i.y + float4(i1.y, i2.y, i3.y, 1.0))
		+ i.x + float4(i1.x, i2.x, i3.x, 1.0));

	// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
	// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
	float4 ip = float4(1.0 / 294.0, 1.0 / 49.0, 1.0 / 7.0, 0.0);

	float4 p0 = grad4(j0, ip);
	float4 p1 = grad4(j1.x, ip);
	float4 p2 = grad4(j1.y, ip);
	float4 p3 = grad4(j1.z, ip);
	float4 p4 = grad4(j1.w, ip);

	// Normalise gradients
	float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	p4 *= taylorInvSqrt(dot(p4, p4));

	// Mix contributions from the five corners
	float3 m0 = max(0.6 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	float2 m1 = max(0.6 - float2(dot(x3, x3), dot(x4, x4)), 0.0);
	m0 = m0 * m0;
	m1 = m1 * m1;
	return 49.0 * (dot(m0*m0, float3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
		+ dot(m1*m1, float2(dot(p3, x3), dot(p4, x4))));

}


//JJ extension

#define PPI 3.1415926535898
float tilableNoise(float2 uv, float scale) {

	float dx = scale;
	float dy = scale;

	float pi2 = 2 * PPI;
	float nx = cos(uv.x * pi2) *dx / (pi2);
	float ny = cos(uv.y * pi2) *dy / (pi2);
	float nz = sin(uv.x * pi2) *dx / (pi2);
	float nw = sin(uv.y * pi2) *dy / (pi2);

	return simplexNoise(float4(nx, ny, nz, nw));
}