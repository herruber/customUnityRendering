using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class rLight : MonoBehaviour
{

    public LightType type = LightType.Directional;
    public Color color;
    public float intensity = 1f;

    private void OnValidate()
    {
        if (LightManager.lightManager == null) return;
        LightManager.lightManager.needsUpdate = true;
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (transform.hasChanged)
        {

            OnValidate();
        }
    }
}
