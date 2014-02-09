using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
public class PostEffectsRenderer : MonoBehaviour {
  private PostEffects post;

  void Start() {
    post = Camera.main.GetComponent<PostEffects>();
  }

  void OnPreRender() {
    if (post.enabled) {
      Graphics.Blit(post.targetTexture, null, post.material, 3);
    }
  }
}
