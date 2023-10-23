Shader "Custom/SparklyNightSkyStencil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StarTex ("Stars Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        [HDR]_StarColor("Star Color", Color) = (1,1,1,1)
        _SparkleSpeedX("Sparkle Speed X", Range(-1, 1)) = 1
        _SparkleSpeedY("Sparkle Speed Y", Range(-1, 1)) = 1
        
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
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _StarTex;
            float4 _StarTex_ST;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4 _Color;
            half4 _StarColor;
            half _SparkleSpeedX, _SparkleSpeedY;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
	            float2 offset = frac(_Time.y * float2(_SparkleSpeedX, _SparkleSpeedY));
	            fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex))*_Color;
                fixed4 star01 = tex2D(_StarTex, TRANSFORM_TEX(i.uv, _StarTex));
	            //fixed4 star02 = tex2D(_StarTex, TRANSFORM_TEX(i.uv, _StarTex) + i.viewDir/5);    

                fixed4 star02 = tex2D(_StarTex, TRANSFORM_TEX(i.uv, _StarTex) + i.viewDir/5 + offset);
                col.rgb += (star01.rgb * star02.rgb * _StarColor);
                // col.rgb += (star01.rgb * star02.rgb * _StarColor) * _Time.x;	
                // apply fog
	            UNITY_APPLY_FOG(i.fogCoord, col);
	            return col;
            }
            ENDCG
        }
    }
}
