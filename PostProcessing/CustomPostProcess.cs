using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class CustomPostProcess : MonoBehaviour 
{
    //Blur
    public bool UseBlur;
    [Range(1, 10)]
    public int BlurIterations = 1;
    [Range(1, 10)]
    public int DownSample = 6;
    public float BlurSize = 1;
    [Range(0, 1)]
    public float Alpha = 1;

    internal int p_BlurSize = Shader.PropertyToID("_BlurSize");
    internal int p_Alpha = Shader.PropertyToID("_Alpha");

    [Space(10)]
    //FXAA3.11
    public bool UseFXAA;
    float wideParam;
    float heightParam;
    float wideParam_1;
    float heightParam_1;

    [Space(10)]
    //Saturate com
    public bool UseSaturation;
    [Range(0,1)]
	public float Saturation;
    internal int p_Saturation = Shader.PropertyToID("_Saturation");

    [Space(10)]
    //Bloom
    public bool UseBloom;
    [Range(0, 2)]
    public float intensity = 0.6f;
    [Range(1, 16)]
    public int iterations = 2;
    [Range(0, 2)]
    public float Threshold = 1.1f;
    [Range(0, 1)]
    public float SoftThreshold = 0.3f;

    RenderTexture[] textures = new RenderTexture[16];

    internal int p_bloomFilter = Shader.PropertyToID("_Filter");
    internal int p_bloomIntensity = Shader.PropertyToID("_Intensity");
    internal int p_bloomSourceTex = Shader.PropertyToID("_SourceTex");


    [Space(10)]
    //Vignette
    public bool UseVignette;

    [Space(10)]
    //Exposure
    public bool UseExposure;
    
    [Range(-10, 10)]
    public float EV=-1f;
    internal int p_ev = Shader.PropertyToID("_EV");

    Shader shader_Com;
    Material mat_Com;

    internal const int CombinePass = 0;
    internal const int BloomPrefilterPass = 1;
	internal const int BloomDownSamplePass = 2;
	internal const int BloomUpSamplePass = 3;
	internal const int BlurHonrizontalPass = 4;
    internal const int BlurVerticalPass = 5;

    RenderTexture combineTemp;

    [Space(10)]
    //Tonmapping
    public bool UseToneMapping = true;

    //GammaCorrection
    public bool UseGammaCorrection = false;

    Material CreateMaterial(Shader shader,Material mat)
	{
		if(mat == null)
		{
			mat = new Material(shader);
            mat.hideFlags = HideFlags.DontSave;
			return mat;
		}
		else
			return mat;
	}
 
    protected void InitComMat()
    {
        if(shader_Com == null)
        {
            shader_Com = Shader.Find("PostProcessing/Combine");
        }
        mat_Com = CreateMaterial(shader_Com,mat_Com);
    }

	void OnRenderImage(RenderTexture src , RenderTexture dest)
	{
        InitComMat();

        RenderTexture combineTemp;
        combineTemp = src;

        mat_Com.SetTexture(p_bloomSourceTex, src);

        if(!UseBlur)
        {
            if (UseBloom)
            {
                combineTemp = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
                mat_Com.SetTexture(p_bloomSourceTex, src);
                Bloom(src,combineTemp);
                mat_Com.EnableKeyword("_USEBLOOM");
            }
            else
            {        
                mat_Com.DisableKeyword("_USEBLOOM");
            }

        }
        else
        {               
            mat_Com.DisableKeyword("_USEBLOOM");
        }

        //Base
        if (UseSaturation)
        {
            mat_Com.SetFloat(p_Saturation, Saturation);
            mat_Com.EnableKeyword("_USESATURATE");
        }
        else
        {
            mat_Com.DisableKeyword("_USESATURATE");
        }

        if(UseVignette)
        {
            mat_Com.EnableKeyword("_USEVIGNETTE");

        }
        else
        {
            mat_Com.DisableKeyword("_USEVIGNETTE");
        }

        if(UseToneMapping)
        {
            mat_Com.EnableKeyword("_TONEMAPPING");

        }
        else
        {
            mat_Com.DisableKeyword("_TONEMAPPING");
        }

        if(UseGammaCorrection)
        {
            mat_Com.EnableKeyword("_GAMMACORRECTION");

        }
        else
        {
            mat_Com.DisableKeyword("_GAMMACORRECTION");
        }
        if(UseExposure)
        {
            mat_Com.SetFloat(p_ev, EV);
            mat_Com.EnableKeyword("_USEEXPOSURE");

        }
        else
        {
            mat_Com.DisableKeyword("_USEEXPOSURE");
        }


        if(!UseBlur)
        {
            if (UseFXAA)
            {
                float rcpWidth = 1.0f / Screen.width;
                float rcpHeight = 1.0f / Screen.height;

                mat_Com.SetVector("_rcpFrame", new Vector4(rcpWidth, rcpHeight, 0, 0));
                mat_Com.SetVector("_rcpFrameOpt", new Vector4(rcpWidth * wideParam, rcpHeight * heightParam, rcpWidth * wideParam_1, rcpHeight * heightParam_1));
                mat_Com.EnableKeyword("_USEFXAA");
            }
            else
            {
                mat_Com.DisableKeyword("_USEFXAA");
            }
            Combine(combineTemp, dest);

        }
        else
        {
            combineTemp = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
            Combine(src, combineTemp);
            Blur(combineTemp,dest);
            RenderTexture.ReleaseTemporary(combineTemp);
        }


	}

    protected void Combine(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, mat_Com, CombinePass);
    }

    void Bloom(RenderTexture source, RenderTexture dest)
    {

        mat_Com.SetVector(p_bloomFilter, GetSoftKneeFilters());

        int width = source.width / 2;
        int height = source.height / 2;

        RenderTexture currentDestination = textures[0] =
            RenderTexture.GetTemporary(width, height, 0, source.format);
        mat_Com.SetFloat(p_bloomIntensity, intensity);
        Graphics.Blit(source, currentDestination, mat_Com, BloomPrefilterPass);
        RenderTexture currentSource = currentDestination;

        int i = 1;
        for (; i < iterations; i++)
        {
            width /= 2;
            height /= 2;
            if (height < 2)
            {
                break;
            }
            currentDestination = textures[i] =
                RenderTexture.GetTemporary(width, height, 0, source.format);
            Graphics.Blit(currentSource, currentDestination, mat_Com, BloomDownSamplePass);
            currentSource = currentDestination;
        }

        for (i -= 2; i >= 0; i--)
        {
            currentDestination = textures[i];
            textures[i] = null;
            Graphics.Blit(currentSource, currentDestination, mat_Com, BloomUpSamplePass);
            RenderTexture.ReleaseTemporary(currentSource);
            currentSource = currentDestination;
        }

        Graphics.Blit(currentSource, dest);
    
        RenderTexture.ReleaseTemporary(currentSource);

    }

    Vector4 GetSoftKneeFilters()
    {
        float knee = Threshold * SoftThreshold;
        Vector4 filter;
        filter.x = Threshold;
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);

        return filter;

    }

    protected void Blur(RenderTexture src, RenderTexture dest)
    {
        mat_Com.SetFloat(p_BlurSize,BlurSize);
        mat_Com.SetFloat(p_Alpha, Alpha);

        int width = src.width;
        int height = src.height;

        RenderTexture downRT = RenderTexture.GetTemporary(width/DownSample,height/DownSample,0,src.format);
        Graphics.Blit(src,downRT,mat_Com,BloomDownSamplePass);

        for (int i = 0; i < BlurIterations; i++)
        {
            RenderTexture tempRT = RenderTexture.GetTemporary(width/DownSample,height/DownSample,0,src.format);
            Graphics.Blit(downRT,tempRT,mat_Com,BlurHonrizontalPass);
            RenderTexture.ReleaseTemporary(downRT);
            downRT = tempRT;

            tempRT = RenderTexture.GetTemporary(width/DownSample,height/DownSample,0,src.format);
            Graphics.Blit(downRT,tempRT,mat_Com,BlurVerticalPass);
            RenderTexture.ReleaseTemporary(downRT);
            downRT = tempRT;
        }
        Graphics.Blit(downRT, dest);
        RenderTexture.ReleaseTemporary(downRT);
    }


    void Saturate(RenderTexture src, RenderTexture dest)
    {
        mat_Com.SetFloat(p_Saturation, Saturation);
    }

}
