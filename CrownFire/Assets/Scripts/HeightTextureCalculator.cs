using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeightTextureCalculator : MonoBehaviour
{
    public static HeightTextureCalculator instance;
    public Camera TerrainRenderCam;
    public Material mapMat;
    public BurnRendererTest1 burnRendererCam;
    private Texture2D mapDataTex2D;
    private int size;
    private Texture2D outColoredHeightTex2D;
    private bool isRendered = false;

    private void Awake()
    {
        instance = this;
    }

    void Start()
    {
        size = burnRendererCam.GetComponent<BurnRendererTest1>().size;
    }

    public void reloadHeightTexture()
    {
        setMapHeightTex2D();
        makeColoredHeightTex();
    }

    private void setMapHeightTex2D()
    {
        RenderTexture.active = TerrainRenderCam.targetTexture;
        Texture2D cameraImage = new Texture2D(TerrainRenderCam.targetTexture.width, TerrainRenderCam.targetTexture.height, TextureFormat.RGB24, false);
        cameraImage.ReadPixels(new Rect(0, 0, TerrainRenderCam.targetTexture.width, TerrainRenderCam.targetTexture.height), 0, 0);
        cameraImage.Apply();
        mapDataTex2D = new Texture2D(size, size, TextureFormat.RGB24, false);
        mapDataTex2D.wrapMode = TextureWrapMode.Repeat;
        mapDataTex2D = cameraImage;
    }

    private void makeColoredHeightTex()
    {
        outColoredHeightTex2D = new Texture2D(size, size, TextureFormat.RGBA32, false);
        outColoredHeightTex2D.wrapMode = TextureWrapMode.Repeat;

        // 0-0.5 langus, 0.5-1 tõus. protsendi jaoks languse puhul x2, tõusu puhul (tõus-0.5) x 2
        for (int i = 0; i < mapDataTex2D.width; i++)
        {
            for (int j = 0; j < mapDataTex2D.height; j++)
            {
                // r - up, g - right, b - down, a - left
                Color currentCol = mapDataTex2D.GetPixel(i, j);
                // -- up --
                Color upCol = mapDataTex2D.GetPixel(i, j + 15);
                float heightMultiplier1 = (currentCol.r / upCol.r) / 2;

                // -- right --
                Color rightCol = mapDataTex2D.GetPixel(i + 15, j);
                float heightMultiplier2 = (currentCol.r / rightCol.r) / 2;

                // -- down --
                Color downCol = mapDataTex2D.GetPixel(i, j - 15);
                float heightMultiplier3 = (currentCol.r / downCol.r) / 2;

                // -- left --
                Color leftCol = mapDataTex2D.GetPixel(i - 15, j);
                float heightMultiplier4 = (currentCol.r / leftCol.r) / 2;
                Color newPixelCol = new Color();
                newPixelCol.r = heightMultiplier1;
                newPixelCol.g = heightMultiplier2;
                newPixelCol.b = heightMultiplier3;
                newPixelCol.a = heightMultiplier4;
                outColoredHeightTex2D.SetPixel(i, j, newPixelCol);
            }
        }
        outColoredHeightTex2D.Apply();
        print("Done with heighttexture2");
        mapMat.SetTexture("_HeightTex", outColoredHeightTex2D);
    }
}
