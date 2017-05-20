/**
  Processing sketch for VisualSynth. 
  Author: Thrifleganger
  
  Dependencies: OscP5, ControlP5
*/

import controlP5.*;
import netP5.*;
import oscP5.*;
import java.util.*;

public enum TRANSITION{
  OPEN, LEFT, RIGHT, AUX  
};

//Class for handling vertical mover objects on mouse click.
class Mover{
  PVector location;
  PVector velocity;
  float diffX, diffY;
  
  Mover(){
    location = new PVector(mouseX,mouseY);
    velocity = new PVector(0, -speed);
  }
  
  Mover(float x, float y){
    location = new PVector(x, y);
    velocity = new PVector(0, -speed);
  }
  
  void update(){
    velocity = new PVector(0, -speed);
    location.add(velocity);
  }
  
  boolean checkThreshRange(Mover prevMover, float thresh){
    if(abs(location.y - prevMover.location.y) < thresh)
        return true;
    return false;
  }
  
  void drawLine(Mover prevMover){ 
    stroke(H, S, B, A);
    noFill();
    strokeWeight(1);
    //line(location.x, location.y, prevMover.location.x, prevMover.location.y);
    diffX = location.x - prevMover.location.x;
    diffY = location.y - prevMover.location.y;
    if(diffY < 50) diffY = random(-50, 50);
    if(diffX < 50) diffX = random(-50, 50);
    bezier(location.x, location.y,
          location.x - random(0,diffX), location.y - random(0,diffY),
          location.x - random(0,diffX), location.y - random(0,diffY),
          prevMover.location.x, prevMover.location.y);
  }
  
  void display(){
    noStroke();
    fill(H, S, B * pow(tone,0.5), A);
    float size = map(location.y, 0, height, width*0.0125, width*0.0625);
    ellipse(location.x, location.y, size, size);
  }
}

//General class for Theremin-like synths with continuous value change through click and drag
class Theramin {
  PVector location; 
  OscMessage mouseClickHeld;
  
  Theramin() {
    location = new PVector(mouseX, mouseY);
    mouseClickHeld = new OscMessage("/MousePressed");
  }
  
  void update() {
    location.x = mouseX;
    location.y = mouseY;
  }
  
  //Propagate Mouse pressed message via OSC
  void propogate() {
    mouseClickHeld = new OscMessage("/MousePressed");
    mouseClickHeld.add(patchSelected)
                  .add(map(mouseX, 0, width, noteNumberLow, noteNumberHigh+1))
                  .add(map(mouseY, 0, height, 0, 1));
    osc.send(mouseClickHeld, supercollider);
  }
  
  void display() {
    noStroke();
    fill(H, S, random(25,100), A);
    float size = random(width*0.00625,width*0.1);
    ellipse(location.x, location.y, size, size);
    strokeWeight(4);
    stroke(H, S, B, A);
    line(location.x,location.y, location.x + random(-150,150), location.y + random(-150,150));
  }
}

//Class of mover objects accompanying "Mover" class
class AuxMover {
  PVector location;
  PVector velocity;
  float initSpeed;
  float size;
  
  AuxMover(float x) {
    initSpeed = -speed * random(2, 4);
    size = random(width*0.01, width*0.05);
  	location = new PVector(random(x-(width*0.0625), x+(width*0.0625)), height + 20);
    velocity = new PVector(0, initSpeed); 
  }
  
  void update(){
    velocity = new PVector(0, initSpeed);
    location.add(velocity);
  }
  
  void display(){
    noStroke();
    fill(H, S, B, 20);
    ellipse(location.x, location.y, size, size);
  }
}

//Class of mover objects accompanying  "Theremin" object
class AuxMover2 {
  PVector location;
  PVector velocity;
  float initSpeedX, initSpeedY;
  float col;
  float size;
  
  AuxMover2() {
    initSpeedX = speed * random(1, 4) * (random(0,1) < 0.5 ? -1 : 1);
    initSpeedY = speed * random(1, 4) * (random(0,1) < 0.5 ? -1 : 1);
    col = random(30,100);
    size = random(8, 40);
    location = new PVector(mouseX, mouseY);
    velocity = new PVector(initSpeedX, initSpeedY); 
  }
  
  void update(){
    velocity.x = initSpeedX;
    velocity.y = initSpeedY;
    location.add(velocity);
  }
  
  void display(){
    noStroke();
    fill(H, col, B, 20);
    ellipse(location.x, location.y, size, size);
  }
}

//Class of semi-transparent rectangular windows hosting controls
class RectGroup {
  PVector location;
  float ht, wd;
  float tranSpeed = height * 0.0044;
  boolean open = false;
  TRANSITION transition;
  
  RectGroup(float x, float y, float w, float h, TRANSITION trans) {
    location = new PVector(x, y);
    ht = h;
    wd = w;
    transition = trans;
  }
  
  void openTransition() { 
    switch(transition) {
      case OPEN:
        if(ht < groupBoxMainHeightOpen) {
          ht += tranSpeed; 
          open = false;
        } else 
          open = true;
        break;
      case LEFT:    
        if(wd < groupBoxLeftWidthOpen) { 
          wd += tranSpeed * 1.8;
          open = false;
        } else
          open = true;
        break;
      case RIGHT:    
        if(wd > groupBoxRightWidthOpen) { 
          wd -= tranSpeed * 1.8;
          open = false;
        } else
          open = true;
        break;
      case AUX:
        if(ht < groupBoxAuxHeight) {
          ht += tranSpeed * 1.5; 
          open = false;
        } else 
          open = true;
        break;
    }
  }
  
