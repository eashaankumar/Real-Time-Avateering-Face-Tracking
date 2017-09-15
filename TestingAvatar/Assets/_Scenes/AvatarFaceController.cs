using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/*
 * This class is responsible for calculating blend weights
 * For the avatar model. It receives the frame everytime DEST
 * updates the facial landmarks and performs three operations:
 * measuring smile, measuring how open the mouth is (gape)
 * and measuring the nose crunch. Although it can calucalate
 * various other blendshapes, only these have been chosen due to 
 * time contraints.
 */
public class AvatarFaceController : MonoBehaviour {

    public SkinnedMeshRenderer blendShapes;
    public BlendShapeIndices blendShapeIndices;
    public Text smileText, gapeText, noseText;

    private ExpressionCalculationParams smileParams = null;
    private ExpressionCalculationParams gapeParams = null;
    private ExpressionCalculationParams noseCrunch = null;

    /*
     * Called by Reset button. Meant to recallibrate the min
     * and max values for a pair of features.
     */
    public void Reset()
    {
        smileParams.Reset();
        gapeParams.Reset();
    }

    /*
     * Called by DestManager. Received new frame and performs 
     * blend weight calculations on each facial feature.
     */
    public void UpdateFrame(Texture2D frame)
    {
        if (smileParams == null) smileParams = new ExpressionCalculationParams(60);
        if (gapeParams == null) gapeParams = new ExpressionCalculationParams(100);
        if (noseCrunch == null) noseCrunch = new ExpressionCalculationParams(200);
        // Calculate the scaling factor to use for blend weight calculation
        float aspectRatio = 1 / ((float)(frame.width));
        MeasureSmile(aspectRatio);
        MeasureGape(aspectRatio);
        MeasureNoseCrunch(aspectRatio);
        // Apply the blendweights to the character model
        UpdateFacialBlendShapes(blendShapeIndices.smileLeftSide, smileParams.percent * smileParams.range);
        UpdateFacialBlendShapes(blendShapeIndices.smileRightSide, smileParams.percent * smileParams.range);
        UpdateFacialBlendShapes(blendShapeIndices.gape, gapeParams.percent * gapeParams.range);
        UpdateFacialBlendShapes(blendShapeIndices.noseLeft, noseCrunch.percent * gapeParams.range);
        UpdateFacialBlendShapes(blendShapeIndices.noseRight, noseCrunch.percent * gapeParams.range);

    }

