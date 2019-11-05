using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteInEditMode]
public class MaterialManager : MonoBehaviour
{


    public static MaterialManager materialManager;

    public rMaterial[] materials;
  

    ComputeBuffer materialBuffer;
    public bool needsUpdate = true;

    private void Awake()
    {
        materialManager = this;

        materials = Resources.FindObjectsOfTypeAll<rMaterial>();

        for (int i = 0; i < materials.Length; i++)
        {
            materials[i].material.SetVector("_Shader", new Vector4(i, 0, 0, 0));
        }

        Shader.SetGlobalFloat("PI", Mathf.PI);
    }

    private void UpdateBuffer()
    {
        materialBuffer = new ComputeBuffer(materials.Length, Marshal.SizeOf(typeof(rMaterial.rMaterialStruct)));
        materialBuffer.SetData(materials.Select(e => e.rmaterial).ToArray());

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
