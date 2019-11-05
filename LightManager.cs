using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteInEditMode]
public class LightManager : MonoBehaviour
{

    ComputeBuffer lightBuffer;
    public static LightManager lightManager;

    public struct rLightStruct
    {
        public int type;
        public Vector3 position;
        public Color color; 
    }

    public rLightStruct[] rlights;
    public rLight[] lights;

    public int batches = 0;
    public int batchSize = 20;

    public bool needsUpdate = false;

    public void UpdateLights()
    {
        rlights = new rLightStruct[lights.Length];

        for (int i = 0; i < lights.Length; i++)
        {
            rLightStruct st = new rLightStruct();
            st.color = lights[i].color;
            st.color.a = lights[i].intensity;

            if (lights[i].type == LightType.Directional)
            {
                st.position = lights[i].transform.forward;
            }
            else
            {
                st.position = lights[i].transform.position;
            }

            st.type = (int)lights[i].type;
            rlights[i] = st;
        }

        batches = Mathf.CeilToInt((float)lights.Length / (float)batchSize);
    
    }

    void LoadBatch(rLightStruct[] lightBatch)
    {
        needsUpdate = false;
        Shader.SetGlobalInt("lightBuffer_Count", lightBatch.Length);
        lightBuffer.SetData(lightBatch);
    }

    void LoadBatch(List<rLightStruct> lightBatch)
    {
        needsUpdate = false;
        Shader.SetGlobalInt("lightBuffer_Count", lightBatch.Count);
        lightBuffer.SetData(lightBatch);
    }

    public void UpdateLight(int batch)
    {
        if (!needsUpdate) return;

        //If only one batch 
        if (batches < 2)
        {
            LoadBatch(rlights);
        }
        else
        {
            int start = batch * batchSize;

            int count = rlights.Length - start;
            count = Math.Min(count, 20);

            List<rLightStruct> lightBatch = new List<rLightStruct>();

            for (int i = 0; i < count; i++)
            {
                lightBatch.Add(rlights[i]);
            }

            LoadBatch(lightBatch);
        }

    }


    private void Awake()
    {
        lightManager = this;
        lightBuffer = new ComputeBuffer(1, Marshal.SizeOf(typeof(rLightStruct)));
        Shader.SetGlobalBuffer("lightBuffer", lightBuffer);

        lights = FindObjectsOfType<rLight>();

        UpdateLights();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (needsUpdate) UpdateLights();
    }
}
