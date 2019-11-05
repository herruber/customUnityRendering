using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class rRenderer : MonoBehaviour
{

    public rMaterial material;
    public bool castShadows = true;

    private void OnValidate()
    {
        if (material.material == null) return;
        Debug.Log("Updating material");
        material.UpdateDisplayShader();
    }

    private void Awake()
    {
        material.material = new Material(material.shader);
        GetComponent<MeshRenderer>().sharedMaterial = material.material;
        material.rrenderer = this;
    }

    void Compare()
    {

        if (material.color != material.rmaterial.color) material.UpdateMaterial();
        else if (material.roughness != material.rmaterial.roughness) material.UpdateMaterial();
        else if (material.metallic != material.rmaterial.metallic) material.UpdateMaterial();




    }

    private void Update()
    {
        Compare();
    }

}
