using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace Assets.Arthur.Scripts
{
    [RequireComponent(typeof(SpellManager))]
    public class StressManager : MonoBehaviour
    {
        private Controller _controller;
        private SpellManager _spellManager;
        private bool isUsingBlinkSpell = false;
        public bool isProtected = false;
        
        private float _startStressLevel = 0;
        public float CurrentStressLevel;
        
        [SerializeField]private float StressIncrement = 0.5f;
        private float MaxStressLevel = 100f;
        public float StressMultiplicator = 1;

        public float TimeBetweenIncrement = 0.2f;
        public float TimeBetweenDecrement = 0.4f;
        public float TimeBeforeDeath = 3f;
        public GameObject DiePanel;
        private float DecreaseAmount;
        
        private float _mainTimer;
        private float _decreaseTimer;
        private float _deathTimer;

        private MadnessProperty _stressSlider;
        private BloodProperty _bloodLevel;
        
        public AudioSource NormalBpm;
        public AudioSource ThirtyPercentBpm;
        public AudioSource SixtyPercentBpm;
        public AudioSource MaxBpm;

        public FpsCam _camera;
        public GameObject StressSound;
        public GameObject UIIG;

        public Animation PlayerCamAnimator;
        public AnimationClip AnimDie;

        private List<GameObject> _passedMultipliers = new List<GameObject>(); 

        void Start()
        {
            DiePanel.SetActive(false);
            StressSound.SetActive(true);
            UIIG.SetActive(true);
            
            _controller = GetComponent<Controller>();
            _bloodLevel = GetComponent<BloodProperty>();
            _stressSlider = GetComponent<MadnessProperty>();
            _spellManager = GetComponent<SpellManager>();

            _bloodLevel.Blood = 0f;
            _stressSlider.Madness = 0f;
            
            NormalBpm.volume = 0.5f;
            ThirtyPercentBpm.volume = 0f;
            SixtyPercentBpm.volume = 0f;
            MaxBpm.volume = 0f;

            CurrentStressLevel = _startStressLevel;
            _mainTimer = TimeBetweenIncrement;
            _decreaseTimer = TimeBetweenDecrement;
            _deathTimer = TimeBeforeDeath;
        }

        void Update()
        {
            _stressSlider.Madness = CurrentStressLevel / 100;
            
            if (CurrentStressLevel < 30)
            {
                NormalBpm.volume = 0.55f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0f;
            }

            else if(CurrentStressLevel > 31 && CurrentStressLevel < 49)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0.65f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0f;
            }
            
            else if(CurrentStressLevel > 50 && CurrentStressLevel < 60)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0.75f;
                MaxBpm.volume = 0f;
            }

            else if(CurrentStressLevel > 70)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0.85f;
            }

            isUsingBlinkSpell = _spellManager.IsUsingBlinkSpell;

            if (_mainTimer > 0)
            {
                _mainTimer -= Time.deltaTime;
            }

            else
            { 
                if (CurrentStressLevel < MaxStressLevel)
                {
                    if (!isUsingBlinkSpell && !isProtected)
                    {
                        IncreaseStressAmount();
                    }
                }
                else
                {
                    StressSound.SetActive(false);
                    _camera.enabled = false;
                    _controller.enabled = false;
                }
                _mainTimer = TimeBetweenIncrement;
            }

            _bloodLevel.Blood = ((CurrentStressLevel / 100f) - 0.2f) * 1.2f;
        }
        
        private void IncreaseStressAmount()
        {
            CurrentStressLevel += StressIncrement * StressMultiplicator
        ;
        }

        private void DecreaseStressAmount()
        {
            DecreaseAmount = StressIncrement * StressMultiplicator;
            
            if (_decreaseTimer > 0)
            {
                _decreaseTimer -= Time.deltaTime;
            }

            else
            {
                if (CurrentStressLevel > _startStressLevel)
                {
                    CurrentStressLevel -= DecreaseAmount;
                }
                _decreaseTimer = TimeBetweenDecrement;
            }
        }
        
        public void Die()
        {
            UIIG.SetActive(false);
            DiePanel.SetActive(true);
            Cursor.lockState = CursorLockMode.None;
        }
        
        ///
        ///
        /// 
        /// <summary>
        /// Méthodes utilisants des colliders
        /// </summary>
        ///
        ///
        ///
        
        private void OnTriggerStay(Collider other)
        {
            if (other.gameObject.CompareTag("SafeZone"))
            {
                isProtected = true;
                DecreaseStressAmount();
            }
        }

        private void OnTriggerExit(Collider other)
        {
            if (other.gameObject.CompareTag("SafeZone"))
            {
                isProtected = false;
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            if (other.gameObject.CompareTag("StressMultiplier"))
            {
                if (!_passedMultipliers.Contains(other.gameObject))
                {
                    StressMultiplicator += 0.2f;
                    _passedMultipliers.Add(other.gameObject);
                }
            }
        }

    }
}
