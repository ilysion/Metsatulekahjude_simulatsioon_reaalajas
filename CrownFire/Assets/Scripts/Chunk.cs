using UnityEngine;
using System.Collections;

public class Chunk : MonoBehaviour
{

    public MeshFilter meshFilter;
    public MeshRenderer meshRenderer;

    public Mesh[] lods;
    public float lodDist = 10f;
    public int currentLod = -1;
    public Vector3 center;

    public void Init(int lodCount, float lodDist)
    {
        this.meshFilter = this.gameObject.AddComponent<MeshFilter>();
        this.meshRenderer = this.gameObject.AddComponent<MeshRenderer>();

        this.lods = new Mesh[lodCount];
        this.lodDist = lodDist;
    }

    public void AddLod(int num, Mesh mesh)
    {
        lods[num] = mesh;
        center = mesh.bounds.center;
        //Debug.Log(center);
    }

    public void Update()
    {
        Vector3 pos = this.transform.position + center;

        float dist = (pos - Camera.main.transform.position).magnitude;
        int lod = (int)(dist / (lodDist * lodDist));
        lod = lod < lods.Length ? lod : lods.Length - 1;

        //Debug.Log(dist + " - " + lod);
        if (lod != currentLod)
        {
            meshFilter.mesh = lods[lod];
            currentLod = lod;
        }
    }
}
