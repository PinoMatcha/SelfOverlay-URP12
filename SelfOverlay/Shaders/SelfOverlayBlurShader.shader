Shader "Hidden/PMP/SelfOverlayBlur"
{
    Properties
    { 
        _MainTex ("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform half4 _MainTex_TexelSize;

            uniform half _BlurSize;

            static const int BLUR_SAMPLE_COUNT = 8;
            static const float2 BLUR_KERNEL[BLUR_SAMPLE_COUNT] = {
                float2(-1.0, -1.0),
                float2(-1.0, 1.0),
                float2(1.0, -1.0),
                float2(1.0, 1.0),
                float2(-0.70711, 0),
                float2(0, 0.70711),
                float2(0.70711, 0),
                float2(0, -0.70711),
            };

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS  : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float2 scale = _BlurSize / 1000;
                scale.y *= _MainTex_TexelSize.y / _MainTex_TexelSize.x;

                half4 color = 0;
                for (int j = 0; j < BLUR_SAMPLE_COUNT; j++) {
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + BLUR_KERNEL[j] * scale);
                }
                color.rgb /= BLUR_SAMPLE_COUNT;
                color.a = 1;

                return color;
            }
            ENDHLSL
        }
    }
}
