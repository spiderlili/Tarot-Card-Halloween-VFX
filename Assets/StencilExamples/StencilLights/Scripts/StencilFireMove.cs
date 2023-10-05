using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class StencilFireMove : MonoBehaviour

{
    [SerializeField]
    AnimationCurve curve = default;
    float time;
    [SerializeField]
    float additiveIntensity;

    [SerializeField]
    Vector3 rotation;

    float randomNum ;
    // Start is called before the first frame update
    void Start()
    {
        randomNum = Random.Range(0.5f, 2f);
    }

    // Update is called once per frame
    void Update()
    {
        time = Mathf.Repeat(Time.time, randomNum);
        float scale = curve.Evaluate(time) + additiveIntensity;
        transform.localScale = new Vector3(scale, scale, scale) ;
        transform.Rotate(rotation, Space.Self);
    }
}