  void closeTransition() { 
    switch(transition) {
      case OPEN:    
        if(ht > groupBoxMainHeightClosed){ 
          ht -= tranSpeed;
          open = false;
        } else 
          open = false;
        break;
      case LEFT:
        if(wd > groupBoxLeftWidthClosed){ 
          wd -= tranSpeed * 1.8;
          open = false;
        } else 
          open = false;
        break;
      case RIGHT:
        if(wd < groupBoxRightWidthClosed){ 
          wd += tranSpeed * 1.8;
          open = false;
        } else 
          open = false;
        break;
      case AUX:    
        if(ht > 0){ 
          ht -= tranSpeed * 1.5;
          open = false;
        } else { 
          ht = 0;  
          open = false;
        }
        break;
    }
  }
  
  boolean isOpen() { return open; }
  
  void display(){
    noStroke();
    fill(255, 30);
    rect(location.x, location.y, wd, ht, 10);
  }
}

//Class of rectangular coloured buttons representing different patches
class PatchBay {
  PVector location;
  float wd = patchWidth;
  float ht = patchHeight;
  int hue, sat, bright;
  boolean isHover = false;
  boolean isClicked;
  String name;
  
  PatchBay(float x, float y, int h, int s, int b, String n){
    location = new PVector(x,y);
    hue = h; sat = s; bright = b;
    name = n;
  }
  
  boolean checkHover() {
    if(mouseX > location.x && mouseX < location.x + wd && mouseY > location.y && mouseY < location.y + ht) {
      isHover = true;
    } else {
      isHover = false;
    }
    return isHover;
  }  
  
  boolean checkClick() {
    if(mouseX > location.x && mouseX < location.x + wd && mouseY > location.y && mouseY < location.y + ht)
      isClicked = true;
    else if(!isClicked)
      isClicked = false;
    return isClicked;
  }
  
  void unclick() {
    isClicked = false;
  }
  
  void display() {
    if(isClicked){
      strokeWeight(2);
      stroke(hue, sat, bright - 30);
    } else
      noStroke();
    fill(hue,(isHover ? sat - 20 : sat),bright);
    rect(location.x, location.y, wd, ht, 5);
  }
  
  void setColor() {
    H = hue;
    S = sat;
    B = bright;
  }
  
  color getColor() {
    return color(hue,sat,bright);
  }
  
  String getName() { return name; }
}

//GLOBAL VARIABLES:

//Dimensions
float groupBoxMainX, groupBoxMainY, groupBoxMainWidth, groupBoxMainHeightOpen, groupBoxMainHeightClosed;
float groupBoxLeftX, groupBoxLeftY, groupBoxLeftWidthOpen, groupBoxLeftWidthClosed, groupBoxLeftHeight; 
float groupBoxRightX, groupBoxRightY, groupBoxRightWidthOpen, groupBoxRightWidthClosed, groupBoxRightHeight; 
float groupBoxAuxX, groupBoxAuxY, groupBoxAuxHeight, groupBoxAuxWidth;
float knobSize, knobPadding, smallKnobSize;
float patchHeight, patchWidth, patchPadding;
float buttonHeight, buttonWidth, buttonPadding;
float collapseThreshold; 
float octaveTextWidth, fullViewTextWidth, largeTextSize, smallTextSize, mediumTextSize, widgetTextSize;
int currWidth, currHeight;

//Misc
PImage bg;
int maxMoverSize = 100, maxAuxMoverSize = 500;
float prevX = -200, prevY = -200;
int moverCount = 0, auxMoverCount = 0, auxMoverCount2 = 0;
float H = 30, S = 80, B = 100, A = 80;
int numPatches = 5;
int patchSelected = 0;
int previousNote, time;
boolean isGroupOpen = false;
boolean isKeyPressed = false;
int noteNumberLow, noteNumberHigh;
String bufferFile = "";
int voiceTypeIndex = 0;

//GUI Component values;
float speed, volume, pan, tone;
float attack, decay, sustain, release;
float delayTime, feedback, delayMix, reverb;
float volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;
int octaveCount = 4;
boolean isFullView = false, isMoreInfo = false;

//Communate with supercollider
OscP5 osc;
NetAddress supercollider;

//GUI controls
ControlP5 guiInterface;
Knob speedKnob, attackKnob, decayKnob, sustainKnob, releaseKnob;
Knob volumeKnob, toneKnob, panKnob;
Knob volModDepthKnob, volModRateKnob, pitchModDepthKnob, pitchModRateKnob, panModDepthKnob, panModRateKnob;
Knob reverbKnob, delayTimeKnob, feedbackKnob, delayMixKnob; 
Button octaveLow, octaveHigh, fullView, moreInfo;
//Synth specific widgets:
int theraminPatch = 2;
int vocalPatch = 4;
int numSynths = 5;
int maxWidgetsPerSynth = 5;
int numWidgetsPerSynth[] = {3,4,0,2,2};
Controller synthSpecific[][] = new Controller[numSynths][5];
CheckBox noteSelector;
RadioButton vowelSelector1, vowelSelector2;
ScrollableList voiceType;


//Custom objects:
Mover[] mover = new Mover[maxMoverSize];
Theramin theramin = new Theramin();
AuxMover[] auxMover = new AuxMover[maxAuxMoverSize];
AuxMover2[] auxMover2 = new AuxMover2[maxAuxMoverSize];
RectGroup groupMain, groupLeft, groupRight, groupAux;
PatchBay[] patchBay = new PatchBay[numPatches];
PatchBay patch1;
PatchBay patch2;

//Main setup method
void setup() {
  //Connection setup
  osc = new OscP5(this, 12000);
  supercollider = new NetAddress("127.0.0.1", 57120);

  //Canvas Setup
  bg = loadImage("background.jpg");
  colorMode(HSB,360,100,100,100);
  surface.setSize(800, 450);
  surface.setResizable(true);
  background(255);
  smooth();
   
  //Misc setup
  time = 0;
  setDimensions();
  
  //GUI setup 
  guiInterface = new ControlP5(this); 
  setGUIWidgets(); 
}

