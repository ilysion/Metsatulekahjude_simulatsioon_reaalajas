using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class BurnRenderer : MonoBehaviour
{

    public int size = 1024;
    public Terrain terrainObject;
    public Material mapMat;
    public Material mapNormalsMat;
    public Material mapTextureMat;
    public Material convertHeightsMat;
    public Material erosionMat;
    public Material BurnAreaMaterial;
    public Texture2D fireStartTexture2D;
    public Vector2 seedPos = new Vector2(0.0f, 0.0f);

    [Range(1, 1000)]
    public int givenSampleCount = 9;

    [Range(0.0001f, 1f)]
    public float givenSampleRadius = 0.001f;

    [Range(0.00001f, 0.1f)]
    public float givenColorBurnaway = 0.01f;

    [Range(1.0f, 1000f)]
    public float speedMultiplier = 1;

    private Vector2 previousSeedPos;
    private RenderTexture rt;
    private RenderTexture rtburn;
    private GameObject quad;
    private MeshRenderer quadRenderer;
    private Camera cam;




    bool movementSpeedStartReached = false;
    bool samplePointReached1 = false;
    bool samplePointReached2 = false;

    public void Awake()
    {
        cam = this.GetComponent<Camera>();
        quad = this.transform.Find("Quad").gameObject;
        quadRenderer = quad.GetComponent<MeshRenderer>();

        mapMat.SetFloat("_DeltaX", seedPos.x);
        mapMat.SetFloat("_DeltaY", seedPos.y);
        previousSeedPos = seedPos;
    }

    void Start()
    {
        float randomSeed = Random.Range(0, 100000);
        BurnAreaMaterial.SetFloat("_RandomSeed", randomSeed);
        Debug.Log("Randomly generated seed for shader: " + randomSeed);
        //set the fire starting place texture
        mapMat.SetTexture("_BurningTex", fireStartTexture2D);

       
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
        //Debug.Log("Render Terrain");
        //Generate heights

        quadRenderer.material = mapMat;
        quadRenderer.material.SetFloat("_Scale", 3.0f);
        rt = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        //rt.filterMode = FilterMode.Bilinear;
        rt.Create();
        cam.targetTexture = rt;
        cam.Render();
        

        GenerateBurn();
        //quadRenderer.material = mapMat;
    }


    void Update()
    {
        terrainObject.speedMultiplier = this.speedMultiplier;
        BurnAreaMaterial.SetFloat("_GivenSampleRadius", givenSampleRadius);
        BurnAreaMaterial.SetFloat("_GivenSampleCount", givenSampleCount);
        BurnAreaMaterial.SetFloat("_GivenColorBurnaway", givenColorBurnaway);
    }

    private void GenerateBurn()
    {
        quadRenderer.material = mapMat;
        quadRenderer.material.SetTexture("_HeightTex", rt);
        rtburn = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rtburn.Create();
        cam.targetTexture = rtburn;
        //mapMat.mainTexture = rtburn;
        cam.Render();
        mapMat.SetTexture("_BurningTex", rtburn);
        Terrain.instance.GenerateBurn(rtburn);

        pixelMovementTest(rtburn);

    }

    private void pixelMovementTest(RenderTexture rt)
    {
        RenderTexture.active = rtburn;
        Texture2D currentTex = new Texture2D(size, size, TextureFormat.RGB24, false);
        currentTex.wrapMode = TextureWrapMode.Clamp;
        currentTex.ReadPixels(new Rect(0, 0, size, size), 0, 0, false);
        currentTex.Apply();
    }

}

/*
 * Old generate burn with texture copying
 * 
   private void GenerateBurn()
    {
        quadRenderer.material = mapMat;
        quadRenderer.material.SetTexture("_HeightTex", rt);
        rtburn = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rtburn.Create();
        cam.targetTexture = rtburn;
        //mapMat.mainTexture = rtburn;
        cam.Render();

        //This is pretty slow, but its finally working!!!
        RenderTexture.active = rtburn;
        Texture2D currentTex = new Texture2D(size, size, TextureFormat.RGB24, false);
        currentTex.wrapMode = TextureWrapMode.Clamp;
        currentTex.ReadPixels(new Rect(0, 0, size, size), 0, 0, false);
        currentTex.Apply();
        //Benchmarkimise jaoks jms
        //currentTex.GetPixel()
        mapMat.SetTexture("_BurningTex", currentTex);


        Terrain.instance.GenerateBurn(rtburn);
    }
    */
