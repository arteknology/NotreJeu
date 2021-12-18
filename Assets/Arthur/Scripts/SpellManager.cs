using System.Collections;
using UnityEngine;

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
        
        void Start()
        {
            _stressManager = GetComponent<StressManager>();
            _blinkCdTimer = BlinkCoolDown;
            _purgeCdTimer = PurgeCoolDown;
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
            PurgeAmount = (_stressManager.CurrentStressLevel / 100) * PurgePercentage;
            _stressManager.CurrentStressLevel -= PurgeAmount;
        }
    }
}
