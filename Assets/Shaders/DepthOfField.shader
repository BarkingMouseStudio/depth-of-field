Shader "Post Effects/Depth of Field" {
  Properties {
    _MainTex ("Dont use this, Used by code", 2D) = "white" {}
    _BlurTexA ("Dont use this, Used by code", 2D) = "white" {}
    _BlurTexB ("Dont use this, Used by code", 2D) = "white" {}
  }

  SubShader {
    Pass { // Pass 0 - Blend between midground and background
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off
      CGPROGRAM
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest

      #include "UnityCG.cginc"

      uniform sampler2D _BlurTexA;
      uniform sampler2D _BlurTexB;

      half4 frag(v2f_img i) : COLOR {
        half4 blurA = tex2D(_BlurTexA, i.uv);
        half4 blurB = tex2D(_BlurTexB, i.uv);
        return lerp(blurA, blurB, min(blurB.a, blurA.a));
      }
      ENDCG
    }

    Pass { // Pass 1 - Blur (small kernel)
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest

      #include "UnityCG.cginc"

      uniform sampler2D _MainTex;
      uniform half4 _MainTex_TexelSize;

      struct v2f {
        half4 pos : SV_POSITION;
        half2 uv : TEXCOORD0;
        half2 uv2[4] : TEXCOORD1;
      };

      v2f vert(appdata_img v) {
        v2f o;
        o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.texcoord;
        o.uv2[0] = v.texcoord + _MainTex_TexelSize.xy * half2(1.5,1.5);
        o.uv2[1] = v.texcoord + _MainTex_TexelSize.xy * half2(-1.5,-1.5);
        o.uv2[2] = v.texcoord + _MainTex_TexelSize.xy * half2(1.5,-1.5);
        o.uv2[3] = v.texcoord + _MainTex_TexelSize.xy * half2(-1.5,1.5);
        return o;
      }

      half4 frag(v2f i) : COLOR {
        half4 color = tex2D(_MainTex, i.uv) * 0.4;
        color += tex2D(_MainTex, i.uv2[0]) * 0.15;
        color += tex2D(_MainTex, i.uv2[1]) * 0.15;
        color += tex2D(_MainTex, i.uv2[2]) * 0.15;
        color += tex2D(_MainTex, i.uv2[3]) * 0.15;
        return color;
      }
      ENDCG
    }

    Pass { // Pass 2 - Blur (large kernel)
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma exclude_renderers flash

      #include "UnityCG.cginc"

      struct v2f {
        half4 pos : POSITION;
        half2 uv : TEXCOORD0;
        half4 uv01 : TEXCOORD1;
        half4 uv23 : TEXCOORD2;
        half4 uv45 : TEXCOORD3;
        half4 uv67 : TEXCOORD4;
      };

      uniform sampler2D _MainTex;
      uniform half4 _MainTex_TexelSize;

      v2f vert(appdata_img v) {
        v2f o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv.xy = v.texcoord.xy;
        o.uv01 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(1.5, +1.5, -1.5, -1.5);
        o.uv23 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(1.5, -1.5, -1.5, +1.5);
        o.uv45 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(0.0, +2.5, -0.0, -2.5);
        o.uv67 = v.texcoord.xyxy + _MainTex_TexelSize.xyxy * half4(2.5, -0.0, -2.5, +0.0);
        return o;
      }

      half4 frag(v2f i) : COLOR {
        half4 color = 0.25 * tex2D(_MainTex, i.uv);
        color += 0.12 * tex2D(_MainTex, i.uv01.xy);
        color += 0.12 * tex2D(_MainTex, i.uv01.zw);
        color += 0.12 * tex2D(_MainTex, i.uv23.xy);
        color += 0.12 * tex2D(_MainTex, i.uv23.zw);
        color += 0.0675 * tex2D(_MainTex, i.uv45.xy);
        color += 0.0675 * tex2D(_MainTex, i.uv45.zw);
        color += 0.0675 * tex2D(_MainTex, i.uv67.xy);
        color += 0.0675 * tex2D(_MainTex, i.uv67.zw);
        return color;
      }
      ENDCG
    }

    Pass { // Pass 3 - blend between focused and blurred
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest

      #include "UnityCG.cginc"

      uniform sampler2D _MainTex;
      uniform sampler2D _BlurTexD;

      half4 frag(v2f_img i) : COLOR {
        half4 colorA = tex2D(_BlurTexD, i.uv);
        half4 colorB = tex2D(_MainTex, i.uv);
        return lerp(colorB, colorA, colorB.a);
      }
      ENDCG
    }

    Pass { // Pass 4
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest

      #include "UnityCG.cginc"

      uniform sampler2D _MainTex;
      uniform half4 _MainTex_TexelSize;

      struct v2f {
        half4 pos : SV_POSITION;
        half2 uv : TEXCOORD0;
        half2 uv2[4] : TEXCOORD1;
      };

      v2f vert(appdata_img v) {
        v2f o;
        o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.texcoord;
        o.uv2[0] = v.texcoord + _MainTex_TexelSize.xy * half2(2.5,2.5);
        o.uv2[1] = v.texcoord + _MainTex_TexelSize.xy * half2(-2.5,-2.5);
        o.uv2[2] = v.texcoord + _MainTex_TexelSize.xy * half2(2.5,-2.5);
        o.uv2[3] = v.texcoord + _MainTex_TexelSize.xy * half2(-2.5,2.5);
        return o;
      }

      half4 frag(v2f i) : COLOR {
        half4 sample = tex2D(_MainTex, i.uv) * 0.3;
        sample += tex2D(_MainTex, i.uv2[0]) * 0.175;
        sample += tex2D(_MainTex, i.uv2[1]) * 0.175;
        sample += tex2D(_MainTex, i.uv2[2]) * 0.175;
        sample += tex2D(_MainTex, i.uv2[3]) * 0.175;
        return sample;
      }
      ENDCG
    }

    Pass { // Pass 5
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma exclude_renderers d3d11 xbox360

      #include "UnityCG.cginc"

      uniform sampler2D _MainTex;
      uniform half4 _MainTex_TexelSize;
      uniform fixed _Aberration;
      uniform float _Vignetting;

      // Offset to reduce banding
      const float3 banding_offset = float3(0, 0.0013, 0.0026);

      half4 frag(v2f_img i) : COLOR {
        half2 coords = (i.uv - 0.5) * 2.0;
        half2 offset = _MainTex_TexelSize.xy * _Aberration * coords * dot(coords, coords);

        half4 color = tex2D(_MainTex, i.uv);
        color.r = tex2D(_MainTex, i.uv - (offset * 0.25)).r;
        color.b = tex2D(_MainTex, i.uv + offset).b;

        coords = i.uv - 0.5;
        color.rgb *= 1.0 - dot(coords, coords) * _Vignetting;
        color.rgb += banding_offset;
        return color;
      }
      ENDCG
    }
  }

  Fallback off
}
