
using UnityEngine;

[ExecuteAlways]
public class MadnessProperty : MonoBehaviour
{
    [Range(0,1)]public float Madness = 0;

    private static readonly int madness = Shader.PropertyToID("_Madness");

    void Update()
    {
        Shader.SetGlobalFloat(madness, Madness);
    }
}
