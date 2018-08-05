using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthOfField : MonoBehaviour {

  public Transform focus;
  public float focalDistance = 10.0f;
  public float aperture = 3;
  public bool debug = false;

  [Range(2, 8)]
  public int downsampleFactor = 4;

  [HideInInspector]
  public Shader shader;

  [HideInInspector]
  public Material material;

  private RenderTexture GetTemporaryTexture(int width, int height) {
    RenderTexture temporaryTexture = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
    temporaryTexture.wrapMode = TextureWrapMode.Clamp;
    // temporaryTexture.useMipMap = false;
    temporaryTexture.isPowerOfTwo = true;
    temporaryTexture.filterMode = FilterMode.Bilinear;
    return temporaryTexture;
  }

  void Awake() {
    GetComponent<Camera>().depthTextureMode = DepthTextureMode.None; // Explicitly disable depthmap
  }

  void OnRenderImage(RenderTexture src, RenderTexture dest) {
    if (shader == null) {
      shader = Shader.Find("Post Effects/Depth of Field (Mobile)");
    }

    if (material == null) {
      material = new Material(shader);
    }

    // Set depth of field variables
    if (focus != null) {
      Shader.SetGlobalFloat("_DepthFar", Vector3.Distance(transform.position, focus.position));
    } else {
      Shader.SetGlobalFloat("_DepthFar", focalDistance);
    }
    Shader.SetGlobalFloat("_DepthAperture", aperture);

    if (debug) {
      Graphics.Blit(src, dest, material, 5); // Render depth from alpha
      return;
    }

    int scale = Screen.dpi >= 220 ? 2 : 1; // Multiply downsampleFactor by scale to compensate for retina

    int temporaryWidth = Mathf.NextPowerOfTwo(Screen.width / (downsampleFactor * scale));
    int temporaryHeight = Mathf.NextPowerOfTwo(Screen.height / (downsampleFactor * scale));
    if (temporaryWidth > temporaryHeight) {
      temporaryHeight = temporaryWidth;
    } else {
      temporaryWidth = temporaryHeight;
    }

    // Create temporary textures
    var grabTextureA = GetTemporaryTexture(temporaryWidth, temporaryHeight);
    var grabTextureB = GetTemporaryTexture(temporaryWidth / 2, temporaryHeight / 2);
    var grabTextureC = GetTemporaryTexture(temporaryWidth / 4, temporaryHeight / 4);
    var grabTextureD = GetTemporaryTexture(temporaryWidth / 2, temporaryHeight / 2);

    // Pass in textures
    material.SetTexture("_GrabTextureB", grabTextureB);
    material.SetTexture("_GrabTextureC", grabTextureC);
    material.SetTexture("_GrabTextureD", grabTextureD);

    Graphics.Blit(src, grabTextureA, material, 0); // Downsample 1
    Graphics.Blit(grabTextureA, grabTextureB, material, 1); // Downsample 2
    Graphics.Blit(grabTextureB, grabTextureC, material, 1); // Upsample
    Graphics.Blit(null, grabTextureD, material, 2); // Blend midground and background
    Graphics.Blit(src, dest, material, 3); // Blend foreground and background

    // Release textures
    RenderTexture.ReleaseTemporary(grabTextureA);
    RenderTexture.ReleaseTemporary(grabTextureB);
    RenderTexture.ReleaseTemporary(grabTextureC);
    RenderTexture.ReleaseTemporary(grabTextureD);
  }
}
