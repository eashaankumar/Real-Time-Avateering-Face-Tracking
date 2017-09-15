using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using System.Net.Sockets;
using UnityEngine.UI;
using UnityEngine;
using System.Threading;
using System.Runtime.InteropServices;

[RequireComponent (typeof(AvatarFaceController))]

/*
 * This class is responsible for all communications with the ultimate_vision 
 * dll. It initializes DEST and sends frame data from the Kinect 
 * camera. Behind the scenes, DEST updates its list of landmarks
 * which can be accessed through the GetXPos and GetYPos methods.
 */
public class DestManager : MonoBehaviour{
    private Texture2D frame = null; // To obtain frame data to send to DEST
    private AvatarFaceController avatarFaceController;
    public SetFaceTexture setFaceTexer;
    public Renderer grayFaceView; // Debug grayscale input image being sent to Dest
    public Text destFeedback; // Debug DEST's error messages
    public string fullPathTempImg = "C:/Users/Eashaan Kumar/Pictures/Screenshots/DestUnity.png"; // Path to temp image Dest uses to reload current frame in grayscale
    public string fullPathClassifier = "C:/Users/Eashaan Kumar/Desktop/classifier_frontalface_alt2.xml"; // Path to trained classifier
    public string fullPathTracker = "C:/Users/Eashaan Kumar/Desktop/dest_tracker_VJ_HELEN.bin"; // Path to tracker
    public static DestManager instance;

    /*
     * Imported functions from ultimate_vision dll
     */ 
    [DllImport("ultimate_vision", EntryPoint = "Init")]
    public static extern int Init(string fullPathCalssifier, string fullPathTracker);

    [DllImport("ultimate_vision", EntryPoint = "DetectFace")]
    public static extern int DetectFace(string fullPathTempImg, double[] a, int rows, int cols);

    [DllImport("ultimate_vision", EntryPoint = "SetLandmarksOfInterest")]
    public static extern void SetLandmarksOfInterest(int[] points, int count);

    [DllImport("ultimate_vision", EntryPoint = "GetXPos")]
    public static extern int GetXPos(int landmarkIndex);

    [DllImport("ultimate_vision", EntryPoint = "GetYPos")]
    public static extern int GetYPos(int landmarkIndex);

    /*
     * Possible error codes received from ultimate_vision
     */
    struct DEST_FEEDBACK
    {
        public const int SUCCESS = 0, CLASFR_ERR = -1, TRACKER_ERR = -2, IMG_ERR = -3, DETECT_ERR = -4;
    };

    /*
     * When game starts, initialize current global instance and obtain
     * reference to AvatarFaceController
     */
    void Awake()
    {
        instance = this;
        avatarFaceController = FindObjectOfType<AvatarFaceController>();
    }

    /*
     * After Awake(), call ultimate_vision's Init method to load the
     * classifier and tracker. Obtain any error code, if possible and
     * Send in list of landmarks that ultimate_vision will track.
     */ 
	void Start(){
        int error = Init(fullPathClassifier, fullPathTracker);
        switch (error)
        {
            case DEST_FEEDBACK.SUCCESS:
                StartCoroutine(UpdateDest());
                break;
            case DEST_FEEDBACK.CLASFR_ERR:
                destFeedback.text = "Failed to load classifier";
                break;
            case DEST_FEEDBACK.TRACKER_ERR:
                destFeedback.text = "Failed to load tracker";
                break;
        }
        SetLandmarksOfInterest(LandMarkConstants.LANDMARKS_OF_INTEREST, LandMarkConstants.LANDMARKS_OF_INTEREST.Length);
    }

    /*
     * Called by SetFaceTexture script. Receives the new frame containing
     * user's face.
     */ 
    public void UpdateCurrentFrameDest(Texture2D tex)
    {
        frame = tex;
    }

    /*
     * A coroutine that calculates grayscale image of current frame and
     * sends it to ultimate_vision. It waits for DEST to perform facial
     * tracking and then receives the output error code. 
     */
    IEnumerator UpdateDest()
    {
        bool run = true;
        destFeedback.text = "Loaded Tracker and Classifier correctly";
        // Wait for 2 seconds to allow user to stand up in front of Kinect
        yield return new WaitForSeconds(2);
        while (run)
        {
            // Wait for current frame to finish processing. Takes off load from main thread.
            yield return null;
            if (frame == null) continue;
            // Calculate grayscale and color pixels. Color pixels are not currently beign used.
            double[] grayscale = new double[frame.width * frame.height];
            double[] color = new double[frame.width * frame.height * 3]; // NOT USED
            Color32[] pixels = frame.GetPixels32();
            int index = 0;
            // Store the grayscale pixel in the grayscale array
            for(int c = 0; c < frame.width; c++)
            {
                for(int r = 0; r < frame.height; r++)
                {
                    // Get current color
                    Color curr = frame.GetPixel(r, c);
                    // 'color' array is not currently used  //
                    color[index * 3 + 0] = curr.r;
                    color[index * 3 + 1] = curr.g;
                    color[index * 3 + 2] = curr.b;
                    //                                      //
                    // Obtain grayscale value
                    grayscale[index] = curr.grayscale;
                    // Update pixels array with 3 channels
                    pixels[r + c * frame.width] = new Color32((byte)(grayscale[index] * 255), (byte)(grayscale[index] * 255), 
                        (byte)(grayscale[index] * 255), 255);
                    index++;
                }
            }
            // Apply the grayscale image to the debug texture
            Texture2D tex = grayFaceView.material.mainTexture as Texture2D;
            if (tex == null) continue;
            tex.SetPixels32(pixels);
            tex.Apply();
            // Send data to ultimate_vision
            int destFdbk = DetectFace(fullPathTempImg, grayscale, frame.width, frame.height);
            // Evalutate error codes
            switch (destFdbk)
            {
                case DEST_FEEDBACK.SUCCESS:
                    destFeedback.text = "Detected face";
                    break;
                case DEST_FEEDBACK.IMG_ERR:
                    destFeedback.text = "Failed to load image";
                    break;
                case DEST_FEEDBACK.DETECT_ERR:
                    destFeedback.text = "Did not detect face";
                    break;
                default:
                    break;
            }
            // Update blendshapes
            avatarFaceController.UpdateFrame(frame);
        }
    }
}

/*
 * This class contains the numbers of landmark indices that correspond to
 * certain facial features. These SHOULD NOT be changed. New features can be
 * added by creating new constants and initializing them with their relative
 * landmark number.
 */
public static class LandMarkConstants
{
    //Mouth
    public const int MOUTH_LEFT_INDEX = 48;
    public const int MOUTH_RIGHT_INDEX = 54;
    public const int MOUTH_UP_INDEX = 51;
    public const int MOUTH_DOWN_INDEX = 57;
    //Nose
    public const int NOSE_LEFT_INDEX = 31;
    public const int NOSE_RIGHT_INDEX = 35;
    // Array must contain all of the above LandMarkConstants for ultimate_vision to track all of them
    public static readonly int[] LANDMARKS_OF_INTEREST = { MOUTH_LEFT_INDEX, MOUTH_RIGHT_INDEX, MOUTH_UP_INDEX, MOUTH_DOWN_INDEX,
                                                           NOSE_LEFT_INDEX, NOSE_RIGHT_INDEX};
    // Obtain x,y pixel coordinate of any given landmark
    public static Vector2 GetXYPosOfLandmark(int landmarkIndex)
    {
        return new Vector2(DestManager.GetXPos(landmarkIndex), DestManager.GetYPos(landmarkIndex));
    }

}