void draw() {
  //Reinitialize interface on window resize
  if(currWidth != width || currHeight != height) {
    bg.resize(width, height);
    setDimensions();
    resetGUIWidgets();
    guiInterface = new ControlP5(this);
    setGUIWidgets();
    currWidth = width;
    currHeight = height;
  }
  
  //Set background image
  image(bg, 0, 0);
  
  patchBay[patchSelected].setColor();
  handleGroupTransition();
  
  //Handle patch bay mouse over event. Animation for custom buttons
  for(int i = 0; i < numPatches; i++) {
    patchBay[i].checkHover();
    if(isGroupOpen)
      patchBay[i].display();
  }
  
  //Handle mouse pressed events for theremin-like synth patches
  if(mousePressed || isKeyPressed){
    if(patchSelected == theraminPatch || patchSelected == vocalPatch) {
      theramin.update();
      theramin.propogate();
    }
    triggerAuxMovers();
  }
  updateMover();
  updateWidgetText();
  updateAuxMovers();
  updateScalingAndView();
}

//Callback for Mouse Pressed event
void mousePressed() {
  //Create OSC message and fill in different parameter values
  OscMessage mouseTriggerMessage = new OscMessage("/MouseClick");
  previousNote = int(map(mouseX, 0, width, noteNumberLow, noteNumberHigh+1));
  mouseTriggerMessage.add(patchSelected)
                     .add(previousNote)
                     .add(map(mouseY, 0, height, -40, 0))
                     .add(volume)
                     .add(pan)
                     .add(tone)
                     .add(attack)
                     .add(decay)
                     .add(sustain)
                     .add(release)
                     .add(volModDepth)
                     .add(volModRate)
                     .add(pitchModDepth)
                     .add(pitchModRate)
                     .add(panModDepth)
                     .add(panModRate)
                     .add(delayTime)
                     .add(feedback)
                     .add(delayMix)
                     .add(reverb);
  for(int i = 0; i < numWidgetsPerSynth[patchSelected]; i++)
    mouseTriggerMessage.add(synthSpecific[patchSelected][i].getValue());
  if(patchSelected == 1) {
    mouseTriggerMessage.add(noteSelector.getArrayValue());
  } else if(patchSelected == 4) {
    mouseTriggerMessage.add(vowelSelector1.getValue());
    mouseTriggerMessage.add(vowelSelector2.getValue());
    mouseTriggerMessage.add(voiceTypeIndex);
  } 
  //Send OSC message
  osc.send(mouseTriggerMessage, supercollider);
  
  //Create prime mover object
  if(patchSelected == theraminPatch || patchSelected == vocalPatch)
    theramin = new Theramin();
  else {
    if(moverCount == maxMoverSize) 
      moverCount = 0;
    mover[moverCount++] = new Mover();
  }
  
  //Highlight and select patch
  for(int i = 0; i < numPatches; i++){
    if(patchBay[i].checkClick()) {
      patchSelected = i;
      for(int j = 0; j < numPatches; j++){
        if(j != i)
          patchBay[j].unclick();
      }
    }
  }
}

//Callback function for Mouse released event 
void mouseReleased() {
  //Create and send OSC message for release event
  OscMessage mouseTriggerMessage = new OscMessage("/MouseClickRelease");
  mouseTriggerMessage.add(patchSelected)
                     .add(previousNote);
  osc.send(mouseTriggerMessage, supercollider);
}

//Callback function when an OSC message is received by Processing
//Function to intercept OSC message coming from Supercollider, for MIDI controller events
void oscEvent(OscMessage message) {
  if(message.checkAddrPattern("/noteTriggered")) {
      int note = message.get(0).intValue();
      int velocity = message.get(1).intValue();
      if(moverCount == maxMoverSize) 
        moverCount = 0;
      mover[moverCount++] = new Mover(map(note,noteNumberLow,noteNumberHigh,0,width), map(velocity, 0, 127, 0, height));
      isKeyPressed = true;
      println("MIDI message received. Note: " + note + ", velocity: " + velocity);
  }
  if(message.checkAddrPattern("/noteOff")) {
    isKeyPressed = false;
  }
}

//Function to update the position of main mover objects.
void updateMover() {
  if(patchSelected == theraminPatch || patchSelected == vocalPatch) {
    if(mousePressed) {
      theramin.update();
      theramin.display();
    }
  } else {
    for(int i = 0; i < moverCount; i++) {
      if(i != 0) {
        if(mover[i].checkThreshRange(mover[i-1],100)){
          mover[i].drawLine(mover[i-1]);
        }
      }
      mover[i].update();
      mover[i].display();
    }
  }
}

//Create mover objects which accompany main movers.
void triggerAuxMovers() {
  if(patchSelected == theraminPatch || patchSelected == vocalPatch) {
    if( millis() > time ){
      time = millis() + int(random(5, 100));
      if(auxMoverCount2 == maxAuxMoverSize) 
          auxMoverCount2 = 0;
      auxMover2[auxMoverCount2++] = new AuxMover2();
    }
  } else {
    if( millis() > time ){
      time = millis() + int(random(5, 300));
      if(auxMoverCount == maxAuxMoverSize) 
          auxMoverCount = 0;
      auxMover[auxMoverCount++] = new AuxMover(mouseX);
    }
  }
}

//Update the position of aux mover objects
void updateAuxMovers() {
  try{
  if(patchSelected == theraminPatch || patchSelected == vocalPatch) {
    for(int i = 0; i < auxMoverCount2; i++) {
      auxMover2[i].update();
      auxMover2[i].display();
    }
  } else {
    for(int i = 0; i < auxMoverCount; i++) {
      auxMover[i].update();
      auxMover[i].display();
    }
  }
  } catch(Exception e){
    println(e.toString());
  }
}

