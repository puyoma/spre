Engine_Spre : CroneEngine {
  var voices, maxVoices, voiceIndex, params, masterBus, masterSynth, voiceGain, noteSynths;
  alloc {
    var buildVoice;
    maxVoices = 12;
    voiceIndex = 0;
    voices = Array.newClear(maxVoices);
    voiceGain = 0.8;
    noteSynths = Dictionary.new;
    masterBus = Bus.audio(Server.default, 2);
    params = (
      baseDecay: 0.4, fmAmt: 0.2, bright: 0.5,
      saturation: 0.3, attackShape: 0.2, tapeAmt: 0.2,
      filter: 0.4, dust: 0.0, spread: 0.0, intone: 0.5,
      sustain: 0.7, release: 0.3, filterType: 0
    );

    // ==== ボイス生成: envType(\perc/\adsr) × filterType(0-3) の8種を生成 ====
    // 1ボイス=1フィルターだけを実体化（CPU削減＋切替ノイズ回避）。
    // filterType はビルド時の定数なので、選ばれた分岐のUGenのみがグラフに載る。
    buildVoice = { |envType, ft|
      SynthDef(("spreV_" ++ envType ++ "_" ++ ft).asSymbol, {
        |out=0, freq=440, gate=1,
         baseDecay=0.4, fmAmt=0.2,
         bright=0.5, saturation=0.3, attackShape=0.2,
         tapeAmt=0.2, filter=0.4, spread=0.0,
         intone=0.5, jiOffset=0.0, dust=0.0, voiceGain=0.8,
         sustain=0.7, release=0.3|
        var decayScaled, fmScaled, brightScaled, satScaled;
        var attack, env, mod, osc, hiss, flutter, crushRate, lpg, sig, dustSig;
        var moogCutoff, moogRes, rq, cutoffBase, envBright, resAmt;
        var ladderRes, vac, lpgCut;
        var intoneAmt, releaseTime, filtSmooth, satSmooth;
        fmScaled     = fmAmt.linlin(0,1,0,8);
        brightScaled = bright.linlin(0,1,300,12000);
        filtSmooth   = Lag2.kr(filter, 0.18);   // 2次ラグ = 舐めらか、ザラつき無し
        satSmooth    = Lag.kr(saturation, 0.03);
        satScaled    = satSmooth.linlin(0,1,1,12);
        intoneAmt = (intone - 0.5) * 2;
        freq = freq * (jiOffset * intoneAmt).midiratio;

        // エンベロープ（ビルド時に perc / adsr を選択）
        if(envType == \perc, {
          decayScaled = baseDecay.linlin(0,1,0.08,8);
          attack = attackShape.linexp(0,1,0.0005,0.12);
          env = EnvGen.kr(Env.perc(attack, decayScaled, curve: attackShape.linlin(0,1,-14,-1)), gate, doneAction:2);
        }, {
          decayScaled = baseDecay.linlin(0,1,0.005,1.5);
          releaseTime = release.linlin(0,1,0.02,4.0);
          attack = attackShape.linexp(0,1,0.001,0.5);
          env = EnvGen.kr(Env.adsr(attack, decayScaled, sustain, releaseTime), gate, doneAction:2);
        });

        mod = SinOsc.ar(freq * LFNoise1.kr(0.5).range(1.2,2.5), 0, freq * fmScaled * 0.16);
        osc = VarSaw.ar(freq + mod, 0, LFNoise1.kr(0.1).range(0.35,0.6));
        hiss = HPF.ar(PinkNoise.ar(tapeAmt*0.22), 4000);
        flutter = LFNoise2.kr(4).range(0.0, tapeAmt*0.012);
        osc = DelayC.ar(osc, 0.03, flutter);
        crushRate = tapeAmt.linexp(0,1,44100,2500);
        osc = Latch.ar(osc, Impulse.ar(crushRate));
        osc = LPF.ar(osc, tapeAmt.linexp(0,1,12000,1800));
        osc = tanh(osc * (1+(tapeAmt*6))) + hiss;

        // 共通コントロール: 1ノブ → カットオフ(指数) と レゾナンス(逆相関・指数)
        cutoffBase = filtSmooth.linexp(0, 1, 120, 9000);
        envBright  = brightScaled * 0.5 * env.squared.squared;
        moogCutoff = (cutoffBase + envBright).clip(30, 18000);
        resAmt  = 1 - filtSmooth;
        moogRes = resAmt.linexp(0, 1, 0.6, 5.5);
        rq      = moogRes.reciprocal;

        // フィルター本体（1種類のみ実体化）
        lpg = switch(ft,
          // 0: AIR — RLPF 2極(12dB)、丸めLPFなし＝開いた明るい上、共鳴がよく歌う
          0, {
            var s = RLPF.ar(osc, moogCutoff, rq);
            s * (1 - (resAmt * 0.16))
          },
          // 1: GLASS — BLowPass4 4極(24dB)、ほぼ無共鳴のフラット＝純クリーンで滑らか
          1, {
            var gq = resAmt.linexp(0, 1, 0.7, 1.6);            // ほぼ無共鳴（フラット寄り）
            var s = BLowPass4.ar(osc, moogCutoff, gq.reciprocal);
            s = LPF.ar(s, (moogCutoff * 1.8).clip(60, 18000));  // 追従丸め＝急峻でも角のない純クリーン
            s
          },
          // 2: AMBER — MoogFF ラダー、太く暖かい、tanhでグリット
          2, {
            ladderRes = resAmt.linlin(0, 1, 0.0, 3.3);
            MoogFF.ar(osc, moogCutoff, ladderRes).tanh
          },
          // 3: WOOD — vactrol風ローパスゲート、有機的な余韻
          3, {
            vac    = LagUD.kr(env, 0.008, 0.22);
            lpgCut = (moogCutoff * vac.linlin(0,1,0.2,1.0)).clip(30, 18000);
            (LPF.ar(LPF.ar(osc, lpgCut), lpgCut)) * vac.linlin(0,1,0.3,1.0)
          }
        );

        lpg = lpg * env * voiceGain;
        lpg = (lpg * satScaled).tanh;
        lpg = HPF.ar(lpg, 60);
        dustSig = (
          Dust2.ar(dust.linexp(0,1,1,200)) * 0.3
          + HPF.ar(WhiteNoise.ar, 1500) * dust * 0.6
          + LFNoise0.ar(6000) * dust * 0.2
        ) * dust * env;
        lpg = lpg + dustSig;
        sig = Pan2.ar(lpg, LFNoise1.kr(0.2).range(spread.neg * 0.9, spread * 0.9));
        sig = LeakDC.ar(sig);
        Out.ar(masterBus, sig * (0.3 / maxVoices));
      }).add;
    };
    [\perc, \adsr].do { |et| 4.do { |ft| buildVoice.(et, ft) } };

    SynthDef(\spreMaster, {
      |out=0, in|
      var sig;
      sig = In.ar(in, 2);
      sig = tanh(sig * 3) / 3;
      sig = Compander.ar(sig, sig, 0.12, 1, 0.15, 0.001, 0.08);
      sig = sig * 10.0;              // メイクアップ（ラウド寄り。数値で音量調整）
      sig = Limiter.ar(sig, 0.98);   // 天井を上げてラウドに、ピークは保護
      Out.ar(out, sig);
    }).add;

    // AUTO/LOOPERモード: percノートオン（現在のfilterTypeのSynthDefを選択）
    this.addCommand(\noteOn, "if", {|msg|
      var note     = msg[1];
      var jiOffset = msg[2];
      var defName  = ("spreV_perc_" ++ params[\filterType]).asSymbol;
      voiceIndex = (voiceIndex + 1) % maxVoices;
      if (voices[voiceIndex].notNil) { voices[voiceIndex].free };
      voices[voiceIndex] = Synth(defName, [
        \freq,         note.midicps,
        \gate,         1,
        \jiOffset,     jiOffset,
        \baseDecay,    params[\baseDecay],
        \fmAmt,        params[\fmAmt],
        \bright,       params[\bright],
        \saturation,   params[\saturation],
        \attackShape,  params[\attackShape],
        \tapeAmt,      params[\tapeAmt],
        \filter,       params[\filter],
        \dust,         params[\dust],
        \spread,       params[\spread],
        \intone,       params[\intone],
        \voiceGain,    voiceGain
      ]);
    });
    // GRID/MIDIモード: ADSRノートオン（現在のfilterTypeのSynthDefを選択）
    this.addCommand(\noteOnAdsr, "if", {|msg|
      var note     = msg[1];
      var jiOffset = msg[2];
      var defName  = ("spreV_adsr_" ++ params[\filterType]).asSymbol;
      var s;
      if (noteSynths[note].notNil) { noteSynths[note].set(\gate, 0) };
      voiceIndex = (voiceIndex + 1) % maxVoices;
      if (voices[voiceIndex].notNil) { voices[voiceIndex].set(\gate, 0) };
      s = Synth(defName, [
        \freq,         note.midicps,
        \gate,         1,
        \jiOffset,     jiOffset,
        \baseDecay,    params[\baseDecay],
        \fmAmt,        params[\fmAmt],
        \bright,       params[\bright],
        \saturation,   params[\saturation],
        \attackShape,  params[\attackShape],
        \tapeAmt,      params[\tapeAmt],
        \filter,       params[\filter],
        \dust,         params[\dust],
        \spread,       params[\spread],
        \intone,       params[\intone],
        \voiceGain,    voiceGain,
        \sustain,      params[\sustain],
        \release,      params[\release]
      ]);
      voices[voiceIndex] = s;
      noteSynths[note] = s;
    });
    // ノートオフ（ADSRリリース）
    this.addCommand(\noteOff, "i", {|msg|
      var note = msg[1];
      if (noteSynths[note].notNil) {
        noteSynths[note].set(\gate, 0);
        noteSynths.removeAt(note);
      };
    });
    this.addCommand(\baseDecay, "f", {|msg|
      var v = msg[1]; params[\baseDecay] = v;
      noteSynths.do({|s| s.set(\baseDecay, v)});
      voices.do({|s| if(s.notNil, {s.set(\baseDecay, v)})});
    });
    this.addCommand(\fmAmt, "f", {|msg|
      var v = msg[1]; params[\fmAmt] = v;
      noteSynths.do({|s| s.set(\fmAmt, v)});
      voices.do({|s| if(s.notNil, {s.set(\fmAmt, v)})});
    });
    this.addCommand(\bright, "f", {|msg|
      var v = msg[1]; params[\bright] = v;
      noteSynths.do({|s| s.set(\bright, v)});
      voices.do({|s| if(s.notNil, {s.set(\bright, v)})});
    });
    this.addCommand(\saturation, "f", {|msg|
      var v = msg[1]; params[\saturation] = v;
      noteSynths.do({|s| s.set(\saturation, v)});
      voices.do({|s| if(s.notNil, {s.set(\saturation, v)})});
    });
    this.addCommand(\attackShape, "f", {|msg|
      var v = msg[1]; params[\attackShape] = v;
      noteSynths.do({|s| s.set(\attackShape, v)});
      voices.do({|s| if(s.notNil, {s.set(\attackShape, v)})});
    });
    this.addCommand(\tapeAmt, "f", {|msg|
      var v = msg[1]; params[\tapeAmt] = v;
      noteSynths.do({|s| s.set(\tapeAmt, v)});
      voices.do({|s| if(s.notNil, {s.set(\tapeAmt, v)})});
    });
    this.addCommand(\filter, "f", {|msg|
      var v = msg[1]; params[\filter] = v;
      noteSynths.do({|s| s.set(\filter, v)});
      voices.do({|s| if(s.notNil, {s.set(\filter, v)})});
    });
    this.addCommand(\dust, "f", {|msg|
      var v = msg[1]; params[\dust] = v;
      noteSynths.do({|s| s.set(\dust, v)});
      voices.do({|s| if(s.notNil, {s.set(\dust, v)})});
    });
    this.addCommand(\spread, "f", {|msg|
      var v = msg[1]; params[\spread] = v;
      noteSynths.do({|s| s.set(\spread, v)});
      voices.do({|s| if(s.notNil, {s.set(\spread, v)})});
    });
    this.addCommand(\intone, "f", {|msg|
      var v = msg[1]; params[\intone] = v;
      noteSynths.do({|s| s.set(\intone, v)});
      voices.do({|s| if(s.notNil, {s.set(\intone, v)})});
    });
    this.addCommand(\sustain, "f", {|msg|
      var v = msg[1]; params[\sustain] = v;
      noteSynths.do({|s| s.set(\sustain, v)});
      voices.do({|s| if(s.notNil, {s.set(\sustain, v)})});
    });
    this.addCommand(\release, "f", {|msg|
      var v = msg[1]; params[\release] = v;
      noteSynths.do({|s| s.set(\release, v)});
      voices.do({|s| if(s.notNil, {s.set(\release, v)})});
    });
    // フィルタータイプ: 0=AIR 1=GLASS 2=AMBER 3=WOOD（次の発音から適用）
    this.addCommand(\filterType, "f", {|msg|
      params[\filterType] = msg[1].round.asInteger.clip(0, 3);
    });
    this.addCommand(\gain, "f", {|msg|
      var v = msg[1]; voiceGain = v;
      noteSynths.do({|s| s.set(\voiceGain, v)});
      voices.do({|s| if(s.notNil, {s.set(\voiceGain, v)})});
    });
    Server.default.sync;
    masterSynth = Synth.tail(Server.default, \spreMaster, [\in, masterBus, \out, 0]);
  }
  free {
    voices.do{|v| v.notNil.if{v.free}};
    noteSynths.do{|v| v.notNil.if{v.free}};
    masterSynth.free;
    masterBus.free;
  }
}
