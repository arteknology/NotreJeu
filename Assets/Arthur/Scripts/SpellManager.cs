using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Arthur.Scripts
{
    [RequireComponent(typeof(StressManager))]
    public class SpellManager : MonoBehaviour
    {
        private StressManager _stressManager;
        private EyeProperty eyeProperty;
        public bool IsUsingBlinkSpell = false;
        private bool canUseBlink = true;
        private bool canUsePurge = true;

        public float BlinkCoolDown = 15f;
        public float BlinkDuration = 2f;
        public float PurgeCoolDown = 15f;
        public float PurgePercentage = 25f;
        private float PurgeAmount;

        private float _blinkCdTimer;
        private float _purgeCdTimer;

        public Slider BlinkSlider;
        public Slider PurgeSlider;
        public Image BlinkLogo;
        public Image PurgeLogo;
        public Image BlinkKey;
        public Image PurgeKey;
        private Color BaseColor;
        private Color NewColor;
        
        void Start()
        {
            _stressManager = GetComponent<StressManager>();
            eyeProperty = GetComponent<EyeProperty>();
            eyeProperty.OpenEyes = 1;
            
            _blinkCdTimer = BlinkCoolDown;
            _purgeCdTimer = PurgeCoolDown;
            
            BlinkSlider.maxValue = BlinkCoolDown;
            BlinkSlider.value = 0;
            
            PurgeSlider.maxValue = PurgeCoolDown;
            PurgeSlider.value = 0;

            canUseBlink = false;
            canUsePurge = false;

            BaseColor = BlinkLogo.color;
            NewColor = BaseColor;
            NewColor.a = 0.5f;

            BlinkLogo.color = NewColor;
            BlinkKey.color = NewColor;
            PurgeLogo.color = NewColor;
            PurgeKey.color = NewColor;
        }

        void Update()
        {
            //BLINK
            if (canUseBlink)
            {
                if (Input.GetKey(KeyCode.E))
                { 
                    Blink();
                }
            }
            
            else
            {
                if (!IsUsingBlinkSpell)
                {
                    if (_blinkCdTimer > 0)
                    {
                        _blinkCdTimer -= Time.deltaTime;
                        BlinkSlider.value += Time.deltaTime;
                    }
                    else
                    {
                        _blinkCdTimer = BlinkCoolDown;
                        BlinkLogo.color = BaseColor;
                        BlinkKey.color = BaseColor;
                        canUseBlink = true;
                    }
                }
            }

            //PURGE
            if (canUsePurge && _stressManager.CurrentStressLevel > 10)
            {
                if (Input.GetKey(KeyCode.R))
                {
                    Purge();
                }
            }
            
            else
            {
                if (_purgeCdTimer > 0)
                {
                    _purgeCdTimer -= Time.deltaTime;
                    PurgeSlider.value += Time.deltaTime;
                }
                    
                else
                {
                    _purgeCdTimer = PurgeCoolDown;
                    PurgeLogo.color = BaseColor;
                    PurgeKey.color = BaseColor;
                    canUsePurge = true;
                }
            }
        }

        private void Blink()
        {
            IsUsingBlinkSpell = true;
            BlinkSlider.value = 0;
            eyeProperty.OpenEyes = 0;
            BlinkLogo.color = NewColor;
            BlinkKey.color = NewColor;
            StartCoroutine(WaitForSeconds());

        }

        IEnumerator WaitForSeconds()
        {
            yield return new WaitForSeconds(BlinkDuration);
            IsUsingBlinkSpell = false;
            canUseBlink = false;
            eyeProperty.OpenEyes = 1;
        }
        private void Purge()
        {
            canUsePurge = false;
            PurgeSlider.value = 0;
            PurgeLogo.color = NewColor;
            PurgeKey.color = NewColor;
            PurgeAmount = (_stressManager.CurrentStressLevel / 100) * PurgePercentage;
            _stressManager.CurrentStressLevel -= PurgeAmount;
        }
    }
}
