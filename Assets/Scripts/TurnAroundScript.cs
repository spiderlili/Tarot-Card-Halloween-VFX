using UnityEngine;

public class TurnAroundScript : MonoBehaviour
{
    public float turnSpeed = 40f;
    public RotationAxis rotationAxis = RotationAxis.Y; // Default to rotating around the Y-axis

    public enum RotationAxis
    {
        X,
        Y,
        Z
    }

    void Update()
    {
        Vector3 rotationVector = Vector3.zero;

        // Set the rotationVector based on the selected axis
        switch (rotationAxis)
        {
            case RotationAxis.X:
                rotationVector = new Vector3(1, 0, 0);
                break;
            case RotationAxis.Y:
                rotationVector = new Vector3(0, 1, 0);
                break;
            case RotationAxis.Z:
                rotationVector = new Vector3(0, 0, 1);
                break;
        }
        
        transform.Rotate(rotationVector * Time.deltaTime * turnSpeed);
    }
}
