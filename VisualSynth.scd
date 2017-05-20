/*
Supercollider code for VisualSynth
Author: Thrifleganger

Incoming OSC message format:
Index - Description
0 - OSC message name(do not use)
1 - Patch number
2 - MIDI note number
3 - Note velocity
4 - Globabl Volume
5 - Global Pan
6 - Global Tone
7 - Attack
8 - Decay
9 - Sustain
10- Release
11- Depth of volume modulation
12- Rate of volume modulation
13- Depth of pitch modulation
14- Rate of pitch modulation
15- Depth of pan modulation
16- Rate of pan modulation
17- Delay time
18- Delay feedback
19- Delay mix
20- Reverb mix

From 21 onwards, patch specific parameters

Instructions on running:

To run the code, press Ctrl+Enter / Cmd+Enter right below the comment lines "Run first" and "Run next"
To stop the code, press Ctrl+. / Cmd+. (period)
Always stop the code before restarting.
*/

//Run first
s.boot;

//Run next:
(
//Global buffer variable for storing audio
~buffer;

//Global variables for storing formant data:
~bass = Array2D.new(5, 3);
~tenor = Array2D.new(5, 3);
~countertenor = Array2D.new(5, 3);
~alto = Array2D.new(5, 3);
~soprano = Array2D.new(5, 3);

//Bass formant data: Frequency, Level(DB), Bandwidth
~bass[0,0] = [600,1040,2250,2450,2750];
~bass[1,0] = [400,1625,2400,2800,3100];
~bass[2,0] = [250,1750,2600,3050,3340];
~bass[3,0] = [400,750,2400,2600,2900];
~bass[4,0] = [350,600,2400,2675,2950];

~bass[0,1] = ([0 ,-7,-9,-9,-20]).dbamp;
~bass[1,1] = ([0 ,-12,-9,-12,-18]).dbamp;
~bass[2,1] = ([0 ,-30,-16,-22,-28]).dbamp;
~bass[3,1] = ([0 ,-11,-21,-20,-40]).dbamp;
~bass[4,1] = ([0 ,-20,-32,-28,-36]).dbamp;

~bass[0,2] = [60,70,110,120,130];
~bass[1,2] = [40,80,100,120,120];
~bass[2,2] = [60,90,100,120,120];
~bass[3,2] = [40,80,100,120,120];
~bass[4,2] = [40,80,100,120,120];

//Tenor formant data: Frequency, Level(DB), Bandwidth
~tenor[0,0] = [650,1080,2650,2900,3250];
~tenor[1,0] = [400,1700,2600,3200,3580];
~tenor[2,0] = [290,1870,2800,3250,3540];
~tenor[3,0] = [400,800,2600,2800,3000];
~tenor[4,0] = [350,600,2700,2900,3300];

~tenor[0,1] = ([0 ,-6,-7,-8,-22]).dbamp;
~tenor[1,1] = ([0 ,-14,-12,-14,-20]).dbamp;
~tenor[2,1] = ([0 ,-15,-18,-20,-30]).dbamp;
~tenor[3,1] = ([0 ,-10,-12,-12,-26]).dbamp;
~tenor[4,1] = ([0 ,-20,-17,-14,-26]).dbamp;

~tenor[0,2] = [80,90,120,130,140];
~tenor[1,2] = [70,80,100,120,120];
~tenor[2,2] = [40,90,100,120,120];
~tenor[3,2] = [40,80,100,120,120];
~tenor[4,2] = [40,60,100,120,120];

//Countertenor formant data: Frequency, Level(DB), Bandwidth
~countertenor[0,0] = [660,1120,2750,3000,3350];
~countertenor[1,0] = [440,1800,2700,3000,3300];
~countertenor[2,0] = [270,1850,2900,3350,3590];
~countertenor[3,0] = [430,820,2700,3000,3300];
~countertenor[4,0] = [370,630,2750,3000,3400];

~countertenor[0,1] = ([0 ,-6,-23,-24,-38]).dbamp;
~countertenor[1,1] = ([0 ,-14,-18,-20,-20]).dbamp;
~countertenor[2,1] = ([0 ,-24,-24,-36,-36]).dbamp;
~countertenor[3,1] = ([0 ,-10,-26,-22,-34]).dbamp;
~countertenor[4,1] = ([0 ,-20,-23,-30,-34]).dbamp;

~countertenor[0,2] = [80,90,120,130,140];
~countertenor[1,2] = [70,80,100,120,120];
~countertenor[2,2] = [40,90,100,120,120];
~countertenor[3,2] = [40,80,100,120,120];
~countertenor[4,2] = [40,60,100,120,120];

//Alto formant data: Frequency, Level(DB), Bandwidth
~alto[0,0] = [800,1150,2800,3500,4950];
~alto[1,0] = [400,1600,2700,3300,4950];
~alto[2,0] = [350,1700,2700,3700,4950];
~alto[3,0] = [450,800,2830,3500,4950];
~alto[4,0] = [325,700,2530,3500,4950];

~alto[0,1] = ([0 ,-4,-20,-36,-60]).dbamp;
~alto[1,1] = ([0 ,-24,-30,-35,-60]).dbamp;
~alto[2,1] = ([0 ,-20,-30,-36,-60]).dbamp;
~alto[3,1] = ([0 ,-9,-16,-28,-55]).dbamp;
~alto[4,1] = ([0 ,-12,-30,-40,-64]).dbamp;

~alto[0,2] = [80,90,120,130,140];
~alto[1,2] = [60,80,120,150,200];
~alto[2,2] = [50,100,120,150,200];
~alto[3,2] = [70,80,100,130,135];
~alto[4,2] = [50,60,170,180,200];

//Soprano formant data: Frequency, Level(DB), Bandwidth
~soprano[0,0] = [800,1150,2900,3900,4950];
~soprano[1,0] = [350,2000,2800,3600,4950];
~soprano[2,0] = [270,2140,2950,3900,4950];
~soprano[3,0] = [450,800,2830,3800,4950];
~soprano[4,0] = [325,700,2700,3800,4950];

~soprano[0,1] = ([0 ,-6,-32,-20,-50]).dbamp;
~soprano[1,1] = ([0 ,-20,-15,-40,-56]).dbamp;
~soprano[2,1] = ([0 ,-12,-26,-26,-44]).dbamp;
~soprano[3,1] = ([0 ,-11,-22,-22,-50]).dbamp;
~soprano[4,1] = ([0 ,-16,-35,-40,-60]).dbamp;

~soprano[0,2] = [80,90,120,130,140];
~soprano[1,2] = [60,100,120,150,200];
~soprano[2,2] = [60,90,100,120,120];
~soprano[3,2] = [70,80,100,130,135];
~soprano[4,2] = [50,60,170,180,200];

//Synth definition for Patch 1: FM Synth
SynthDef(\FMSynth, {
	arg index= 3, pitch = 440, ratio = 3.5, amp = 0.5, gate = 1, pan = 0.5, tone = 1,
	attack=0.01, sustain=0.5, release=1, decay=0.3, duration = 1,
	volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;

	//Generate envelopes for volume and index
	var indexEnv = EnvGen.kr(Env([index,0.2],[duration],\lin));
	var volEnv = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);

	//Handle modulation
	var volMod = SinOsc.kr(freq: volModRate, mul: volModDepth/2, add: 0.5);
	var panMod = SinOsc.kr(freq: panModRate, mul: panModDepth);
	var pitchMod = SinOsc.kr(freq: pitchModRate, mul: pitchModDepth);

	var mod = SinOsc.ar(freq: pitch * ratio, mul: pitch * indexEnv);
	var carr = SinOsc.ar(freq: pitch * 2.pow(pitchMod/1200) + mod , mul: volEnv * amp);
	var filter = LPF.ar(carr * volMod, tone.linexp(0, 1, 200, 20000));
	var out = Pan2.ar(filter, if(panModDepth < 0.01, pan, panMod));

	Out.ar(0, out);
}).add;

