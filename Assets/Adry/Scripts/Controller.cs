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
    public float CrouchSpeed = 12f;
    public bool isUnderObj = false;

    private Vector3 velocity;


    void FixedUpdate()
    {
        //deplacement
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        Vector3 move = transform.right * x + transform.forward * z;
        Vector3.ClampMagnitude(move, 1f);

        controller.Move(move * MouvementSpeed * Time.deltaTime);

        //jump
        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
        ;
        if (Input.GetKey(KeyCode.Space) && controller.isGrounded)
        {
            velocity.y = Mathf.Sqrt(JumpHeight * -2f * gravity);
        }

        //crouch
        if (Input.GetKey(KeyCode.LeftControl))
        {
            if (controller.height > 1.2f)
            {
                controller.height = Mathf.Lerp(controller.height, 1.2f, Time.deltaTime * CrouchSpeed);
            }
        }
        else
        {
            if (controller.height < 2f && !isUnderObj)
            {
                controller.height = Mathf.Lerp(controller.height, 2f, Time.deltaTime * CrouchSpeed * 3f );
            }
        }
    }

    void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ground"))
        {
            isGrounded = true;
        }
    }

     void OnCollisionExit(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ground"))
        {
            isGrounded = false;
        }
    }

    private void OnTriggerStay(Collider other)
    {
        if (other.gameObject.CompareTag("UnderObj"))
        {
            isUnderObj = true;
        }
    }
    private void OnTriggerExit(Collider other)
    {
        if (other.gameObject.CompareTag("UnderObj"))
        {
            isUnderObj = false;
        }
    }

}
