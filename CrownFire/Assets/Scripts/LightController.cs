using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightController : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        transform.LookAt(new Vector3(0, 0, 0));
    }

    // Update is called once per frame
    void Update()
    {
        transform.RotateAround(Vector3.zero, Vector3.left, Time.deltaTime * 3f);
        transform.LookAt(Vector3.zero);
    }
}
