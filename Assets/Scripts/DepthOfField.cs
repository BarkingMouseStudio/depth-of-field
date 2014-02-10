using UnityEngine;
using System.Collections;

// [ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthOfField : MonoBehaviour {
  protected internal RenderTexture targetTexture;

  private RenderTexture grabTextureA;
  private RenderTexture grabTextureB;
  private RenderTexture grabTextureC;
  private RenderTexture grabTextureD;

  public float aberration = 0;
  public float vignetting = 0;

  [HideInInspector]
  public Shader shader;
  protected internal Material material;
  public Transform focus;
  public float aperture = 1;

  public int captureBufferWidth = 512;
  public int captureBufferHeight = 256;

  public bool useCheap = false;

  public void Awake() {
    material = new Material(shader);

    int ajustedforSquareCaptureBufferWidth = captureBufferWidth;
    int ajustedforSquareCaptureBufferHeight = captureBufferHeight;

    targetTexture = new RenderTexture(Screen.width, Screen.height, 16, RenderTextureFormat.ARGB32);
    targetTexture.wrapMode = TextureWrapMode.Clamp;
    targetTexture.useMipMap = false;
    targetTexture.isPowerOfTwo = false;
    targetTexture.filterMode = FilterMode.Bilinear;
    targetTexture.Create();

    grabTextureD = new RenderTexture(captureBufferWidth / 2, captureBufferHeight / 2, 0, RenderTextureFormat.ARGB32);
    grabTextureD.wrapMode = TextureWrapMode.Clamp;
    grabTextureD.useMipMap = false;
    targetTexture.isPowerOfTwo = true;
    grabTextureD.filterMode = FilterMode.Bilinear;
    grabTextureD.Create();
    material.SetTexture("_BlurTexD", grabTextureD);

    grabTextureA = new RenderTexture(captureBufferWidth, captureBufferHeight, 0, RenderTextureFormat.ARGB32);
    grabTextureA.wrapMode = TextureWrapMode.Clamp;
    grabTextureA.useMipMap = false;
    targetTexture.isPowerOfTwo = true;
    grabTextureA.filterMode = FilterMode.Bilinear;
    grabTextureA.Create();
    Shader.SetGlobalTexture("_CaptureTex", grabTextureA);

    grabTextureB = new RenderTexture(ajustedforSquareCaptureBufferWidth / 2, ajustedforSquareCaptureBufferHeight / 2, 0, RenderTextureFormat.ARGB32);
    grabTextureB.wrapMode = TextureWrapMode.Clamp;
    grabTextureB.useMipMap = false;
    targetTexture.isPowerOfTwo = true;
    grabTextureB.filterMode = FilterMode.Bilinear;
    grabTextureB.Create();
    material.SetTexture("_BlurTexA", grabTextureB);

    grabTextureC = new RenderTexture(ajustedforSquareCaptureBufferWidth / 4, ajustedforSquareCaptureBufferHeight / 4, 0, RenderTextureFormat.ARGB32);
    grabTextureC.wrapMode = TextureWrapMode.Clamp;
    grabTextureC.useMipMap = false;
    targetTexture.isPowerOfTwo = true;
    grabTextureC.filterMode = FilterMode.Bilinear;
    grabTextureC.Create();
    material.SetTexture("_BlurTexB", grabTextureC);

    camera.depthTextureMode = DepthTextureMode.None; // Explicitly disable depthmap
  }

  void OnRenderImage(RenderTexture src, RenderTexture dest) {
    Shader.SetGlobalFloat("_DepthFar", Vector3.Distance(transform.position, focus.position));
    Shader.SetGlobalFloat("_DepthAperture", aperture);

    material.SetFloat("_Aberration", aberration);
    material.SetFloat("_Vignetting", vignetting);

    grabTextureA.DiscardContents();
    Graphics.Blit(src, grabTextureA, material, 5);
    grabTextureB.DiscardContents();
    Graphics.Blit(grabTextureA, grabTextureB, material, 2);
    grabTextureC.DiscardContents();
    Graphics.Blit(grabTextureB, grabTextureC, material, 2);
    grabTextureD.DiscardContents();
    Graphics.Blit(null, grabTextureD, material, 0);

    Graphics.Blit(src, null, material, 3);
  }
}
