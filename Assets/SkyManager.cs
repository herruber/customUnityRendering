using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyManager : Manager
{
    public static SkyManager skyManager;
    public Gradient horizonColor;
    public Gradient zenithColor;
    public float time = 0.5f;

    private void Awake()
    {
        skyManager = this;
    }

    private void UpdateSky()
    {
        if (CustomRendering.customRendering == null) return;
        CustomRendering.customRendering.objectMaterial.SetColor("horizonColor", horizonColor.Evaluate(time));
        CustomRendering.customRendering.objectMaterial.SetColor("zenithColor", zenithColor.Evaluate(time));
        CustomRendering.customRendering.objectMaterial.SetFloat("dayTime", time);
    }

    private void OnValidate()
    {
        UpdateSky();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        UpdateSky();
    }
}
