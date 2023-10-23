Shader "Mobile/Bloom Vertical Billboard - Mobile Optimized"
{
    Properties
    {
        [NoScaleOffset]
		_MainTex ("Glow Texture (B/W)", 2D) = "white" {}
		_ZOffset ("Z Offset", Range(-0.2, 0.2)) = -0.1
        _BloomBillboardIntensity("Intensity", Range(0,1)) = 1
        [HDR]_Tint("Tint", Color) = (1, 1, 1, 1)
    }
 
  	SubShader
  	{
  		Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector" = "True" "DisableBatching" = "True"}
  		Pass
  		{
  			// Blend SrcAlpha OneMinusSrcAlpha
  		    Blend One One
  			Cull Off Lighting Off ZWrite Off 

  			CGPROGRAM
  			#pragma vertex vert
  			#pragma fragment frag

  			#include "UnityCG.cginc"

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
  				return tex2D (_MainTex, i.uv) * _Tint * _BloomBillboardIntensity;
            }
             
            ENDCG
          }
      }
      FallBack "Diffuse"
  }