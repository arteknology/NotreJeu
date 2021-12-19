using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Arthur.Scripts
{
    [RequireComponent(typeof(SpellManager))]
    public class StressManager : MonoBehaviour
    {
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
        private float DecreaseAmount;
        
        private float _mainTimer;
        private float _decreaseTimer;
        private float _deathTimer;

        public Slider StressSlider;
        public AudioSource NormalBpm;
        public AudioSource ThirtyPercentBpm;
        public AudioSource SixtyPercentBpm;
        public AudioSource MaxBpm;

        private List<GameObject> _passedMultipliers = new List<GameObject>(); 

        void Start()
        {
            NormalBpm.volume = 0.5f;
            ThirtyPercentBpm.volume = 0f;
            SixtyPercentBpm.volume = 0f;
            MaxBpm.volume = 0f;
            
            _spellManager = GetComponent<SpellManager>();
            
            CurrentStressLevel = _startStressLevel;
            _mainTimer = TimeBetweenIncrement;
            _decreaseTimer = TimeBetweenDecrement;
            _deathTimer = TimeBeforeDeath;
            StressSlider.value = _startStressLevel;
        }

        void Update()
        {
            if (CurrentStressLevel < 30)
            {
                NormalBpm.volume = 0.45f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0f;
            }

            else if(CurrentStressLevel > 31 && CurrentStressLevel < 59)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0.65f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0f;
            }
            
            else if(CurrentStressLevel > 60 && CurrentStressLevel < 79)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0.75f;
                MaxBpm.volume = 0f;
            }

            else if(CurrentStressLevel > 80)
            {
                NormalBpm.volume = 0f;
                ThirtyPercentBpm.volume = 0f;
                SixtyPercentBpm.volume = 0f;
                MaxBpm.volume = 0.85f;
            }
            
            
            StressSlider.value = CurrentStressLevel;
            
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
                    WaitBeforeDeath();
                }
                _mainTimer = TimeBetweenIncrement;
            }
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

        private void WaitBeforeDeath()
        {
            if (_deathTimer > 0)
            {
                _deathTimer -= Time.deltaTime;
            }

            else
            {
                if (CurrentStressLevel == MaxStressLevel)
                {
                    Die();
                }
                _deathTimer = TimeBeforeDeath;
            }
        }

        private void Die()
        {
            Debug.Log("T'es mort");
        }
        
        ///
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