//Synth definition for Patch 3: Theremin
SynthDef(\Theremin, {
	arg mod = 7, detune = 0, pitch = 440,
	attack=0.01, sustain=0.5, release=1, decay=0.3, gate=1, amp=0.5, pan=0, tone=1,
	volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;

	var volEnv = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
	var volMod = SinOsc.kr(freq: volModRate, mul: volModDepth/2, add: 0.5);
	var panMod = SinOsc.kr(freq: panModRate, mul: panModDepth);
	var pitchMod = SinOsc.kr(freq: pitchModRate, mul: pitchModDepth);

	var synth = SinOsc.ar(pitch * 2.pow(pitchMod/1200) + (pitch * SinOsc.ar(mod,0,0.02)),
		mul: amp*volEnv*volMod);
	var filter = LPF.ar(synth, tone.linexp(0, 1, 200, 20000));
	var out = Pan2.ar(filter, if(panModDepth < 0.01, pan, panMod));

	Out.ar(0, out);
}).add;

//Synth definition for Patch 4: Sampler
SynthDef(\Sampler, {
	arg buffer = ~buffer, keyPressed = 60, reference = 60,
	attack=0.01, sustain=0.5, release=1, decay=0.3, gate=1, amp=0.5, pan=0, tone=1,
	volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;

	var difference = keyPressed - reference;
	var volEnv = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
	var volMod = SinOsc.kr(freq: volModRate, mul: volModDepth/2, add: 0.5);
	var panMod = SinOsc.kr(freq: panModRate, mul: panModDepth);
	var pitchMod = SinOsc.kr(freq: pitchModRate, mul: pitchModDepth, add:1);

	var player = PlayBuf.ar(1, buffer, 2.pow(difference/12));
	var pitched = PitchShift.ar(player, pitchRatio: 2.pow(pitchMod/1200));
	var filter = LPF.ar(pitched * volMod * volEnv * amp, tone.linexp(0, 1, 200, 20000));
	var out = Pan2.ar(filter, if(panModDepth < 0.01, pan, panMod));
	Out.ar(0, out);
}).add;

