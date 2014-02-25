Shader "Mobile/Depth of Field/Diffuse (VertFrag)" {
  Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
  }

  SubShader {
    Tags { "RenderType"="Opaque" }

    Pass {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag

      #include "UnityCG.cginc"
      #include "Lighting.cginc"
      #include "Assets/DepthOfField/Shaders/DepthCG.cginc"

      struct v2f {
        float4 position : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 lighting : COLOR0;
        float depth : TEXCOORD2; // Define depth float to pass to `frag`
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;

      v2f vert(appdata_base i) {
        v2f o;
        o.position = mul(UNITY_MATRIX_MVP, i.vertex);
        o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);

        // Calculate depth and place in output
        o.depth = CalculateDepth(i.vertex);

        // Simple Lambert lighting
        float3 normalDirection = normalize(float3(mul(float4(i.normal, 0.0), _World2Object)));
        float3 lightDirection = normalize(float3(_WorldSpaceLightPos0));
        float3 diffuseReflection = float3(_LightColor0) * (max(0.0, dot(normalDirection, lightDirection)) * 2.0);
        o.lighting = float4(diffuseReflection, 1.0) + UNITY_LIGHTMODEL_AMBIENT;

        return o;
      }

      half4 frag(v2f i) : COLOR {
        half4 main_color = tex2D(_MainTex, i.uv) * i.lighting;

        // Place `vert` depth calculation into alpha channel
        main_color.a = i.depth;
        return main_color;
      }
      ENDCG
    }
  }
}
