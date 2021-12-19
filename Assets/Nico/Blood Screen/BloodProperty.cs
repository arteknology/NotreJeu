
using UnityEngine;

[ExecuteAlways]
public class BloodProperty : MonoBehaviour
{
    [Range(0,1)]public float Blood = 0;

    private static readonly int blood = Shader.PropertyToID("_Blood");

    void Update()
    {
        Shader.SetGlobalFloat(blood, Blood);
    }
}
