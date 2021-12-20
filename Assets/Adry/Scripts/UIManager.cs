using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class UIManager : MonoBehaviour
{

    public GameObject MenuPanel;
    public GameObject SettingsPanel;
    public Animator CamAnimator;
    public Camera Cam;
    public GameObject FpsCam;
    public GameObject IGUI;
    public GameObject Credits;
    public GameObject MenuCam;
    public GameObject MiniScene;

    void Start()
    {
        MenuPanel.SetActive(true);
        SettingsPanel.SetActive(false);
        IGUI.SetActive(false);
        Credits.SetActive(false);
        MenuCam.SetActive(true);
        MiniScene.SetActive(true);
    }

    public void SettingsButton()
    {
        MenuPanel.SetActive(false);
        Invoke("SettingsDelay", 0.6f);
        CamAnimator.Play("SettingsAnim");
    }

    public void SettingsDelay()
    {
        SettingsPanel.SetActive(true);
    }

    public void BackButton()
    {
        Invoke("MenuDelay", 0.5f);
        SettingsPanel.SetActive(false);
        CamAnimator.Play("SettingsAnimOut");
    }

    public void MenuDelay()
    {
        MenuPanel.SetActive(true);
    }

    public void BackButton2()
    {
        Invoke("MenuDelay", 0.5f);
        Credits.SetActive(false);
        CamAnimator.Play("CreditsOut");
    }

    public void CreditsBut()
    {
        MenuPanel.SetActive(false);
        CamAnimator.Play("CreditsIn");
        Invoke("CreditsDelay", 0.6f);
    }

    public void CreditsDelay()
    {
        Credits.SetActive(true);
    }

    public void QuitButton()
    {
        Application.Quit();
    } 

    public void PlayButton()
    {
        MenuPanel.SetActive(false);

        CamAnimator.Play("MenuCamPlay");
        Invoke("MenuCamStop", 4.4f);
    }

    public void MenuCamStop()
    {
        MenuCam.SetActive(false);
        MiniScene.SetActive(false);
        FpsCam.SetActive(true);
        IGUI.SetActive(true);
    }

    public void Menu()
    {
        SceneManager.LoadScene("MenuTest");
    }

}
