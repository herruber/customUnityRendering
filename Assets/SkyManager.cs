using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyManager : Manager
{
    public static SkyManager skyManager;
    public Gradient horizonColor;
    public Gradient zenithColor;
    public Gradient sunColor;
    public AnimationCurve sunAltitudeCurve;
    public float time = 0f;

    public float dawn = 0.25f;
    public float dusk = 0.75f;

    private void Awake()
    {
        skyManager = this;
    }

    private void UpdateSky()
    {
        if (CustomRendering.customRendering == null) return;


        //float altitude = 0f;
        //CustomRendering.customRendering.objectMaterial.SetColor("horizonColor", horizonColor.Evaluate(time));
        //CustomRendering.customRendering.objectMaterial.SetColor("zenithColor", zenithColor.Evaluate(time));
        //CustomRendering.customRendering.objectMaterial.SetFloat("dayTime", time);
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
