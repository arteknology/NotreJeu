using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Arthur.Scripts
{
    [RequireComponent(typeof(StressManager))]
    public class SpellManager : MonoBehaviour
    {
        private StressManager _stressManager;
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

        void Start()
        {
            _stressManager = GetComponent<StressManager>();
            _blinkCdTimer = BlinkCoolDown;
            _purgeCdTimer = PurgeCoolDown;
            
            BlinkSlider.maxValue = BlinkCoolDown;
            BlinkSlider.value = 0;
            
            PurgeSlider.maxValue = PurgeCoolDown;
            PurgeSlider.value = 0;

            canUseBlink = false;
            canUsePurge = false;

        }

        void Update()
        {
            //BLINK
            if (canUseBlink && _stressManager.CurrentStressLevel > 10)
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
                        canUseBlink = true;
                    }
                }
            }

            //PURGE
            if (canUsePurge)
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
                    canUsePurge = true;
                }
            }
        }

        private void Blink()
        {
            IsUsingBlinkSpell = true;
            BlinkSlider.value = 0;
            StartCoroutine(WaitForSeconds());

        }

        IEnumerator WaitForSeconds()
        {
            yield return new WaitForSeconds(BlinkDuration);
            IsUsingBlinkSpell = false;
            canUseBlink = false;
        }
        private void Purge()
        {
            canUsePurge = false;
            PurgeSlider.value = 0;
            PurgeAmount = (_stressManager.CurrentStressLevel / 100) * PurgePercentage;
            _stressManager.CurrentStressLevel -= PurgeAmount;
        }
    }
}
