/*

 MindWave MIDI experiment by Avi Goldberg
 MindWave and JSON implementation based on 
 Mindwave processing experiment by Recipient.cc collective
 Fractal Tree visualization based on Recursive Tree by Daniel Shiffman 
 http://processing.org/learning/topics/tree.html
 
 +------------------------------------------------------------------------------------+
 | 
 | This program is free software: you can redistribute it and/or modify |
 | it under the terms of the GNU General Public License as published by |
 | the Free Software Foundation, either version 3 of the License, or |
 | (at your option) any later version. |
 | |
 | This program is distributed in the hope that it will be useful, |
 | but WITHOUT ANY WARRANTY; without even the implied warranty of |
 | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the |
 | GNU General Public License for more details. |
 | |
 | You should have received a copy of the GNU General Public License |
 | along with this program. If not, see <http://www.gnu.org/licenses/>. |
 | |
 | REFERENCES |
 | http://processing.org |
 | http://blog.blprnt.com/blog/blprnt/processing-json-the-new-york-times |
 | http://recipient.cc |
 | |
 | LIBRARIES |
 | JSON Processing Library. | http://www.blprnt.com/processing/json.zip |
 | an alternative library | https://github.com/agoransson/JSON-processing |
 |  |
 +------------------------------------------------------------------------------------+
 */

import processing.net.*;
// I am assuming here that you are using the Processing 1.0 release or higher. Libraries are added to your processing sketchbook folder (~user/Documents/Processing on a Mac) in a directory called ‘libraries’.
//If it doesn’t already exist, create it, and drop the unzipped ‘json’ folder inside)
import org.json.*;

Client myBrainwave; //JSON client
//PrintWriter output; //output file
int fps, i, lastHit; 
int data, oldData, newData;
int[] intPoints; //interpolated points for the next second
float floatPoint;
String dataIn; //string for data from thinkgear driver
float theta;

Boolean debug = true;

int time1, time2, loopCounter;

void setup() {  
  
  size(640, 360);
  smooth();
  fps = 60;
  frameRate(fps);
  intPoints = new int[fps];

  // Connect to the local machine at port 13854.
  // This will not run if you haven't
  // previously started "ThinkGear connector" server
  myBrainwave = new Client(this, "127.0.0.1", 13854);
  //initialize brainwave with raw data disabled, JSON format
  myBrainwave.write("{\"enableRawOutput\": false, \"format\": \"Json\"}");
}

void draw() {

  //debugging loop counter/timer
  loopCounter++;
  time2 = millis() - time1;
  time1 = millis();

  if (debug) {
    //should print on each iteration of loop regardless of dataIn
    println("loop time: " + time2 + "  loop number " + loopCounter);
  }

  if (myBrainwave.available() > 0) {

    dataIn = myBrainwave.readString();

    if (debug) {
      //made it to dataIn
      println(dataIn);
    }

    try {
      //parse JSON object from dataIn string
      JSONObject headsetData = new JSONObject(dataIn);
      //parse individual datasets from main JSON object
      JSONObject results = headsetData.getJSONObject("eegPower"); //eegPower dataset
      JSONObject resultsM = headsetData.getJSONObject("eSense"); //eSense dataset
      
      //parse rawEeg data, need to change drivers mode to enable this
      //JSONObject rawData = nytData.getJSONObject("rawEeg");
      //parse blink data. also off by default.
      //JSONObject resultsB = nytData.getJSONObject("blinkStrength");

      //pull individual values from eSense and eegPower JSON objects
      //this is the eegPower stuff
      int delta = results.getInt("delta");
      int theta = results.getInt("theta");
      int lowAlpha = results.getInt("lowAlpha");
      int highAlpha = results.getInt("highAlpha");
      int lowBeta = results.getInt("lowBeta");
      int highBeta = results.getInt("highBeta");
      int lowGamma = results.getInt("lowGamma");
      int highGamma = results.getInt("highGamma");
      //this is the eSense stuff
      int attention = resultsM.getInt("attention");
      int meditation = resultsM.getInt("meditation");

      //map the point coming in based on high and low cutoffs
      newData = constrain(attention, 0, 70); 
      newData = (int) map(newData, 0, 70, 1, 99);
      println("data = " + data + " newData = " + newData);
    } 
    catch (JSONException e) {
      if (debug) {
        println ("There was an error parsing the JSONObject.");
        println(e);
      }
    }
  }
  if (newData != data) { //check if we actually got new data
    //save new data and recalc interpolation points
    data = newData;
    
    recalculatePoints(intPoints[i], data);
    if (debug) println("recalculated points");
    i = 0;
  } 
  else {
    background(0);
    stroke(255);
    // Let's pick an angle 0 to 90 degrees based on the mouse position
    float a = ((float)intPoints[i] / 99f) * 90f;
    i++;
    if (i >= fps) { //make sure i doesnt go out of bounds for intPoints[] if no update in >1sec
      i = fps - 1;
    }
    // Convert it to radians
    theta = radians(a);
    // Start the tree from the bottom of the screen
    translate(width/2,height);
    // Draw a line 120 pixels
    line(0,0,0,-120);
    // Move to the end of that line
    translate(0,-120);
    // Start the recursive branching!
    branch(120);
  }
}

void recalculatePoints (int oldData, int data) {
  //recalculates the array of interpolation points 
  //based on current position and new target position

  float increment = ((float) data - oldData) / fps;
  for (int ii = 0; ii < fps; ii++) {
    float pointFloat = (oldData + (increment * ii));
    intPoints[ii] = (int) pointFloat;
  }
}


void branch(float h) {
  // Each branch will be 2/3rds the size of the previous one
  h *= 0.66;
  
  // All recursive functions must have an exit condition!!!!
  // Here, ours is when the length of the branch is 2 pixels or less
  if (h > 2) {
    pushMatrix();    // Save the current state of transformation (i.e. where are we now)
    rotate(theta);   // Rotate by theta
    line(0, 0, 0, -h);  // Draw the branch
    translate(0, -h); // Move to the end of the branch
    branch(h);       // Ok, now call myself to draw two new branches!!
    popMatrix();     // Whenever we get back here, we "pop" in order to restore the previous matrix state
    
    // Repeat the same thing, only branch off to the "left" this time!
    pushMatrix();
    rotate(-theta);
    line(0, 0, 0, -h);
    translate(0, -h);
    branch(h);
    popMatrix();
  }
}

void keyPressed() {
  if (key == 'x') {
    stop();
  }   
}

void stop () {
  //output.flush(); // Writes the remaining data to the file
  //output.close(); // Finishes the file
  exit();
}

