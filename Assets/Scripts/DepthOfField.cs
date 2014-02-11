using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthOfField : MonoBehaviour {

  public Transform focus;
  public float aperture = 1;

  [Range(2, 8)]
  public int downsampleFactor = 4;

  [HideInInspector]
  public Shader shader;

  [HideInInspector]
  public Material material;

  RenderTexture CreateTexture(int width, int height) {
    RenderTexture texture = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
    texture.wrapMode = TextureWrapMode.Clamp;
    texture.useMipMap = false;
    texture.isPowerOfTwo = true;
    texture.filterMode = FilterMode.Bilinear;
    return texture;
  }

  void Awake() {
    material = new Material(shader);
    camera.depthTextureMode = DepthTextureMode.None; // Explicitly disable depthmap
  }

  void OnRenderImage(RenderTexture src, RenderTexture dest) {
    // Initialize textures
    int captureBufferWidth = 512; // Mathf.NextPowerOfTwo(Screen.width / downsampleFactor);
    int captureBufferHeight = 256; // Mathf.NextPowerOfTwo(Screen.height / downsampleFactor);

    if (captureBufferWidth > captureBufferHeight) {
      captureBufferHeight = captureBufferWidth;
    } else {
      captureBufferWidth = captureBufferHeight;
    }

    RenderTexture grabTextureA = CreateTexture(captureBufferWidth, captureBufferHeight);
    material.SetTexture("_CaptureTex", grabTextureA);

    RenderTexture grabTextureB = CreateTexture(captureBufferWidth / 2, captureBufferHeight / 2);
    material.SetTexture("_GrabTextureB", grabTextureB);

    RenderTexture grabTextureC = CreateTexture(captureBufferWidth / 4, captureBufferHeight / 4);
    material.SetTexture("_GrabTextureC", grabTextureC);

    RenderTexture grabTextureD = CreateTexture(captureBufferWidth / 2, captureBufferHeight / 2);
    material.SetTexture("_GrabTextureD", grabTextureD);

    // Setup material variables
    Shader.SetGlobalFloat("_DepthFar", Vector3.Distance(transform.position, focus.position));
    Shader.SetGlobalFloat("_DepthAperture", aperture);

    // Blit textures
    grabTextureA.DiscardContents();
    Graphics.Blit(src, grabTextureA, material, 1); // First downsample

    grabTextureB.DiscardContents();
    Graphics.Blit(grabTextureA, grabTextureB, material, 1); // Second downsample

    grabTextureC.DiscardContents();
    Graphics.Blit(grabTextureB, grabTextureC, material, 1); // Third downsample

    grabTextureD.DiscardContents();
    Graphics.Blit(null, grabTextureD, material, 0);

    Graphics.Blit(src, dest, material, 2);

    // Cleanup
    RenderTexture.ReleaseTemporary(grabTextureA);
    RenderTexture.ReleaseTemporary(grabTextureB);
    RenderTexture.ReleaseTemporary(grabTextureC);
    RenderTexture.ReleaseTemporary(grabTextureD);
  }
}
