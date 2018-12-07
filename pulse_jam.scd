s.quit;
s.boot;

(
SynthDef(\pulse, {
	arg freq = 440, amp = 0.2, rel = 4, gate = 1,
	pw = 0.25, cutoff = 11500, pol = 0.05, hpfCut = 20,
	pan = 0, out = 0;
	var sig, env;

	env = EnvGen.kr(Env.adsr(0.005, rel, 0, 0.05), gate, doneAction: 2);
	sig = PulseDPW.ar(Lag2.kr(freq, pol), pw, amp*0.85) * env;
	// sig = LPF.ar(sig, cutoff).tanh;
	sig = LPF.ar(sig, cutoff*EnvGen.kr(Env.perc(0.01, 0.3), 1, 0.8, 0.2)).tanh;
	// sig = LPF.ar(sig, cutoff*EnvGen.kr(Env.perc(0.01, 0.1), 1, 0.8, 0.2)).tanh;
	sig = HPF.ar(sig, hpfCut).clip2(1.0);
	sig = Pan2.ar(sig, pan);

	Out.ar(0, sig);
}).add;

SynthDef(\noise, {
	arg amp = 0.1, gate = 1, srDenom = 4, pan = 0.0,
	atk = 0.01, dec = 1.0, sus = 1.0, rel = 0.05,
	out = 0;

	var sig, env;

	env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate, doneAction: 2);
	sig = Decimator.ar(WhiteNoise.ar, SampleRate.ir/srDenom, 8);
	sig = Pan2.ar(sig, pan, amp);
	sig = sig * env;

	Out.ar(0, sig);
}).add;

SynthDef(\kick, {
	arg amp = 0.1, gate = 1, out = 0;

	var sig, env, freq, transient, tenv;

	freq = EnvGen.kr(Env([40, 3200, 210, 40], [0.001, 0.02, 0.1], [2, -4, -2]));
	env = EnvGen.kr(Env.adsr(0.001, 0.25, 0.75, 0.05), gate, doneAction: 2);
	tenv = EnvGen.kr(Env.perc(0.001, 0.05));
	transient = Decimator.ar(WhiteNoise.ar, SampleRate.ir/[2*2,3*2], 8) * amp * 0.75 * tenv;
	sig = SinOsc.ar(freq, 0, amp) * env;
	sig = Pan2.ar(sig, 0) + Splay.ar(transient, 0.5);

	Out.ar(out, sig);
}).add;

SynthDef(\bass, {
	arg freq = 440, amp = 0.1, gate = 1, pol = 0.05, out = 0;

	var sig, env;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.05), gate, doneAction: 2);
	sig = PulseDPW.ar(Lag2.kr(freq, pol), 0.25, amp);
	sig = Pan2.ar(sig, 0);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\master, {
	arg gate = 1, out = 0;
	var sig;
	sig = In.ar(out, 2);
	// sig = sig * 1.3;
	// sig = sig.softclip * 1.3;
	sig = sig * 1.55;
	sig = Limiter.ar(sig, 0.99);
	sig = sig * EnvGen.kr(Env([1, 1, 0], [1, 1], 'lin', 1), gate, doneAction: 2);
	ReplaceOut.ar(out, sig);
}).add;
)

