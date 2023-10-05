// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Legacy Shaders/Particles/Fire" {
    Properties {
        _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("Particle Texture", 2D) = "white" {}
        _DistortTex ("Distortion Texture", 2D) = "white" {}
        _ShapeTex("Shape Texture", 2D) = "white" {}
        _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
        _SpeedX("Speed X", Range(-2,2)) = 1.0
        _SpeedY("Speed Y", Range(-2,2)) = 1.0
        _Gradient("Gradient Texture", 2D) = "white" {}
        _Stretch("Stretch", Range(-2,10)) = 1.0
        _Distortion("Distortion", Range(-2,10)) = 1.0
        _Intensity("INtensity", Range(-2,10)) = 1.0
        _Offset("Offset", Range(-2,10)) = 1.0
        // _Slider("Slider Shape", Range(-2,10)) = 1.0
        _StretchShape("Stretch Shape", Range(-1,4)) = 1.0
        
        _Fade("Fade", Range(0,1)) = 1.0
        _Fade2("Fade2", Range(0,1)) = 1.0
    }

    Category {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Blend One OneMinusSrcAlpha
        ColorMask RGB
        Cull Off Lighting Off ZWrite Off

        SubShader {
            Pass {

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0
                #pragma multi_compile_particles
                #pragma multi_compile_fog

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                fixed4 _TintColor;

                struct appdata_t {
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                    float4 texcoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f {
                    float4 vertex : SV_POSITION;
                    fixed4 color : COLOR;
                    float4 texcoord : TEXCOORD0;
                    float2 texcoord2 : TEXCOORD3;
                    UNITY_FOG_COORDS(1)
                    #ifdef SOFTPARTICLES_ON
                        float4 projPos : TEXCOORD2;
                    #endif
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                float4 _MainTex_ST;
                float4 _ShapeTex_ST;

                v2f vert (appdata_t v)
                {
                    v2f o;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    #ifdef SOFTPARTICLES_ON
                        o.projPos = ComputeScreenPos (o.vertex);
                        COMPUTE_EYEDEPTH(o.projPos.z);
                    #endif
                    o.color = v.color * _TintColor;
                    o.texcoord.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.texcoord.z = v.texcoord.z;
                    o.texcoord2 = TRANSFORM_TEX(v.texcoord,_ShapeTex);
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    return o;
                }

                UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
                float _InvFade;
                float _SpeedX, _SpeedY;
                sampler2D _ShapeTex,_DistortTex;
                sampler2D _Gradient;
                float _Slider;
                float _Stretch;
                float _Distortion;
                float _Intensity,_Offset;
                float _Fade,_Fade2;
                float _StretchShape;
                

                fixed4 frag (v2f i) : SV_Target
                {
                    #ifdef SOFTPARTICLES_ON
                        float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                        float partZ = i.projPos.z;
                        float fade = saturate (_InvFade * (sceneZ-partZ));
                        i.color.a *= fade;
                    #endif

                    float particleLifeTime = 1- i.texcoord.z;
                    float2 movingUV = float2(i.texcoord.x + (_Time.x * _SpeedX), i.texcoord.y + (_Time.x * _SpeedY));
                    fixed4 dist =  tex2D(_DistortTex, movingUV);
                    fixed4 col =  tex2D(_MainTex, movingUV);
                    fixed shapeTex = tex2D(_ShapeTex, i.texcoord2);
                    float gradientfalloff =   smoothstep(0.99, _Fade, i.texcoord2.y) * smoothstep(0.99, _Fade2,1- i.texcoord2.y);
                    // col = (col *dist) ;
                    // col *= i.color;
                    // col *= i.color.a;
                    // col *= gradientfalloff;
                    // col *= shapeTex;
                    float4 final = lerp(shapeTex, 0, col);
                    
                    //  final = step(_Distortion, final);
                    // float4 gradientmap = tex2D(_Gradient, (final * _Stretch) + _Offset)*  final.a; //* _Intensity ;
                    // // gradientmap *= col.a; // alpha should not have double-brightness applied to it, but we can't fix that legacy behavior without breaking everyone's effects, so instead clamp the output to get sensible HDR behavior (case 967476)
                    // //   gradientmap *= 
                    // clip(gradientmap.a - 0.01);
                    // // gradientmap *= _TintColor * _Intensity;
                    // // gradientmap.a = saturate(gradientmap.a);
                    // gradientmap = smoothstep(_Distortion, _Distortion + 0.1, gradientmap);

                    final.rgb *= _TintColor * _Intensity;
                    //gradientmap *= gradientMap.a;
                    UNITY_APPLY_FOG(i.fogCoord, final);
                    //return float4(particleLifeTime,particleLifeTime,particleLifeTime,1);
                    return saturate(final);
                }
                ENDCG
            }
        }
    }
}