Shader "Mobile/Depth of Field/Diffuse Excluded (Surface)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    CGPROGRAM
    #pragma surface surf Lambert keepalpha

    #include "UnityCG.cginc"
    #include "Assets/DepthOfField/Shaders/DepthCG.cginc"

    sampler2D _MainTex;

    struct Input {
      float2 uv_MainTex;
      float depth; // Define depth float to pass to `surf`
    };

    void surf(Input IN, inout SurfaceOutput o) {
      o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;

      // Place `vert` depth calculation into alpha channel
      o.Alpha = -1.0f;
    }
    ENDCG
  }
}