//Reverb generator
SynthDef(\Reverb, {
	arg mix = 0.5;
	var input = In.ar(0, 2);
	var reverb = FreeVerb.ar(input, mix, 0.8, 0.5);
	Out.ar(0, reverb);
}).add;

//Delay generator
SynthDef(\Delay, {
	arg mix, delayTime, feedback;
	var input = In.ar(0, 2);
	var feedSignal = LocalIn.ar(2);
	var delay = DelayL.ar(input + feedSignal, 5, delayTime);
	LocalOut.ar(delay * feedback);
	Out.ar(0, delay * mix);
}).add;

//Deploy reverb and delay synths irrespective of any event
~reverb = Synth.new(\Reverb);
~delay = Synth.new(\Delay);

//Declare space for 128 notes (polyphony)
~notes = Array.newClear(128);
~patchNumber = 0;

//Mouse click event listener, intercepted from Processing
OSCdef('MouseListener', {
	arg msg;
	var nn, pitch, ampinDB, amp, volume, pan, tone, attack, decay, sustain, release;
	var volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;
	var delayTime, feedback, delayMix, reverbMix, genericControl;
	var nSel = Array.newClear(12);
	var nList = List.new(11);

	~patchNumber = msg[1];
	nn = msg[2];
	pitch = midicps(nn);
	ampinDB = msg[3];
	amp = dbamp(ampinDB);
	volume = msg[4];
	pan = msg[5];
	tone = msg[6];
	attack = msg[7];
	decay = msg[8];
	sustain = msg[9];
	release = msg[10];
	volModDepth = msg[11];
	volModRate = msg[12];
	pitchModDepth = msg[13];
	pitchModRate = msg[14];
	panModDepth = msg[15];
	panModRate = msg[16];
	delayTime = msg[17];
	feedback = msg[18];
	delayMix = msg[19];
	reverbMix = msg[20];

	genericControl = [\pitch, pitch,
			\amp, amp * volume,
			\gate, 1,
			\pan, pan,
			\tone, tone,
			\attack, attack,
			\decay, decay,
			\sustain, sustain,
			\release, release,
			\volModDepth, volModDepth,
			\volModRate, volModRate,
			\pitchModDepth, pitchModDepth,
			\pitchModRate, pitchModRate,
			\panModDepth, panModDepth,
		    \panModRate, panModRate];

	msg.postln;
	//If patch is FM Synth:
	if(~patchNumber == 0, {
		~notes[nn] = Synth.new(\FMSynth,
			genericControl
			//Patch specific:
			 ++ [\index, msg[21],
			\ratio, msg[22],
			\duration, msg[23]
		]);
	});
	//If patch is Arpeggiator
	if(~patchNumber == 1, {
		nSel = [msg[25],msg[26],msg[27],msg[28],msg[29],msg[30],msg[31],msg[32],msg[33],
			msg[34],msg[35],msg[36]];
		12.do({arg i;
			if(nSel[i] == 1, {nList.add(nn+i);}, {})
		});
		~tempList = nList;
		msg[22].do({arg i;
			if(i != 0, {
				~octList = ~tempList + (12 * i);
				nList = nList ++ ~octList;
			});
		});
		if(msg[23] == 1, {nList = nList ++ nList.reverse}, {});
		if(msg[24] == 1,
			{~sequence = Pseq(nList.midicps, 1)},
			{~sequence = Pseq(nList.midicps, 1)}
		);
		Pbind(
			\freq, ~sequence,
			\tempo, msg[21],
			\amp, amp
		).play;
	});
	//If patch is Theremin:
	if(~patchNumber == 2, {
		~theremin = Synth.new(\Theremin,
			genericControl
			//Patch specific:
			++ [
		]);
	});
	//If patch is Sampler:
	if(~patchNumber == 3, {
		~notes[nn] = Synth.new(\Sampler,
			genericControl
			//Patch specific:
			++ [\buffer, ~buffer,
				\keyPressed, nn,
				\reference, msg[21]
		]);
	});
	//If patch is Choir:
	if(~patchNumber == 4, {
		~voiced = msg[21];
		~resonance = msg[22];
		~vowelA = msg[23];
		~vowelB = msg[24];
		~voiceType = msg[25];
		if(~vowelA == -1, {~vowelA = 0;});
		if(~vowelB == -1, {~vowelB = 0;});
		//This synth definition could not be in the earlier section, since this Synthdef needs to be
		//loaded everytime a value changes, since these values are used in control structures
		//within the SynthDef
		SynthDef(\Vocals, {
			arg freq = 220, amp=0.01, blend=0.5,
			attack=0.01, sustain=0.5, release=1, decay=0.3, gate=1, pan=0, tone=1,
			volModDepth, volModRate, pitchModDepth, pitchModRate, panModDepth, panModRate;
			//Naming format: example(v1fa) - voice 1, frequency for vowel 'a'
			//                      (v2ae) - voice 2, amplitude of formant for vowel 'e'
			//                      (v3bo) - voice 3, bandwidth of formant for vowel 'o'
			var freqTab, ampTab, bwTab;
			var periodicsource, aperiodicsource, source, output;
			var vibrato, out;
			var vibratonoise= LFNoise1.kr(10);
			var style = Array2D.new(5, 3);

			var volEnv = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
			var volMod = SinOsc.kr(freq: volModRate, mul: volModDepth/2, add: 0.5);
			var panMod = SinOsc.kr(freq: panModRate, mul: panModDepth);
			var pitchMod = SinOsc.kr(freq: pitchModRate, mul: pitchModDepth, add:1);

			//Choose voice type
			switch(~voiceType,
				0, {style = ~bass;},
				1, {style = ~tenor;},
				2, {style = ~countertenor;},
				3, {style = ~alto;},
				4, {style = ~soprano;},
				{style = ~soprano;}
			);

			freqTab = Array.newClear(5);
			ampTab = Array.newClear(5);
			bwTab = Array.newClear(5);

			//Get interpolated voice between 2 vowels
			freqTab = style[~vowelA,0].blend(style[~vowelB,0], blend);
			ampTab = style[~vowelA,1].blend(style[~vowelB,1], blend);
			bwTab = style[~vowelA,2].blend(style[~vowelB,2], blend);

			vibrato= (((freq.cpsmidi * 2.pow(pitchMod/1200))+(Line.kr(0.0,1.0,2.5)*SinOsc.kr(6+(1.0*vibratonoise),0,0.5))).midicps).lag(0.2);
			periodicsource= LPF.ar(Impulse.ar(vibrato),5000);
			aperiodicsource= PinkNoise.ar(0.7);
			source= (~voiced*periodicsource)+((1.0-~voiced)*aperiodicsource);

			output= Mix(Formlet.ar(source, freqTab, 0.001, ~resonance*bwTab.reciprocal, ampTab))*amp*volEnv*volMod;
			out = Pan2.ar(output, if(panModDepth < 0.01, pan, panMod));
			Out.ar(0,out)
		}).add(completionMsg: {
		~vocalPatch = Synth.new(\Vocals,
			genericControl
		);});
	});

	~reverb.set(\mix, reverbMix);
	~delay.set(\mix, delayMix);
	~delay.set(\delayTime, delayTime);
	~delay.set(\feedback, feedback);

}, "/MouseClick");

