﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using UnityEngine;

public class LightManager : MonoBehaviour
{

    ComputeBuffer lightBuffer;
    public static LightManager lightManager;
    bool isReady = false;
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
        Shader.SetGlobalInt("lightBuffer_Count", lightBatch.Length);
        lightBuffer.SetData(lightBatch);
    }

    void LoadBatch(List<rLightStruct> lightBatch)
    {
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
   
    }

    // Start is called before the first frame update
    void Start()
    {
        lightBuffer = new ComputeBuffer(20, Marshal.SizeOf(typeof(rLightStruct)));
        Shader.SetGlobalBuffer("lightBuffer", lightBuffer);
        lights = FindObjectsOfType<rLight>();

        UpdateLights();
    }

    // Update is called once per frame
    void Update()
    {
      
        if (needsUpdate)
        {
            UpdateLights();
        }
    }
}
