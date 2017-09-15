/*
 * Ultimate Vision
 * By Eashaan Kumar
 * Professor Matthias Zwicker
 * University of Maryland - College Park, Department of Computer Science
 *----------------------------------------------------------------------
 * This program is part of a research project on Computer Vision, Kinect
 * and full-body skeleton tracking. The program is exported as a dll
 * into Unity and the methods are accessed using C#'s Interop services. 
 */
#include <iostream>
#include <Eigen/Geometry>
#include <dest/dest.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <dest/face/face_detector.h>
#include <opencv2/imgproc.hpp>
#include <opencv2/objdetect.hpp>
#include <thread>
#include <windows.h>
#include <chrono>
#include <string>

dest::face::FaceDetector fd;
dest::core::Tracker t;
std::vector<dest::core::Shape::Index> landmarksOfinterest;
dest::core::Shape lastShape;

/*
 * Draws landmarks on img by placing its index on the
 * corresponding pixel coordinate. Highlights the
 * landmarks that are present in the landmarksOfinterest
 * array. 
 * Parameters:
 *   img: image to draw on
 *   s: Shape containing landmark information
 *   color: landmark color
 *   interestColor: highlight landmark color
 */
void drawShapeAux(cv::Mat &img, const dest::core::Shape &s, const cv::Scalar &color, const cv::Scalar &interestColor) {
	// Setup text and font
	std::string text;
	int fontFace = cv::FONT_HERSHEY_SCRIPT_SIMPLEX;
	double fontScale = 0.2;
	int thickness = 1;
	// Iterate through every landmark present in Shape s
	for (dest::core::Shape::Index i = 0; i < s.cols(); ++i) {
		//cv::circle(img, cv::Point2f(s(0, i), s(1, i)), 1.f, color, -1, CV_AA);
		//Obtain coordinate information
		text = "" + std::to_string(i);
		cv::Point org(s(0, i), s(1, i));
		// Render text in highlighed color if present in landmarksOfinterest array
		if (std::find(landmarksOfinterest.begin(), landmarksOfinterest.end(), i) != landmarksOfinterest.end()) {
			cv::putText(img, text, org, fontFace, fontScale, interestColor, thickness, 8);
		}
		// Otherwise render with normal color
		else {
			cv::putText(img, text, org, fontFace, fontScale, color, thickness, 8);
		}
	}
}

/*
 * Draws the landmark shape using the given image. 
 * Paramters:
 *  img: image to be used to draw landmarks on
 *  s: shape object containing landmark information
 *  color: main color of landmarks in window
 *  interstColor: highligh color of landmarks of interest
 */
cv::Mat drawShapeMain(const dest::core::Image &img, const dest::core::Shape &s, const cv::Scalar &color, const cv::Scalar &interestColor)
{
	cv::Mat tmp, tmp2;
	// Convert img to OpenCV conpatible form
	dest::util::toCVHeaderOnly(img, tmp);
	// Convert from grayscale to RGB
	cv::cvtColor(tmp, tmp2, CV_GRAY2BGR);
	// Draw all landmarks
	drawShapeAux(tmp2, s, color, interestColor);
	// Return final image containing landmarks
	return tmp2;
}


/*
 * This program performs image processing on a frame sent by Unity. First
 * the Init() method is called to setup the face detector, classifier and 
 * tracker such that they do not have to be loaded every frame. Next, the
 * DetectFace() method is called to enable the tracker and render landmark
 * data on the received frame. 
 */
