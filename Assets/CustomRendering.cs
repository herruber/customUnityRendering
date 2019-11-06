using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CustomRendering : MonoBehaviour
{

    public Material lightingMaterial;
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

    private void RenderLighting()
    {
        current.SetTargetBuffers(Display.main.colorBuffer, Display.main.depthBuffer);
        Graphics.Blit(null, null, lightingMaterial);
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
            RenderLighting();
        }

        
    }

    IEnumerator Renderloop()
    {
        while (true)
        {
            yield return new WaitForEndOfFrame();
            current.clearFlags = CameraClearFlags.Color;
            RenderFramebuffer();

            current.clearFlags = CameraClearFlags.Color;
            LightLoop();
            
        }
    }

    private void Awake()
    {
        gbuffer = new Gbuffer(new string[] { "colorTex", "worldTex", "normalTex", "shaderTex" }, 32, new Vector2Int(Screen.width, Screen.height));
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
        
    }
}
