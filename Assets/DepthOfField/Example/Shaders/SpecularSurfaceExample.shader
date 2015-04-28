Shader "Mobile/Depth of Field/Specular (Surface)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _BumpMap ("Bumpmap", 2D) = "bump" {}
    _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
    _SpecColor ("Spec Color", Color) = (1,1,1,1)
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    CGPROGRAM
    #pragma surface surf MobileBlinnPhong vertex:vert exclude_path:prepass noforwardadd halfasview keepalpha

    #include "UnityCG.cginc"
    #include "Lighting.cginc"
    #include "Assets/DepthOfField/Shaders/DepthCG.cginc"

    sampler2D _MainTex;
    sampler2D _BumpMap;
    half _Shininess;

    struct Input {
      float2 uv_MainTex;
      float2 uv_BumpMap;
      float depth; // Define depth float to pass to `surf`
    };

    inline fixed4 LightingMobileBlinnPhong_PrePass(SurfaceOutput s, half4 light) {
      fixed spec = light.a * s.Gloss;
      
      fixed4 c;
      c.rgb = (s.Albedo * light.rgb + light.rgb * _SpecColor.rgb * spec);
      c.a = s.Alpha;
      return c;
    }

    inline half4 LightingMobileBlinnPhong_DirLightmap(SurfaceOutput s, fixed4 color, fixed4 scale, half3 viewDir, bool surfFuncWritesNormal, out half3 specColor) {
      UNITY_DIRBASIS
      half3 scalePerBasisVector;
      
      half3 lm = DirLightmapDiffuse(unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector);
      
      half3 lightDir = normalize(scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
      half3 h = normalize(lightDir + viewDir);

      float nh = max(0, dot (s.Normal, h));
      float spec = pow(nh, s.Specular * 128.0);
      
      // specColor used outside in the forward path, compiled out in prepass
      specColor = lm * _SpecColor.rgb * s.Gloss * spec;
      
      // spec from the alpha component is used to calculate specular
      // in the Lighting*_Prepass function, it's not used in forward
      return half4(lm, spec);
    }

    inline fixed4 LightingMobileBlinnPhong(SurfaceOutput s, fixed3 lightDir, fixed3 halfDir, fixed atten) {
      fixed diff = max(0, dot(s.Normal, lightDir));
      fixed nh = max(0, dot(s.Normal, halfDir));
      fixed spec = pow(nh, s.Specular*128) * s.Gloss;
      
      fixed4 c;
      c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten*2);
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
      half4 color = tex2D(_MainTex, IN.uv_MainTex);
      o.Albedo = color.rgb;
      o.Gloss = color.a;
      o.Specular = _Shininess;
      o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));

      // Place `vert` depth calculation into alpha channel
      o.Alpha = IN.depth;
    }
    ENDCG
  }
}
