Shader "Hidden/PMP/SelfOverlayBlur"
{
    // Unity シェーダーのプロパティブロック。この例では出力の色がフラグメントシェーダーの
    // コード内に事前定義されているため、このブロックは空です。
    Properties
    { 
        _MainTex ("Main Texture", 2D) = "white" {}
    }

    // シェーダーのコードが含まれる SubShader ブロック。
    SubShader
    {
        // SubShader Tags では SubShader ブロックまたはパスが実行されるタイミングと条件を
        // 定義します。
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // HLSL コードブロック。Unity SRP では HLSL 言語を使用します。
            HLSLPROGRAM
            // この行では頂点シェーダーの名前を定義します。
            #pragma vertex vert
            // この行ではフラグメントシェーダーの名前を定義します。
            #pragma fragment frag

            // Core.hlsl ファイルには、よく使用される HLSL マクロおよび関数の
            // 定義が含まれ、その他の HLSL ファイル (Common.hlsl、
            // SpaceTransforms.hlsl など) への #include 参照も含まれています。
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

            // この構造体定義では構造体に含まれる変数を定義します。
            // この例では Attributes 構造体を頂点シェーダーの入力構造体として
            // 使用しています。
            struct Attributes
            {
                // positionOS 変数にはオブジェクト空間内での頂点位置が
                // 含まれます。
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                // この構造体内の位置には SV_POSITION セマンティクスが必要です。
                float4 positionHCS  : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Varyings 構造体内に定義されたプロパティを含む頂点シェーダーの
            // 定義。vert 関数の型は戻り値の型 (構造体) に一致させる
            // 必要があります。
            Varyings vert(Attributes IN)
            {
                // Varyings 構造体での出力オブジェクト (OUT) の宣言。
                Varyings OUT;
                // TransformObjectToHClip 関数は頂点位置をオブジェクト空間から
                // 同種のクリップスペースに変換します。
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                // 出力を返します。
                return OUT;
            }

            // フラグメントシェーダーの定義。
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