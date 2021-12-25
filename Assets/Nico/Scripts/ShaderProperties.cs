using UnityEngine;

namespace Properties {
    public static class ShaderProperties {

        //Floats
        public static readonly int Wetness = ToID("_Wetness");
        public static readonly int Horizon = ToID("_Horizon");
        public static readonly int BackgroundXOffset = ToID("_XOffset");
    
        //Time Management
        public static readonly int DayTime = ToID("_DayTime");
        public static readonly int DayTimeLerp = ToID("_DayTimeLerp");
        public static readonly int CustomTime = ToID("_CustomTime");
    
        //Water
        public static readonly int WaterHeight = ToID("_WaterHeight");
        public static readonly int WaterTransition = ToID("_WaterTransition");
        public static readonly int FlowSpeed = ToID("_FlowSpeed");
        public static readonly int WaveSpeed = ToID("_WaveSpeed");
        public static readonly int WaterColor = ToID("_WaterColor");
    
        //Lighting
        public static readonly int SunDirection = ToID("_SunDirection");
        public static readonly int AmbientColor = ToID("_AmbientColor");
        public static readonly int ShadowColor = ToID("_ShadowColor");
        public static readonly int VegetationColor = ToID("_VegetationColor");
        
        //Snow
        public static readonly int Snow = ToID("_Snow");
        public static readonly int SnowBlur = ToID("_SnowBlur");
        
        public static readonly int SnowFlakes = ToID("_SnowFlakes");
        public static readonly int SnowFlakeFallSpeed = ToID("_SnowFlakeFallSpeed");
        public static readonly int SnowFlakeWobbleSpeed = ToID("_SnowFlakeWobbleSpeed");
        
        public static readonly int SnowDirection = ToID("_SnowDirection");
        public static readonly int SnowColor = ToID("_SnowColor");
        public static readonly int SnowAmbientColor = ToID("_SnowAmbientColor");
    
        //Rain
        public static readonly int RainAmount = ToID("_RainAmount");
        public static readonly int RainSpeed = ToID("_RainSpeed");
        public static readonly int RainAngle = ToID("_RainAngle");
        public static readonly int RainOpacity = ToID("_RainOpacity");
        public static readonly int Thunder = ToID("_Thunder");
    
        // Wind
        public static readonly int WindDirection = ToID("_WindDirection");
        public static readonly int WindStrength = ToID("_WindStrength");
        public static readonly int WindSpeed = ToID("_WindSpeed");
    
        //Sky
        public static readonly int SkyColor = ToID("_SkyColor");
        public static readonly int HorizonColor = ToID("_HorizonColor");
        public static readonly int MoonColor = ToID("_MoonColor");
        public static readonly int SunColor = ToID("_SunColor");
        public static readonly int MoonRotation = ToID("_MoonRotation");
        public static readonly int AstralSize = ToID("_AstralSize");
        public static readonly int NorthStarPosition = ToID("_NorthStarPosition");
        public static readonly int OrbitSize = ToID("_OrbitSize");

        //Clouds
        public static readonly int CloudColor = ToID("_CloudColor");
        public static readonly int CloudOpacity = ToID("_CloudOpacity");
        public static readonly int CloudCover = ToID("_CloudCover");
        public static readonly int CloudSpeed = ToID("_CloudSpeed");

        //Fire & Smoke
        public static readonly int FireColor = ToID("_FireColor");
        public static readonly int FireOpacity = ToID("_FireOpacity");
        public static readonly int SmokeOpacity = ToID("_SmokeOpacity");
        public static readonly int SmokeColor = ToID("_SmokeColor");
        public static readonly int FireSmokeColor = ToID("_FireSmokeColor");
        public static readonly int SmokeAngle = ToID("_SmokeAngle");
        public static readonly int SmokeHeight = ToID("_SmokeHeight");
        public static readonly int FireOffset = ToID("_FireOffset");
        public static readonly int FireSmokeOffset = ToID("_FireSmokeOffset");
        public static readonly int FireSmokeRange = ToID("_FireSmokeRange");

        //Mist
        public static readonly int MistThickness = ToID("_MistThickness");
        public static readonly int MistSpeed = ToID("_MistSpeed");
        public static readonly int MistColor = ToID("_MistColor");

