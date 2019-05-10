using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class MapRendererTest1 : MonoBehaviour
{

    public int size = 1024;
    public Material mapMat;
    public Material mapNormalsMat;
    public Material mapTextureMat;
    public Material convertHeightsMat;
    public Material erosionMat;

    public Vector2 seedPos = new Vector2(0.0f, 0.0f);

    private Vector2 previousSeedPos;
    private RenderTexture rt;
    private RenderTexture rts;
    private RenderTexture rtnormals;
    private RenderTexture rttexture;
    private RenderTexture rtao;
    private RenderTexture rtburn;
    private GameObject quad;
    private MeshRenderer quadRenderer;
    private Camera cam;
    private BlurOptimized blurOptimized;
    private bool terrainRendered = false;

    public void Awake()
    {
        cam = this.GetComponent<Camera>();
        quad = this.transform.Find("Quad").gameObject;
        quadRenderer = quad.GetComponent<MeshRenderer>();
        blurOptimized = this.GetComponent<BlurOptimized>();

        mapMat.SetFloat("_DeltaX", seedPos.x);
        mapMat.SetFloat("_DeltaY", seedPos.y);
        previousSeedPos = seedPos;
    }

    private Texture2D GetTexture2D(RenderTexture rt)
    {
        RenderTexture currentActiveRT = RenderTexture.active;
        RenderTexture.active = rt;
        Texture2D tex = new Texture2D(rt.width, rt.height);
        tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);
        RenderTexture.active = currentActiveRT;
        return tex;
    }

    public void RenderTerrain()
    {
        Debug.Log("Render Terrain");
        //Generate heights
        if (!terrainRendered)
        {
            quadRenderer.material = mapMat;
            quadRenderer.material.SetFloat("_Scale", 3.0f);
            rt = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
            //rt.filterMode = FilterMode.Bilinear;
            rt.Create();
            cam.targetTexture = rt;
            cam.Render();
            GenerateNormals();
            GenerateAO();
            terrainRendered = true;
        }
        GenerateTerrain(rt);
        //quadRenderer.material = mapMat;
    }

    public void RerenderTerrain()
    {
        quadRenderer.material = mapMat;
        quadRenderer.material.SetFloat("_Scale", 3.0f);
        rt = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        //rt.filterMode = FilterMode.Bilinear;
        rt.Create();
        cam.targetTexture = rt;
        cam.Render();
        GenerateNormals();
        GenerateAO();
        terrainRendered = true;
        GenerateTerrain(rt);
    }

    void Start()
    {
        RenderTerrain();
    }

    void Update()
    {    
        if (Vector2.SqrMagnitude(seedPos - previousSeedPos) > 0.01)
        {
            mapMat.SetFloat("_DeltaX", seedPos.x);
            mapMat.SetFloat("_DeltaY", seedPos.y);
            RenderTerrain();
            previousSeedPos = seedPos;
        }



        if (Input.GetKey(KeyCode.R))
        {
            RenderTerrain();
        }

        if (Input.GetKey(KeyCode.T))
        {
            
        }
       
        //quadRenderer.material.SetFloat("_Delta", Time.time * 0.1f);

        /*
        if (erosionStep >= 0)
        {
            RenderTexture rt2 = new RenderTexture(size, size, 16, RenderTextureFormat.ARGBFloat);
            rt2.Create();

            quadRenderer.material = erosionMat;
            quadRenderer.material.SetTexture("_HeightTex", rt);
            cam.targetTexture = rt2;
            cam.Render();
            GenerateTerrain(rt2);
            rt = rt2;

            erosionStep++;
            Debug.Log(erosionStep);
            if (erosionStep > 5000)
            {
                //FinalizeTerrain();
                erosionStep = -1;
            }
        }
        */
    }

    private void GenerateTerrain(RenderTexture rt)
    {
        quadRenderer.material = convertHeightsMat;
        quadRenderer.material.SetTexture("_HeightTex", rt);
        RenderTexture rtn = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rtn.Create();
        cam.targetTexture = rtn;
        cam.Render();

        //rtn = rt;

        Texture2D tex = GetTexture2D(rtn);
        TerrainTest1.instance.GenerateTerrain(tex, rtn, rtao);
    }

    private void GenerateNormals()
    {
        //Generate normals
        blurOptimized.enabled = true;
        quadRenderer.material = mapNormalsMat;
        quadRenderer.material.SetTexture("_HeightTex", rt);
        rtnormals = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rtnormals.Create();
        cam.targetTexture = rtnormals;
        cam.Render();
        blurOptimized.enabled = false;
    }

    private void GenerateAO()
    {
        blurOptimized.enabled = true;
        quadRenderer.material = mapTextureMat;
        quadRenderer.material.SetTexture("_HeightTex", rt);
        quadRenderer.material.SetTexture("_NormalsTex", rtnormals);
        rttexture = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rttexture.wrapMode = TextureWrapMode.Repeat;
        rttexture.Create();
        cam.targetTexture = rttexture;
        cam.Render();
        blurOptimized.enabled = false;

        rtao = rttexture;
    }
    

}
