using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PMP.PostProcess.SelfOverlay {
    public class SelfOverlayRenderPass : ScriptableRenderPass {

        private const string RenderPassName = nameof(SelfOverlayRenderPass);

        private readonly bool applyToSceneView;
        private readonly Material blurMaterial;
        private readonly Material overlayMaterial;

        RenderTargetIdentifier source;

        private SelfOverlayVolume volume;

        public SelfOverlayRenderPass(bool applyToSceneView, Shader blurShader, Shader overlayShader) {
            // シェーダーがない場合は何もしない
            if (blurShader == null || overlayShader == null)
                return;

            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

            this.applyToSceneView = applyToSceneView;

            // マテリアルを作成
            this.blurMaterial = CoreUtils.CreateEngineMaterial(blurShader);
            this.overlayMaterial = CoreUtils.CreateEngineMaterial(overlayShader);

            // RenderPassEvent.AfterRenderingではポストエフェクトを掛けた後のカラーテクスチャがこの名前で取得できる
            //_afterPostProcessTexture.Init("_AfterPostProcessTexture");
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {
            // RenderTextureDescriptorの取得
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            // 深度は使わないので0に
            descriptor.depthBufferBits = 0;

            var renderer = renderingData.cameraData.renderer;
            source = renderer.cameraColorTarget;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
            // マテリアルがない場合は何もしない
            if (blurMaterial == null || overlayMaterial == null)
                return;

            // カメラのポストプロセス設定が無効になっていたら何もしない
            if (!renderingData.cameraData.postProcessEnabled)
                return;

            // カメラがシーンビューカメラかつシーンビューに適用しない場合には何もしない
            if (!applyToSceneView && renderingData.cameraData.cameraType == CameraType.SceneView)
                return;

            // renderPassEventがAfterRenderingの場合、カメラのカラーターゲットではなく_AfterPostProcessTextureを使う
            /*var source = renderPassEvent == RenderPassEvent.AfterRendering && renderingData.cameraData.resolveFinalTarget
                ? _afterPostProcessTexture.Identifier()
                : _cameraColorTarget;*/

            // コマンドバッファを作成
            var cmd = CommandBufferPool.Get(RenderPassName);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            // Volumeコンポーネントを取得
            if (!volume) volume = VolumeManager.instance.stack.GetComponent<SelfOverlayVolume>();

            // Volumeがない場合はエラーreturn
            if (!volume) {
                Debug.LogError("Volume is null");
                return;
            }

            using (new ProfilingScope(cmd, profilingSampler)) {
                if (volume.IsActive()) {
                    // フルサイズのTempRT
                    var tempSrc = RenderTexture.GetTemporary(Screen.width, Screen.height, 0);
                    // source を書き込み
                    Blit(cmd, source, tempSrc);

                    // ブラーを適応するか
                    float blurSize = volume.active ? volume.blurSize.value : 0.0f;
                    if (blurSize > 0) {
                        // ブラーサイズを設定
                        blurMaterial.SetFloat(Shader.PropertyToID("_BlurSize"), volume.blurSize.value);

                        // 縮小バッファを用意
                        // 1/4、1/8
                        var bufferA = RenderTexture.GetTemporary(Screen.width / 4, Screen.height / 4, 0);
                        var bufferB = RenderTexture.GetTemporary(Screen.width / 8, Screen.height / 8, 0);

                        // 縮小バッファを使ってぼかし処理
                        Blit(cmd, tempSrc, bufferA, blurMaterial);
                        Blit(cmd, bufferA, bufferB, blurMaterial);
                        Blit(cmd, bufferB, source, blurMaterial);

                        RenderTexture.ReleaseTemporary(bufferA);
                        RenderTexture.ReleaseTemporary(bufferB);
                    }

                    // オーバーレイ用のプロパティを設定
                    overlayMaterial.SetTexture(Shader.PropertyToID("_BaseTex"), tempSrc);
                    overlayMaterial.SetFloat(Shader.PropertyToID("_Brightness"), volume.brightness.value);
                    overlayMaterial.SetFloat(Shader.PropertyToID("_Correction"), volume.correction.value);
                    overlayMaterial.SetFloat(Shader.PropertyToID("_Intensity"), volume.intensity.value);

                    // オーバーレイ適応
                    Blit(cmd, ref renderingData, overlayMaterial);

                    RenderTexture.ReleaseTemporary(tempSrc);
                }

                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd) {

        }
    }
}