using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteInEditMode]
public class MaterialManager : MonoBehaviour
{

    public static MaterialManager materialManager;

    public Material[] materialIds;

    ComputeBuffer materialBuffer;
    public bool needsUpdate = true;

    private void GatherAllMaterialsUsed()
    {
        Shader shader = Shader.Find("Unlit/MrtStandard");
        materialIds = Resources.FindObjectsOfTypeAll<Material>().Where(e => e.shader == shader).ToArray();
    }

    private void Awake()
    {
        materialManager = this;
        GatherAllMaterialsUsed();
        Shader.SetGlobalFloat("PI", Mathf.PI);
    }


    public rRenderer.GpuStruct ToGpu(Material mat)
    {
        Material m = mat;

        rRenderer.GpuStruct st = new rRenderer.GpuStruct();
        st.color = m.GetColor("_Color");
        st.roughness = m.GetFloat("_Roughness");
        st.metallic = m.GetFloat("_Metallic");
        st.shaderData = new Vector4(mat.GetFloat("_MaterialIndex"), mat.GetFloat("_ObjectIndex"), 0, 0);

        return st;
    }

    private void UpdateBuffer()
    {
        materialBuffer = new ComputeBuffer(materialIds.Length, Marshal.SizeOf(typeof(rRenderer.GpuStruct)));

        List<rRenderer.GpuStruct> sts = new List<rRenderer.GpuStruct>();

        for (int i = 0; i < materialIds.Length; i++)
        {
            Material mat = materialIds[i];

            sts.Add(ToGpu(mat));
        }

        materialBuffer.SetData(sts);

        Shader.SetGlobalBuffer("materialBuffer", materialBuffer);
        Shader.SetGlobalInt("materialBuffer_Count", materialBuffer.count);
        needsUpdate = false;
    }

    // Start is called before the first frame update
    void Start()
    {
      
    }

    // Update is called once per frame
    void Update()
    {
        if (needsUpdate) UpdateBuffer();
    }
}
