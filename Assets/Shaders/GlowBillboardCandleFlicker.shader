Shader "Mobile/Glow Vertical Billboard Candle Flicker"
{
    Properties
    {
        [NoScaleOffset]
		_MainTex ("Glow Texture (B/W)", 2D) = "white" {}
		_ZOffset ("Z Offset", Range(-0.2, 0.2)) = -0.1
        _BloomBillboardIntensity("Intensity", Range(0,1)) = 1
    	_FlickerSpeed("Flicker Speed", Range(0, 5)) = 1
    	_MaxBrightnessAdd("Max Brightness Add", Range(0, 1)) = 0.5
    	_MinBrightnessAdd("Min Brightness Add", Range(-1, 1)) = 0
        [HDR]_Tint("Tint", Color) = (1, 1, 1, 1)
    	
    	// Stencil
    	_ID("Mask ID", Int) = 1
    }
 
    SubShader
  	{
  		Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector" = "True" "DisableBatching" = "True"}
  		Pass
  		{
	        Stencil
  			{
				Ref[_ID]
				Comp equal
	        }
  			
  			// Blend SrcAlpha OneMinusSrcAlpha
  		    Blend One One
  			Cull Off Lighting Off ZWrite Off 

            CGPROGRAM
  			#pragma vertex vert
  			#pragma fragment frag

  			#include "UnityCG.cginc"

            // Simplex noise
			float wglnoise_mod289(float x)
			{
			    return x - floor(x / 289) * 289;
			}
            float3 wglnoise_permute(float3 x)
			{
			    return wglnoise_mod289((x * 34 + 1) * x);
			}

			float4 wglnoise_permute(float4 x)
			{
			    return wglnoise_mod289((x * 34 + 1) * x);
			}

            float3 SimplexNoiseGrad(float2 v)
			{
			    const float C1 = (3 - sqrt(3)) / 6;
			    const float C2 = (sqrt(3) - 1) / 2;

			    // First corner
			    float2 i  = floor(v + dot(v, C2));
			    float2 x0 = v -   i + dot(i, C1);

			    // Other corners
			    float2 i1 = x0.x > x0.y ? float2(1, 0) : float2(0, 1);
			    float2 x1 = x0 + C1 - i1;
			    float2 x2 = x0 + C1 * 2 - 1;

			    // Permutations
			    i = wglnoise_mod289(i); // Avoid truncation effects in permutation
			    float3 p = wglnoise_permute(    i.y + float3(0, i1.y, 1));
			           p = wglnoise_permute(p + i.x + float3(0, i1.x, 1));

			    // Gradients: 41 points uniformly over a unit circle.
			    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
			    float3 phi = p / 41 * 3.14159265359 * 2;
			    float2 g0 = float2(cos(phi.x), sin(phi.x));
			    float2 g1 = float2(cos(phi.y), sin(phi.y));
			    float2 g2 = float2(cos(phi.z), sin(phi.z));

			    // Compute noise and gradient at P
			    float3 m  = float3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
			    float3 px = float3(dot(g0, x0), dot(g1, x1), dot(g2, x2));

			    m = max(0.5 - m, 0);
			    float3 m3 = m * m * m;
			    float3 m4 = m * m3;

			    float3 temp = -8 * m3 * px;
			    float2 grad = m4.x * g0 + temp.x * x0 +
			                  m4.y * g1 + temp.y * x1 +
			                  m4.z * g2 + temp.z * x2;

			    return 99.2 * float3(grad, dot(m4, px));
			}

			float SimplexNoise(float2 v)
			{
			    return SimplexNoiseGrad(v).z;
			}

  			struct VertexInput
  			{
  				half4	vertex		: POSITION;
                float2	texcoord0	: TEXCOORD0;
  			};

  			struct VertexOutput
  			{
  				half4	pos		: SV_POSITION;
  				float2	uv		: TEXCOORD0;
  			};

  			sampler2D		_MainTex;
  			uniform float	_ZOffset;
  			uniform float _BloomBillboardIntensity;
  			uniform half4 _Tint;
            uniform half _FlickerSpeed;
            uniform half _MinBrightnessAdd;
            uniform half _MaxBrightnessAdd;

  			VertexOutput vert (VertexInput v)
  			{
  				VertexOutput o;

				#if defined(USING_STEREO_MATRICES)
					float3 cameraPos = lerp(unity_StereoWorldSpaceCameraPos[0], unity_StereoWorldSpaceCameraPos[1], 0.5);
				#else
					float3 cameraPos = _WorldSpaceCameraPos;
				#endif

  				// Vertical billboard
				float3 forward = normalize(cameraPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz);
				float3 right = cross(forward, float3(0, 1, 0));
				float yawCamera = atan2(right.x, forward.x) - UNITY_PI / 2;//Add 90 for quads to face towards camera
				float s, c;
				sincos(yawCamera, s, c);

				float3x3 transposed = transpose((float3x3)unity_ObjectToWorld);
				float3 scale = float3(length(transposed[0]), length(transposed[1]), length(transposed[2]));

				float3x3 newBasis = float3x3(
					float3(c * scale.x, 0, s * scale.z),
					float3(0, scale.y, 0),
					float3(-s * scale.x, 0, c * scale.z)
					);//Rotate yaw to point towards camera, and scale by transform.scale

				float4x4 objectToWorld = unity_ObjectToWorld;
				//Overwrite basis vectors so the object rotation isn't taken into account
				objectToWorld[0].xyz = newBasis[0];
				objectToWorld[1].xyz = newBasis[1];
				objectToWorld[2].xyz = newBasis[2];
				//Now just normal MVP multiply, but with the new objectToWorld injected in place of matrix M
				o.pos = mul(UNITY_MATRIX_VP, mul(objectToWorld, v.vertex));
				o.uv = v.texcoord0;
				return o;
  			}

  			half4 frag (VertexOutput i) : COLOR
  			{
  				float noise = clamp(SimplexNoise(_Time.y * _FlickerSpeed), _MinBrightnessAdd, _MaxBrightnessAdd);
  				_BloomBillboardIntensity += noise;
  				return tex2D (_MainTex, i.uv) * _Tint * _BloomBillboardIntensity;
            }
            
            ENDCG
          }
      }
      FallBack "Diffuse"
  }