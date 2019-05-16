using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class BurnRendererTest1 : MonoBehaviour
{

    public int size = 1024;
    public TerrainTest1 terrainObject;
    public Material mapMat;
    public Material mapNormalsMat;
    public Material mapTextureMat;
    public Material convertHeightsMat;
    public Material erosionMat;
    public Material BurnAreaMaterial;
    public Texture2D fireStartTexture2D;
    public Vector2 seedPos = new Vector2(0.0f, 0.0f);
    public Camera TerrainRenderCam;
    private Vector2 previousSeedPos;
    private RenderTexture rt;
    private RenderTexture rtburn;
    private GameObject quad;
    private MeshRenderer quadRenderer;
    private Camera cam;
    private Texture2D mapDataTex2D;
    private Texture2D outColoredHeightTex2D;
    private RenderTexture unchangedBurnAreaTexture;
    private RenderTexture rtBurnToPass;
    private bool heightTexRendered = false;
    private double testStart;
    private double movementSpeedTestStart;
    private int framesPassed = 0;
    bool LB = false;
    bool LT = false;
    bool RB = false;
    bool RT = false;
    bool movementSpeedStartReached = false;
    bool samplePointReached1 = false;
    bool samplePointReached2 = false;
    private bool startBurnSet = false;

    [Range(1, 1000)]
    public int givenSampleCount = 9;

    [Range(0.0001f, 1f)]
    public float givenSampleRadius = 0.001f;

    [Range(0.00001f, 0.1f)]
    public float givenColorBurnaway = 0.01f;

    [Range(1.0f, 1000f)]
    public float framerateLimiter = 1;

    [Range(0.001f, 10f)]
    public float burnSpeedMultiplier = 1;
    
    public void Awake()
    {
        cam = this.GetComponent<Camera>();
        quad = this.transform.Find("Quad").gameObject;
        quadRenderer = quad.GetComponent<MeshRenderer>();
        mapMat.SetFloat("_DeltaX", seedPos.x);
        mapMat.SetFloat("_DeltaY", seedPos.y);
        previousSeedPos = seedPos;
        unchangedBurnAreaTexture = rtburn;
    }

    void Start()
    {
        float randomSeed = Random.Range(0, 100000);
        BurnAreaMaterial.SetFloat("_RandomSeed", randomSeed);
        Debug.Log("Randomly generated seed for shader: " + randomSeed);
        testStart = Time.time;
        //set the fire starting place texture
        mapMat.SetTexture("_BurningTex", fireStartTexture2D);
        rtBurnToPass = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
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
        //Generate heights
        quadRenderer.material = mapMat;
        quadRenderer.material.SetFloat("_Scale", 3.0f);
        rt = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rt.Create();
        cam.targetTexture = rt;
        cam.Render();

        if (!heightTexRendered)
        {
            HeightTextureCalculator.instance.reloadHeightTexture();
            heightTexRendered = true;
        }
        GenerateBurn();
    }

    void Update()
    {
        terrainObject.speedMultiplier = this.framerateLimiter;
        BurnAreaMaterial.SetFloat("_GivenSampleRadius", givenSampleRadius);
        BurnAreaMaterial.SetFloat("_GivenSampleCount", givenSampleCount);
        BurnAreaMaterial.SetFloat("_GivenColorBurnaway", givenColorBurnaway);
        BurnAreaMaterial.SetFloat("_BurnAmmount", burnSpeedMultiplier);
    }

    public void ResetBurnData()
    {
        mapMat.SetTexture("_BurningTex", fireStartTexture2D);
    }

    private void GenerateBurn()
    {
        RenderTexture.Destroy(rtburn);
        rtburn = new RenderTexture(size, size, 16, RenderTextureFormat.ARGB32);
        rtburn.Create();
        cam.targetTexture = rtburn;
        if (!startBurnSet)
        {
            print("fire start texture set!");
            unchangedBurnAreaTexture = rtburn;
            startBurnSet = true;
        }
        cam.Render();
        mapMat.SetTexture("_BurningTex", rtburn);
        TerrainTest1.instance.GenerateBurn(rtburn);

        //----------------------For Pixel movement test uncomment the following line: ------------------------------------
        //PixelMovementTest(rtburn);

    }
    
    private void PixelMovementTest(RenderTexture rt)
    {
        RenderTexture.active = rtburn;
        Texture2D currentTex = new Texture2D(size, size, TextureFormat.RGB24, false);
        currentTex.wrapMode = TextureWrapMode.Clamp;
        currentTex.ReadPixels(new Rect(0, 0, size, size), 0, 0, false);
        currentTex.Apply();
        Color pixelLeftBottom = currentTex.GetPixel(0, 0);
        Color pixelLeftTop = currentTex.GetPixel(0, 512);
        Color pixelRightBottom = currentTex.GetPixel(512, 0);
        Color pixelRightTop = currentTex.GetPixel(512, 512);

        //256 + 100 + 200
        Color samplePointPixelTestStart = currentTex.GetPixel(256, 300);
        Color samplePointPixel1 = currentTex.GetPixel(256, 400);
        Color samplePointPixel2 = currentTex.GetPixel(256, 500);
        
        //Setting the frame start time:
        float currentFrameStartTime = Time.time;

        if (!LB && pixelLeftBottom.r != 1.0)
        {
            Debug.Log("Fire reached left bottom corner in: " + (currentFrameStartTime - testStart));
            LB = true;
        }

        if (!LT && pixelLeftTop.r != 1.0)
        {
            Debug.Log("Fire reached left top corner in: " + (currentFrameStartTime - testStart));
            LT = true;
        }

        if (!RB && pixelRightBottom.r != 1.0)
        {
            Debug.Log("Fire reached right bottom corner in: " + (currentFrameStartTime - testStart));
            RB = true;
        }

        if (!RT && pixelRightBottom.r != 1.0)
        {
            Debug.Log("Fire reached right top corner in: " + (currentFrameStartTime - testStart));
            RT = true;
        }

        //Movement speed test:

        if (!movementSpeedStartReached && samplePointPixelTestStart.r != 1.0)
        {
            movementSpeedTestStart = Time.time;
            movementSpeedStartReached = true;
            Debug.Log("Fire movement speed consistency test started!");
        }

        if (movementSpeedStartReached)
        {
            framesPassed += 1;
        }

        if (!samplePointReached1 && samplePointPixel1.r != 1.0)
        {
            Debug.Log("Fire reached first sample point in (100px from start): " + (currentFrameStartTime - movementSpeedTestStart));
            Debug.Log("First point reach frames: (100px from start): " + (framesPassed));
            samplePointReached1 = true;
        }

        if (!samplePointReached2 && samplePointPixel2.r != 1.0)
        {
            Debug.Log("Fire reached seccond sample point in (200px from start): " + (currentFrameStartTime - movementSpeedTestStart));
            Debug.Log("Seccond point reach frames: (200px from start): " + (framesPassed));
            samplePointReached2 = true;
        }
    }

}