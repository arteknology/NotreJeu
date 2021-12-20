using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Assets.Arthur.Scripts;

public class DieAnimRedirector : MonoBehaviour
{
    public StressManager stressManager;

    public void TriggerDie()
    {
        stressManager.Die();
    }
}
