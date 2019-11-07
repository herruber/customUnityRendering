using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteAlways]
public class ObjectManager : Manager
{
    public static ObjectManager objectManager;
    ComputeBuffer objectBuffer;

    public List<rRenderer> renderers;
    public bool needsUpdate = false;

    private void Awake()
    {
        objectManager = this;
    }

    private void SetBufferData(List<rRenderer> _renderers)
    {
        needsUpdate = false;

        List<rRenderer.TriGPU> tris = new List<rRenderer.TriGPU>();

        foreach (var item in _renderers)
        {
            tris.AddRange(item.GetGeo());
        }

        objectBuffer = new ComputeBuffer(tris.Count, Marshal.SizeOf(typeof(rRenderer.TriGPU)));
        objectBuffer.SetData(tris);
        Shader.SetGlobalBuffer("objectBuffer", objectBuffer);
        Shader.SetGlobalInt("objectBuffer_Count", objectBuffer.count);
    }

    // Update is called once per frame
    void Update()
    {

        if (needsUpdate)
        {
            Debug.Log("setting data");
            SetBufferData(renderers);
        }
    }
}
