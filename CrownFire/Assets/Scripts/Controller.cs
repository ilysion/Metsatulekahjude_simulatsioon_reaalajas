using UnityEngine;
using System.Collections;

public class Controller : MonoBehaviour {

    public float moveSpeed = 1f;
    public float autoMoveSpeed = 1f;

	// Use this for initialization
	void Start () {
        transform.LookAt(new Vector3(0, 0, 0));
    }
	
	// Update is called once per frame
	void Update () {
	    if (Input.GetKey(KeyCode.A))
        {
            this.transform.Translate(Vector3.left * Time.deltaTime * (moveSpeed + autoMoveSpeed));
        }
        if (Input.GetKey(KeyCode.D))
        {
            this.transform.Translate(Vector3.right * Time.deltaTime * (moveSpeed - autoMoveSpeed));
        }
        if (Input.GetKey(KeyCode.W))
        {
            this.transform.Translate(Vector3.up * Time.deltaTime * moveSpeed);
        }
        if (Input.GetKey(KeyCode.S))
        {
            this.transform.Translate(Vector3.down * Time.deltaTime * moveSpeed);
        }
        //movement to 0 point
        if (Input.GetKey(KeyCode.Z))
        {
            this.transform.position = Vector3.MoveTowards(this.transform.position, Vector3.zero, Time.deltaTime * moveSpeed);
        }
        //movement from 0 point
        if (Input.GetKey(KeyCode.X))
        {
            this.transform.position = Vector3.MoveTowards(this.transform.position, Vector3.zero, Time.deltaTime * moveSpeed * (-1));
        }

        if (Input.GetKey(KeyCode.Escape))
        {
            Application.Quit();
        }

        //automatic movement
        transform.LookAt(new Vector3(0,0,0));
        transform.Translate(Vector3.right * Time.deltaTime * autoMoveSpeed);

    }
}
