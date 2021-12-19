using UnityEngine;
using UnityEngine.SceneManagement;

namespace Assets.Arthur.Scripts
{
    public class IntroManager : MonoBehaviour
    {
        private float _delayBeforeLoading = 4f;
        [SerializeField] private string _sceneToLoad;
        private float timeElapsed;
        
        void Update()
        {
            timeElapsed += Time.deltaTime;
            if (timeElapsed > _delayBeforeLoading)
            {
                SceneManager.LoadScene(_sceneToLoad);
            }
        }
    }
}
