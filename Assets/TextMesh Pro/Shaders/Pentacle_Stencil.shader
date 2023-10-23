Shader "Custom/Pentacle_Stencil"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _GlowSpeed("Glow Speed", Range(0, 10)) = 10
        _GlowAdd("Glow Add", Range(0, 0.5)) = 0.1
        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        
        // Stencil
        _ID("Mask ID", Int) = 1
    }
    SubShader
    {
        Stencil {
			Ref [_ID]
			Comp equal
		}
        
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+2"} // Important queue
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        half4 _EmissionColor;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _GlowSpeed;
        half _GlowAdd;
        
        struct Input
        {
            float2 uv_MainTex;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            half glow = sin(_Time.y * _GlowSpeed) * _GlowAdd + _GlowAdd;
            o.Emission = c.rgb * tex2D(_MainTex, IN.uv_MainTex).a * _EmissionColor + glow;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
