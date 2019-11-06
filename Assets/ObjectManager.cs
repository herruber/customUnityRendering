using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectManager : MonoBehaviour
{

    public rRenderer[] renderers;

    // Start is called before the first frame update
    void Start()
    {
        renderers = FindObjectsOfType<rRenderer>();

        for (int i = 0; i < renderers.Length; i++)
        {
            renderers[i].objectIndex = i;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
