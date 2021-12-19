using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIManager : MonoBehaviour
{

    public GameObject MenuPanel;
    public GameObject SettingsPanel;
    public Animator CamAnimator;
    public Camera Cam;
    public GameObject FpsCam;
    public GameObject IGUI;

    void Start()
    {
        MenuPanel.SetActive(true);
        SettingsPanel.SetActive(false);
        IGUI.SetActive(false);
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

    public void QuitButton()
    {
        Application.Quit();
    } 

    public void PlayButton()
    {
        MenuPanel.SetActive(false);
        CamAnimator.Play("MenuCamPlay");
        Invoke("CamDestroy", 3.3f);
    }

    public void CamDestroy()
    {
        Destroy(Cam);
        FpsCam.SetActive(true);
        IGUI.SetActive(true);
    }

}
