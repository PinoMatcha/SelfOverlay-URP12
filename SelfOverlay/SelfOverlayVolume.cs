using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace PMP.PostProcess.SelfOverlay {
    [Serializable]
    [VolumeComponentMenu("Post-processing/PM Presents/SelfOverlay")]
#if UNITY_EDITOR
    [UnityEditor.CanEditMultipleObjects]
#endif
    public class SelfOverlayVolume : VolumeComponent, IPostProcessComponent {

        public ClampedFloatParameter blurSize = new ClampedFloatParameter(0.0f, 0.0f, 20f);

        public ClampedFloatParameter brightness = new ClampedFloatParameter(0.8f, 0.0f, 1.0f);
        public ClampedFloatParameter correction = new ClampedFloatParameter(0.8f, 0.0f, 1.0f);
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

        public bool IsActive() => intensity.value > 0f;

        public bool IsTileCompatible() => false;
    }
}