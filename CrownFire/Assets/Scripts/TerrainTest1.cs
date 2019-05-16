using UnityEngine;
using System.Collections;
using System;
using UnityEngine.UI;

public class TerrainTest1 : MonoBehaviour
{
    public static TerrainTest1 instance;

    public Material chunkMaterial;
    public Material BurnAreaMaterial;
    public Camera burnRenderCam;
    public Camera mainRenderCam;
    public Vector3 scale = new Vector3(10f, 2f, 10f);
    public Texture flameStartingPoint;
    private Texture2D mapDataTexture;
    private RenderTexture mapDataRenderTexture;
    private RenderTexture aoRenderTexture;
    private RenderTexture burnAreaTexture;
    private BurnRendererTest1 burnRenderer;
    private MapRendererTest1 mapRenderer;
    public Chunk[] chunks;
    private RenderTexture tempRT;
    private RenderTexture current;
    private RenderTexture last;
    private bool orto = true;
    private bool realtimeActive = true;
    private bool isTerrainRendered = false;
    public int lodCount = 5;
    public float lodDistance = 10f;
    public float speedMultiplier = 1;
    private float timePassed = 0f;
    private float lastRenderTime = 0f;
    private float timeBetweenRenders = 1f;
    public int vcountx = 3; //Vertex count x
    public int vcounty = 3; //Vertex count y
    public int ccountx = 3; //Chunk count x
    public int ccounty = 3; //Chunk count y
    
    public void Awake()
    {
        chunkMaterial.SetTexture("_BurningTex", flameStartingPoint);
        instance = this;
    }

    public void Start()
    {
        this.mapRenderer = mainRenderCam.GetComponent<MapRendererTest1>();
        this.burnRenderer = burnRenderCam.GetComponent<BurnRendererTest1>();
    }

    public void Update()
    {
        float glowMultiplier = (1 + Mathf.Sin(Time.time)) * 0.5f;
        float flashMultiplier = Time.deltaTime * 10f;
        chunkMaterial.SetFloat("_DeltaTime", (glowMultiplier));
        chunkMaterial.SetFloat("_DeltaTimeFast", (flashMultiplier));
        timePassed = Time.deltaTime;
        float timePassedMultiplier = 1 / ((1 / timePassed) / 60);
        
        if (Input.GetKeyDown(KeyCode.P))
        {
            realtimeActive = !realtimeActive;
        }

        if (Input.GetKeyDown(KeyCode.Space))
        {
            GenerateTerrain();
            orto = !orto;
        }
        
        if (realtimeActive)
        {
            if(lastRenderTime + timeBetweenRenders * ((1/speedMultiplier)) < Time.time)
            {
                BurnAreaMaterial.SetFloat("_Delta", timePassedMultiplier);
                chunkMaterial.SetFloat("_Delta", timePassedMultiplier);
                burnRenderer.RenderTerrain();
                if (!isTerrainRendered)
                {
                    mapRenderer.RenderTerrain();
                    isTerrainRendered = true;
                }
                SetBurnData();
                lastRenderTime = Time.time;
                ConsoleManager.instance.AddPasses(1);
                ConsoleManager.instance.updateTimeText(Time.deltaTime);
            }
        }
    }
    
    public void passTimeAndRender(float sec)
    {
        BurnAreaMaterial.SetFloat("_Delta", sec);
        burnRenderer.RenderTerrain();
        SetBurnData();
    }
    
    public void GenerateTerrain(Texture2D mapDataTexture, RenderTexture rt, RenderTexture aort)
    {
        this.mapDataTexture = mapDataTexture;
        this.mapDataRenderTexture = rt;
        this.aoRenderTexture = aort;
        GenerateTerrain();
    }
    
    public void GenerateBurn(RenderTexture burnrt)
    {
        Resources.UnloadUnusedAssets();
        burnAreaTexture = burnrt;
    }

    public void SetBurnData()
    {
        BurnAreaMaterial.SetTexture("_MainTex", mapDataRenderTexture);
        chunkMaterial.SetTexture("_BurningTex", burnAreaTexture);
    }
    
    public void GenerateTerrain()
    {
        DeleteChunks();
        chunks = new Chunk[ccountx * ccounty];
        Color[] mapCols = mapDataTexture.GetPixels();
        chunkMaterial.SetTexture("_MainTex", mapDataRenderTexture);
        chunkMaterial.SetTexture("_OcclusionMap", aoRenderTexture);
        chunkMaterial.SetTexture("_BurningTex", burnAreaTexture);
        BurnAreaMaterial.SetTexture("_MainTex", mapDataRenderTexture);

        for (int i = 0; i < ccountx; i++)
        {
            for (int j = 0; j < ccounty; j++)
            {
                float fx = 1.0f / (float)ccountx;
                float fy = 1.0f / (float)ccounty;
                Vector2 start = new Vector2(i * fx, j * fy);
                Vector2 size = new Vector2(fx, fy);
                Chunk leftChunk = i > 0 ? chunks[ccountx * j + (i - 1)] : null;
                Chunk upChunk = j > 0 ? chunks[ccountx * (j - 1) + i] : null;
                Chunk chunk = GenerateChunk(leftChunk, upChunk, start, size, mapCols);
                chunks[ccountx * j + i] = chunk;
            }
        }
    }

    public void DeleteChunks()
    {
        if (chunks != null)
        {
            for (int i=0; i<chunks.Length; i++)
            {
                GameObject.Destroy(chunks[i].gameObject);
            }
        }
    }

