using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PMP.PostProcess.SelfOverlay {
    [Serializable]
    public class SelfOverlayRenderFeature : ScriptableRendererFeature {

        // ブラー用のシェーダー
        [SerializeField] Shader blurShader;
        // オーバーレイ用のシェーダー
        [SerializeField] Shader overlayShader;
        // SceneView に適応するか
        [SerializeField] bool applyToSceneView = true;
        // ScriptableRenderPass
        SelfOverlayRenderPass pass;

        public override void Create() {
            pass = new SelfOverlayRenderPass(applyToSceneView, blurShader, overlayShader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
            renderer.EnqueuePass(pass);
        }
    }
}