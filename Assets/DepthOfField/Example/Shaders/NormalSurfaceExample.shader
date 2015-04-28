Shader "Mobile/Depth of Field/Normal (Surface)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _BumpMap ("Bumpmap", 2D) = "bump" {}
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    CGPROGRAM
    #pragma surface surf Lambert vertex:vert keepalpha

    #include "UnityCG.cginc"
    #include "Assets/DepthOfField/Shaders/DepthCG.cginc"

    sampler2D _MainTex;
    sampler2D _BumpMap;

    struct Input {
      float2 uv_MainTex;
      float2 uv_BumpMap;
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
      o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));

      // Place `vert` depth calculation into alpha channel
      o.Alpha = IN.depth;
    }
    ENDCG
  }
}