//Mouse release event listener, intercepted from Processing
OSCdef('MouseOffListener', {
	arg msg;
	var nn = msg[2];
	~patchNumber = msg[1];
	msg.postln;
	if(~notes[nn] != nil, {
		~notes[nn].set(\gate, 0);
		~notes[nn] = nil;
	});
	if(~theremin != nil, {
		~theremin.set(\gate, 0);
		~theremin = nil;
	});
	if(~vocalPatch != nil, {
		~vocalPatch.set(\gate, 0);
		~vocalPatch = nil;
	});
}, "/MouseClickRelease");

//Mouse press and hold event listener, intercepted from Processing
OSCdef('MousePressedListener', {
	arg msg;
	var nn = msg[2];
	~patchNumber = msg[1];
	msg.postln;
	if(~patchNumber == 2, {
		~theremin.set(\pitch, midicps(nn));
	});
	if(~patchNumber == 4, {
		~vocalPatch.set(\freq, midicps(nn.ceil));
		~vocalPatch.set(\blend, msg[3]);
	});
}, "/MousePressed");

//File change event listener, intercepted from Processing
OSCdef('FileChangeListener', {
	arg msg;
	var fileName = msg[1];
	msg.postln;
	~buffer = Buffer.read(s, fileName);
}, "/FileChange");

//Initialize OSC
b = NetAddr.new("127.0.0.1", 12000);
//Initialize and select all active MIDI input devices
MIDIClient.init;
MIDIClient.sources;
MIDIIn.connectAll;

//Handle Midi note on event
MIDIdef.noteOn(\MIDINoteOn, {
	arg vel, nn, chan, src;
	if(~patchNumber == 0, {
		~notes[nn] = Synth.new(\FMSynth, [\pitch, midicps(nn),
			\amp, vel.linexp(1, 127, 0.01, 1),
			\gate, 1
		]);
	});
	//Send OSC message to Processing
	b.sendMsg("/noteTriggered", nn, vel);
});

//Handle MIDI note off event
MIDIdef.noteOff(\MIDINoteOff, {
	arg vel, nn, chan, src;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;

	//Send OSC message to Processing
	b.sendMsg("/noteOff", nn, vel);
});

)

//Find local address for use with Processing
NetAddr.localAddr
s.reboot;
s.plotTree;