    /*
     * Measures the smile using the left and right edges of the mouth. 
     * If the distance between them is larger than previously recorded,
     * then it is inferred that the user must be smiling more than in the
     * previous frame. Similarily if it is smaller than previously recorded,
     * then user must be smiling less. 
     */
    private void MeasureSmile(float aspectRatio)
    {
        // Calculate left and right mouth edge positions
        Vector2 leftMouth = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.MOUTH_LEFT_INDEX);
        Vector2 rightMouth = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.MOUTH_RIGHT_INDEX);
        // Calculate scaled distance with left and right mouth edges
        float distance = Vector2.Distance(leftMouth, rightMouth) * aspectRatio;
        // Set the min and max recorded distances
        if (smileParams.min == -1) { smileParams.min = distance; }
        smileParams.min = Mathf.Min(distance, smileParams.min);
        smileParams.max = Mathf.Max(distance, smileParams.max);
        // Calculate what percentile is distance in the range [min, max]
        smileParams.percent = (distance - smileParams.min) / (smileParams.max - smileParams.min);
        // Smooth lerping from previous percent value to minimize gittering
        if (smileParams.lastPercent != 0 && smileParams.percent != 0)
        {
            smileParams.percent = Mathf.Lerp(smileParams.lastPercent, smileParams.percent, Mathf.Abs(smileParams.lastPercent - smileParams.percent) / smileParams.lastPercent);
        }
        // Debugg new smile percent value
        if (smileText != null)
        {
            smileText.text = "Smile %: " + smileParams.percent;
        }
        // Update lastPercent value to be used in next iteration
        smileParams.lastPercent = smileParams.percent;
    }

    /*
     * Measures how open the mouth is using the top and bottom edges
     * (upper and lower lip) of the mouth. Using the distance between them
     * over time, it can be inferred if the user is gaping more than before 
     * and the blendweight percentage can be calculated accordingly
     */ 
    private void MeasureGape(float aspectRatio)
    {
        // Calculate distance between bottom and top edges
        Vector2 bottomMouth = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.MOUTH_DOWN_INDEX);
        Vector2 upMouth = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.MOUTH_UP_INDEX);
        float distance = Vector2.Distance(bottomMouth, upMouth);
        // Update min and max distances
        if (gapeParams.min == -1) { gapeParams.min = distance; }
        gapeParams.min = Mathf.Min(distance, gapeParams.min);
        gapeParams.max = Mathf.Max(distance, gapeParams.max);
        // Calculate percentile between [min, max]
        gapeParams.percent = (distance - gapeParams.min) / (gapeParams.max - gapeParams.min);
        gapeParams.percent -= 0.2f;
        gapeParams.percent = Mathf.Clamp01(gapeParams.percent);
        // Debug new percent value
        if (gapeText != null)
        {
            gapeText.text = "Gape %: " + gapeParams.percent;
        }
    }

    /*
     * Measures how crunched the nose is using the left and right
     * edges of the nose. Using distance between them over time, 
     * infers if the nose is more/less crunched than in the previous 
     * frame.
     */
    private void MeasureNoseCrunch(float aspectRatio)
    {
        // Calculate distance between left and right nose edges
        Vector2 noseLeftPos = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.NOSE_LEFT_INDEX);
        Vector2 noseRight = LandMarkConstants.GetXYPosOfLandmark(LandMarkConstants.NOSE_RIGHT_INDEX);
        float distance = Vector2.Distance(noseLeftPos, noseRight) * aspectRatio;
        // Update min and max
        if (noseCrunch.min == -1) { noseCrunch.min = distance; }
        noseCrunch.min = Mathf.Min(distance, noseCrunch.min);
        noseCrunch.max = Mathf.Max(distance, noseCrunch.max);
        // Calculate percentile of distance between [min, max]
        noseCrunch.percent = (distance - noseCrunch.min) / (noseCrunch.max - noseCrunch.min);
        // Smooth lerping to avoid jerky movements
        if (noseCrunch.lastPercent != 0 && noseCrunch.percent != 0)
        {
            noseCrunch.percent = Mathf.Lerp(noseCrunch.lastPercent, noseCrunch.percent, Mathf.Abs(noseCrunch.lastPercent - noseCrunch.percent) / noseCrunch.lastPercent);
        }
        // Debug new percent value
        if (noseCrunch != null)
        {
            noseText.text = "Nose %: " + noseCrunch.percent;
        }
        // Update last percent value to be used next frame
        noseCrunch.lastPercent = noseCrunch.percent;
    }
   
    /*
     * Checks if blendShapeIndex is < 0. Otherwise applies blendshape
     */
    private void UpdateFacialBlendShapes(int blendShapeIndex, float amount){
		if (blendShapeIndex < 0)
			return;
		blendShapes.SetBlendShapeWeight (blendShapeIndex, amount);
	}

    /*
     * Holds the variables necessary for blendweight
     * percentage calculations. Each pair of landmarks
     * uses one of this object to hold min, max and
     * percent data.
     */
    private class ExpressionCalculationParams
    {
        public float min = -1, max, lastPercent, percent;
        public float range;

        /*
         * Maximum blendweight value for a particular pair of features
         */
        public ExpressionCalculationParams(float r)
        {
            range = r;
        }

        /*
         * Resets the min and max to current value
         */ 
        public void Reset()
        {
            min = percent;
            max = percent;
        }
    }
}

/*
 * These are set through the Unity editor. Each value
 * corresponds to the blendshape for the model. A different model
 * might have different numbers. Each number is the index of the blendshape.
 */
[System.Serializable]
public struct BlendShapeIndices
{
    public int smileLeftSide, smileRightSide, gape, noseLeft, noseRight;
}
