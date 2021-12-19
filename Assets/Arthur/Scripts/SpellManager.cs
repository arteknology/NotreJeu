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
        public bool IsUsingPurgeSpell = false;
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

        public Animator Anim;
        public AudioClip BlinkSound;
        public AudioClip PurgeSound;
        private AudioSource AudioSource;
        
        void Start()
        {
            AudioSource = GetComponent<AudioSource>();
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
            NewColor.a = 0.4f;

            BlinkLogo.color = NewColor;
            BlinkKey.color = NewColor;
            PurgeLogo.color = NewColor;
            PurgeKey.color = NewColor;
            
            Anim.SetBool("UseBlink", false);
            Anim.SetBool("UsePurge", false);
        }

        void Update()
        {
            //BLINK
            if (canUseBlink && !IsUsingPurgeSpell)
            {
                if (Input.GetKey(KeyCode.E))
                { 
                    Anim.SetBool("UseBlink", true);
                    AudioSource.clip = BlinkSound;
                    AudioSource.Play();
                }
            }
            
            else
            {
                if (!IsUsingBlinkSpell)
                {
                    Anim.SetBool("UseBlink", false);

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
            if (canUsePurge && _stressManager.CurrentStressLevel > 10 && !IsUsingBlinkSpell)
            {
                if (Input.GetKey(KeyCode.R))
                {
                    Anim.SetBool("UsePurge", true);
                    AudioSource.clip = PurgeSound;
                    AudioSource.Play();
                }
            }
            
            else
            {
                IsUsingPurgeSpell = false;
                Anim.SetBool("UsePurge", false);
                
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

        public void Blink()
        {
            IsUsingBlinkSpell = true;
            BlinkSlider.value = 0;
            eyeProperty.OpenEyes = 0;
            BlinkLogo.color = NewColor;
            BlinkKey.color = NewColor;
            StartCoroutine(WaitForSeconds());

        }

        private IEnumerator WaitForSeconds()
        {
            yield return new WaitForSeconds(BlinkDuration);
            IsUsingBlinkSpell = false;
            canUseBlink = false;
            eyeProperty.OpenEyes = 1;
        }
        public  void Purge()
        {
            IsUsingPurgeSpell = true;
            canUsePurge = false;
            PurgeSlider.value = 0;
            PurgeLogo.color = NewColor;
            PurgeKey.color = NewColor;
            PurgeAmount = (_stressManager.CurrentStressLevel / 100) * PurgePercentage;
            _stressManager.CurrentStressLevel -= PurgeAmount;
        }
    }
}
