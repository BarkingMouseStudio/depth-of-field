Shader "Mobile/Depth of Field/Diffuse (Surface)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    CGPROGRAM
    #pragma surface surf Lambert vertex:vert keepalpha

    #include "UnityCG.cginc"
    #include "Assets/DepthOfField/Shaders/DepthCG.cginc"

    sampler2D _MainTex;

    struct Input {
      float2 uv_MainTex;
      float depth; // Define depth float to pass to `surf`
    };

    // `vert` function to calculate depth
    void vert(inout appdata_full v, out Input o) {
      // Unity helper (see UnityCG.cginc for definition)
      UNITY_INITIALIZE_OUTPUT(Input, o);

      // Calculate depth to pass to `surf`
      o.depth = CalculateDepth(v.vertex);
    }

    void surf(Input IN, inout SurfaceOutput o) {
      o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;

      // Place `vert` depth calculation into alpha channel
      o.Alpha = IN.depth;
    }
    ENDCG
  }
}
