using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

[CreateAssetMenu]
public class rMaterial : ScriptableObject
{

    public Shader shader;
    [HideInInspector]
    public Material material;
    [HideInInspector]
    public rRenderer rrenderer;

    public struct rMaterialStruct
    {
        public Color color;
        public float roughness;
        public float metallic;
    }

    public Color color;
    [Range(0, 1)]
    public float roughness;
    [Range(0, 1)]
    public float metallic;

    public rMaterialStruct rmaterial;

    public void UpdateDisplayShader()
    {
        material.SetColor("_Color", rmaterial.color);
    }

    public void UpdateMaterial()
    {
        Debug.Log("MAterial changed");
        rmaterial.color = color;
        rmaterial.roughness = roughness;
        rmaterial.metallic = metallic;

        UpdateDisplayShader();
        MaterialManager.materialManager.needsUpdate = true;
    }

    public void SetProperty(string prop, object val)
    {
        PropertyInfo property = typeof(rMaterialStruct).GetProperty(prop);
        property.SetValue(rmaterial, val);
        MaterialManager.materialManager.needsUpdate = true;
    }


}
