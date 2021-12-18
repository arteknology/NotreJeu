// Fork of: https://www.shadertoy.com/view/4djXDy

//=====================================================

// Box occlusion (if fully visible)
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

float FastAngle (float3 v1, float3 v2)
{
	return FastACos(dot(v1,v2));
}
float3 PerpendicularAxis(float3 v1, float3 v2)
{
	return normalize(cross(v1,v2));
}

float3 OcclusionFunction(float3 n, float3 v1, float3 v2)
{
	return dot( n, PerpendicularAxis(v1,v2) ) * FastAngle( v1,v2 );
}

float boxOcclusion(float3 pos, float3 nor, float4x4 txx, float3 rad )
{
	const float3 p = mul(txx, float4(pos, 1)).xyz; // Position ?
	const float3 n = mul(txx, float4(nor, 0)).xyz; // Normal ?
    
    // Orient the hexagon based on p
	const float3 f = rad * sign(p);
    
    // Make sure the hexagon is always convex
    float3 s = sign(rad - abs(p)); // Sign // For Culling ?
    
    // 6 verts
	const float3 v0 = normalize( float3( 1, 1,-1) * f - p);
	const float3 v1 = normalize( float3( 1, s.xx) * f - p);
	const float3 v2 = normalize( float3( 1,-1, 1) * f - p);
	const float3 v3 = normalize( float3( s.zz, 1) * f - p);
	const float3 v4 = normalize( float3(-1, 1, 1) * f - p);
	const float3 v5 = normalize( float3( s.y, 1, s.y) * f - p);
    
    // 6 edges
    return abs( OcclusionFunction(n, v0,v1 ) +
    	    	OcclusionFunction(n, v1, v2 ) +
    	    	OcclusionFunction(n, v2,v3 ) +
    	    	OcclusionFunction(n, v3,v4 ) +
    	    	OcclusionFunction(n, v4,v5 ) +
    	    	OcclusionFunction(n, v5,v0 ))
            	/ 6.2831;
}

// // returns t and normal
// float4 boxIntersect( in float3 ro, in float3 rd, in float4x4 txx, in float4x4 txi, in float3 rad ) 
// {
//     // convert from ray to box space
// 	float3 rdd = (txx*float4(rd,0)).xyz;
// 	float3 roo = (txx*float4(ro,1)).xyz;
//
// 	// ray-box intersection in box space
//     float3 m = 1 / rdd;
//     float3 n = m * roo;
//     float3 k = abs(m) * rad;
// 	
//     float3 t1 = -n - k;
//     float3 t2 = -n + k;
//
// 	float tN = max( max( t1.x, t1.y ), t1.z );
// 	float tF = min( min( t2.x, t2.y ), t2.z );
// 	
// 	if( tN > tF || tF < 0) return -1; // float4(-1,-1,-1,-1)
//
// 	float3 nor = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
//
//     // convert to ray space
// 	
// 	nor = (txi * float4(nor,0)).xyz;
//
// 	return float4( tN, nor );
// }

//-----------------------------------------------------------------------------------------

float4x4 rotationAxisAngle( float3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1 - c;

    return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0,
			     0,                0,                0,                1 );
}

float4x4 translate( float3 t )
{
    return float4x4( 1, 0, 0, 0,
					 0, 1, 0, 0,
					 0, 0, 1, 0,
					 t.x, t.y, t.z, 1 );
}


float2 hash2( float n ) { return frac(sin(float2(n,n+1))*float2(43758.5453123,22578.1459123)); }

//-----------------------------------------------------------------------------------------

float iPlane( in float3 rayOrigin, in float3 rayDirection )
{
    return (-1 - rayOrigin.z) / rayDirection.z;
}

float FinalBoxOcclusion( float3 PositionWS, float3 normalWS, float3 BoxCenterPosition, float3 RotationAxis, float RotationAmount)
{
	// Maybe there is a better way to define the box without rotation and translation.
	const float4x4 rotation = rotationAxisAngle( normalize(RotationAxis), RotationAmount ); // needs to be assigned by script
	const float4x4 translation = translate(BoxCenterPosition); // Needs to be assigned by script
	const float4x4 txi = (translation * rotation);
	const float4x4 txx = Inverse( txi );
	const float3 box = float3(3, 3, 3) ; // Needs to be assigned by script
	return 1 -boxOcclusion(PositionWS, normalWS, txx, box); // confusing transformation matrices
}

