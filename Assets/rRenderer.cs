using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshRenderer))]
public class rRenderer : MonoBehaviour
{

    MeshRenderer mr;
    public bool castShadows = true;
    public Color color = Color.white;
    [Range(0, 1)]
    public float roughness = 0.5f;
    [Range(0, 1)]
    public float metallic = 0;
    bool needsUpdate = false;

    private int _materialIndex;
    public int materialIndex
    {
        get { return _materialIndex; }
        set {
            _materialIndex = value;
            needsUpdate = true;
          
        }
    }

    private int _objectIndex;
    public int objectIndex
    {
        get { return _objectIndex; }
        set {
            _objectIndex = value;
            needsUpdate = true;
        }
    }

    public MaterialPropertyBlock block;

    public struct GpuStruct
    {
        public Color color;
        public float roughness;
        public float metallic;
        public Vector4 shaderData;
    }

    private void UpdateMaterial()
    {
       
        if (block == null) return;
        Debug.Log("editing");
        block.SetColor("_Color", color);
        block.SetInt("_ObjectIndex", objectIndex);
        mr.sharedMaterial.SetInt("_MaterialIndex", materialIndex);
        mr.sharedMaterial.SetFloat("_Roughness", roughness);
        mr.sharedMaterial.SetFloat("_Metallic", metallic);
        mr.SetPropertyBlock(block);
        MaterialManager.materialManager.needsUpdate = true;
        needsUpdate = false;
    }

    private void OnValidate()
    {
        needsUpdate = true;
    }

    private void Awake()
    {
       mr = GetComponent<MeshRenderer>();
       block = new MaterialPropertyBlock();
       mr.GetPropertyBlock(block);
       OnValidate();
    }

    private void Update()
    {
        if (needsUpdate) UpdateMaterial();
    }

}
