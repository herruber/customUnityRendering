using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteAlways]
public class MaterialManager : MonoBehaviour
{

    public static MaterialManager materialManager;

    public MaterialBuffer materialBuffer;
    public bool needsUpdate = true;

    [Serializable]
    public class MaterialBuffer
    {
        public ComputeBuffer buffer;
        public List<rRenderer> renderers = new List<rRenderer>();
        public List<Material> usedMaterials = new List<Material>();

        public struct Struct
        {
            public Color color;
            public float roughness;
            public float metallic;
            public float lightwrap;
            public int objectId;
            public int materialId;
        }

        List<Struct> usedMaterialsGpu = new List<Struct>();

        public bool needsUpdate = false;

        //On init, get all materials in resource folder that uses MrtStandard. And get all active rRenderers
        public MaterialBuffer(Shader shader)
        {

            usedMaterials = Resources.FindObjectsOfTypeAll<Material>().Where(e => e.shader == shader).ToList();
            renderers = FindObjectsOfType<rRenderer>().ToList();

            for (int i = 0; i < renderers.Count; i++)
            {
                usedMaterialsGpu.Add(new Struct());
                renderers[i].SetIds(i, i);

            }

            SetBuffer();
        }

        public int GetObjectId(rRenderer r)
        {
            return renderers.IndexOf(r);
        }

        public int GetMaterialId(rRenderer r)
        {
            return usedMaterials.IndexOf(r.GetComponent<MeshRenderer>().sharedMaterial);
        }

        public void UpdateStruct(rRenderer r)
        {
            int id = renderers.IndexOf(r);

            Struct s = usedMaterialsGpu[id];
            s.color = r.color;
            s.materialId = r.block.GetInt("_MaterialIndex");
            s.objectId = r.block.GetInt("_ObjectIndex");
            
            s.roughness = r.roughness;
            s.metallic = r.metallic;
            s.lightwrap = r.lightwrap;

            usedMaterialsGpu[id] = s;
            needsUpdate = true;
        }

        public void UpdateBufferData()
        {
            buffer.SetData(usedMaterialsGpu);
            needsUpdate = false;
        }

        public void SetBuffer()
        {
            buffer = new ComputeBuffer(renderers.Count, Marshal.SizeOf(typeof(Struct)));

            Shader.SetGlobalBuffer("materialBuffer", buffer);
            Shader.SetGlobalInt("materialBuffer_Count", buffer.count);
        }
    }

    private void Awake()
    {
        materialManager = this;
        materialBuffer = new MaterialBuffer(Shader.Find("Unlit/MrtStandard"));
        Shader.SetGlobalFloat("PI", Mathf.PI);
    }

    // Start is called before the first frame update
    void Start()
    {
      
    }

    private void Update()
    {
        if (materialBuffer != null && materialBuffer.needsUpdate) materialBuffer.UpdateBufferData();
    }

}
