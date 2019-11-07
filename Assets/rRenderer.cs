using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class rRenderer : MonoBehaviour
{

    MeshRenderer mr;
    MeshFilter mf;

    public bool castShadows = true;
    public Color color = Color.white;
    [Range(0, 1)]
    public float roughness = 0.5f;
    [Range(0, 1)]
    public float metallic = 0;
    [Range(0, 1)]
    public float lightwrap = 0.5f;

    public bool needsUpdate = true;

    public class Tri
    {
        public int triIndex = -1;
        public Bounds bounds = new Bounds();
        public Vector3[] vertices = new Vector3[3];
    }

    public List<Tri> tris = new List<Tri>();

    public enum Type
    {
        geo,
        sphere
    }

    public Type type = Type.geo;

    public struct TriGPU
    {
        public int type;
        public int materialId; //materialindex
        public int objectId;
        public Vector3 a;
        public Vector3 b;
        public Vector3 c;
    }

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

    bool queued = false;
    IEnumerator QueueUpdates()
    {
        queued = true;
        while (MaterialManager.materialManager == null)
        {
            yield return null;
        }

        queued = false;
        MaterialManager.materialManager.materialBuffer.UpdateStruct(this);
    }

    //Only change user variables, things like objectid and materialid are changed by the program
    private void OnValidate()
    {

        if (block == null) SetBlock();
        
        Debug.Log("editing");
        block.SetColor("_Color", color);
        mr.sharedMaterial.SetFloat("_Roughness", roughness);
        mr.sharedMaterial.SetFloat("_Metallic", metallic);
        mr.SetPropertyBlock(block);

        if (MaterialManager.materialManager == null && !queued)
        {
            StartCoroutine(QueueUpdates());
            return;
        }
        MaterialManager.materialManager.materialBuffer.UpdateStruct(this);
    }

    public TriGPU[] GetGeo()
    {
        if (block == null) SetBlock();
        TriGPU[] triGpus = new TriGPU[tris.Count];
        int oi = block.GetInt("_ObjectIndex");
        int mi = block.GetInt("_MaterialIndex");

        if (type == Type.geo)
        {
            for (int i = 0; i < tris.Count; i++)
            {
                TriGPU tri = new TriGPU();
                tri.type = (int)type;
                tri.materialId = mi;
                tri.objectId = oi;
                tri.a = transform.TransformPoint(tris[i].vertices[0]);
                tri.b = transform.TransformPoint(tris[i].vertices[1]);
                tri.c = transform.TransformPoint(tris[i].vertices[2]);
                triGpus[i] = tri;
            }
        }
        else if (type == Type.sphere)
        {
            for (int i = 0; i < tris.Count; i++)
            {
                TriGPU tri = new TriGPU();
                tri.type = (int)type;
                tri.materialId = mi;
                tri.objectId = oi;
                tri.a = tris[i].vertices[0];
                tri.b = tris[i].vertices[1];
                tri.c = tris[i].vertices[2];
                triGpus[i] = tri;
            }
        }


        return triGpus;
    }

    void CreateTris()
    {
        for (int i = 0; i < mf.sharedMesh.triangles.Length / 3; i++)
        {

            int id = i * 3;

            Tri tri = new Tri();

            Vector3 min = new Vector3(Mathf.Infinity, Mathf.Infinity, Mathf.Infinity);
            Vector3 max = new Vector3(-Mathf.Infinity, -Mathf.Infinity, -Mathf.Infinity);

            for (int j = 0; j < 3; j++)
            {
                tri.vertices[j] = mf.sharedMesh.vertices[mf.sharedMesh.triangles[id + j]];

                Vector3 wp = transform.TransformPoint(tri.vertices[j]);

                min = Vector3Int.FloorToInt(Vector3.Min(wp, min));
                max = Vector3Int.CeilToInt(Vector3.Max(wp, max));
            }

            max = Vector3.Max(min + new Vector3(1, 1, 1), max);

            tri.bounds.SetMinMax(min, max);

            tris.Add(tri);
        }

    }

    void CreateSphere()
    {

        Tri tri = new Tri();

        Vector3 rvec = transform.localScale / 2.0f;
        Vector3 min = Vector3Int.FloorToInt(transform.position - rvec);
        Vector3 max = Vector3Int.CeilToInt(transform.position + rvec);

        max = Vector3.Max(min + Vector3.one, max);

        tri.bounds.SetMinMax(min, max);
        tri.vertices[0] = transform.position;
        tri.vertices[1] = rvec;
        tri.vertices[2] = Vector3.zero;
        tris.Add(tri);
    }

    private void Awake()
    {
        mr = GetComponent<MeshRenderer>();
        mf = GetComponent<MeshFilter>();

        if (type == Type.sphere) CreateSphere();
        else if (type == Type.geo) CreateTris();

    }

    private void Start()
    {
        OnValidate();
        ObjectManager.objectManager.needsUpdate = true;
    }

    private void Update()
    {
        if (transform.hasChanged)
        {
            transform.hasChanged = false;
            ObjectManager.objectManager.needsUpdate = true;
        }
    }

}
