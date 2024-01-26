Shader "Hidden/PMP/SelfSoftOverlay"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        
        _Brightness("Brightness", float) = 0.1
        _Correction("Correnction", float) = 0.8
        _Intensity("Intensity", float) = 0.75
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            Name "SelfSoftOverlay"

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D(_BaseTex);
            SAMPLER(sampler_BaseTex);
            
            float _Brightness;
            float _Correction;
            float _Intensity;

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                // Returning the output.
                return OUT;
            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                float4 Color;		// 処理後のピクセルカラーを格納
                float4 ColorOrg;	// 処理前のピクセルカラーを格納

                float4 Overlay = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                Color = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, IN.uv);
                ColorOrg = Color;

                //　ボカしたオーバーレイ合成レイヤーの明度調整
                float bright = _Correction * _Brightness;

                Overlay.rgb *= bright;

                //　オーバーレイ合成
                // http://www.cg-ya.net/2dcg/aboutimage/composite-is-math/
                Color.rgb = Color.rgb < 0.5 ? 2.0 * Color.rgb * Overlay.rgb : 1.0 - 2.0 * (1.0 - Color.rgb) * (1.0 - Overlay.rgb);

                //　アクセサリの不透明度を元にオリジナルと合成
                Color.rgb = lerp(ColorOrg.rgb, Color.rgb, _Intensity);
                
                return Color;
            }
            ENDHLSL
        }
    }
}