extern "C" {

	/*
	 * Exit codes that are returned to Unity when applicable
	 */
	__declspec(dllexport) struct DEST_FEEDBACK {
		static const int SUCCESS = 0, CLASFR_ERR = -1, TRACKER_ERR = -2, IMG_ERR = -3, DETECT_ERR = -4;
	};

	/*
	 * Initializes the face detector fd and tracker t. Returns
	 * appropriate exit code if either failed. Otherwise returns
	 * SUCCESS. 
	 */
	__declspec(dllexport) int Init(const char *fullPathCalssifier, const char *fullPathTracker) {
		//Detector
		if (!fd.loadClassifiers(fullPathCalssifier)) {
			std::cout << "Failed to load classifiers." << std::endl;
			return DEST_FEEDBACK::CLASFR_ERR;
		}
		//Tracker
		if (!t.load(fullPathTracker)) {
			std::cout << "Failed to load tracker." << std::endl;
			return DEST_FEEDBACK::TRACKER_ERR;
		}
		return DEST_FEEDBACK::SUCCESS;
	}

	/*
	 * Runs the face tracking on image created from array a. Uses
	 * fullPathTempImg to temporarily store the image and read it
	 * in as a grayscale image. This is to avoid the image from
	 * having missing rgb channels when the cv::Mat contructor
	 * is used to initialize imgCV. rows and cols represent the
	 * dimentions of the image. 
	 */
	__declspec(dllexport) int DetectFace(const char *fullPathTempImg, double* a, int rows, int cols) {
		// Load current frame
		cv::Mat imgCV = cv::Mat(rows, cols, CV_64F, (uchar*)a); //CV_xxtCn = xx: num bits; t: type (F: float, S: signed int, U: unsigned int); n: num channels
		// Convert image color values from 0-1 to 0-255
		imgCV.convertTo(imgCV, CV_64F, 255);
		// Write and read image to temporary path
		cv::imwrite(fullPathTempImg, imgCV);
		imgCV = cv::imread(fullPathTempImg, CV_LOAD_IMAGE_GRAYSCALE);
		if (imgCV.empty()) {
			std::cout << "Failed to load image." << std::endl;
			return  DEST_FEEDBACK::IMG_ERR;
		}
		// Show input image in a window
		cv::imshow("Dest input", imgCV);
		dest::core::Image img;
		// Convert input image to DEST format
		dest::util::toDest(imgCV, img);
		// Perform face detection
		dest::core::Rect r;
		if (!fd.detectSingleFace(img, r)) {
			std::cout << "Failed to detect face" << std::endl;
			return DEST_FEEDBACK::DETECT_ERR;
		}
		// Default inverse shape normalization. Create the landmark dots and store the data in Shape
		dest::core::ShapeTransform shapeToImage = dest::core::estimateSimilarityTransform(dest::core::unitRectangle(), r);
		dest::core::Rect ur = dest::core::unitRectangle();
		shapeToImage = dest::core::estimateSimilarityTransform(ur, r);
		lastShape = t.predict(img, shapeToImage);
		//Show the landmarks in a window
		cv::Scalar color = cv::Scalar(255, 0, 102);
		cv::Scalar landmarkColor = cv::Scalar(0, 0, 255);
		//cv::Mat tmp = dest::util::drawShape(img, s, color); // default drawShape() provided by DEST
		cv::Mat tmp = drawShapeMain(img, lastShape, color, landmarkColor); // Custom implementation of drawShape()
		cv::imshow("Landmarks", tmp);
		return DEST_FEEDBACK::SUCCESS;
	}

	/*
	 * Updates the list of landmark indices that should be hilighted
	 * red when rendering the Landmarks window. 
	 */
	__declspec(dllexport) void SetLandmarksOfInterest(int* points, int count) {
		landmarksOfinterest.resize(count);
		for (int i = 0; i < count; i++) {
			landmarksOfinterest[i] = points[i];
		}
	}

	/* 
	 * Returns the X pixel coordinate of the specified landmark.
	 */
	__declspec(dllexport) int GetXPos(int landmarkIndex) {
		return lastShape(0, landmarkIndex);
	}

	/*
	 * Returns the Y pixel coordinate of the specified landmark
	 */
	__declspec(dllexport) int GetYPos(int landmarkIndex) {
		return lastShape(1, landmarkIndex);
	}
}