    public Chunk GenerateChunk(Chunk left, Chunk up, Vector2 start, Vector2 size, Color[] mapCols)
    {
        GameObject chunko = new GameObject("Chunk");
        chunko.transform.parent = this.transform;
        Chunk chunk = chunko.AddComponent<Chunk>();

        chunk.Init(lodCount, lodDistance);

        int vx = vcountx;
        int vy = vcounty;
        for (int i = 0; i < lodCount; i++)
        {
            
            Mesh mesh = new Mesh();
            GenerateTerrainMesh(mesh, vx, vy, orto, start, size, mapCols);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();

            Vector3[] normals = mesh.normals;
            int vx1 = vx + 1;
            int vy1 = vy + 1;

            
            if (up != null)
            {
                Mesh upMesh = up.lods[i];
                Vector3[] upNormals = upMesh.normals;
                for (int k=0; k<vy1; k++)
                {
                    Vector3 newNormal = (normals[k * vx1] + upNormals[k * vx1 + vy]) * 0.5f;
                    upNormals[k * vx1 + vy] = newNormal;
                    normals[k * vx1] = newNormal;
                }
                upMesh.normals = upNormals;
            }              
            if (left != null)
            {
                Mesh leftMesh = left.lods[i];
                Vector3[] leftNormals = leftMesh.normals;
                for (int k = 0; k < vx1; k++)
                {
                    Vector3 newNormal = (normals[k] + leftNormals[k + vx1 * vy]) * 0.5f;
                    leftNormals[k + vx1 * vy] = newNormal;
                    normals[k] = newNormal;
                }
                leftMesh.normals = leftNormals;
            }
            mesh.normals = normals;

            chunk.meshFilter.mesh = mesh;
            chunk.AddLod(i, mesh);

            vx /= 2;
            vy /= 2;
        }

        chunk.meshRenderer.sharedMaterial = chunkMaterial;
        return chunk;
    }

    public Color Bisample(Vector2 pp, int tw, int th, Color[] colors)
    {
        float px = pp.x * tw;
        float py = pp.y * th;
        float fx = px - (int)(px);
        float fy = py - (int)(py);

        int ix = (int)(px);
        int iy = (int)(py);
        //Clamping
        ix = ix < tw ? ix : tw - 1;
        iy = iy < th ? iy : th - 1;
        int ix2 = (ix+1) < tw ? (ix+1) : tw - 1;
        int iy2 = (iy+1) < th ? (iy+1) : th - 1;

        int m1 = ix + iy * tw;
        int m2 = ix2 + iy * tw;
        int m3 = ix + iy2 * tw;
        int m4 = ix2 + iy2 * tw;

        Color c1 = colors[m1];
        Color c2 = colors[m2];
        Color c3 = colors[m3];
        Color c4 = colors[m4];
        return Color.Lerp(Color.Lerp(c1, c2, fx), Color.Lerp(c3, c4, fx), fy);
    }

    public float GetHeight(Color col)
    {
        //return col.r + col.g + col.b;
        return col.r;
    }
    
    public void GenerateTerrainMesh(Mesh mesh, int vx, int vy, bool orto, Vector2 start, Vector2 size, Color[] mapCols)
    {
        vx++;
        vy++;
        if (vx < 2 || vy < 2)
            return;

        int tw = mapDataTexture.width;
        int th = mapDataTexture.height;

        Vector3 centerPos = scale / 2f;
        int vertCount = vx * vy;


        int[] tris = new int[(vx - 1) * (vy - 1) * 6];
        Vector3[] verts = new Vector3[vertCount];
        Vector2[] uvs = new Vector2[vertCount];

        int k = 0;
        int k2 = 0;
        for (int i = 0; i < vx; i++)
        {
            for (int j = 0; j < vy; j++)
            {
                Vector2 pp = new Vector2(i / ((float)vx - 1), j / ((float)vy - 1));
                if (orto)
                {
                    
                    if (j % 2 == 1 && i != (vy - 1) 
                     || j % 2 == 0 && i == 0)
                    //if (j % 2 == 1)
                    {
                        pp = new Vector2((i + 0.5f) / ((float)vx - 1), j / ((float)vy - 1));
                    }
                    pp.x = (float)((double)pp.x * ((vx - 1.0) / (vx - 1.5)));
                    pp.x -= (float)(0.5 / (vx - 1.5));
                }

                pp = new Vector2(Mathf.Clamp01(pp.x * size.x + start.x), Mathf.Clamp01(pp.y * size.y + start.y));

                Color val = Bisample(pp, tw, th, mapCols);
                float h = GetHeight(val);
                verts[k] = new Vector3(pp.x * scale.x, h * scale.y, pp.y * scale.z) - centerPos;

                uvs[k] = pp;
                k++;
                if (i < (vx - 1) && j < (vy - 1))
                {
                    int pos = j + vy * i;
                    if (j % 2 == 0)
                    {
                        tris[k2] = pos;
                        tris[k2 + 1] = pos + 1;
                        tris[k2 + 2] = pos + vy;
                        tris[k2 + 3] = pos + 1;
                        tris[k2 + 4] = pos + 1 + vy;
                        tris[k2 + 5] = pos + vy;
                    }
                    else
                    {
                        tris[k2] = pos;
                        tris[k2 + 1] = pos + 1;
                        tris[k2 + 2] = pos + 1 + vy;
                        tris[k2 + 3] = pos;
                        tris[k2 + 4] = pos + 1 + vy;
                        tris[k2 + 5] = pos + vy;
                    }
                    k2 += 6;
                }
            }
        }
        
        mesh.vertices = verts;
        mesh.uv = uvs;
        mesh.triangles = tris;
    }

}
