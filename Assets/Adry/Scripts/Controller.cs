using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Controller : MonoBehaviour
{

    public CharacterController controller;
    public float MouvementSpeed = 10;
    public float JumpHeight = 2;
    public float gravity = -20f;
    public bool isGrounded;

    private Vector3 velocity; 

    void FixedUpdate()
    {

        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        Vector3 move = transform.right * x + transform.forward * z;

        controller.Move(move * MouvementSpeed * Time.deltaTime);

        velocity.y += gravity * Time.deltaTime;

        controller.Move(velocity * Time.deltaTime);;

        if (Input.GetKey(KeyCode.Space) && controller.isGrounded)
        {
            velocity.y = Mathf.Sqrt(JumpHeight * -2f * gravity);
        }


        if (Input.GetKey(KeyCode.LeftControl))
        {
           controller.height = 1.5f;
        }
        else
        {
           controller.height = 2f;
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ground"))
        {
            isGrounded = true;
        }
    }

    private void OnCollisionExit(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ground"))
        {
            isGrounded = false;
        }
    }

}