(
~root = -9;

~pattern_noise1 = Pbind(
	\instrument, \noise,
	\amp, 0.175,
	\pan, 0.5,
	\dec, Pseq([0.05, 0.1, 0.01, 0.1], inf),
	\srDenom, Pseq([8, 12, 8, 16], inf),
	\sus, Pseq([0.0, 0.0, 0.0, 0.0], inf),
	\dur, Pseq([1, 2/3, 1/3], inf)/4,
);

~pattern_noise2 = Pbind(
	\instrument, \noise,
	\amp, 0.175,
	\pan, -0.5,
	\dec, Pseq([0.05, 0.1, 0.01, 0.1], inf),
	\srDenom, Pseq([8, 8], inf),
	\sus, Pseq([0.0, 0.0], inf),
	\dur, Pseq([1], inf)/4,
);

~pattern_noise3 = Pbind(
	\instrument, \noise,
	\amp, 0.15,
	\pan, 0.0,
	\dec, 0.5,
	\srDenom, 4,
	\sus, 0.5,
	\legato, 1,
	\dur, Pseq([
		Pn(Rest(1), 8*3),
		Pn(Rest(1), 6), Rest(2/3), 1/3, Rest(1)
	], inf)/4,
);

~pattern_clap = Pbind(
	\instrument, \noise,
	\amp, 0.23,
	\pan, [-0.25, 0.25],
	\dec, 0.125,
	\srDenom, [5, 8],
	\sus, 0.5,
	\legato, 0.1,
	\dur, Pseq([
		Rest(2), 2,
	], inf)/4,
);

~pattern_noise = Ppar([~pattern_noise1, ~pattern_noise2]);

~pattern_kick = Pbind(
	\instrument, \kick,
	\amp, 0.467,
	\legato, 0.15,
	\dur, 1/2,
);

~patternA = PmonoArtic(
	\pulse,
	\amp, 0.25*1,
	\degree, Prewrite(0, (
		0: [0, 1, 2, 0],
		1: [-3, 2, 1],
		2: [4, 0, 2],
	), 4),
	\root, ~root + 12,
	\legato, Prand([1.5, 0.75, 0.5], inf),
	\pan, Pwhite(-0.1, 0.1, inf),
	\dur, Pseq([Pseq([
		Pwrand([Rest(2/3), 2/3], [0.05, 0.95]),
		Prand([Rest(1/3), 1/3])
	], 7), 1], inf)/4,
	\rel, 16,
);

~patternA_top = Pbindf(
	~patternA,
	\amp, 0.30*1,
	\pw, 0.1,
	\pol, Pwrand([0.05, 1], [0.6, 0.4], inf),
	\root, ~root + 24,
	\legato, 0.25,
	\degree, Prewrite(0, (
		0: [0, 4, 0, 0],
		2: [2, 1, 0, 0],
		4: [-3, -2, 1, 2],
	), 4),
);

~patternB_top = PmonoArtic(
	\pulse,
	\amp, 0.30*1,
	\pw, 0.1,
	\pol, Pwrand([0.05, 1], [0.6, 0.4], inf),
	\root, ~root + 24,
	\legato, Prand([1.5, 0.75, 0.5], inf),
	\pan, Pwhite(-0.1, 0.1, inf),
	\degree, Prewrite(0, (
		0: [0, 4, 0, 0],
		2: [2, 1, 0, 0],
		4: [-3, -2, 1, 2],
	), 4),
	\dur, Pseq([Pseq([2/3, 1/3], 7), 1], inf)/4,
	\rel, 16,
);

~patternA_bass = Pbindf(
	~patternA,
	\root, ~root,
	\amp, 0.3*1,
	\pw, 0.25,
	\pan, 0,
	\degree, Prewrite(0, (
		0: [0, 4, 0, 2],
		2: [1, 0, 2, -3],
		4: [0, -2, 1],
	), 4),
);

~pattern_subBass = Pbind(
	\instrument, \bass,
	\root, ~root-12,
	\amp, 0.18,
	\dur, 1/4,
	\legato, 0.6,
	\degree, Pseq([
		Rest(1), 0,
	], inf),
);

~pattern_subBass_slide = PmonoArtic(
	\bass,
	\root, ~root-12,
	\amp, 0.15,
	\pol, 1,
	\dur, Pseq([Rest((1/3)/4), (2/3)/4, 3/4]),
	\legato, Pseq([Rest(1), 1.5, 0.2]),
	\degree, Pseq([Rest(1), 0, -3]),
);

Pfx(Pseq([
	Event.silent(0.5),
	Psync(Pbindf(~patternA, \amp, 0.3*1.2), 0.1, 0.5),
	Psync(Ppar([
		Pseq([
			Psync(Ppar([
				~patternA,
				~patternA_bass,
				Pseq([Event.silent(15.5), ~patternA_top]),
			]), 0.5, 16),
			Ppar([
				~patternA,
				~patternA_bass,
				~patternA_top,
			]),
		]),
		Pseq([Event.silent(31.5), ~pattern_noise]),
	]), 0.5, 66+16),
	Event.silent(2 + (1/3)),
	Psync(Pbindf(~patternB_top, \amp, 0.35*1.1), 0.5, 1),
	Psync(Ppar([
		Pbindf(~patternA, \amp, 0.25*0.98, \hpfCut, 150),
		Pbindf(~patternA_top, \amp, 0.3*0.98, \hpfCut, 150),
		Pbindf(~patternA_bass, \amp, 0.3*0.98, \hpfCut, 150),
		~pattern_kick,
		Pseq([
			Pfindur(31.5, ~pattern_subBass),
			~pattern_subBass_slide,
			~pattern_subBass,
		]),
		Pseq([
			Pfindur(31.75 + (2/(3*4)), ~pattern_noise),
			Event.silent(1/(3*4)),
			~pattern_noise,
		]),
		Pseq([
			Pfindur(31.5, Ppar([~pattern_clap, ~pattern_noise3])),
			Event.silent(0.5),
			Ppar([~pattern_clap, ~pattern_noise3]),
		]),
		Pbind(
			\type, \rest,
			\dur, Pseq([31.5, 0.25, 0.25, 29]),
			\tempo, Pseq([1, 1/2, 1/8, 1]),
		),
	]), 0.5, 29+16+16),
	Psync(Ppar([
		Pfindur(3.0, Pbindf(~patternA, \amp, 0.25*1, \hpfCut, 150)),
		Pbindf(~patternA_top, \amp, 0.3*1, \hpfCut, 150),
		Pbindf(~patternA_bass, \amp, 0.3*1, \hpfCut, 150),
		Pfindur(3.0, ~pattern_kick),
		Pfindur(3.0, ~pattern_subBass),
		~pattern_clap,
		~pattern_noise,
	]), 0.1, 3.1),
	Event.silent(0.9),
], 1), \master).play;
)
