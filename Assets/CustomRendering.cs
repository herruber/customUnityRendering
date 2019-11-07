using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CustomRendering : MonoBehaviour
{
    public static CustomRendering customRendering;
    //Materials to process the gbuffer and do all effects
    public Material objectMaterial;
    Vector4[] dirs = new Vector4[4];
    Camera current;

    public class Gbuffer
    {
        public RenderBuffer[] colorbuffers;
        public RenderTexture[] targets;

        public RenderBuffer depthbuffer;

        public Gbuffer(string[] channels, int depth, Vector2Int size)
        {

            targets = new RenderTexture[channels.Length];
            colorbuffers = new RenderBuffer[targets.Length];
        

            for (int i = 0; i < targets.Length; i++)
            {

                int currentDepth = 0;
                if (i == 0) currentDepth = depth;

                RenderTexture tex = new RenderTexture(size.x, size.y, currentDepth, RenderTextureFormat.ARGBFloat);
                tex.filterMode = FilterMode.Point;
                tex.wrapMode = TextureWrapMode.Clamp;
                tex.Create();
                colorbuffers[i] = tex.colorBuffer;

                Shader.SetGlobalTexture(channels[i], tex);
                targets[i] = tex;
            }

            depthbuffer = targets[0].depthBuffer;

            Shader.SetGlobalVector("screen", new Vector4(1f / Screen.width, 1f / Screen.height, Screen.width, Screen.height));
        }
    }

    Gbuffer gbuffer;

    private void RenderObjects()
    {
        Graphics.Blit(null, null, objectMaterial);
    }

    private void RenderFramebuffer()
    {
        current.SetTargetBuffers(gbuffer.colorbuffers, gbuffer.depthbuffer);
        current.Render();
    }

    private void LightLoop()
    {

        for (int i = 0; i < LightManager.lightManager.batches; i++)
        {
            LightManager.lightManager.UpdateLight(i);
            RenderObjects();
        }
   
    }

    public void UpdateCameraVariables()
    {
        transform.hasChanged = false;

        for (int y = 0; y < 2; y++)
        {
            for (int x = 0; x < 2; x++)
            {
                dirs[x + y * 2] = current.ViewportPointToRay(new Vector3(x, y, 0)).direction;
            }
        }

        Shader.SetGlobalVectorArray("dirs", dirs);
    }

    IEnumerator Renderloop()
    {
        while (true)
        {
            yield return new WaitForEndOfFrame();

            current.clearFlags = CameraClearFlags.Color;
            RenderFramebuffer();
            LightLoop();
        }
    }

    private void Awake()
    {
        customRendering = this;
        Vector2Int size = new Vector2Int(Screen.width, Screen.height);
        gbuffer = new Gbuffer(new string[] { "colorTex", "worldTex", "normalTex", "shaderTex" }, 32, size);
        current = GetComponent<Camera>();
        current.enabled = false;
    }

    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(Renderloop());
    }

    // Update is called once per frame
    void Update()
    {
        if (transform.hasChanged) UpdateCameraVariables();
    }
}
