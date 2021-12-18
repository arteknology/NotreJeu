using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FpsCam : MonoBehaviour
{
    public float maxSpeed = 500;
    public float _mouseSpeed = 150;
    public Transform playerBody;
    private float xRotation = 0f;

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X") * _mouseSpeed * Time.deltaTime;
        float mouseY = Input.GetAxis("Mouse Y") * _mouseSpeed * Time.deltaTime;

        xRotation -= mouseY;
        xRotation = Mathf.Clamp(xRotation, -65f, 65f);

        transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
        playerBody.Rotate(Vector3.up * mouseX);
    }
}
