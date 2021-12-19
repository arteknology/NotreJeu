using UnityEngine;

[ExecuteAlways]
public class FillMaterialProperty : MonoBehaviour
{
    [Range(0,1)]public float Fill = 0;
    public Material fillMaterial;
    public Color fillColor = Color.green;
    private static readonly int fill = Shader.PropertyToID("_Fill");
    private static readonly int color = Shader.PropertyToID("_Color");

    void Update()
    {
        if (fillMaterial != null)
        {
            fillMaterial.SetFloat(fill, Fill);
            fillMaterial.SetColor(color, fillColor);
        }
        
    }
}