//Handle events from "Info" and "Octave view/Full view" buttons
void updateScalingAndView() {
  if(!isFullView) {
    noteNumberLow = octaveCount * 12;
    noteNumberHigh = octaveCount * 12 + 12;
  } else {
    noteNumberLow = 24;
    noteNumberHigh = 107;
  } 
  
  if(isMoreInfo) {
    textSize(largeTextSize);
    fill(255,60);
    textAlign(CENTER);
    if(!isFullView) {
      text("C",   octaveTextWidth*0 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C#",  octaveTextWidth*1 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("D",   octaveTextWidth*2 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("D#",  octaveTextWidth*3 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("E",   octaveTextWidth*4 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("F",   octaveTextWidth*5 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("F#",  octaveTextWidth*6 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("G",   octaveTextWidth*7 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("G#",  octaveTextWidth*8 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("A",   octaveTextWidth*9 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("A#",  octaveTextWidth*10 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("B",   octaveTextWidth*11 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C",   octaveTextWidth*12 + octaveTextWidth/2, height -octaveTextWidth/2);
    } else {
      text("C1",  fullViewTextWidth*0 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C2",  fullViewTextWidth*1 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C3",  fullViewTextWidth*2 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C4",  fullViewTextWidth*3 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C5",  fullViewTextWidth*4 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C6",  fullViewTextWidth*5 + octaveTextWidth/2, height -octaveTextWidth/2);
      text("C7",  fullViewTextWidth*6 + octaveTextWidth/2, height -octaveTextWidth/2);
    }
    
    textSize(mediumTextSize);
    textAlign(LEFT);
    text("Synth: "+patchBay[patchSelected].getName(), octaveTextWidth/3, height - octaveTextWidth*1.4);
    if(!isFullView)
      text("Octave: "+(octaveCount-1), octaveTextWidth/3, height - octaveTextWidth*2);
  }
}

//Handle opening and closing semi-transparent docks based on mouse position
void handleGroupTransition() {
  if(mouseY < collapseThreshold) {
    groupMain.openTransition();
    groupLeft.openTransition();
    groupRight.openTransition();
    groupAux.openTransition();
  } else {
    if(!mousePressed) {
      groupMain.closeTransition();
      groupLeft.closeTransition();
      groupRight.closeTransition();
      groupAux.closeTransition();
    }
  }
  
  if(groupMain.isOpen()) {
    isGroupOpen = true;
    showGUIComponents();
  } else {
    isGroupOpen = false;
    hideGUIComponents();
  }
  
  groupMain.display();
  groupLeft.display();
  groupRight.display();
  groupAux.display();
}

//Update text labels to be displayed for control widgets and their positioning
void updateWidgetText() {
  textSize(smallTextSize);
  textAlign(CENTER, CENTER);
  fill(0,0,90);
  if(isGroupOpen) {
    text(octaveCount-1, buttonPadding*1.7+buttonWidth, groupBoxMainY+knobSize+knobPadding*3.5);
    
    text("Volume", groupBoxMainX + knobPadding + knobSize/2, groupBoxMainY*2/3);
    text("Pan", groupBoxMainX + knobSize*1 + knobPadding*2 + knobSize/2, groupBoxMainY*2/3);
    text("Tone", groupBoxMainX + knobSize*2 + knobPadding*3 + knobSize/2, groupBoxMainY*2/3);
    text("Attack", groupBoxMainX + knobSize*3 + knobPadding*6 + knobSize/2, groupBoxMainY*2/3);
    text("Decay", groupBoxMainX + knobSize*4 + knobPadding*7 + knobSize/2, groupBoxMainY*2/3);
    text("Sustain", groupBoxMainX + knobSize*5 + knobPadding*8 + knobSize/2, groupBoxMainY*2/3);
    text("Release", groupBoxMainX + knobSize*6 + knobPadding*9 + knobSize/2, groupBoxMainY*2/3);
    
    float translateX = width + (groupBoxRightWidthOpen-groupBoxRightWidthClosed)/2;
    text("Modulation", translateX, groupBoxMainY/4);
    text("Depth  Rate", translateX, groupBoxMainY*2/3);
    text("Volume", translateX, groupBoxMainY + knobPadding);
    text("Pitch", translateX, groupBoxMainY + knobPadding*2 + smallKnobSize/2 + smallKnobSize);
    text("Pan", translateX, groupBoxMainY + knobPadding*3 + smallKnobSize + smallKnobSize*2);
    
    translateX = groupBoxMainX + groupBoxMainWidth;
    text("Reverb", translateX - knobPadding - knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
    text("Mix", translateX - knobPadding*2 - knobSize*1 - knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
    text("Delay", translateX - knobPadding*3 - knobSize*2 - knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*1/4);
    text("Feedback", translateX - knobPadding*3 - knobSize*2 - knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
    text("Time", translateX - knobPadding*4 - knobSize*3 - knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
    float refX;
    switch(patchSelected) {
    case 0:
      text("Index", groupBoxMainX + knobPadding + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Ratio", groupBoxMainX + knobPadding*2 + knobSize*1 + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Duration", groupBoxMainX + knobPadding*3 + knobSize*2 + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      break;
    case 1:
      text("Speed", groupBoxMainX + knobPadding + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Octaves", groupBoxMainX + knobPadding*2 + knobSize*1 + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Reverse", groupBoxMainX + knobPadding*3 + knobSize*2 + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Loop", groupBoxMainX + knobPadding*3 + knobSize*2 + knobSize/2, groupBoxAuxY + groupBoxAuxHeight + groupBoxMainY/3);
      text("Semitones", groupBoxMainX + knobPadding*5 + knobSize*3 + 5*(knobSize/4 + knobSize/6), groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY/4);
      refX = groupBoxMainX + knobPadding*5 + knobSize*3;
      for(int i = 0; i < 12; i++)
        text(i, refX + i*(int(knobSize)/6) + i*int(knobSize)/4, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      break;
    case 2:
      break;
    case 3:
      text("Reference", groupBoxMainX + knobPadding + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      break;
    case 4:
      text("Noise", groupBoxMainX + knobPadding + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Resonance", groupBoxMainX + knobPadding*2 + knobSize*1 + knobSize/2, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Style", groupBoxMainX + knobPadding*3 + knobSize*3, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("Vowels", groupBoxMainX + knobPadding*6 + knobSize*5, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY/4);
      refX = groupBoxAuxX + knobSize*4 + knobPadding*5 + knobSize/6;
      text("a", refX, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("e", refX + knobSize*1/4 + knobSize*1/3, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("i", refX + knobSize*2/4 + knobSize*2/3, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("o", refX + knobSize*3/4 + knobSize*3/3, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
      text("u", refX + knobSize*4/4 + knobSize*4/3, groupBoxMainY + groupBoxMainHeightOpen + groupBoxMainY*2/3);
    }
  }
}

//Hide control widgets and components when mouse is not at the top
void hideGUIComponents(){
  attackKnob.hide(); decayKnob.hide(); sustainKnob.hide(); releaseKnob.hide(); volumeKnob.hide(); panKnob.hide(); toneKnob.hide();
  speedKnob.hide(); octaveLow.hide(); octaveHigh.hide(); moreInfo.hide(); fullView.hide();
  volModDepthKnob.hide(); volModRateKnob.hide(); pitchModDepthKnob.hide(); pitchModRateKnob.hide(); panModDepthKnob.hide(); panModRateKnob.hide();
  delayTimeKnob.hide(); delayMixKnob.hide(); feedbackKnob.hide(); reverbKnob.hide(); noteSelector.hide(); vowelSelector1.hide(); vowelSelector2.hide();
  voiceType.hide();
  for(int i = 0; i < numSynths; i++)
    for(int j = 0; j < maxWidgetsPerSynth; j++)
      if(j < numWidgetsPerSynth[i])
        synthSpecific[i][j].hide();
}

//Show relevant widgets and components when mouse is at the top
void showGUIComponents(){
  attackKnob.show(); decayKnob.show(); sustainKnob.show(); releaseKnob.show(); volumeKnob.show(); panKnob.show(); toneKnob.show();
  speedKnob.show(); octaveLow.show(); octaveHigh.show(); moreInfo.show(); fullView.show();
  volModDepthKnob.show(); volModRateKnob.show(); pitchModDepthKnob.show(); pitchModRateKnob.show(); panModDepthKnob.show(); panModRateKnob.show();
  delayTimeKnob.show(); delayMixKnob.show(); feedbackKnob.show(); reverbKnob.show();
  togglePatchSpecificWidgets();
}

//Show or hide control widgets based on patch selected
void togglePatchSpecificWidgets() {
  for(int i = 0; i < numSynths; i++)
    for(int j = 0; j < maxWidgetsPerSynth; j++)
      if(i != patchSelected)
        if(j < numWidgetsPerSynth[i])
          synthSpecific[i][j].hide();
   
  for(int i = 0; i < numWidgetsPerSynth[patchSelected]; i++)
    synthSpecific[patchSelected][i].show();
  
  if(patchSelected == 1)
    noteSelector.show();
  else
    noteSelector.hide();
  if(patchSelected == 4) {
    vowelSelector1.show();
    vowelSelector2.show();
    voiceType.show();
  } else {
    vowelSelector1.hide();
    vowelSelector2.hide();
    voiceType.hide();
  }
}

//Set responsive dimensions based on the height and width of the window
void setDimensions() {
  groupBoxMainX = width * 0.125;
  groupBoxMainY = height * 0.088;
  groupBoxMainWidth = width - groupBoxMainX * 2;
  groupBoxMainHeightOpen = height * 0.133;
  groupBoxMainHeightClosed = height * 0.044;
  
  groupBoxAuxX = groupBoxMainX;
  groupBoxAuxY = groupBoxMainY*2 + groupBoxMainHeightOpen;
  groupBoxAuxWidth = groupBoxMainWidth;
  groupBoxAuxHeight = groupBoxMainHeightOpen;
  
  groupBoxLeftX = - width * 0.125;
  groupBoxLeftY = height * 0.088;
  groupBoxLeftHeight = height * 0.355;
  groupBoxLeftWidthClosed = width * 0.125;
  groupBoxLeftWidthOpen = width * 0.1 + groupBoxLeftWidthClosed;
  
  groupBoxRightX = width + (width * 0.125);
  groupBoxRightY = height * 0.088;
  groupBoxRightHeight = height * 0.355;
  groupBoxRightWidthClosed = -width * 0.125;
  groupBoxRightWidthOpen = groupBoxRightWidthClosed - width * 0.1;
  
  knobSize = height * 0.088;
  smallKnobSize = knobSize*2/3;
  knobPadding = height * 0.022;
  
  patchHeight = height * 0.088;
  patchWidth = width * 0.025;
  patchPadding = width * 0.00625;
  
  buttonHeight = height * 0.033;
  buttonWidth = width * 0.0313;
  buttonPadding = width * 0.01;
  
  collapseThreshold = height * 0.444; 
  
  octaveTextWidth = width * 0.0768; 
  fullViewTextWidth = width * 0.143;
  largeTextSize = height * 0.067;
  smallTextSize = height * 0.0247; 
  mediumTextSize = height * 0.0444;
  widgetTextSize = height * 0.02;
}

//Creates and assigns control widgets
void setGUIWidgets() {
  groupMain = new RectGroup(groupBoxMainX, groupBoxMainY, groupBoxMainWidth, groupBoxMainHeightOpen, TRANSITION.OPEN);
  groupLeft = new RectGroup(groupBoxLeftX, groupBoxLeftY, groupBoxLeftWidthClosed, groupBoxLeftHeight, TRANSITION.LEFT);
  groupRight = new RectGroup(groupBoxRightX, groupBoxRightY, groupBoxRightWidthClosed, groupBoxRightHeight, TRANSITION.RIGHT);
  groupAux = new RectGroup(groupBoxAuxX, groupBoxAuxY, groupBoxAuxWidth, 0, TRANSITION.AUX);
  
  float patchOffset = width - groupBoxMainX - knobPadding - patchWidth;
  float patchOffsetY = groupBoxMainY + knobPadding;
  color thisColor;
  patchBay[0] = new PatchBay(patchOffset - patchWidth*4 - patchPadding*4, patchOffsetY, 30, 80, 100, "FM Synth");
  patchBay[1] = new PatchBay(patchOffset - patchWidth*3 - patchPadding*3, patchOffsetY, 80, 80, 100, "Arpeggiator");
  patchBay[2] = new PatchBay(patchOffset - patchWidth*2 - patchPadding*2, patchOffsetY, 146, 80, 100, "Theremin");
  patchBay[3] = new PatchBay(patchOffset - patchWidth*1 - patchPadding*1, patchOffsetY, 190, 80, 100, "Sampler");
  patchBay[4] = new PatchBay(patchOffset - patchWidth*0 - patchPadding*0, patchOffsetY, 262, 80, 100, "Choir");
  
  PFont font = createFont("Tahoma", widgetTextSize, true); 
  guiInterface.setFont(font);
                      
  volumeKnob = guiInterface.addKnob("volume")
                      .setRange(0.01, 1)
                      .setValue(0.5)
                      .setPosition(groupBoxMainX + knobPadding, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  panKnob = guiInterface.addKnob("pan")
                      .setRange(-1, 1)
                      .setValue(0)
                      .setPosition(groupBoxMainX + knobSize*1 + knobPadding*2, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
  
  toneKnob = guiInterface.addKnob("tone")
                      .setRange(0.01, 1)
                      .setValue(1)
                      .setPosition(groupBoxMainX + knobSize*2 + knobPadding*3, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  attackKnob = guiInterface.addKnob("attack")
                      .setRange(0.01, 1)
                      .setValue(0.1)
                      .setPosition(groupBoxMainX + knobSize*3 + knobPadding*6, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  decayKnob = guiInterface.addKnob("decay")
                      .setRange(0.01, 1)
                      .setValue(0.1)
                      .setPosition(groupBoxMainX + knobSize*4 + knobPadding*7, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  sustainKnob = guiInterface.addKnob("sustain")
                      .setRange(0.01, 1)
                      .setValue(0.8)
                      .setPosition(groupBoxMainX + knobSize*5 + knobPadding*8, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  releaseKnob = guiInterface.addKnob("release")
                      .setRange(0.01, 3)
                      .setValue(1)
                      .setPosition(groupBoxMainX + knobSize*6 + knobPadding*9, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  //Left group box
  speedKnob = guiInterface.addKnob("speed")                      
                      .setRange(0, 5)
                      .setValue(2)
                      .setPosition(knobPadding*2, groupBoxMainY + knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setDragDirection(Knob.VERTICAL); 
                      
  octaveLow = guiInterface.addButton("octaveDecrement")
                      .setPosition(buttonPadding, groupBoxMainY + knobSize + knobPadding*3)
                      .setSize(int(buttonWidth), int(buttonHeight))
                      .setCaptionLabel("<")
                      .setColorBackground(color(360, 52, 83));
                      
  octaveHigh = guiInterface.addButton("octaveIncrement")
                      .setPosition((groupBoxLeftWidthOpen-groupBoxLeftWidthClosed)-buttonPadding-buttonWidth, groupBoxMainY+knobSize+knobPadding*3)
                      .setSize(int(buttonWidth), int(buttonHeight))
                      .setCaptionLabel(">")
                      .setColorBackground(color(360, 52, 83));;
                      
  fullView = guiInterface.addButton("fullView")
                      .setPosition(buttonPadding, groupBoxMainY+knobSize+knobPadding*5+buttonHeight)
                      .setSize(int(groupBoxLeftWidthOpen-groupBoxLeftWidthClosed-buttonPadding*2), int(buttonHeight))
                      .setCaptionLabel("Octave View")
                      .setColorBackground(color(360, 52, 83));
                      
  moreInfo = guiInterface.addButton("additionalInfo")
                      .setPosition(buttonPadding, groupBoxMainY+knobSize+knobPadding*6+buttonHeight*2)
                      .setSize(int(groupBoxLeftWidthOpen-groupBoxLeftWidthClosed-buttonPadding*2), int(buttonHeight))
                      .setCaptionLabel("Info")
                      .setColorBackground(color(360, 52, 83));
                      
  //Right Group Box:
  float translateX = width+(groupBoxRightWidthOpen-groupBoxRightWidthClosed);
  float smallKnobSize = knobSize*2/3;
  volModDepthKnob = guiInterface.addKnob("volModDepth")
                      .setRange(0, 1)
                      .setValue(0)
                      .setPosition(translateX+knobPadding, groupBoxMainY + knobPadding + smallKnobSize/2)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  volModRateKnob = guiInterface.addKnob("volModRate")
                      .setRange(0, 5)
                      .setValue(2)
                      .setPosition(translateX+knobPadding*2+smallKnobSize, groupBoxMainY + knobPadding + smallKnobSize/2)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");

  pitchModDepthKnob = guiInterface.addKnob("pitchModDepth")
                      .setRange(0, 100)
                      .setValue(0)
                      .setPosition(translateX+knobPadding, groupBoxMainY + knobPadding*2 + smallKnobSize*2/2 + smallKnobSize)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  pitchModRateKnob = guiInterface.addKnob("pitchModRate")
                      .setRange(0, 5)
                      .setValue(2)
                      .setPosition(translateX+knobPadding*2+smallKnobSize, groupBoxMainY + knobPadding*2 + smallKnobSize*2/2 + smallKnobSize)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");   
                      
  panModDepthKnob = guiInterface.addKnob("panModDepth")
                      .setRange(0, 1)
                      .setValue(0)
                      .setPosition(translateX+knobPadding, groupBoxMainY + knobPadding*3 + smallKnobSize*3/2 + smallKnobSize*2)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  panModRateKnob = guiInterface.addKnob("panModRate")
                      .setRange(0, 5)
                      .setValue(2)
                      .setPosition(translateX+knobPadding*2+smallKnobSize, groupBoxMainY + knobPadding*3 + smallKnobSize*3/2 + smallKnobSize*2)
                      .setSize(int(smallKnobSize), int(smallKnobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  //Aux group box:
  reverbKnob = guiInterface.addKnob("reverb")
                      .setRange(0, 1)
                      .setValue(0.3)
                      .setPosition(groupBoxAuxX+groupBoxAuxWidth-knobPadding-knobSize, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  delayMixKnob = guiInterface.addKnob("delayMix")
                      .setRange(0, 1)
                      .setValue(0.3)
                      .setPosition(groupBoxAuxX+groupBoxAuxWidth-knobPadding*2-knobSize*2, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
  
  feedbackKnob = guiInterface.addKnob("feedback")
                      .setRange(0, 1)
                      .setValue(0.3)
                      .setPosition(groupBoxAuxX+groupBoxAuxWidth-knobPadding*3-knobSize*3, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");
                      
  delayTimeKnob = guiInterface.addKnob("delayTime")
                      .setRange(0, 4)
                      .setValue(1)
                      .setPosition(groupBoxAuxX+groupBoxAuxWidth-knobPadding*4-knobSize*4, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(color(303,50,82))
                      .setColorBackground(color(261,77,62))
                      .setLabel("");                   
                      
  //Synth specific widgets

  thisColor = patchBay[0].getColor();
  int altBright = 60;
  int altSat = 50;
  
  //Synth: 1
  synthSpecific[0][0] = guiInterface.addKnob("01")
                      .setRange(0, 10)
                      .setValue(5)
                      .setPosition(groupBoxAuxX+knobPadding, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
                      
  synthSpecific[0][1] = guiInterface.addKnob("02")
                      .setRange(0, 5)
                      .setValue(2)
                      .setPosition(groupBoxAuxX+knobSize*1+knobPadding*2, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
                      
  synthSpecific[0][2] = guiInterface.addKnob("03")
                      .setRange(0, 3)
                      .setValue(1)
                      .setPosition(groupBoxAuxX+knobSize*2+knobPadding*3, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
  
  //Synth: 2
  thisColor = patchBay[1].getColor();
  synthSpecific[1][0] = guiInterface.addKnob("11")
                      .setRange(4, 20)
                      .setValue(0)
                      .setPosition(groupBoxAuxX+knobPadding, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
                      
  synthSpecific[1][1] = guiInterface.addKnob("12")
                      .setRange(1, 5)
                      .setValue(1)
                      .setNumberOfTickMarks(4)
                      .snapToTickMarks(true)
                      .showTickMarks(false)
                      .setPosition(groupBoxAuxX+knobSize*1+knobPadding*2, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
                      
  synthSpecific[1][2] = guiInterface.addToggle("13")
                        .setPosition(groupBoxAuxX+knobSize*2+knobPadding*3, groupBoxAuxY+knobPadding)
                        .setSize(int(knobSize*1.2),int(knobSize/3))
                        .setColorForeground(thisColor)
                        .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                        .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
                        .setCaptionLabel("");
                      
  synthSpecific[1][3] = guiInterface.addToggle("14")
                        .setPosition(groupBoxAuxX+knobSize*2+knobPadding*3, groupBoxAuxY+knobPadding*2+knobSize/3)
                        .setSize(int(knobSize*1.2),int(knobSize/3))
                        .setColorForeground(thisColor)
                        .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                        .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
                        .setCaptionLabel("");
                    
  noteSelector = guiInterface.addCheckBox("notesSelected")
                 .setPosition(groupBoxAuxX+knobSize*3+knobPadding*5, groupBoxAuxY+knobPadding)
                 .setSize(int(knobSize/4), int(knobSize))
                 .setItemsPerRow(12)
                 .setSpacingColumn(int(knobSize/6))
                 .setSpacingRow(10)
                 .setColorForeground(thisColor)
                 .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                 .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
                 .addItem("N0", 0)
                 .addItem("N1", 1)
                 .addItem("N2", 2)
                 .addItem("N3", 3)
                 .addItem("N4", 4)
                 .addItem("N5", 5)
                 .addItem("N6", 6)
                 .addItem("N7", 7)
                 .addItem("N8", 8)
                 .addItem("N9", 9)
                 .addItem("N10", 10)
                 .addItem("N11", 11)
                 .hideLabels();
  noteSelector.toggle(0).toggle(2).toggle(4).toggle(5).toggle(7).toggle(9).toggle(11);
                      
  //Synth 3:
  //None
                      
  //Synth4
  thisColor = patchBay[3].getColor();
  synthSpecific[3][0] = guiInterface.addKnob("31")
                      .setRange(1, 88)
                      .setValue(60)
                      .setNumberOfTickMarks(87)
                      .snapToTickMarks(true)
                      .showTickMarks(false)
                      .setPosition(groupBoxAuxX+knobPadding, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
  synthSpecific[3][1] = guiInterface.addButton("fileChooser")
                        .setPosition(groupBoxAuxX+knobSize+knobPadding*2, groupBoxAuxY+knobPadding+knobSize/3)
                        .setSize(int(knobSize*1.5),int(knobSize/3))
                        .setColorForeground(color(hue(thisColor),altSat,brightness(thisColor)))
                        .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                        .setCaptionLabel("File");
                        
  //Synth 5
  thisColor = patchBay[4].getColor();
  synthSpecific[4][0] = guiInterface.addKnob("41")
                      .setRange(0, 1)
                      .setValue(0.9)
                      .setPosition(groupBoxAuxX+knobPadding, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
  
  synthSpecific[4][1] = guiInterface.addKnob("42")
                      .setRange(2, 15)
                      .setValue(5)
                      .setPosition(groupBoxAuxX+knobPadding*2+knobSize, groupBoxAuxY+knobPadding)
                      .setSize(int(knobSize), int(knobSize))
                      .setDragDirection(Knob.VERTICAL)
                      .setColorForeground(thisColor)
                      .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                      .setColorBackground(color(hue(thisColor),saturation(thisColor),altBright))
                      .setLabel("");
                      
  List typeList = Arrays.asList("Bass", "Tenor", "Countertenor", "Alto", "Soprano");
  voiceType = guiInterface.addScrollableList("voiceTypeDropdown")
             .setPosition(groupBoxAuxX+knobPadding*3+knobSize*2, groupBoxAuxY+knobPadding)
             .setSize(int(knobSize*2+knobPadding), int(knobSize+knobPadding))
             .setBarHeight(int(buttonHeight))
             .setItemHeight(int(buttonHeight))
             .addItems(typeList)
             .setColorForeground(thisColor)
             .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
             .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
             .setOpen(false)
             .setValue(2)
             .setCaptionLabel("Voice Type");
             
  vowelSelector1 = guiInterface.addRadioButton("vowelSelect1")
                 .setPosition(groupBoxAuxX+knobSize*4+knobPadding*5, groupBoxAuxY+knobPadding)
                 .setSize(int(knobSize/3), int(knobSize/3))       
                 .setItemsPerRow(5)
                 .setSpacingColumn(int(knobSize/4))
                 .setColorForeground(thisColor)
                 .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                 .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
                 .addItem("V11", 0)
                 .addItem("V12", 1)
                 .addItem("V13", 2)
                 .addItem("V14", 3)
                 .addItem("V15", 4)
                 .hideLabels();
  vowelSelector1.activate(0);
                 
  vowelSelector2 = guiInterface.addRadioButton("vowelSelect2")
                 .setPosition(groupBoxAuxX+knobSize*4+knobPadding*5, groupBoxAuxY+knobPadding*2+knobSize/3)
                 .setSize(int(knobSize/3), int(knobSize/3))       
                 .setItemsPerRow(5)
                 .setSpacingColumn(int(knobSize/4))
                 .setColorForeground(thisColor)
                 .setColorActive(color(hue(thisColor),altSat,brightness(thisColor)))
                 .setColorBackground(color(hue(thisColor),saturation(thisColor),30))
                 .addItem("V21", 0)
                 .addItem("V22", 1)
                 .addItem("V23", 2)
                 .addItem("V24", 3)
                 .addItem("V25", 4)
                 .hideLabels();
  vowelSelector2.activate(3);
}

//Callbacks for control widgets:
void octaveDecrement() { if(octaveCount > 2) octaveCount--; }
void octaveIncrement() { if(octaveCount < 8) octaveCount++; }
void fullView() { 
  isFullView = !isFullView; 
  if(isFullView) {
    fullView.setColorBackground(color(261, 77, 62));
    fullView.setCaptionLabel("Full View");
  }
  else {
    fullView.setColorBackground(color(360, 52, 83));
    fullView.setCaptionLabel("Octave View");
  }
}
void additionalInfo() { 
  isMoreInfo = !isMoreInfo; 
  if(isMoreInfo)
    moreInfo.setColorBackground(color(261, 77, 62));
  else
    moreInfo.setColorBackground(color(360, 52, 83));
}
void fileChooser() {
  selectInput("Select a file to process:", "fileSelected", dataFile("*.wav"));
}
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath().replace("\\", "\\\\"));
    bufferFile = selection.getAbsolutePath().replace("\\", "\\\\");
    OscMessage fileChangeMessage = new OscMessage("/FileChange");
    fileChangeMessage.add(bufferFile);
    osc.send(fileChangeMessage, supercollider);
  }
}
void voiceTypeDropdown(int n) { voiceTypeIndex = n; }

//Function to reset control widgets when window resize event occurs
void resetGUIWidgets(){
  guiInterface.remove("volume");
  guiInterface.remove("pan");
  guiInterface.remove("tone");
  guiInterface.remove("attack");
  guiInterface.remove("decay");
  guiInterface.remove("sustain");
  guiInterface.remove("release");
  guiInterface.remove("speed");
  guiInterface.remove("octaveDecrement");
  guiInterface.remove("octaveIncrement");
  guiInterface.remove("fullView");
  guiInterface.remove("additionalInfo");
  guiInterface.remove("volModDepth");
  guiInterface.remove("volModRate");
  guiInterface.remove("pitchModDepth");
  guiInterface.remove("pitchModRate");
  guiInterface.remove("panModDepth");
  guiInterface.remove("panModRate");
  guiInterface.remove("reverb");
  guiInterface.remove("delayMix");
  guiInterface.remove("delayTime");
  guiInterface.remove("feedback");
  guiInterface.remove("fileChooser");
  guiInterface.remove("notesSelected");
  guiInterface.remove("vowelSelect1");
  guiInterface.remove("vowelSelect2");
  guiInterface.remove("voiceTypeDropdown");
  for(int i = 0; i < numSynths; i++)
    for(int j = 0; j < maxWidgetsPerSynth; j++)
      if(j < numWidgetsPerSynth[i]){ 
        guiInterface.remove(i+""+(j+1));
      }
}