Shader "Mobile/Depth of Field/Specular (Surface)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _BumpMap ("Bumpmap", 2D) = "bump" {}
    _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    CGPROGRAM
    #pragma surface surf MobileBlinnPhong vertex:vert exclude_path:prepass nolightmap noforwardadd halfasview

    #include "UnityCG.cginc"
    #include "DepthCG.cginc"

    sampler2D _MainTex;
    sampler2D _BumpMap;
    half _Shininess;

    struct Input {
      float2 uv_MainTex;
      float2 uv_BumpMap;
      float depth; // Define depth float to pass to `surf`
    };

    inline fixed4 LightingMobileBlinnPhong(SurfaceOutput s, fixed3 lightDir, fixed3 halfDir, fixed atten) {
      fixed diff = max(0, dot (s.Normal, lightDir));
      fixed nh = max(0, dot (s.Normal, halfDir));
      fixed spec = pow(nh, s.Specular*128) * s.Gloss;
      
      fixed4 c;
      c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);

      // NOTE: If you're using a custom lighting model you must make sure
      // that you copy through the depth you placed in the alpha channel
      c.a = s.Alpha;

      return c;
    }

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
      o.Gloss = 1.0f;
      o.Specular = _Shininess;

      // Place `vert` depth calculation into alpha channel
      o.Alpha = IN.depth;
    }
    ENDCG
  }
}
