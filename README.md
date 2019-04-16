Documentation
---

### Setting up the camera

1. Add DepthOfField.cs to the camera you wish to apply depth of field. While you can adjust parameters at any time we recommend finishing the setup so you can preview your changes.

2. Make sure you set your camera's clear flag to something other than "Depth".

### Modifying your shaders

When in doubt we provide a number of example shaders in DepthOfField/Example/Shaders/ that demonstrates a fully working surface and vertex/fragment shaders.

> NOTE: ShaderLab syntax is not supported since they do not support vertex functions.

#### Surface Shaders

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

#### Transparency

Transparency on mobile is expensive so its best to try and avoid it entirely. Most of the time you can use more polygons cheaper than alpha transparency. Note that the depth of field shader is only compatible with transparent-cutout. Alpha blending won't work without some crazy hacks and its too expensive anyway.

For transparent-cutout and depth of field to play nicely you must use a vertex/fragment shader. The transparency shader is otherwise identical to the vertex-fragment shader example with two exceptions:

1. Make sure the appropriate render tags are set:

  ```glsl
  Tags {
    "Queue" = "Transparent"
    "RenderType" = "TransparentCutout"
  }
  ```

2. Call the `clip` function in the fragment shader _before_ you override the output alpha with the depth:

  ```glsl
  // Clip based on the texture alpha
  clip(main_color.a - 0.5f); // You can vary the 0.5 if the cutout seems a bit rough

  // Place `vert` depth calculation into alpha channel
  main_color.a = i.depth;
  ```

An example is include in "Example/Materials/Transparency.mat".

#### Terrain

An example of a built-in terrain shader modified to work with the depth of field is included (see "Example/Materials/Tree.mat" or toggle the "Terrain" game object).

The changes to apply to the terrain shaders are the same as above. A few things to keep in mind:

- Sometimes the vertex function is inside of an external include file such as "SH_Vertex.cginc". You'll need to create your own "SH_Vertex.cginc" (just copy+paste) to override the internal Unity version.
- In the fragment function make sure that you set the alpha _after_ the clip has been applied:

  ```glsl
  fixed4 frag(v2f input) : SV_Target {
    fixed4 c = tex2D( _MainTex, input.uv.xy);
    c.rgb *= 2.0f * input.color.rgb;

    clip (c.a - _Cutoff);

    // Override alpha, _after_ `clip`
    c.a = input.depth; // <= HERE

    return c;
  }
  ```

- Some terrain shaders use `ColorMask RGB`. This must be disabled (just remove/comment the line) as it prevents the alpha value from getting passed to the RenderTexture.
- Usually only one of the shader passes needs to be modified. For example, in the example terrain shader, you don't need to modify the "ShadowCaster" pass since its only used for calculating shadows.

#### Excluding meshes

There are two methods for excluding meshes like GUIs or lens flares from the depth of field. Each approach has different advantages and drawbacks.

The first method is to modify the shader you want to be in focus to force the depth to a fixed value outside of the normal range, like `-1.0f`. For example, in the excluded shader’s `surf` or `frag` function setting the alpha value (which holds the real depth value) to `-1.0f`:

With a surface shader:

  ```glsl
  void surf(Input IN, inout SurfaceOutput o) {
    // ...
    o.Alpha = -1.0f;
  }
  ```

With a vertex/fragment shader:

  ```glsl
  half4 frag(v2f i) : COLOR {
    // ...

    main_color.a = -1.0f;
    return main_color;
  }
  ```

See Example/Images/Exclude1.jpg or toggle the "Exclude 1" game object for an example.

Note that the cubes are in focus, despite their blurred surroundings.

The second method for excluding a mesh from the depth of field requires two cameras. Everything you exclude will be rendered on top of everything else. The benefit to this approach is that there are no bleeding edges like in the first approach and can be useful for GUIs or lens flares.

1. Create a new layer called “DoF Exclude” by going to Edit > Project Settings > Tags and Layers
2. Assign the objects you want to exclude to this new layer.
3. On your main camera, uncheck “DoF Exclude” from the Culling Mask option. You should see the excluded objects disappear.
4. Create a new camera and parent it under your main camera (so they move together).
5. Set the secondary camera’s Clear Flags to depth only. Since we’ve disabled the Unity depth map on both cameras this camera should always render on top of the main camera.
6. Set the secondary camera’s Culling Mask to only “DoF Exclude”.
7. All other settings should probably match your main camera (such as Field of View, etc.)

See Example/Images/Exclude2.jpg or toggle the "Exclude 2" game object and "Main Camera/Exclude Camera" for an example of this approach.

Note how the cubes are overlapping everything in the main layer.
