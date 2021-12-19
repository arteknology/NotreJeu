
using UnityEngine;

[ExecuteAlways]
public class EyeProperty : MonoBehaviour
{
    [Range(0,1)]public float OpenEyes = 1;

    private static readonly int Eyes = Shader.PropertyToID("_OpenEyes");

    void Update()
    {
        Shader.SetGlobalFloat(Eyes, OpenEyes);
    }
}
