using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

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
    [Range(0, 1)]
    public float lightwrap = 0.5f;

    public MaterialPropertyBlock block;

    void SetBlock()
    {
        mr = GetComponent<MeshRenderer>();
        block = new MaterialPropertyBlock();
        mr.GetPropertyBlock(block);
    }

    //Being set for each rrenderer found in scene from MaterialManager
    public void SetIds(int oid, int mid)
    {
        if (block == null) SetBlock();

        block.SetInt("_ObjectIndex", oid);
        block.SetInt("_MaterialIndex", mid);

        mr.SetPropertyBlock(block);
    }

    //Only change user variables, things like objectid and materialid are changed by the program
    private void OnValidate()
    {

        if (block == null) SetBlock();
        if (MaterialManager.materialManager == null) return;

        Debug.Log("editing");
        block.SetColor("_Color", color);
        mr.sharedMaterial.SetFloat("_Roughness", roughness);
        mr.sharedMaterial.SetFloat("_Metallic", metallic);
        mr.SetPropertyBlock(block);

        MaterialManager.materialManager.materialBuffer.UpdateStruct(this);
    }

    private void Awake()
    {
       mr = GetComponent<MeshRenderer>();
    
      
    }

    private void Start()
    {
        OnValidate();
    }

    private void Update()
    {

    }

}
