using System.Collections;
using System.Collections.Generic;
using Assets.Arthur.Scripts;
using UnityEngine;

public class AnimationRedirector : MonoBehaviour
{
    public SpellManager SpellManager;

    public void TriggerBlink()
    {
        SpellManager.Blink();
    }

    public void TriggerPurge()
    {
        SpellManager.Purge();
    }

}
