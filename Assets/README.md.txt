Documentation
---

### Setting up the camera

Add DepthOfField.cs to the camera you wish to apply depth of field. While you can adjust parameters at any time we recommend finishing the setup so you can preview your changes.

### Modifying your shaders

When in doubt we provide a number of example shaders in Example/Shaders/ that demonstrates a fully working surface and vertex/fragment shaders.

> NOTE: ShaderLab syntax is not supported since they do not support vertex functions.

#### Surface Shaders

0. Note that in order for Unity to find the required CG Include you should use one of the following methods:

    a. Copy DepthCG.cginc shader include next to your other shaders

    b. Use an absolute path to reference DepthCG.cginc (e.g. Assets/Absolute/Path/To/DepthCG.cginc)

    b. Use a relative path to reference DepthCG.cginc (e.g. ./Wherever/You/Put/DepthCG.cginc)

1. Add the DepthCG.cginc include just after your surface pragma. This will import the necessary helper function for calculating distance from the camera. If you already have includes, DepthCG should be first.

  ```glsl
  #pragma surface surf Lambert vertex:vert

  #include "DepthCG.cginc" // <= HERE
  ```

2. Define a new float inside your `Input`. This will be passed from `vert` to `surf`.

  ```glsl
  struct Input {
    ...

    float depth; // <= HERE
  };
  ```

3. Define a `vert` function like so (skip to step 4 if you already have one):

  ```glsl
  void vert(inout appdata_full v, out Input o) {
    UNITY_INITIALIZE_OUTPUT(Input, o); // Unity helper (see UnityCG.cginc for definition)
  }
  ```

4. Use the included helper to calculate the depth of the current vertex and add it to the output:

  ```glsl
  void vert(inout appdata_full v, out Input o) {
    ...

    o.depth = CalculateDepth(v.vertex); // <= HERE
  }
  ```

5. Place `IN.depth` (calculated in `vert`) inside your SurfaceOutput's `Alpha`:

  ```glsl
  void surf(Input IN, inout SurfaceOutput o) {
    ...

    o.Alpha = IN.depth; // <= HERE
  }
  ```

#### Vertex Shaders

0. Note that in order for Unity to find the required CG Include you should use one of the following methods:

    a. Copy DepthCG.cginc shader include next to your other shaders

    b. Use an absolute path to reference DepthCG.cginc (e.g. Assets/Absolute/Path/To/DepthCG.cginc)

    b. Use a relative path to reference DepthCG.cginc (e.g. ./Wherever/You/Put/DepthCG.cginc)

1. Add the DepthCG.cginc include just after your vert/frag pragmas. This will import the necessary helper function for calculating distance from the camera. If you already have includes, DepthCG should be first.

  ```glsl
  #pragma vertex vert
  #pragma fragment frag

  #include "DepthCG.cginc" // <= HERE
  ```

2. Define depth float to pass to `frag`:

  ```glsl
  struct v2f {
    ...

    float depth : TEXCOORD2; // <= HERE
  };
  ```

3. In `vert`, calculate depth and place it in `v2f`:

  ```glsl
  v2f vert(appdata_base i) {
    v2f o;

    ...

    o.depth = CalculateDepth(i.vertex); // <= HERE

    ...

    return o;
  }
  ```

4. In `frag`, place the depth calculation from `v2f` into the output color's alpha channel:

  ```glsl
  half4 frag(v2f i) : COLOR {
    half4 main_color;

    ...

    main_color.a = i.depth; // <= HERE

    ...

    return main_color;
  }
  ```
