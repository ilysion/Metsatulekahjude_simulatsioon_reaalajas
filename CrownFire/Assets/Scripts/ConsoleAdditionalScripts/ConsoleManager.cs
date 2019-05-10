using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleManager : MonoBehaviour
{
    public static ConsoleManager instance;

    public GameObject terrainObject;
    public Material burnAreaMat;
    public Material flatMapMat;
    public Material normalMapMat;
    public Material proceduralMapMat;
    public Material burnVisualsTerrainMat;
    public Material whiteTerrainMat;
    public Material ProceduralChunkMat;
    public Material RealisticChunkMat;
    public Texture2D tempMat;
    public Texture2D temp1Mat;

    public Texture2D humidityMat;
    public Texture2D humidity1Mat;
    public Material Skybox1;
    public Material Skybox2;
    public Material Skybox3;
    public Material Skybox4;
    public Material Skybox5;
    public Material Skybox6;
    public GameObject Sun;
    public GameObject Moon;
    public GameObject MainLight;

    public GameObject infoPanel;
    public GameObject buttonsPanel;
    public GameObject directionPanel;
    private TerrainTest1 terrainTest1;
    
    public Text PassCounterText;
    public Text TimeText;
    public Text MapTypeText;
    public Text LoopingText;
    public Text SkyboxText;
    
    public Button LoopTogglButton;
    public Button resetButton;
    public Button tempTogglButton;
    public Button humidityTogglButton;
    public Button windTogglButton;
    public Button mapDataTogglButton;
    public Button burnVisualsTogglButton;
    public Button SkyboxTogglButton;
    public Button uiEnableButton;

    public Button NButton;
    public Button SButton;
    public Button EButton;
    public Button WButton;

    public Camera burnRenderCam;
    public Camera mainRenderCam;
    private BurnRendererTest1 burnRenderer;
    private MapRendererTest1 mapRenderer;
    
    public float loopTime = 30f;

    private bool tempEnabled = false;
    private bool humidityEnabled = false;
    private bool mapDataEnabled = false;
    private bool burnVisualsEnabled = false;
    private bool skyboxSwitched = true;
    private bool uiEnabled = true;
    private bool loopEnabled = false;
    private bool windEnabled = false;
    private int passCounter;
    private float timeFromStart;
    private float loopTimeStart;
    private int mapMatNumber = 1;
    private int skyboxNumber = 1;
    

    private Color buttonClickedColor;
    private Color buttonUnclickedColor;

    private void Awake()
    {
        instance = this;
        terrainTest1 = terrainObject.GetComponent<TerrainTest1>();
    }

    void Start()
    {
        buttonClickedColor = new Color32(255,200,0,160);
        buttonUnclickedColor = new Color32(255, 255, 255, 46);

        this.mapRenderer = mainRenderCam.GetComponent<MapRendererTest1>();
        this.burnRenderer = burnRenderCam.GetComponent<BurnRendererTest1>();
        LoopTogglButton.onClick.AddListener(LoopToggl);
        tempTogglButton.onClick.AddListener(togglTemp);
        humidityTogglButton.onClick.AddListener(togglHumidity);
        mapDataTogglButton.onClick.AddListener(togglMapData);
        burnVisualsTogglButton.onClick.AddListener(togglBurnVisuals);
        resetButton.onClick.AddListener(resetAll);
        SkyboxTogglButton.onClick.AddListener(togglSkybox);
        uiEnableButton.onClick.AddListener(togglUI);
        windTogglButton.onClick.AddListener(togglWind);

        NButton.onClick.AddListener(togglN);
        SButton.onClick.AddListener(togglS);
        EButton.onClick.AddListener(togglE);
        WButton.onClick.AddListener(togglW);

        MapTypeText.text = "map: Realistic";
        LoopingText.text = "Loop: Disabled";
        SkyboxText.text = "Skybox: Sun/Moon";

        //sets the starting skybox nr 3
        skyboxNumber = 3;
        togglSkybox();
        togglN();
    }
    
    void Update()
    {
        if (loopEnabled)
        {
            if(loopTimeStart + loopTime < Time.time)
            {
                loopTimeStart = Time.time;
                resetAll();
            }
        } 
    }
    
    public void togglN()
    {
        NButton.GetComponent<Image>().color = buttonClickedColor;
        SButton.GetComponent<Image>().color = buttonUnclickedColor;
        EButton.GetComponent<Image>().color = buttonUnclickedColor;
        WButton.GetComponent<Image>().color = buttonUnclickedColor;
        burnAreaMat.SetVector("_WindDirectionVector", new Vector4(0, -1, 0, 0));
    }
    public void togglS()
    {
        NButton.GetComponent<Image>().color = buttonUnclickedColor;
        SButton.GetComponent<Image>().color = buttonClickedColor;
        EButton.GetComponent<Image>().color = buttonUnclickedColor;
        WButton.GetComponent<Image>().color = buttonUnclickedColor;
        burnAreaMat.SetVector("_WindDirectionVector", new Vector4(0, 1, 0, 0));
    }
    public void togglE()
    {
        NButton.GetComponent<Image>().color = buttonUnclickedColor;
        SButton.GetComponent<Image>().color = buttonUnclickedColor;
        EButton.GetComponent<Image>().color = buttonClickedColor;
        WButton.GetComponent<Image>().color = buttonUnclickedColor;
        burnAreaMat.SetVector("_WindDirectionVector", new Vector4(-1, 0, 0, 0));
    }
    public void togglW()
    {
        NButton.GetComponent<Image>().color = buttonUnclickedColor;
        SButton.GetComponent<Image>().color = buttonUnclickedColor;
        EButton.GetComponent<Image>().color = buttonUnclickedColor;
        WButton.GetComponent<Image>().color = buttonClickedColor;
        burnAreaMat.SetVector("_WindDirectionVector", new Vector4(1, 0, 0, 0));
    }


    public void AddPasses(int count)
    {
        passCounter += count;
        PassCounterText.text = "Frame: " + passCounter;
    }

    public void updateTimeText(float time)
    {
        timeFromStart += time;
        TimeText.text = "Time: " + timeFromStart;
    }

    public void LoopToggl()
    {

        loopEnabled = !loopEnabled;
        if (loopEnabled)
        {
            LoopingText.text = "Loop: Enabled";
            loopTimeStart = Time.time;
            LoopTogglButton.GetComponent<Image>().color = buttonClickedColor;
        }
        else
        {
            LoopingText.text = "Loop: Disabled";
            loopTimeStart = 0f;
            LoopTogglButton.GetComponent<Image>().color = buttonUnclickedColor;
        }
    }

    public void togglUI()
    {
        uiEnabled = !uiEnabled;
        if (uiEnabled)
        {
            uiEnableButton.image.color = buttonUnclickedColor;
            uiEnableButton.GetComponent<Image>().color = buttonUnclickedColor;
            infoPanel.SetActive(true);
            directionPanel.SetActive(true);
            buttonsPanel.SetActive(true);
        }
        else
        {
            uiEnableButton.GetComponent<Image>().color = buttonClickedColor;
            infoPanel.SetActive(false);
            directionPanel.SetActive(false);
            buttonsPanel.SetActive(false);
        }
    }


    public void togglTemp()
    {
        tempEnabled = !tempEnabled;
        if (tempEnabled)
        {
            burnAreaMat.SetTexture("_TemperatureTex", tempMat);
            tempTogglButton.image.color = buttonClickedColor;
        }
        else
        {
            burnAreaMat.SetTexture("_TemperatureTex", temp1Mat);
            tempTogglButton.image.color = buttonUnclickedColor;
        }
    }

    public void togglWind()
    {
        windEnabled = !windEnabled;
        if (windEnabled)
        {
            burnAreaMat.SetFloat("_DisableWinds", 1.0f);
            windTogglButton.image.color = buttonClickedColor;
        }
        else
        {
            burnAreaMat.SetFloat("_DisableWinds", 0.0f);
            windTogglButton.image.color = buttonUnclickedColor;
        }
    }

    public void togglSkybox()
    {
        if (skyboxNumber == 6)
        {
            skyboxNumber = 1;
        }
        else
        {
            skyboxNumber += 1;
        }

        if (skyboxNumber == 1)
        {
            RenderSettings.skybox = Skybox1;
            Sun.SetActive(true);
            Moon.SetActive(true);
            MainLight.SetActive(false);
            SkyboxTogglButton.image.color = buttonUnclickedColor;
            SkyboxText.text = "Skybox: Sun/Moon";
        }
        else if(skyboxNumber == 2)
        {
            RenderSettings.skybox = Skybox2;
            Sun.SetActive(false);
            Moon.SetActive(false);
            MainLight.SetActive(true);
            SkyboxTogglButton.image.color = buttonClickedColor;
            SkyboxText.text = "Skybox: Bright";
        }
        else if (skyboxNumber == 3)
        {
            RenderSettings.skybox = Skybox3;
            Sun.SetActive(false);
            Moon.SetActive(false);
            MainLight.SetActive(true);
            SkyboxTogglButton.image.color = buttonUnclickedColor;
            SkyboxText.text = "Skybox: Day";
        }
        else if (skyboxNumber == 4)
        {
            RenderSettings.skybox = Skybox4;
            Sun.SetActive(false);
            Moon.SetActive(false);
            MainLight.SetActive(true);
            SkyboxTogglButton.image.color = buttonClickedColor;
            SkyboxText.text = "Skybox: Dim";
        }
        else if (skyboxNumber == 5)
        {
            RenderSettings.skybox = Skybox5;
            Sun.SetActive(false);
            Moon.SetActive(false);
            MainLight.SetActive(true);
            SkyboxTogglButton.image.color = buttonClickedColor;
            SkyboxText.text = "Skybox: Night";
        }
        else if (skyboxNumber == 6)
        {
            RenderSettings.skybox = Skybox6;
            Sun.SetActive(false);
            Moon.SetActive(false);
            MainLight.SetActive(true);
            SkyboxTogglButton.image.color = buttonClickedColor;
            SkyboxText.text = "Skybox: Rainy";
        }
    }

    public void togglHumidity()
    {
        humidityEnabled = !humidityEnabled;
        if (humidityEnabled)
        {
            burnAreaMat.SetTexture("_HumidityTex", humidityMat);
            humidityTogglButton.image.color = buttonClickedColor;
        }
        else
        {
            burnAreaMat.SetTexture("_HumidityTex", humidity1Mat);
            humidityTogglButton.image.color = buttonUnclickedColor;
        }
    }

    public void togglMapData()
    {
        //Switching between 1, 2 and 3.
        if(mapMatNumber == 3)
        {
            mapMatNumber = 1;
        }
        else
        {
            mapMatNumber += 1;
        }


        mapDataEnabled = !mapDataEnabled;
        if (mapMatNumber == 1)
        {
            MapTypeText.text = "map: Realistic";
            mapRenderer.mapMat = normalMapMat;
            terrainTest1.chunkMaterial = RealisticChunkMat;
            //Rerender terrain with new material
            mapRenderer.RerenderTerrain();
            mapDataTogglButton.image.color = buttonClickedColor;
        }
        else if(mapMatNumber == 2)
        {
            MapTypeText.text = "map: Flat";
            mapRenderer.mapMat = flatMapMat;
            terrainTest1.chunkMaterial = whiteTerrainMat;
            //Rerender terrain with new material
            mapRenderer.RerenderTerrain();
            mapDataTogglButton.image.color = buttonUnclickedColor;
        }
        //Procedural map:
        else
        {
            MapTypeText.text = "map: Procedural";
            //Setting different offset for procedurally generated map
            float randX = Random.Range(0, 10000);
            float randY = Random.Range(0, 10000);
            proceduralMapMat.SetFloat("_DeltaX", (randX));
            proceduralMapMat.SetFloat("_DeltaY", (randY));
            mapRenderer.mapMat = proceduralMapMat;
            terrainTest1.chunkMaterial = ProceduralChunkMat;
            //Rerender terrain with new material
            mapRenderer.RerenderTerrain();
            mapDataTogglButton.image.color = buttonUnclickedColor;
        }
    }

    public void togglBurnVisuals()
    {
        burnVisualsEnabled = !burnVisualsEnabled;
        if (burnVisualsEnabled)
        {
            terrainTest1.chunkMaterial = whiteTerrainMat;
            //Rerender terrain with new material
            mapRenderer.RenderTerrain();
            burnVisualsTogglButton.image.color = buttonClickedColor;
        }
        else
        {
            terrainTest1.chunkMaterial = burnVisualsTerrainMat;
            //Rerender terrain with new material
            mapRenderer.RenderTerrain();
            burnVisualsTogglButton.image.color = buttonUnclickedColor;
        }
    }


    public void resetAll()
    {
        //It means procedurally generated map is used and so
        //Every time it gets different map
        if(mapMatNumber == 3)
        {
            //Setting different offset for procedurally generated map
            float randX = Random.Range(0, 10000);
            float randY = Random.Range(0, 10000);
            proceduralMapMat.SetFloat("_DeltaX", (randX));
            proceduralMapMat.SetFloat("_DeltaY", (randY));
            mapRenderer.RerenderTerrain();
        }
        //TerrainTest1.instance.SetBurnData();
        burnRenderer.ResetBurnData();
        timeFromStart = 0f;
        passCounter = 0;
    }

    /*
     * render 50 passes
     * for (int i = 0; i < 50; i++)
        {
            terrainTest1.passTimeAndRender(1f);
        }
        passCounter += 50;
        mapRenderer.RenderTerrain();
     */
}
