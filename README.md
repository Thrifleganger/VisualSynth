# VisualSynth: Processing + SuperCollider

A visual interface for generating sound, developed using Processing and SuperCollider. This is a functional beta. 

Instructions:
1) Download Processing: https://processing.org/download/
2) Download SuperCollider: http://supercollider.github.io/download
3) Install Processing dependencies: Launch the sketch, VisualSynth.pde. Go to Tools -> Add Tool. Go to the Libraries tab. Search for "OscP5" and "ControlP5" and install them.
4) Run the sketch.
5) Open VisualSynth.scd
6) Run the statements right below the commands "Run First" and "Run Next". To run, press Ctrl+Enter or Cmd+Enter
7) Go on a clicking frenzy.

The Next Step:
The next step would be to port it to browsers and mobile devices. Porting to a browser seems harder than expected since SuperCollider is based on a server architecture and cannot be run on a web client. Thus scaling and performance issues persist. Another approach to this problem would be to ditch SuperCollider and try and implement HTML5 WebAudio API. This is the cleanest approach, but it would mean loosing the flexibity of having to code with SuperCollider. Another alternative is to explore NaCl / Emscripten with Csound. Things to do in the future.

Known issues:
- Clicking on controls triggers sound as well.
- Loop button on Choir synth does not work. Couldn't figure out a certain nuance with global envelopes on Pbind.
- Performance decrease when resized to high dimensions.
