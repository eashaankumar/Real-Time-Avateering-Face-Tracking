# Real Time Avateering Face Tracking
**University of Maryland - College Park** <br />
**Eashaan Kumar, Professor Matthias Zwicker** <br />

## Overview
### Abstract
This research project aims to create a system for remote presence for users in the form of a 3D virtual avatar. It allows them to establish eye contact with their avatar. Through the use of Kinect SDK and facial landmark detection techniques, the system does full body tracking and facial expression tracking. For a more immersive experience, it makes use of virtual reality through Oculus Rift. The project is implemented in a popular game engine called Unity3D that renders the avatar and talks to the Kinect sensor. Skeleton tracking and avatar mesh deformation is done directly by the Kinect. Facial landmark detection is done by an open source library called the Deformable Shape Tracking library. Blend weights are used to alter the avatar’s facial expressions and successfully mirror the user.

### Skeleton Tracking
The Kinect skeleton tracking system can be broken down into two stages: first computing a depth map and second inferring body position. First, the depth map is constructed by the Kinect’s time-of-flight camera. This camera “emits light signals and then measures how long it takes them to return” (Meisner 1). It is accurate to the speed of light: 1/10,000,000,000 of a second. Thus, the camera is able to differentiate between light reflected from objects in the surrounding environment. From a single input depth image, a per-pixel body part distribution is calculated

### Facial Feature Tracking
<a href="https://github.com/cheind/dest">DEST</a>, a facial landmark tracking library used in this research depends on OpenCV’s CascadeClassifier class. The CascadeClassifier class relies on the Haar Feature-based Cascades to perform facial detection operations.

### Blendshapes
Blendshapes are simple linear model of facial expressions used for realistic facial animation. Rendering in Unity3D is done through the “Mesh Renderer” Component. A Mesh Renderer was used to render the image of the user’s face captures by Kinect’s own camera. That image was then sent to the DEST library and OpenCV for facial tracking. 