        //Buildings
        public static readonly int BuildingLightsFrequency = ToID("_BuildingLightFrequency");
        public static readonly int BuildingLightsColor = ToID("_BuildingLightColor");
        public static readonly int ConstructionDustColor = ToID("_ConstructionDustColor");
        public static readonly int ConstructionDustOpacity = ToID("_ConstructionDustOpacity");
        public static readonly int GrungeAmount = ToID("_GrungeAmount");
        public static readonly int GrungeColor = ToID("_GrungeColor");
        
        //Paper effect
        public static readonly int PaperLerpState = ToID("_PaperLerpState");
        public static readonly int PaperAmount = ToID("_PaperAmount");
        public static readonly int PaperColor = ToID("_PaperColor");
        public static readonly int MapState1 = ToID("_MapState1");
        public static readonly int MapState2 = ToID("_MapState2");
        public static readonly int EdgeNoiseStrength = ToID("_EdgeNoiseStrength");
        public static readonly int EdgeNoiseScale = ToID("_EdgeNoiseScale");
        public static readonly int GrungeNoiseScale = ToID("_GrungeNoiseScale");
        public static readonly int MapTilingAndOffset = ToID("_MapTilingAndOffset"); 
        public static readonly int PaperTexture = ToID("_PaperTexture");
        
        // Fog Of War
        public static readonly int FOWLerpState = ToID("_FOWLerpState");
        public static readonly int FOWColor = ToID("_FOWColor");
        public static readonly int FOWTilingAndOffset = ToID("_FOWTilingAndOffset");
        public static readonly int FOWState1 = ToID("_FOWState1");
        public static readonly int FOWState2 = ToID("_FOWState2");
        
        // Paper & Fog Of War
        public static readonly int LerpBlur = ToID("_LerpBlur");
        public static readonly int BaseBlur = ToID("_BaseBlur");
        

        // Other Properties
        public static readonly int HexEdgeWidthTransparent = ToID("_HexEdgeWidthTransparent");
        public static readonly int HexEdgeWidthOpaque = ToID("_HexEdgeWidthOpaque");
        
        public static readonly int TesselationFactor = ToID("_TesselationFactor");
        
        
        

        // KEYWORDS
        public static readonly int SnowKeyword = ToID("SNOW_ON");
        public static readonly int WindKeyword = ToID("WIND_ON");
        public static readonly int ShadowsKeyword = ToID("SHADOWS_ON");

        private static int ToID(string Name) => Shader.PropertyToID(Name);
        
        public static void SetProperty(this float c, int ID) => Shader.SetGlobalFloat(ID, c);
        public static void SetProperty(this Vector4 c, int ID) => Shader.SetGlobalVector(ID, c);
        public static void SetProperty(this Color c, int ID) => Shader.SetGlobalColor(ID, c);
        public static void SetProperty(this Texture2D c, int ID) => Shader.SetGlobalTexture(ID, c);

        //Using Int Property ID
        public static void SetProperty(this int ID,  float c) => Shader.SetGlobalFloat(ID, c);
        public static void SetProperty(this int ID,  bool c) => Shader.SetGlobalFloat(ID, c ? 1 : 0);
        public static void SetProperty(this int ID, Vector4 c) => Shader.SetGlobalVector(ID, c);
        public static void SetProperty(this int ID, Color c) => Shader.SetGlobalColor(ID, c);
        public static void SetProperty(this int ID, Texture c) => Shader.SetGlobalTexture(ID, c);
        
        
        //Using Int Property ID
        public static void SetProperty(this Material m, int ID,  float c) => m.SetFloat(ID, c);
        public static void SetProperty(this Material m, int ID, Vector4 c) => m.SetVector(ID, c);
        public static void SetProperty(this Material m, int ID, Color c) => m.SetColor(ID, c);

        //Using String Property Name
        public static void SetProperty(this string Name,  float c) => Shader.SetGlobalFloat(Name, c);
        public static void SetProperty(this string Name, Vector4 c) => Shader.SetGlobalVector(Name, c);
        public static void SetProperty(this string Name, Color c) => Shader.SetGlobalColor(Name, c);
        
    }
}