float NewBoxOcclusion( float3 pos, float3 nor, float3 p, float3 n,  float3 rad ) 
{
	
	// Orient the hexagon based on p // p = center position
	float3 f = rad * sign(p);
    
	// Make sure the hexagon is always convex
	float3 s = sign(rad - abs(p));
    
	// 6 verts
	float3 v0 = normalize( float3( 1.0,-1.0, 1.0)*f - p);
	float3 v1 = normalize( float3( 1.0, s.x, s.x)*f - p);
	float3 v2 = normalize( float3( 1.0, 1.0,-1.0)*f - p);
	float3 v3 = normalize( float3( s.z, 1.0, s.z)*f - p);
	float3 v4 = normalize( float3(-1.0, 1.0, 1.0)*f - p);
	float3 v5 = normalize( float3( s.y, s.y, 1.0)*f - p);
    
	// 6 edges
	return abs( dot( n, normalize( cross(v0,v1)) ) * FastAngle(v0,v1) +
				dot( n, normalize( cross(v1,v2)) ) * FastAngle(v1,v2) +
				dot( n, normalize( cross(v2,v3)) ) * FastAngle(v2,v3) +
				dot( n, normalize( cross(v3,v4)) ) * FastAngle(v3,v4) +
				dot( n, normalize( cross(v4,v5)) ) * FastAngle(v4,v5) +
				dot( n, normalize( cross(v5,v0)) ) * FastAngle(v5,v0))
				/ 6.283185;
}

float OtherBoxOcclusion(float3 pos, float3 nor, float3 n, float3 box[8] ) 
{
	// 8 points
	const float3 v0 = normalize( box[0] );
	const float3 v1 = normalize( box[1] );
	const float3 v2 = normalize( box[2] );
	const float3 v3 = normalize( box[3] );
	const float3 v4 = normalize( box[4] );
	const float3 v5 = normalize( box[5] );
	const float3 v6 = normalize( box[6] );
	const float3 v7 = normalize( box[7] );
    
	// 12 edges    
	const float k02 = dot( n, normalize( cross(v2,v0)) ) * FastAngle(v0,v2);
	const float k23 = dot( n, normalize( cross(v3,v2)) ) * FastAngle(v2,v3);
	const float k31 = dot( n, normalize( cross(v1,v3)) ) * FastAngle(v3,v1);
	const float k10 = dot( n, normalize( cross(v0,v1)) ) * FastAngle(v1,v0);
	const float k45 = dot( n, normalize( cross(v5,v4)) ) * FastAngle(v4,v5);
	const float k57 = dot( n, normalize( cross(v7,v5)) ) * FastAngle(v5,v7);
	const float k76 = dot( n, normalize( cross(v6,v7)) ) * FastAngle(v7,v6);
	const float k37 = dot( n, normalize( cross(v7,v3)) ) * FastAngle(v3,v7);
	const float k64 = dot( n, normalize( cross(v4,v6)) ) * FastAngle(v6,v4);
	const float k51 = dot( n, normalize( cross(v1,v5)) ) * FastAngle(v5,v1);
	const float k04 = dot( n, normalize( cross(v4,v0)) ) * FastAngle(v0,v4);
	const float k62 = dot( n, normalize( cross(v2,v6)) ) * FastAngle(v6,v2);
    
	// 6 faces
	float occ = 0;
	occ += ( k02 + k23 + k31 + k10) * step( 0,  v0.z );
	occ += ( k45 + k57 + k76 + k64) * step( 0, -v4.z );
	occ += ( k51 - k31 + k37 - k57) * step( 0, -v5.x );
	occ += ( k04 - k64 + k62 - k02) * step( 0,  v0.x );
	occ += (-k76 - k37 - k23 - k62) * step( 0, -v6.y );
	occ += (-k10 - k51 - k45 - k04) * step( 0,  v0.y );
        
	return occ / 6.283185;
}



// Triangle occlusion (if fully visible)
float triOcclusion( float3 pos, float3 nor, float3 v0, float3 v1, float3 v2 )
{
	const float3 a = normalize( v0 - pos );
	const float3 b = normalize( v1 - pos );
	const float3 c = normalize( v2 - pos );

	// return pos;
	float s = sign(dot(v0-pos,cross(v1-v0,v2-v1))); // side of the triangle
	// return s;

	return s * abs(
			dot( nor, normalize( cross(a,b)) ) * FastAngle(a,b) +
			dot( nor, normalize( cross(b,c)) ) * FastAngle(b,c) +
			dot( nor, normalize( cross(c,a)) ) * FastAngle(c,a)
			) / 6.2831;
}