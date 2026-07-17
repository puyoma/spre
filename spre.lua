-- spre: a generative synthesizer for monome norns
-- v1.0.0 @Puyoma
-- https://github.com/puyoma/spre
engine.name = "Spre"
local g = grid.connect()
local SCALES = {
  { name="PENMI",  intervals={0,3,5,7,10} },
  { name="PENMA",  intervals={0,2,4,7,9} },
  { name="MAJOR",      intervals={0,2,4,5,7,9,11} },
  { name="MINOR",      intervals={0,2,3,5,7,8,10} },
  { name="DORIAN",     intervals={0,2,3,5,7,9,10} },
  { name="LYDIAN",     intervals={0,2,4,6,7,9,11} },
  { name="MIXOLYD",    intervals={0,2,4,5,7,9,10} },
  { name="PHRYGIAN",   intervals={0,1,3,5,7,8,10} },
  { name="LOCRIAN",    intervals={0,1,3,5,6,8,10} },
  { name="PHRYG DOM",  intervals={0,1,4,5,7,8,10} },
  { name="BLUES",      intervals={0,3,5,6,7,10} },
  { name="WHOLE TONE", intervals={0,2,4,6,8,10} },
  { name="DIMINISH",   intervals={0,2,3,5,6,8,9,11} },
  { name="HUNG MIN",   intervals={0,2,3,6,7,8,11} },
  { name="IN SEN",     intervals={0,1,5,7,10} },
  { name="HIRAJOSHI",  intervals={0,2,3,7,8} },
  { name="ARABIC",     intervals={0,1,4,5,7,8,11} },
  { name="BEBOP MAJ",  intervals={0,2,4,5,7,8,9,11} },
  { name="ENIGMATIC",  intervals={0,1,4,6,8,10,11} },
  { name="CHROMATIC",  intervals={0,1,2,3,4,5,6,7,8,9,10,11} },
}
local PARAMS_DEF = {
  { id="bright",        name="BRIGHT",      def=0.50 },
  { id="saturation",    name="SATURATION",  def=0.30 },
  { id="attackShape",   name="ATTACK",      def=0.50 },
  { id="tapeAmt",       name="TAPE",        def=0.20 },
  { id="baseDecay",     name="DECAY",       def=0.50 },
  { id="dust",          name="DUST",         def=0.0  },
  { id="fmAmt",         name="FM",          def=0.20 },
  { id="spread",        name="SPREAD",      def=0.0  },
  { id="filter",        name="FILTER",      def=0.40 },
  { id="intone",        name="INTONE",      def=0.5  },
}
local MODES      = {"AUTO", "MIDI", "GRID"}
local mode       = 1
local root       = 60
local scale_idx  = 1
local density    = 0.3
local chance     = 0.0
local sel_item   = 0
local display_timer = 0
local display_text  = ""
local midiDevice    = nil
local grid_notes    = {}
local all_params    = {}
local auto_clock    = nil
local redraw_clock  = nil
local blink_tick    = 0
local blink_on      = false
local k1_held       = false
local k2_held       = false
local octave_shift  = 0
local screen_page   = 1
local particles     = {}
local wave_phase    = 0
local wave_anim     = 0
local note_birds    = {}
local master_level  = 0.5
local FILTER_TYPES  = {"AIR", "GLASS", "AMBER", "WOOD"}
local filter_type   = 1
local amp_level     = 0
local melody_mode   = 1
local last_degree   = 7
local clas_dir        = 1
local clas_phrase_pos = 0
local clas_phrase_root= 4
local MELODY_NAMES  = {"RAND", "GAUSS", "MRKV", "ORBIT", "FOLD"}
local poly_mode     = 1
local POLY_NAMES    = {"MONO", "OCT", "5TH", "TRIAD", "7TH", "RAND", "ADD4", "JAZZ"}
local mel_col       = 0
local poly_spread   = 0.0
local viewer_t      = 0
local boy_shuffle   = 0
local looper_sel_slot = 1
local degree_history = {}
local NOTE_NAMES   = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}
local midi_note_map = {}
local MIDI_OUT_CH = 1
local midiOut = nil
local JI_OFFSET = {
  [0]= 0,
  [1]= 0.5865,
  [2]= 0.1955,
  [3]= 0.7820,
  [4]=-0.6845,
  [5]=-0.0980,
  [6]=-0.5865,
  [7]= 0.0980,
  [8]= 0.6845,
  [9]=-0.7820,
  [10]=-0.1955,
  [11]=-0.5865,
}
local loops = {}
for i = 1, 6 do
  loops[i] = { state="empty", notes={}, length=0, clock_id=nil, last_press=0, rec_mode=1 }
end
local recording_slot = nil
local record_start   = nil
local DOUBLE_CLICK_T = 0.35
local looper_mode       = 1
local SC_BUF_OFFSET     = {0, 35}
local SC_BUF_NUM        = {1, 2}
local sc_loop_len       = {0, 0}
local sc_stopping_clock = {nil, nil}
local sc_record_start   = {nil, nil}
local sc_dir            = {1, 1}
local sc_speed          = {1.0, 1.0}
local sc_level          = {1.0, 1.0}
local sc_pre         = 0.0
local splash_active  = true
local splash_t       = 0
local SPLASH_FRAMES  = 75
local splash_birds   = {}
for i = 1, 9 do
  table.insert(splash_birds, {
    x      = math.random(0, 128),
    y      = 10 + math.random() * 40,
    vx     = 0.25 + math.random() * 0.35,
    vy     = 0,
    flap   = math.random() * math.pi * 2,
    level  = math.random(4, 9),
    delay  = math.random(0, 25),
  })
end
function draw_pixel_bird(x, y, frame, lv)
  x = math.floor(x); y = math.floor(y)
  screen.level(lv)
  if frame == 0 then
    screen.pixel(x-2, y-1); screen.fill()
    screen.pixel(x-1, y-1); screen.fill()
    screen.pixel(x,   y  ); screen.fill()
    screen.pixel(x+1, y-1); screen.fill()
    screen.pixel(x+2, y-1); screen.fill()
  elseif frame == 1 then
    screen.pixel(x-2, y  ); screen.fill()
    screen.pixel(x-1, y  ); screen.fill()
    screen.pixel(x,   y  ); screen.fill()
    screen.pixel(x+1, y  ); screen.fill()
    screen.pixel(x+2, y  ); screen.fill()
  else
    screen.pixel(x-2, y+1); screen.fill()
    screen.pixel(x-1, y  ); screen.fill()
    screen.pixel(x,   y  ); screen.fill()
    screen.pixel(x+1, y  ); screen.fill()
    screen.pixel(x+2, y+1); screen.fill()
  end
end
function draw_splash()
  screen.clear()
  local fade_in  = math.min(1.0, splash_t / 35.0)
  local fade_out = splash_t > 60 and math.max(0, 1 - (splash_t - 60) / 15.0) or 1.0
  local alpha    = fade_in * fade_out
  if fade_in < 0.95 then
    local n = math.floor((1 - fade_in) * 12)
    for _ = 1, n do
      screen.level(math.random(1, 4))
      screen.pixel(math.random(14, 114), math.random(16, 44))
      screen.fill()
    end
  end
  local flicker  = math.random() < 0.25 and math.random(-2, 2) or 0
  local txt_lv   = math.max(0, math.min(15, math.floor(alpha * 15) + flicker))
  if txt_lv > 0 then
    screen.level(txt_lv)
    screen.font_face(1)
    screen.font_size(20)
    screen.move(64, 34)
    screen.text_center("SPRE")
  end
  local sub_alpha = math.max(0, math.min(1, (splash_t - 20) / 25.0)) * fade_out
  if sub_alpha > 0 then
    local sub_lv = math.max(0, math.min(8, math.floor(sub_alpha * 8)))
    screen.font_face(1)
    screen.font_size(8)
    screen.level(sub_lv)
    screen.move(64, 47)
    screen.text_center("generative synthesizer")
    screen.level(math.floor(sub_lv * 0.6))
    screen.move(64, 59)
    screen.text_center("v1.0  /  by Puyoma")
  end
  for _, b in ipairs(splash_birds) do
    if splash_t >= b.delay then
      b.x   = b.x + b.vx
      b.vy  = b.vy + math.sin(splash_t * 0.08 + b.flap) * 0.015
      b.vy  = math.max(-0.3, math.min(0.3, b.vy))
      b.y   = b.y + b.vy
      b.flap = (b.flap + 0.13 + math.random() * 0.04) % (math.pi * 2)
      if b.x > 134 then b.x = -6; b.y = 10 + math.random() * 40 end
      local frame = math.floor(b.flap / (math.pi * 2 / 3)) % 3
      local blv   = math.max(0, math.min(15, math.floor(b.level * alpha)))
      if blv > 0 then draw_pixel_bird(b.x, b.y, frame, blv) end
    end
  end
  screen.font_face(1)
  screen.update()
  splash_t = splash_t + 1
  if splash_t >= SPLASH_FRAMES then splash_active = false end
end
function gauss_random(mean, std)
  local u1 = math.max(1e-9, math.random())
  local u2 = math.random()
  local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
  return mean + z * std
end
function markov_next_degree(current, max_deg)
  local weights = {}
  local total = 0
  for d = 0, max_deg do
    local dist = math.abs(d - current)
    local w = math.exp(-dist * 0.45)
    weights[d] = w
    total = total + w
  end
  local r = math.random() * total
  local cumul = 0
  for d = 0, max_deg do
    cumul = cumul + weights[d]
    if cumul >= r then return d end
  end
  return max_deg
end
function quantize_to_scale(midi_note)
  local scale      = SCALES[scale_idx].intervals
  local root_class = root % 12
  local note_class = midi_note % 12
  local octave     = math.floor(midi_note / 12)
  local best_class = note_class
  local best_dist  = 999
  for _, interval in ipairs(scale) do
    local sc = (root_class + interval) % 12
    local d  = math.min(math.abs(note_class - sc), 12 - math.abs(note_class - sc))
    if d < best_dist then
      best_dist  = d
      best_class = sc
    end
  end
  local q = octave * 12 + best_class
  if q - midi_note >  6 then q = q - 12 end
  if midi_note - q >  6 then q = q + 12 end
  return math.max(0, math.min(127, q))
end
function root_name(midi)
  local name   = NOTE_NAMES[(midi % 12) + 1]
  local octave = math.floor(midi / 12) - 1
  return name .. octave
end
function get_scale_note(degree)
  local scale    = SCALES[scale_idx].intervals
  local octave   = math.floor(degree / #scale)
  local interval = scale[(degree % #scale) + 1]
  local note     = root + octave * 12 + interval + octave_shift * 12
  return math.max(0, math.min(127, note))
end
function grid_to_degree(row, col)
  local scale_len  = #SCALES[scale_idx].intervals
  local row_octave = (8 - row)
  local col_pos    = (col - 1) % scale_len
  return row_octave * scale_len + col_pos
end
function add_particles(midi_note)
  local x = math.random(10, 118)
  local y = math.random(14, 58)
  local r_max = util.linlin(36, 84, 5, 24, midi_note)
  r_max = util.clamp(r_max, 4, 24)
  local br_init = 8 + params:get("bright") * 7
  local decay_time = params:get("baseDecay") * 6 + 0.3
  local dr = br_init / (decay_time * 15)
  local vr = r_max * dr / br_init
  local fm = params:get("fmAmt")
  vr = vr * (1 + fm * (math.random() * 0.8 - 0.2))
  vr = math.max(0.05, vr)
  table.insert(particles, { x=x, y=y, r=0.0, r_max=r_max, vr=vr, br=br_init, dr=dr })
  while #particles > 30 do table.remove(particles, 1) end
end
function play_note(midi_note)
  local interval = (midi_note - root) % 12
  local ji_off   = JI_OFFSET[interval] or 0
  looper_capture(midi_note)
  engine.noteOn(midi_note, ji_off)
  wave_anim = 1.0
  table.insert(note_birds, {
    x = 0, y = math.random(-3, 3),
    speed = 0.5 + density * 0.8,
    flap_phase = math.random() * math.pi * 2
  })
  while #note_birds > 8 do table.remove(note_birds, 1) end
  add_particles(midi_note)
  if midiOut then
    midiOut:note_on(midi_note, 100, MIDI_OUT_CH)
    local dur = params:get("baseDecay") * 4 + 0.1
    clock.run(function()
      clock.sleep(dur)
      midiOut:note_off(midi_note, 0, MIDI_OUT_CH)
    end)
  end
end
function play_note_adsr(midi_note)
  local interval = (midi_note - root) % 12
  local ji_off   = JI_OFFSET[interval] or 0
  engine.noteOnAdsr(midi_note, ji_off)
  wave_anim = 1.0
  table.insert(note_birds, {
    x = 0, y = math.random(-3, 3),
    speed = 0.7,
    flap_phase = math.random() * math.pi * 2
  })
  while #note_birds > 8 do table.remove(note_birds, 1) end
  add_particles(midi_note)
  if midiOut then midiOut:note_on(midi_note, 100, MIDI_OUT_CH) end
end
-- 和音を発音。poly_spread>0 なら各音を時間差で散らす（ストラム/人間味）
function play_chord(notes)
  if #notes == 0 then return end
  if poly_spread <= 0.001 or #notes == 1 then
    for _, n in ipairs(notes) do play_note(n) end
    return
  end
  local max_delay = poly_spread * 0.13   -- 最大 ~130ms の散らし
  play_note(notes[1])                    -- 最初の音は即時
  for i = 2, #notes do
    local n      = notes[i]
    local base   = (i - 1) / #notes * max_delay          -- 順番にずらす
    local jitter = (math.random() - 0.5) * max_delay * 0.5 -- 少し不均一に
    local d      = math.max(0, base + jitter)
    clock.run(function()
      clock.sleep(d)
      play_note(n)
    end)
  end
end
function looper_capture(note, ev_type)
  if recording_slot then
    local t = util.time() - record_start
    table.insert(loops[recording_slot].notes, {note=note, t=t, type=ev_type or "on"})
  end
end
function looper_reset(slot)
  if loops[slot].clock_id then clock.cancel(loops[slot].clock_id) end
  for _, ev in ipairs(loops[slot].notes) do
    engine.noteOff(ev.note)
  end
  loops[slot] = { state="empty", notes={}, length=0, clock_id=nil, last_press=0, rec_mode=1 }
  if recording_slot == slot then recording_slot = nil end
end
function looper_start_play(slot)
  local loop = loops[slot]
  if loop.clock_id then clock.cancel(loop.clock_id) end
  loop.state = "playing"
  loop.clock_id = clock.run(function()
    while true do
      local base     = util.time()
      local rec_mode = loop.rec_mode or 1
      for _, ev in ipairs(loop.notes) do
        local wait = ev.t - (util.time() - base)
        if wait > 0.005 then clock.sleep(wait) end
        if loops[slot].state == "playing" then
          if ev.type == "off" then
            engine.noteOff(ev.note)
            if midiOut then midiOut:note_off(ev.note, 0, MIDI_OUT_CH) end
          elseif rec_mode == 3 then
            play_note_adsr(ev.note)
          else
            play_note(ev.note)
          end
        end
      end
      local remain = loop.length - (util.time() - base)
      if remain > 0.005 then clock.sleep(remain) end
    end
  end)
end
function looper_press(slot)
  if looper_mode == 2 then
    looper_sc_press(looper_sel_slot)
    return
  end
  local loop   = loops[slot]
  loop.last_press = util.time()
  if loop.state == "empty" then
    loop.state     = "recording"
    loop.notes     = {}
    loop.rec_mode  = mode
    recording_slot = slot
    record_start   = util.time()
  elseif loop.state == "recording" then
    loop.length    = util.time() - record_start
    recording_slot = nil
    if #loop.notes == 0 then
      looper_reset(slot)
    else
      looper_start_play(slot)
    end
  elseif loop.state == "playing" then
    if loop.clock_id then clock.cancel(loop.clock_id) end
    loop.clock_id = nil
    loop.state    = "stopped"
    -- 再生中だったノートをすべて即時オフ
    for _, ev in ipairs(loop.notes) do
      if ev.type == "on" then
        engine.noteOff(ev.note)
        if midiOut then midiOut:note_off(ev.note, 0, MIDI_OUT_CH) end
      end
    end
  elseif loop.state == "stopped" then
    looper_start_play(slot)
  end
  grid_redraw()
end
function looper_clear_all()
  if looper_mode == 2 then
    for i = 1, 2 do looper_sc_reset(i) end
  else
    for i = 1, 6 do looper_reset(i) end
  end
end
function looper_sc_reset(slot)
  if sc_stopping_clock[slot] then clock.cancel(sc_stopping_clock[slot]); sc_stopping_clock[slot] = nil end
  softcut.rec(slot, 0)
  softcut.play(slot, 0)
  loops[slot] = { state="empty", notes={}, length=0, clock_id=nil, last_press=0 }
  sc_loop_len[slot] = 0
  grid_redraw()
end
function looper_sc_press(slot)
  local loop   = loops[slot]
  local now    = util.time()
  loop.last_press = now
  local offset = SC_BUF_OFFSET[slot]
  if loop.state == "empty" then
    softcut.loop_start(slot, offset)
    softcut.loop_end(slot, offset + 30)
    softcut.position(slot, offset)
    softcut.rate(slot, 1.0)
    softcut.rec_level(slot, 1.0)
    softcut.pre_level(slot, 0.0)   -- 必ず0: 古いバッファを上書き
    softcut.level(slot, 0.0)       -- 録音中はミュート(古い音を聴かせない)
    softcut.play(slot, 1)
    softcut.rec(slot, 1)
    loop.state = "recording"
    sc_record_start[slot] = util.time()
  elseif loop.state == "recording" then
    loop.state = "stopping"
    sc_stopping_clock[slot] = clock.run(function()
      clock.sync(1)
      sc_loop_len[slot] = math.max(0.1, util.time() - sc_record_start[slot])
      softcut.rec(slot, 0)
      softcut.loop_end(slot, offset + sc_loop_len[slot])
      softcut.rate(slot, sc_dir[slot] * sc_speed[slot])
      softcut.level(slot, sc_level[slot])  -- 再生開始時にレベル復元
      loops[slot].state = "playing"
      density = 0
      sc_stopping_clock[slot] = nil
      grid_redraw()
    end)
  elseif loop.state == "stopping" then
    if sc_stopping_clock[slot] then clock.cancel(sc_stopping_clock[slot]); sc_stopping_clock[slot] = nil end
    sc_loop_len[slot] = math.max(0.1, util.time() - sc_record_start[slot])
    softcut.rec(slot, 0)
    softcut.loop_end(slot, offset + sc_loop_len[slot])
    softcut.rate(slot, sc_dir[slot] * sc_speed[slot])
    softcut.level(slot, sc_level[slot])  -- 再生開始時にレベル復元
    loop.state = "playing"
    density = 0
  elseif loop.state == "playing" then
    softcut.play(slot, 0); loop.state = "stopped"
  elseif loop.state == "stopped" then
    softcut.play(slot, 1); loop.state = "playing"
  end
  grid_redraw()
end
function show_overlay(text)
  display_text  = text
  display_timer = 45
end
function start_auto()
  if auto_clock then clock.cancel(auto_clock) end
  auto_clock = clock.run(function()
    while true do
      if mode == 1 and density > 0.005 then
        local scale    = SCALES[scale_idx].intervals
        local max_deg  = #scale * 2 - 1
        local degree
        if melody_mode == 1 then
          degree = math.random(0, max_deg)
        elseif melody_mode == 2 then
          local center = max_deg * 0.5
          local std    = max_deg * 0.45
          degree = math.floor(gauss_random(center, std) + 0.5)
          degree = util.clamp(degree, 0, max_deg)
        elseif melody_mode == 3 then
          degree = markov_next_degree(last_degree, max_deg)
          last_degree = degree
        elseif melody_mode == 4 then
          local scale_len = #SCALES[scale_idx].intervals
          local chord_tones = {}
          for oct = 0, 1 do
            for _, d in ipairs({0, 2, 4, 6}) do
              local cd = oct * scale_len + d
              if cd <= max_deg then table.insert(chord_tones, cd) end
            end
          end
          local nearest_ct = chord_tones[1]
          local min_dist = 999
          for _, ct in ipairs(chord_tones) do
            if math.abs(ct - last_degree) < min_dist then
              min_dist = math.abs(ct - last_degree)
              nearest_ct = ct
            end
          end
          local r = math.random()
          if r < 0.42 then
            degree = chord_tones[math.random(#chord_tones)]
          elseif r < 0.70 then
            local target = chord_tones[math.random(#chord_tones)]
            degree = util.clamp(target - 1, 0, max_deg)
          elseif r < 0.88 then
            local dir = nearest_ct >= last_degree and 1 or -1
            degree = util.clamp(last_degree + dir, 0, max_deg)
          else
            local jump = math.random() < 0.5 and 3 or 4
            degree = util.clamp(last_degree + (math.random()<0.5 and jump or -jump), 0, max_deg)
          end
          last_degree = degree
        elseif melody_mode == 5 then
          local MOTIF = {0, 2, 1, 3}
          degree = util.clamp(clas_phrase_root + MOTIF[clas_phrase_pos + 1], 0, max_deg)
          clas_phrase_pos = (clas_phrase_pos + 1) % 4
          if clas_phrase_pos == 0 then
            clas_phrase_root = clas_phrase_root + clas_dir
            if clas_phrase_root + 3 > max_deg or clas_phrase_root < 0 then
              clas_dir = -clas_dir
              clas_phrase_root = util.clamp(clas_phrase_root, 0, max_deg - 3)
            end
          end
          last_degree = degree
        end
        table.insert(degree_history, degree)
        while #degree_history > 24 do table.remove(degree_history, 1) end
        local note = get_scale_note(degree)
        if melody_mode == 1 and math.random() < 0.25 then
          note = math.min(127, note + 12)
        end
        local scale_len = #SCALES[scale_idx].intervals
        if math.random() < (1 - chance) then
          local chord = {note}
          if poly_mode == 1 then
            -- MONO: 単音のみ
          elseif poly_mode == 2 then
            local od = degree + scale_len
            if od <= max_deg then table.insert(chord, get_scale_note(od))
            else table.insert(chord, math.min(127, note + 12)) end
          elseif poly_mode == 3 then
            if degree + 4 <= max_deg then table.insert(chord, get_scale_note(degree + 4)) end
          elseif poly_mode == 4 then
            if degree + 2 <= max_deg then table.insert(chord, get_scale_note(degree + 2)) end
            if degree + 4 <= max_deg then table.insert(chord, get_scale_note(degree + 4)) end
          elseif poly_mode == 5 then
            if degree + 2 <= max_deg then table.insert(chord, get_scale_note(degree + 2)) end
            if degree + 4 <= max_deg then table.insert(chord, get_scale_note(degree + 4)) end
            if degree + 6 <= max_deg then table.insert(chord, get_scale_note(degree + 6)) end
          elseif poly_mode == 6 then
            local extra = math.random(1, 2)
            for _ = 1, extra do
              local rd = math.random(1, 5)
              if degree + rd <= max_deg then table.insert(chord, get_scale_note(degree + rd)) end
            end
          elseif poly_mode == 7 then
            if degree + 2 <= max_deg then table.insert(chord, get_scale_note(degree + 2)) end
            if degree + 3 <= max_deg then table.insert(chord, get_scale_note(degree + 3)) end
          elseif poly_mode == 8 then
            if degree + 2 <= max_deg then table.insert(chord, get_scale_note(degree + 2)) end
            if degree + 6 <= max_deg then table.insert(chord, get_scale_note(degree + 6)) end
          end
          play_chord(chord)
        end
      end
      local densityHz = density * density * 8
      local interval
      if densityHz < 0.005 then
        interval = 0.05
      else
        interval = -math.log(math.random()) / densityHz
        interval = math.max(0.03, math.min(interval, 5.0))
      end
      clock.sleep(interval)
    end
  end)
end
local AUTO_GRID_PARAMS = {
  [3] = { left="density",     right="bright"     },
  [4] = { left="chance",      right="saturation" },
  [5] = { left="attackShape", right="tapeAmt"    },
  [6] = { left="baseDecay",   right="dust"       },
  [7] = { left="fmAmt",       right="spread"     },
  [8] = { left="filter",      right="intone"     },
}
local function val_to_col(v) return math.max(1, math.min(8, math.floor(v * 7 + 0.5) + 1)) end
local function get_auto_val(id)
  if id == "density" then return density end
  if id == "chance"  then return chance  end
  return params:get(id)
end
local function set_auto_val(id, v)
  if     id == "density" then
    density = util.clamp(v, 0, 1)
  elseif id == "chance"  then chance  = util.clamp(v, 0, 1)
  else params:set(id, util.clamp(v, 0, 1)) end
end
function grid_redraw()
  if g.device == nil then return end
  g:all(0)
  if mode == 1 then
    for col = 1, 12 do
      g:led(col, 1, (root % 12 == (col - 1)) and 15 or 3)
    end
    g:led(15, 1, octave_shift > -3 and 4 or 1)
    g:led(16, 1, octave_shift < 3  and 4 or 1)
    for col = 1, math.min(#SCALES, 16) do
      g:led(col, 2, (scale_idx == col) and 15 or 3)
    end
    for row = 3, 8 do
      local p = AUTO_GRID_PARAMS[row]
      if p then
        if p.left then
          local lit_col = val_to_col(get_auto_val(p.left))
          for col = 1, 8 do
            local base = (col == 1) and 5 or 2
            g:led(col, row, col == lit_col and 15 or base)
          end
        end
        if p.right then
          local lit_col = math.max(1, math.min(7, math.floor(get_auto_val(p.right) * 6 + 0.5) + 1))
          for col = 9, 15 do
            local base = (col == 9) and 5 or 2
            g:led(col, row, (col - 8) == lit_col and 15 or base)
          end
        else
          g:led(9, row, 5)
        end
        if looper_mode == 2 then
          for tr = 1, 2 do
            local st = loops[tr].state
            local br = (st=="recording" or st=="stopping") and 15
                    or st=="playing"  and 7
                    or st=="stopped"  and (blink_on and 5 or 0)
                    or 1
            if looper_sel_slot == tr then br = math.max(br, 5) end
            g:led(16, tr + 2, br)
          end
          if row > 4 then g:led(16, row, 0) end
        else
          -- MIDIルーパー: 各行=スロット（行3→1 … 行8→6）を全表示
          local slot = row - 2
          local st = loops[slot].state
          local br = (st == "recording" or st == "stopping") and 15
                  or st == "playing"   and 7
                  or st == "stopped"   and (blink_on and 5 or 0)
                  or 1
          g:led(16, row, br)
        end
      end
    end
  else
    for col = 1, 12 do
      g:led(col, 1, (root % 12 == (col - 1)) and 15 or 3)
    end
    g:led(15, 1, octave_shift > -3 and 4 or 1)
    g:led(16, 1, octave_shift < 3  and 4 or 1)
    for col = 1, math.min(#SCALES, 16) do
      g:led(col, 2, (scale_idx == col) and 15 or 3)
    end
    for row = 3, 8 do
      for col = 1, 15 do
        local degree = grid_to_degree(row, col)
        local note   = get_scale_note(degree)
        g:led(col, row, grid_notes[note] and 15 or 2)
      end
    end
    if mode == 2 or mode == 3 then
      local max_slot = looper_mode == 2 and 2 or 6
      for slot = 1, max_slot do
        local st = loops[slot].state
        local br = (st == "recording" or st == "stopping") and 15
                or st == "playing"   and 7
                or st == "stopped"   and (blink_on and 5 or 0)
                or 1
        g:led(16, slot + 2, br)
      end
    end
  end
  g:refresh()
end
function build_param_list()
  local row1_left, row1_right
  if mode == 1 then
    row1_left  = { type="density" }
    row1_right = { type="chance"  }
  else
    row1_left  = { type="adsr_a" }
    row1_right = { type="adsr_d" }
  end
  local row1_3 = (mode == 1) and { type="control", id="attackShape", name="ATK" } or { type="adsr_s" }
  local row1_4 = (mode == 1) and { type="control", id="baseDecay",   name="DEC" } or { type="adsr_r" }
  local page0_top
  if looper_mode == 2 then
    page0_top = {
      { type="sc_rate"  },
      { type="looper"   },
      { type="sc_speed" },
      { type="sc_level" },
    }
  else
    page0_top = {
      { type="mode"   },
      { type="looper" },
      { type="root"   },
      { type="scale"  },
    }
  end
  all_params = {
    page0_top[1], page0_top[2], page0_top[3], page0_top[4],
    row1_left,
    row1_right,
    row1_3,
    row1_4,
    { type="control", id="fmAmt",       name="FM"     },
    { type="control", id="saturation",  name="SAT"    },
    { type="control", id="tapeAmt",     name="TAPE"   },
    { type="control", id="bright",      name="BRIT"   },
    { type="control", id="filter",      name="FILTER" },
    { type="control", id="dust",        name="DUST"   },
    { type="control", id="spread",      name="SPREAD" },
    { type="control", id="intone",      name="INTONE" },
  }
end
function init()
  params:add_separator("SPRE")
  params:add_number("mode_param",    "MODE",    1, 3,       1)
  params:add_number("root_param",    "ROOT",    48, 72,     60)
  params:add_number("scale_param",   "SCALE",   1, #SCALES, 1)
  params:add_number("density_param", "DENSITY", 0, 100,     30)
  params:add_control("sustain", "SUSTAIN",
    controlspec.new(0, 1, "lin", 0.001, 0.7, ""))
  params:set_action("sustain", function(v) engine.sustain(v) end)
  params:add_control("release", "RELEASE",
    controlspec.new(0, 1, "lin", 0.001, 0.3, ""))
  params:set_action("release", function(v) engine.release(v) end)
  for _, p in ipairs(PARAMS_DEF) do
    params:add_control(
      p.id, p.name,
      controlspec.new(0, 1, "lin", 0.001, p.def, "")
    )
    params:set_action(p.id, function(v)
      engine[p.id](v)
    end)
  end
  -- フィルタータイプ (E1でも変更可 / メニューからも選択・保存可)
  params:add_option("filter_type", "FILTER TYPE", FILTER_TYPES, 1)
  params:set_action("filter_type", function(v)
    filter_type = v
    engine.filterType(v - 1)
  end)
  params:bang()
  for _, dev in pairs(midi.devices) do
    if dev ~= nil then
      dev.event  = onMidi
      if midiDevice == nil then midiDevice = dev end
    end
  end
  midi.add = function(dev)
    if dev ~= nil then
      dev.event = onMidi
      if midiDevice == nil then midiDevice = dev end
    end
  end
  midiOut = midi.connect(1)
  -- amp poll（VUメーター用）
  local ap = poll.set("amp_out_l")
  ap.callback = function(v) amp_level = v end
  ap.time = 1/15
  ap:start()
  -- softcut初期化
  audio.level_eng_cut(1.0)
  softcut.buffer_clear()
  for v = 1, 2 do
    softcut.level_input_cut(1, v, 1.0)
    softcut.level_input_cut(2, v, 1.0)
    softcut.enable(v, 1)
    softcut.buffer(v, SC_BUF_NUM[v])
    softcut.level(v, 1.0)
    softcut.pan(v, 0.0)
    softcut.rate(v, 1.0)
    softcut.loop(v, 1)
    softcut.loop_start(v, SC_BUF_OFFSET[v])
    softcut.loop_end(v, SC_BUF_OFFSET[v] + 30)
    softcut.rec_level(v, 1.0)
    softcut.pre_level(v, 0.0)
    softcut.fade_time(v, 0.1)
    softcut.rec(v, 0)
    softcut.play(v, 1)
  end
  g.key = onGrid
  grid_redraw()
  build_param_list()
  start_auto()
  redraw_clock = clock.run(function()
    while true do
      clock.sleep(1/15)
      if display_timer > 0 then
        display_timer = display_timer - 1
      end
      blink_tick = blink_tick + 1
      if blink_tick >= 5 then
        blink_tick = 0
        blink_on = not blink_on
        grid_redraw()
      end
      redraw()
    end
  end)
end
function onMidi(data)
  local msg = midi.to_msg(data)
  if msg.type == "note_on" and msg.vel > 0 and mode == 2 then
    local q = quantize_to_scale(msg.note)
    midi_note_map[msg.note] = q
    play_note_adsr(q)
  end
  if (msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0)) and mode == 2 then
    local q = midi_note_map[msg.note] or msg.note
    midi_note_map[msg.note] = nil
    engine.noteOff(q)
    if midiOut then midiOut:note_off(q, 0, MIDI_OUT_CH) end
  end
  if msg.type == "cc" then
    local v   = msg.val / 127
    local val = msg.val
    -- CC 1-12: サウンドパラメーター (0-1)
    if     msg.cc == 1  then density = util.clamp(v, 0, 1)
    elseif msg.cc == 2  then chance  = util.clamp(v, 0, 1)
    elseif msg.cc == 3  then params:set("attackShape", v)
    elseif msg.cc == 4  then params:set("baseDecay",   v)
    elseif msg.cc == 5  then params:set("fmAmt",       v)
    elseif msg.cc == 6  then params:set("filter",      v)
    elseif msg.cc == 7  then params:set("bright",      v)
    elseif msg.cc == 8  then params:set("saturation",  v)
    elseif msg.cc == 9  then params:set("tapeAmt",     v)
    elseif msg.cc == 10 then params:set("dust",        v)
    elseif msg.cc == 11 then params:set("spread",      v)
    elseif msg.cc == 12 then params:set("intone",      v)
    -- CC 13-14: オクターブシフト (momentary, >63でトリガー)
    elseif msg.cc == 13 then
      if val > 63 then octave_shift = util.clamp(octave_shift - 1, -3, 3); grid_redraw() end
    elseif msg.cc == 14 then
      if val > 63 then octave_shift = util.clamp(octave_shift + 1, -3, 3); grid_redraw() end
    -- CC 15-16: ADSR サスティン / リリース
    elseif msg.cc == 15 then params:set("sustain", v)
    elseif msg.cc == 16 then params:set("release", v)
    -- CC 17: FILTER TYPE (0-127 → 1-4)
    elseif msg.cc == 17 then
      params:set("filter_type", util.clamp(math.floor(v * 4) + 1, 1, 4))
    -- CC 18: MODE (0-42=AUTO / 43-84=MIDI / 85-127=GRID)
    elseif msg.cc == 18 then
      local new_mode = math.floor(val / 128 * 3) + 1
      new_mode = util.clamp(new_mode, 1, 3)
      if new_mode ~= mode then
        local prev = mode
        mode = new_mode
        if prev == 3 and mode ~= 3 then looper_clear_all() end
        build_param_list(); grid_redraw()
      end
    -- CC 19: ROOT (0-127 → MIDI 48-72, C3〜C5)
    elseif msg.cc == 19 then
      root = math.floor(v * 24) + 48
      grid_redraw()
    -- CC 20: SCALE (0-127 → 1-21スケール)
    elseif msg.cc == 20 then
      scale_idx = util.clamp(math.floor(val / 128 * #SCALES) + 1, 1, #SCALES)
      grid_redraw()
    -- CC 21: OCT SHIFT (0-127 → −3〜+3, 7段階)
    elseif msg.cc == 21 then
      octave_shift = math.floor(v * 6 + 0.5) - 3
      grid_redraw()
    -- CC 22: MELODY MODE (0-127 → 1-5)
    elseif msg.cc == 22 then
      melody_mode = util.clamp(math.floor(val / 128 * 5) + 1, 1, 5)
    -- CC 23: LOOPER MODE (0-63=MIDIルーパー / 64-127=SCルーパー)
    elseif msg.cc == 23 then
      local new_lm = val < 64 and 1 or 2
      if new_lm ~= looper_mode then
        looper_mode = new_lm
        if looper_mode == 2 then looper_sel_slot = 1 end
        build_param_list(); grid_redraw()
      end
    -- CC 24-29: ループスロット 1-6 トリガー (>63でpress)
    elseif msg.cc >= 24 and msg.cc <= 29 then
      if val > 63 then
        local slot = msg.cc - 23
        local max_slot = looper_mode == 2 and 2 or 6
        if slot <= max_slot then
          if looper_mode == 2 then
            looper_sel_slot = slot
            looper_sc_press(slot)
          else
            looper_press(slot)
          end
        end
      end
    -- CC 30: SC SPEED (選択中スロット, 0-1 → x0.25〜x4.0)
    elseif msg.cc == 30 then
      local sl = looper_sel_slot
      sc_speed[sl] = v * (4.0 - 0.25) + 0.25
      softcut.rate(sl, sc_dir[sl] * sc_speed[sl])
    -- CC 31: SC LEVEL (選択中スロット, 0-1)
    elseif msg.cc == 31 then
      local sl = looper_sel_slot
      sc_level[sl] = v
      if loops[sl].state == "playing" or loops[sl].state == "stopped" then
        softcut.level(sl, sc_level[sl])
      end
    -- CC 32: SC OVDB / overdub pre_level (0-1)
    elseif msg.cc == 32 then
      sc_pre = v
      for sl = 1, 2 do softcut.pre_level(sl, sc_pre) end
    -- CC 33: SC DIR (0-63=REV / 64-127=FWD)
    elseif msg.cc == 33 then
      local sl = looper_sel_slot
      sc_dir[sl] = val < 64 and -1 or 1
      softcut.rate(sl, sc_dir[sl] * sc_speed[sl])
    end
  end
end
function onGrid(x, y, z)
  if mode == 1 then
    if z == 1 then
      if y == 1 then
        if x <= 12 then
          root = (math.floor(root / 12) * 12) + (x - 1)
        elseif x == 15 then
          octave_shift = util.clamp(octave_shift - 1, -3, 3)
        elseif x == 16 then
          octave_shift = util.clamp(octave_shift + 1, -3, 3)
        end
        grid_redraw()
      elseif y == 2 then
        if x <= #SCALES then
          scale_idx = x
          grid_redraw()
        end
      elseif y >= 3 and y <= 8 then
        local p = AUTO_GRID_PARAMS[y]
        if p then
          if x >= 1 and x <= 8 and p.left then
            set_auto_val(p.left, (x - 1) / 7)
            grid_redraw()
          elseif x == 16 then
            local slot     = y - 2
            local max_slot = looper_mode == 2 and 2 or 6
            if slot >= 1 and slot <= max_slot then
              local now = util.time()
              if (now - loops[slot].last_press) < DOUBLE_CLICK_T then
                if looper_mode == 2 then
                  looper_sc_reset(slot)
                else
                  looper_reset(slot)
                  grid_redraw()
                end
              else
                if looper_mode == 2 then
                  looper_sel_slot = slot
                  looper_sc_press(slot)
                else
                  looper_press(slot)
                end
              end
            end
          elseif x >= 9 and x <= 15 and p.right then
            set_auto_val(p.right, (x - 9) / 6)
            grid_redraw()
          end
        end
      end
    end
  else
    if y == 1 and z == 1 then
      if x <= 12 then
        root = (math.floor(root / 12) * 12) + (x - 1)
      elseif x == 15 then
        octave_shift = util.clamp(octave_shift - 1, -3, 3)
      elseif x == 16 then
        octave_shift = util.clamp(octave_shift + 1, -3, 3)
      end
      grid_redraw()
    elseif y == 2 and z == 1 and x <= #SCALES then
      scale_idx = x
      grid_redraw()
    elseif y >= 3 and y <= 8 then
      if (mode == 2 or mode == 3) and x == 16 then
        -- 列16 = ルーパーボタン (行3→スロット1 … 行8→スロット6)
        if z == 1 then
          local slot     = y - 2
          local max_slot = looper_mode == 2 and 2 or 6
          if slot <= max_slot then
            local now = util.time()
            if (now - loops[slot].last_press) < DOUBLE_CLICK_T then
              -- ダブルクリック: スロットをリセット
              if looper_mode == 2 then
                looper_sc_reset(slot)
              else
                looper_reset(slot)
                grid_redraw()
              end
            else
              if looper_mode == 2 then
                looper_sel_slot = slot
                looper_sc_press(slot)
              else
                looper_press(slot)
              end
            end
          end
        end
      else
        local degree = grid_to_degree(y, x)
        local note   = get_scale_note(degree)
        if z == 1 then
          grid_notes[note] = true
          if mode == 2 or mode == 3 then
            play_note_adsr(note)
            looper_capture(note)
          end
        else
          grid_notes[note] = nil
          if mode == 2 or mode == 3 then
            engine.noteOff(note)
            if midiOut then midiOut:note_off(note, 0, MIDI_OUT_CH) end
            looper_capture(note, "off")
          end
        end
        grid_redraw()
      end
    end
  end
end
function enc(n, delta)
  if n == 1 then
    if k1_held then
      screen_page = ((screen_page - 1 + (delta > 0 and 1 or -1)) % 3) + 1
    else
      -- E1: 選択中パラメータのタイプ変更（現状フィルターのみ）
      if screen_page == 1 then
        local p = all_params[sel_item + 1]
        if p and p.id == "filter" then
          local nv = util.clamp(filter_type + (delta > 0 and 1 or -1), 1, #FILTER_TYPES)
          if nv ~= filter_type then params:set("filter_type", nv) end
        end
      end
    end
    return
  end
  if screen_page == 2 then
    if n == 2 then
      mel_col = util.clamp(mel_col + (delta > 0 and 1 or -1), 0, 2)
    elseif n == 3 then
      if mel_col == 0 then
        melody_mode = util.clamp(melody_mode + (delta > 0 and 1 or -1), 1, #MELODY_NAMES)
        last_degree = 7
      elseif mel_col == 1 then
        poly_mode = util.clamp(poly_mode + (delta > 0 and 1 or -1), 1, #POLY_NAMES)
      else
        poly_spread = util.clamp(poly_spread + delta * 0.05, 0, 1)
      end
    end
    return
  end
  if screen_page == 3 then return end
  if n == 2 then
    sel_item = (sel_item + (delta > 0 and 1 or -1)) % 16
  elseif n == 3 then
    local p = all_params[sel_item + 1]
    if p == nil then return end
    if p.type == "mode" then
      local prev = mode
      mode = util.clamp(mode + (delta > 0 and 1 or -1), 1, #MODES)
      if prev == 3 and mode ~= 3 then looper_clear_all() end
      build_param_list()
      grid_redraw()
    elseif p.type == "gain" then
      master_level = util.clamp(master_level + delta * 0.02, 0, 1)
      engine.gain(master_level)
    elseif p.type == "looper" then
      if looper_mode == 1 then
        if delta > 0 then
          looper_mode = 2; looper_sel_slot = 1
          build_param_list(); grid_redraw()
        end
      else
        local new_slot = looper_sel_slot + (delta > 0 and 1 or -1)
        if new_slot < 1 then
          looper_mode = 1
          looper_sel_slot = 1
          build_param_list(); grid_redraw()
        else
          looper_sel_slot = util.clamp(new_slot, 1, 2)
        end
      end
    elseif p.type == "sc_rate" then
      local sl = looper_sel_slot
      sc_dir[sl] = delta > 0 and 1 or -1
      softcut.rate(sl, sc_dir[sl] * sc_speed[sl])
    elseif p.type == "sc_speed" then
      local sl = looper_sel_slot
      sc_speed[sl] = util.clamp(sc_speed[sl] + delta * 0.05, 0.25, 4.0)
      softcut.rate(sl, sc_dir[sl] * sc_speed[sl])
    elseif p.type == "sc_pre" then
      sc_pre = util.clamp(sc_pre + delta * 0.01, 0, 1)
      for v = 1, 2 do softcut.pre_level(v, sc_pre) end
    elseif p.type == "sc_level" then
      local sl = looper_sel_slot
      sc_level[sl] = util.clamp(sc_level[sl] + delta * 0.01, 0, 1)
      softcut.level(sl, sc_level[sl])
    elseif p.type == "root" then
      root = util.clamp(root + (delta > 0 and 1 or -1), 36, 84)
      grid_redraw()
    elseif p.type == "scale" then
      scale_idx = util.clamp(scale_idx + (delta > 0 and 1 or -1), 1, #SCALES)
      grid_redraw()
    elseif p.type == "density" then
      density = util.clamp(density + delta * 0.01, 0, 1)
    elseif p.type == "chance" then
      chance = util.clamp(chance + delta * 0.01, 0, 1)
    elseif p.type == "adsr_a" then
      params:set("attackShape", util.clamp(params:get("attackShape") + delta * 0.01, 0, 1))
    elseif p.type == "adsr_d" then
      params:set("baseDecay",   util.clamp(params:get("baseDecay")   + delta * 0.01, 0, 1))
    elseif p.type == "adsr_s" then
      params:set("sustain",     util.clamp(params:get("sustain")     + delta * 0.01, 0, 1))
    elseif p.type == "adsr_r" then
      params:set("release",     util.clamp(params:get("release")     + delta * 0.01, 0, 1))
    elseif p.type == "control" then
      local cur = params:get(p.id)
      params:set(p.id, util.clamp(cur + delta * 0.01, 0, 1))
    end
  end
end
function key(n, z)
  if n == 1 then k1_held = (z == 1) end
  if n == 2 then k2_held = (z == 1) end
  if z == 1 then
    if k1_held and n == 2 then
      octave_shift = util.clamp(octave_shift - 1, -3, 3)
    elseif k1_held and n == 3 then
      octave_shift = util.clamp(octave_shift + 1, -3, 3)
    elseif k2_held and n == 3 then
      if looper_mode == 2 then
        looper_sc_reset(looper_sel_slot)
      else
        looper_reset(1)
        grid_redraw()
      end
    elseif not k1_held and not k2_held and n == 3 then
      if screen_page == 1 then screen_page = 2
      elseif screen_page == 2 then screen_page = 1 end
    elseif not k1_held and n == 2 then
      if screen_page == 1 then
        local p = all_params[sel_item + 1]
        if p and p.type == "looper" then
          looper_press(1)
        else
          sel_item = (sel_item + 4) % 16
        end
      elseif screen_page == 2 then
        mel_col = (mel_col + 1) % 3
      end
    end
  end
end
function redraw()
  if splash_active then draw_splash(); return end
  if mode == 1 then
    wave_phase = (wave_phase + 0.07) % (math.pi * 2)
  elseif wave_anim > 0 then
    wave_phase = (wave_phase + 0.07) % (math.pi * 2)
    wave_anim  = math.max(0, wave_anim - 0.02)
  end
  local alive_birds = {}
  for _, b in ipairs(note_birds) do
    b.x = b.x + b.speed
    if b.x < 38 then table.insert(alive_birds, b) end
  end
  note_birds = alive_birds
  screen.clear()
  if screen_page ~= 3 then
    -- ヘッダ（SPRE / MODE / TYPE / OCT を font8 で統一）
    screen.font_size(8)
    screen.level(10)
    screen.move(2, 8)
    screen.text("SPRE")
    screen.level(15)
    screen.move(64, 8)
    screen.text_center(MODES[mode])
    -- オクターブ表示（右端）
    local oct_str = (octave_shift >= 0 and "+" or "") .. octave_shift
    screen.level(octave_shift == 0 and 7 or 15)
    screen.move(127, 8)
    screen.text_right(oct_str)
    -- 選択中パラメータのタイプ表示（E1で変更）
    local ptype_str = ""
    if screen_page == 1 then
      local psel = all_params[sel_item + 1]
      if psel and psel.id == "filter" then
        ptype_str = FILTER_TYPES[filter_type]
      end
    end
    if ptype_str ~= "" then
      screen.level(15)
      screen.move(108, 8); screen.text_right(ptype_str)
    end
    screen.font_size(7)
    screen.level(3)
    screen.move(0, 10)
    screen.line(128, 10)
    screen.stroke()
  end
  if display_timer > 0 then
    screen.level(0)
    screen.rect(0, 11, 128, 40)
    screen.fill()
    screen.level(15)
    screen.font_size(16)
    screen.move(64, 38)
    screen.text_center(display_text)
    screen.font_size(7)
    screen.update()
    return
  end
  -- ===== MELODYページ（3カラム: MEL / POLY / STRUM）=====
  if screen_page == 2 then
    local max_deg = #SCALES[scale_idx].intervals * 2 - 1
    local cxs   = {21, 64, 106}
    local heads = {"MEL", "POLY", "STRUM"}
    local icy   = 36
    local lbl_y = 54
    local BOX_Y, BOX_H = 22, 34
    local box_x = {1, 44, 87}
    local box_w = {41, 41, 40}
    -- 区切り線
    screen.level(3)
    screen.move(43, 11); screen.line(43, 63); screen.stroke()
    screen.move(85, 11); screen.line(85, 63); screen.stroke()
    -- 選択カラムのボックス反転
    screen.level(15)
    screen.rect(box_x[mel_col+1], BOX_Y, box_w[mel_col+1], BOX_H); screen.fill()
    -- ヘッダ
    screen.font_size(7)
    for c = 0, 2 do
      local sel = (mel_col == c)
      screen.level(sel and 15 or 5)
      screen.move(cxs[c+1], 19); screen.text_center(heads[c+1])
      if sel then
        local hw = #heads[c+1] * 3
        screen.move(cxs[c+1]-hw, 20); screen.line(cxs[c+1]+hw, 20); screen.stroke()
      end
    end
    -- --- カラム0: MELODY ---
    local icx = cxs[1]
    local inv = (mel_col == 0)
    screen.level(inv and 0 or 12)
    if melody_mode == 1 then
      local pts = {{-10,-5},{5,-10},{11,3},{-3,9},{9,-3},{-9,5},{1,11},{-5,-10}}
      for _, p in ipairs(pts) do
        screen.move(icx+p[1]+1, icy+p[2]); screen.circle(icx+p[1], icy+p[2], 1); screen.fill()
      end
    elseif melody_mode == 2 then
      screen.move(icx-13, icy+10)
      for xi = -13, 13 do
        screen.line(icx+xi, icy+10-math.floor(math.exp(-(xi*xi)/25)*13))
      end
      screen.stroke()
      screen.move(icx-13, icy+10); screen.line(icx+13, icy+10); screen.stroke()
    elseif melody_mode == 3 then
      local pts = {{-12,7},{-6,-5},{0,3},{8,-9},{14,5}}
      for j = 1, #pts-1 do
        screen.move(icx+pts[j][1], icy+pts[j][2])
        screen.line(icx+pts[j+1][1], icy+pts[j+1][2]); screen.stroke()
      end
      for _, p in ipairs(pts) do
        screen.move(icx+p[1]+2, icy+p[2]); screen.circle(icx+p[1], icy+p[2], 2); screen.fill()
      end
    elseif melody_mode == 4 then
      screen.move(icx+11, icy); screen.circle(icx, icy, 11); screen.stroke()
      for j = 0, 3 do
        local a  = j/4*math.pi*2 - math.pi/2
        local px = icx+math.floor(math.cos(a)*11)
        local py = icy+math.floor(math.sin(a)*11)
        screen.move(px+2, py); screen.circle(px, py, 2); screen.fill()
      end
      screen.move(icx+2, icy); screen.circle(icx, icy, 2); screen.fill()
    elseif melody_mode == 5 then
      screen.move(icx-12, icy+9)
      screen.line(icx-6, icy+9); screen.line(icx-6, icy+3)
      screen.line(icx,   icy+3); screen.line(icx,   icy-3)
      screen.line(icx+6, icy-3); screen.line(icx+6, icy-9); screen.line(icx+12, icy-9)
      screen.stroke()
    end
    screen.level(inv and 0 or 10)
    screen.move(cxs[1], lbl_y); screen.text_center(MELODY_NAMES[melody_mode])
    -- --- カラム1: POLY ---
    icx = cxs[2]
    inv = (mel_col == 1)
    screen.level(inv and 0 or 12)
    if poly_mode == 1 then
      screen.move(icx-13, icy); screen.line(icx+13, icy); screen.stroke()
      screen.move(icx+3, icy); screen.circle(icx, icy, 3); screen.fill()
    elseif poly_mode == 2 then
      for j = -1, 1, 2 do
        local ly = icy + j*7
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        screen.move(icx+3, ly); screen.circle(icx, ly, 2); screen.fill()
      end
    elseif poly_mode == 3 then
      for j = -1, 1, 2 do
        local ly = icy + j*4
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        screen.move(icx+j*3+2, ly); screen.circle(icx+j*3, ly, 2); screen.fill()
      end
    elseif poly_mode == 4 then
      for j = -1, 0, 1 do
        local ly = icy + j*6
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        screen.move(icx+j*4+2, ly); screen.circle(icx+j*4, ly, 2); screen.fill()
      end
    elseif poly_mode == 5 then
      for j = 0, 3 do
        local ly = icy - 9 + j*6
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        screen.move(icx+3, ly); screen.circle(icx, ly, 2); screen.fill()
      end
    elseif poly_mode == 6 then
      local rys = {icy-8, icy-2, icy+5}
      local rxs = {icx-6, icx+3, icx-2}
      for i = 1, 3 do
        screen.move(icx-13, rys[i]); screen.line(icx+13, rys[i]); screen.stroke()
        screen.move(rxs[i]+3, rys[i]); screen.circle(rxs[i], rys[i], 2); screen.fill()
      end
    elseif poly_mode == 7 then
      for j, off in ipairs({-5, 0, 4}) do
        local ly = icy + off
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        screen.move(icx+3, ly); screen.circle(icx, ly, 2); screen.fill()
      end
    elseif poly_mode == 8 then
      for j, off in ipairs({-7, 0, 7}) do
        local ly = icy + off
        screen.move(icx-13, ly); screen.line(icx+13, ly); screen.stroke()
        local nx = icx + (j==2 and 0 or j*4)
        screen.move(nx+2, ly); screen.circle(nx, ly, 2); screen.fill()
      end
    end
    screen.level(inv and 0 or 10)
    screen.move(cxs[2], lbl_y); screen.text_center(POLY_NAMES[poly_mode])
    -- --- カラム2: STRUM（和音の発音タイミングの散らし）---
    icx = cxs[3]
    inv = (mel_col == 2)
    screen.level(inv and 0 or 12)
    screen.move(icx-14, icy+9); screen.line(icx+14, icy+9); screen.stroke()  -- 基準線
    do
      local ntick = 4
      for k = 0, ntick-1 do
        local off = math.floor((k - (ntick-1)/2) * poly_spread * 9)   -- 時間方向の散らし
        local yy  = icy + 6 - k * 4                                    -- 音を段々に
        screen.move(icx+off, icy+9); screen.line(icx+off, yy); screen.stroke() -- ステム
        screen.move(icx+off+2, yy); screen.circle(icx+off, yy, 1.5); screen.fill() -- 音符
      end
    end
    screen.level(inv and 0 or 10)
    screen.move(cxs[3], lbl_y); screen.text_center(string.format("%d", math.floor(poly_spread*99)))
    -- 履歴スパークライン
    if #degree_history > 1 then
      for hi, dg in ipairs(degree_history) do
        local dx = math.floor((hi-1)/(#degree_history-1)*124)+2
        local dy = 62 - math.floor(dg/math.max(1,max_deg)*5)
        screen.level(math.floor(hi/#degree_history*8+2))
        screen.pixel(dx, dy); screen.fill()
      end
    end
    screen.update()
    return
  end
  -- ===== ビューワーページ（MOTHER3風・雨の路地裏）=====
  if screen_page == 3 then
    viewer_t = viewer_t + 1
    local t  = viewer_t
    local bx = 62
    local floor_y = 52

    -- 楕円の水たまり
    local function puddle(px, py, rw, rh, lv)
      screen.level(lv)
      for dx = -rw, rw do
        local h = math.floor(math.sqrt(math.max(0, 1 - (dx/rw)^2)) * rh)
        if h > 0 then screen.rect(px + dx, py - h, 1, h * 2 + 1); screen.fill() end
      end
    end

    -- 路地の抜け（空）と遠くの町並み
    screen.level(1); screen.rect(44, 4, 40, 30); screen.fill()
    screen.level(3)
    screen.rect(48, 22, 10, 9); screen.fill()
    screen.rect(60, 17, 15, 14); screen.fill()
    screen.rect(76, 24, 7, 7); screen.fill()
    screen.level(2)
    screen.move(48,22); screen.line(53,18); screen.line(58,22); screen.fill()
    screen.move(60,17); screen.line(67,12); screen.line(75,17); screen.fill()

    -- 左右のビル
    screen.level(3)
    screen.rect(0,  0, 44, 40); screen.fill()
    screen.rect(84, 0, 44, 40); screen.fill()
    screen.level(0)
    screen.move(44,0); screen.line(44,14); screen.line(30,0); screen.fill()
    screen.move(84,0); screen.line(84,14); screen.line(98,0); screen.fill()
    screen.level(2)
    for by = 6, 38, 5 do
      screen.move(0, by); screen.line(42, by); screen.stroke()
      screen.move(86, by); screen.line(127, by); screen.stroke()
    end
    screen.level(6)
    screen.move(43, 6); screen.line(43, 40); screen.stroke()
    screen.move(84, 6); screen.line(84, 40); screen.stroke()
    screen.level(1); screen.rect(8, 16, 8, 9); screen.fill()
    screen.level(5); screen.rect(8, 16, 8, 1); screen.fill()
    screen.level(1); screen.rect(112, 30, 9, 8); screen.fill()

    -- 街灯（右壁）＋グロー
    local lx, ly = 98, 22
    screen.level(2); screen.move(lx+7, ly); screen.circle(lx, ly, 7); screen.fill()
    screen.level(5); screen.move(lx+4, ly); screen.circle(lx, ly, 4); screen.fill()
    screen.level(9); screen.move(lx+2, ly); screen.circle(lx, ly, 2); screen.fill()
    screen.level(15); screen.rect(lx-1, ly-1, 2, 2); screen.fill()
    screen.level(6)
    screen.move(lx, ly-6); screen.line(lx, ly-9); screen.stroke()
    screen.move(lx, ly-9); screen.line(lx+9, ly-9); screen.stroke()
    screen.move(lx+9, ly-9); screen.line(lx+9, ly-6); screen.stroke()

    -- 濡れた地面
    screen.level(2); screen.rect(0, 38, 128, 26); screen.fill()
    puddle(60, 60, 20, 3, 4)
    puddle(30, 55, 10, 2, 4)
    puddle(100, 61, 13, 3, 4)
    puddle(bx, floor_y + 2, 12, 2, 3)
    -- 波紋
    local rings = {{60,60,0},{30,55,15},{100,61,29}}
    for _, r in ipairs(rings) do
      local ph = (t + r[3]) % 44
      if ph < 12 then
        screen.level(math.max(2, 6 - math.floor(ph/3)))
        local rr = 2 + math.floor(ph * 0.6)
        screen.move(r[1]+rr, r[2]); screen.circle(r[1], r[2], rr); screen.stroke()
      end
    end

    -- 小物: 樽（左手前）とタイヤ（右手前）
    screen.level(4); screen.rect(6, 50, 16, 12); screen.stroke()
    screen.move(6,50); screen.line(22,62); screen.stroke()
    screen.move(22,50); screen.line(6,62); screen.stroke()
    screen.level(3)
    screen.move(114,60); screen.circle(108,60,6); screen.stroke()
    screen.move(111,60); screen.circle(108,60,3); screen.stroke()

    -- 雨（少年の背後）
    for i = 0, 44 do
      local rx = (i * 37 + math.floor(t * 6)) % 140 - 6
      local ry = (i * 53 + math.floor(t * 9)) % 60
      screen.level((i % 4 == 0) and 8 or 4)
      screen.move(rx, ry); screen.line(rx - 2, ry + 5); screen.stroke()
    end

    -- 少年（後ろ姿・傘）。たまに足を動かす
    if boy_shuffle <= 0 and math.random() < 0.015 then boy_shuffle = 12 end
    if boy_shuffle > 0 then boy_shuffle = boy_shuffle - 1 end
    local step = (boy_shuffle > 0) and math.floor(math.sin(t * 0.8) * 1.5 + 0.5) or 0

    screen.level(5)
    screen.rect(bx - 3 - step, 46, 2, 5); screen.fill()
    screen.rect(bx + 1 + step, 46, 2, 5); screen.fill()
    screen.level(7)
    screen.rect(bx - 4 - step, 50, 3, 2); screen.fill()
    screen.rect(bx + 1 + step, 50, 3, 2); screen.fill()
    -- ボーダーシャツ
    for sy = 0, 7 do
      screen.level((sy % 2 == 0) and 11 or 4)
      screen.rect(bx - 4, 38 + sy, 9, 1); screen.fill()
    end
    -- 傘（後ろ＆上から: 楕円ドーム＋放射状の骨）
    local ucx, ucy, urx, ury = bx, 32, 14, 7
    local up = {}
    for k = 0, 8 do
      local a = k / 8 * math.pi * 2
      up[k+1] = { ucx + math.cos(a) * urx, ucy + math.sin(a) * ury }
    end
    screen.level(6)
    screen.move(up[1][1], up[1][2])
    for k = 2, 9 do screen.line(up[k][1], up[k][2]) end
    screen.fill()
    screen.level(3)
    for k = 1, 8 do
      screen.move(ucx, ucy); screen.line(up[k][1], up[k][2]); screen.stroke()
    end
    screen.level(10)
    screen.move(up[1][1], up[1][2])
    for k = 2, 9 do screen.line(up[k][1], up[k][2]) end
    screen.stroke()
    screen.move(ucx, ucy - ury); screen.line(ucx, ucy - ury - 3); screen.stroke()

    screen.update()
    return
  end
  -- ===== パラメータページ =====
  local COLS = {16, 48, 80, 112}
  local ROWS = {20, 45}
  local CR   = 9
  local function pval(p)
    if p.type == "mode"    then return (mode-1)/2,            MODES[mode]
    elseif p.type == "gain"   then return master_level,       string.format("%d", math.floor(master_level*99))
    elseif p.type == "looper" then return (looper_sel_slot-1)/5, tostring(looper_sel_slot)
    elseif p.type == "root"   then return (root-36)/(84-36), root_name(root)
    elseif p.type == "scale"  then
      local sn = SCALES[scale_idx].name
      return (scale_idx-1)/(#SCALES-1), (#sn>5 and sn:sub(1,5) or sn)
    elseif p.type == "density" then return density,                    string.format("%d", math.floor(density*99))
    elseif p.type == "chance"  then return chance,                     string.format("%d", math.floor(chance*99))
    elseif p.type == "sustain" then return params:get("sustain"), string.format("%d", math.floor(params:get("sustain")*99))
    elseif p.type == "release" then return params:get("release"), string.format("%d", math.floor(params:get("release")*99))
    elseif p.type == "adsr_a"  then return params:get("attackShape"), string.format("%d", math.floor(params:get("attackShape")*99))
    elseif p.type == "adsr_d"  then return params:get("baseDecay"),   string.format("%d", math.floor(params:get("baseDecay")*99))
    elseif p.type == "adsr_s"  then return params:get("sustain"),     string.format("%d", math.floor(params:get("sustain")*99))
    elseif p.type == "adsr_r"  then return params:get("release"),     string.format("%d", math.floor(params:get("release")*99))
    elseif p.type == "sc_rate"  then local sl=looper_sel_slot; return sc_dir[sl] > 0 and 1 or 0, sc_dir[sl] > 0 and "FWD" or "REV"
    elseif p.type == "sc_speed" then local sl=looper_sel_slot; return (sc_speed[sl] - 0.25) / (4.0 - 0.25), string.format("x%.2f", sc_speed[sl])
    elseif p.type == "sc_pre"   then return sc_pre,                    string.format("%d",   math.floor(sc_pre  * 99))
    elseif p.type == "sc_level" then local sl=looper_sel_slot; return sc_level[sl],            string.format("%d",   math.floor(sc_level[sl]* 99))
    else
      local v = params:get(p.id)
      return v, string.format("%d", math.floor(v*99))
    end
  end
  local function draw_opz_knob(cx, cy, val, val_str, lbl, is_sel)
    screen.level(is_sel and 15 or 4)
    screen.move(cx + CR, cy)
    screen.circle(cx, cy, CR); screen.stroke()
    local a_start = math.pi * 0.75
    if val > 0.01 then
      local a_val = a_start + val * math.pi * 2
      screen.level(is_sel and 15 or 11)
      screen.move(cx + (CR-2)*math.cos(a_start), cy + (CR-2)*math.sin(a_start))
      screen.arc(cx, cy, CR-2, a_start, a_val)
      screen.line(cx, cy)
      screen.fill()
    end
    if is_sel then
      screen.level(15)
      screen.move(cx + CR, cy)
      screen.circle(cx, cy, CR); screen.stroke()
    end
    local lw = #lbl * 5 + 4
    local bx = cx - lw/2
    local mbx = cx - 9  -- fixed 19px bar, centered
    -- bar (always same style)
    screen.level(2); screen.rect(mbx, cy+CR+1, 19, 1); screen.fill()
    local bw = math.floor(val * 19)
    if bw > 0 then screen.level(10); screen.rect(mbx, cy+CR+1, bw, 1); screen.fill() end
    -- text highlight (text area only)
    if is_sel then
      screen.level(15); screen.rect(bx, cy+CR+2, lw, 7); screen.fill()
      screen.level(0)
    else
      screen.level(6)
    end
    screen.font_size(7)
    screen.move(cx, cy + CR + 8); screen.text_center(lbl)
  end
  local function draw_env_box(ax, ay, dx, val_atk, val_dec, sel_atk, sel_dec)
    local x0  = ax - CR
    local x1  = dx + CR
    local y0  = ay - CR
    local W   = x1 - x0
    local IH  = CR * 2
    local atk_frac = math.max(0.12, math.min(0.50, val_atk))
    local mid = x0 + math.floor(W * atk_frac)
    local atk_w = mid - x0
    local dec_w = x1 - mid
    screen.level(2); screen.rect(x0, y0, W, IH); screen.stroke()
    screen.level(3)
    screen.move(mid, y0); screen.line(mid, y0 + IH); screen.stroke()
    if sel_atk then screen.level(4); screen.rect(x0, y0, atk_w, IH); screen.fill() end
    if sel_dec then screen.level(4); screen.rect(mid, y0, dec_w, IH); screen.fill() end
    screen.level((sel_atk or sel_dec) and 15 or 10)
    screen.move(x0+1, y0+IH-2)
    local atk_exp = 0.15 + val_atk * 1.35
    for xi = 1, atk_w - 1 do
      local t  = xi / atk_w
      local yy = y0+IH-2 - math.floor(t^atk_exp * (IH-4))
      screen.line(x0+xi, yy)
    end
    local dec_exp = 8 - val_dec * 7.7
    for xi = 1, dec_w - 1 do
      local t  = xi / dec_w
      local yy = y0+2 + math.floor((1-(1-t)^dec_exp) * (IH-4))
      screen.line(mid+xi, yy)
    end
    screen.stroke()
    screen.font_size(7)
    if sel_atk then screen.level(15); screen.rect(x0+atk_w/2-8, ay+CR, 16, 8); screen.fill(); screen.level(0)
    else screen.level(5) end
    screen.move(x0 + atk_w / 2, ay + CR + 6); screen.text_center("ATK")
    if sel_dec then screen.level(15); screen.rect(mid+dec_w/2-8, ay+CR, 16, 8); screen.fill(); screen.level(0)
    else screen.level(5) end
    screen.move(mid + dec_w / 2, ay + CR + 6); screen.text_center("DEC")
  end
  local function draw_waveform_group(yc, sel_sub)
    local fm    = params:get("fmAmt")
    local sat   = params:get("saturation")
    local tape  = params:get("tapeAmt")
    local bri   = params:get("bright")
    local amp   = CR - 1
    local W     = 124
    local x0    = 2
    local anim = mode == 1 and 1.0 or wave_anim
    for xi = 0, W-1 do
      local t     = xi / W
      local phase = t * math.pi * 6 + wave_phase * anim
      local y     = math.sin(phase)
      local fm_mod = math.sin(phase * 3.0 + math.sin(phase * 1.2) * fm * 6) * fm * 1.8
      y = y + fm_mod
      local peak = 1 + fm * 1.8
      y = y / peak
      if sat > 0.01 then
        local drive = 1 + sat * 14
        y = math.tanh(y * drive) / math.tanh(drive * 0.6)
      end
      local lv  = math.max(2, math.floor(bri * 13 + 2))
      local amp_scaled = amp * (0.05 + bri * 0.95)
      if tape > 0.01 then
        local noise = math.sin(xi * 6.7) * math.sin(xi * 2.3 + 0.9)
                    + math.sin(xi * 11.3 + 0.4) * 0.4
        y = y + noise * tape * 0.7
        local py2 = yc - math.floor(y * amp_scaled * 0.8) + 2
        py2 = math.max(yc-amp, math.min(yc+amp, py2))
        screen.level(math.floor(tape * 9 + 1))
        screen.pixel(x0+xi, py2); screen.fill()
      end
      local py = yc - math.floor(y * amp_scaled)
      py = math.max(yc-amp, math.min(yc+amp, math.floor(py)))
      screen.level(lv)
      screen.pixel(x0+xi, py); screen.fill()
    end
    local sublbls = {"FM","SAT","TAPE","BRIT"}
    local subids  = {"fmAmt","saturation","tapeAmt","bright"}
    local subx    = {16, 48, 80, 112}
    for si = 0, 3 do
      local ssl  = (sel_sub == si)
      local sw   = #sublbls[si+1] * 5 + 4
      local sbx  = subx[si+1] - sw/2
      local smbx = subx[si+1] - 9  -- fixed 19px bar, centered
      local sv   = params:get(subids[si+1])
      screen.font_size(7)
      -- bar (always same style)
      screen.level(2); screen.rect(smbx, yc+CR+1, 19, 1); screen.fill()
      local bw = math.floor(sv * 19)
      if bw > 0 then screen.level(10); screen.rect(smbx, yc+CR+1, bw, 1); screen.fill() end
      -- text highlight (text area only)
      if ssl then
        screen.level(15); screen.rect(sbx, yc+CR+2, sw, 7); screen.fill()
        screen.level(0)
      else
        screen.level(4)
      end
      screen.move(subx[si+1], yc + CR + 8)
      screen.text_center(sublbls[si+1])
    end
  end
  local cur_page   = math.floor(sel_item / 8)
  local page_start = cur_page * 8
  local skip_count = 0
  screen.font_size(7)
  for i = 0, 7 do
    if skip_count > 0 then skip_count = skip_count - 1 goto continue end
    local p = all_params[page_start + i + 1]
    if p then
      local row = math.floor(i / 4)
      local col = i % 4
      local cx  = COLS[col+1]
      local cy  = ROWS[row+1]
      local is_sel = sel_item == page_start + i
      if p.id == "fmAmt" and row == 0 then
        local p2 = all_params[page_start+i+2]
        local p3 = all_params[page_start+i+3]
        local p4 = all_params[page_start+i+4]
        if p2 and p2.id=="saturation" and p3 and p3.id=="tapeAmt" and p4 and p4.id=="bright" then
          local sel_sub = sel_item - (page_start+i)
          if sel_sub < 0 or sel_sub > 3 then sel_sub = -1 end
          draw_waveform_group(cy, sel_sub)
          skip_count = 3
          goto continue
        end
      end
      if p.id == "attackShape" then
        local pn = all_params[page_start + i + 2]
        if pn and pn.id == "baseDecay" and col < 3 then
          local dx = COLS[col+2]
          local va = pval(p)
          local vd = pval(pn)
          draw_env_box(cx, cy, dx, va, vd,
            sel_item==page_start+i, sel_item==page_start+i+1)
          skip_count = 1
          goto continue
        end
      end
      local val, vs = pval(p)
      local lbl
      if p.type=="mode"     then lbl="MODE"
      elseif p.type=="gain"    then lbl="GAIN"
      elseif p.type=="looper"  then lbl="LOOP"
      elseif p.type=="root"    then lbl="ROOT"
      elseif p.type=="scale"   then lbl="SCAL"
      elseif p.type=="density" then lbl="FLOCK"
      elseif p.type=="chance"  then lbl="RAIN"
      elseif p.type=="sc_rate"  then lbl="DIR"
      elseif p.type=="sc_speed" then lbl="SPEED"
      elseif p.type=="sc_pre"   then lbl="OVDB"
      elseif p.type=="sc_level" then lbl="LEVL"
      else lbl = p.name end
      if p.type == "mode" or p.type == "root" or p.type == "scale" then
        local lw = #lbl * 5 + 4
        screen.font_size(7)
        if is_sel then screen.level(15); screen.rect(cx-lw/2, cy-8, lw, 8); screen.fill(); screen.level(0)
        else screen.level(4) end
        screen.move(cx, cy-3); screen.text_center(lbl)
        screen.level(is_sel and 15 or 12)
        screen.font_size(7)
        screen.move(cx, cy+7); screen.text_center(vs)
        goto continue
      end
      if p.id == "dust" then
        local y_top = cy - CR + 1
        local y_bot = cy + CR - 1
        local n_seg = 7
        local seg_h = (y_bot - y_top) / n_seg
        local lv    = math.min(15, math.floor(4 + val * 11) + (is_sel and 2 or 0))
        screen.level(lv)
        screen.move(cx, y_top)
        local pts = {}
        for i2 = 1, n_seg do
          local y2     = math.floor(y_top + i2 * seg_h)
          local base2  = (i2 % 2 == 0) and -5 or 5
          local wiggle = math.floor(math.sin(wave_phase * 2.5 + i2 * 1.8) * val * 5)
          local x2     = math.max(cx-CR+2, math.min(cx+CR-2, cx + base2 + wiggle))
          pts[i2]      = {x=x2, y=y2}
          screen.line(x2, y2)
        end
        screen.stroke()
        if val > 0.5 then
          local bi  = 3
          local bx2  = pts[bi].x
          local by2  = pts[bi].y
          local bex = math.max(cx-CR+2, math.min(cx+CR-2,
                        bx2 + math.floor((val-0.5)*2 * 7 * (math.sin(wave_phase*1.7)>0 and 1 or -1))))
          local bey = math.floor(by2 + seg_h * 2.5)
          screen.level(math.max(2, math.floor(lv * 0.55)))
          screen.move(bx2, by2); screen.line(bex, bey); screen.stroke()
        end
        local lbl_w = #lbl * 5 + 4
        local bx_d = cx - lbl_w/2
        local mbx_d = cx - 9  -- fixed 19px bar, centered
        -- bar (always same style)
        screen.level(2); screen.rect(mbx_d, cy+CR+1, 19, 1); screen.fill()
        local bw = math.floor(val * 19)
        if bw > 0 then screen.level(10); screen.rect(mbx_d, cy+CR+1, bw, 1); screen.fill() end
        -- text highlight (text area only)
        if is_sel then
          screen.level(15); screen.rect(bx_d, cy+CR+2, lbl_w, 7); screen.fill()
          screen.level(0)
        else
          screen.level(5)
        end
        screen.font_size(7)
        screen.move(cx, cy + CR + 8); screen.text_center(lbl)
        goto continue
      end
      if p.type == "adsr_a" then
        local pn = all_params[page_start + i + 4]
        if pn and pn.type == "adsr_r" and col < 3 then
          local atk_v = params:get("attackShape")
          local dec_v = params:get("baseDecay")
          local sus_v = params:get("sustain")
          local rel_v = params:get("release")
          local sel_a = sel_item == page_start + i
          local sel_d = sel_item == page_start + i + 1
          local sel_s = sel_item == page_start + i + 2
          local sel_r = sel_item == page_start + i + 3
          local fx0 = COLS[1] - CR
          local fx1 = COLS[4] + CR
          local FW  = fx1 - fx0
          local fy0 = cy - CR
          local FH  = CR * 2
          -- 各セグメントを「見た目上の時間」で比率割り当て
          -- SUSだけ係数を圧縮して視覚的に小さく
          local a_dur  = atk_v + 0.10
          local d_dur  = dec_v + 0.10
          local s_dur  = sus_v * 0.28 + 0.08
          local r_dur  = rel_v + 0.10
          local total  = a_dur + d_dur + s_dur + r_dur
          local usable = FW - 2
          local aw = math.max(4, math.floor(a_dur / total * usable))
          local dw = math.max(4, math.floor(d_dur / total * usable))
          local rw = math.max(4, math.floor(r_dur / total * usable))
          local sw = math.max(4, usable - aw - dw - rw)
          local peak_y = fy0 + 2
          local bot_y  = fy0 + FH - 2
          local sus_y  = bot_y - math.floor(sus_v * (FH - 4))
          screen.level(3)
          screen.rect(fx0, fy0, FW, FH); screen.stroke()
          local px0 = fx0 + 1
          local lby = cy + CR + 6
          screen.font_size(7)
          local function draw_env_section(sel, bx, bw, get_y)
            if sel then screen.level(15); screen.rect(bx, fy0+1, bw, FH-2); screen.fill() end
            screen.level(sel and 0 or 8)
            for xi = 0, bw do
              local t  = bw > 0 and (xi / bw) or 0
              local py = math.floor(get_y(t))
              py = math.max(fy0+1, math.min(fy0+FH-2, py))
              screen.pixel(bx + xi, py); screen.fill()
            end
          end
          draw_env_section(sel_a, px0, aw, function(t)
            return bot_y - (t^0.35) * (bot_y - peak_y)
          end)
          local function adsr_lbl(sel, mx, txt)
            screen.font_size(7)
            local w = #txt * 4 + 4
            if sel then screen.level(15); screen.rect(mx-w/2, lby-6, w, 8); screen.fill(); screen.level(0)
            else screen.level(5) end
            screen.move(mx, lby); screen.text_center(txt)
          end
          adsr_lbl(sel_a, px0 + aw/2,               "ATT")
          draw_env_section(sel_d, px0+aw, dw, function(t)
            return peak_y + (1-(1-t)^2.5) * (sus_y - peak_y)
          end)
          adsr_lbl(sel_d, px0 + aw + dw/2,          "DEC")
          draw_env_section(sel_s, px0+aw+dw, sw, function(t)
            return sus_y
          end)
          adsr_lbl(sel_s, px0 + aw + dw + sw/2,     "SUS")
          draw_env_section(sel_r, px0+aw+dw+sw, rw, function(t)
            return sus_y + (1-(1-t)^2.5) * (bot_y - sus_y)
          end)
          adsr_lbl(sel_r, px0 + aw + dw + sw + rw/2,"REL")
          skip_count = 3
          goto continue
        end
        goto continue
      end
      if p.type == "adsr_d" then goto continue end
      if p.type == "adsr_s" then goto continue end
      if p.type == "adsr_r" then goto continue end
      if p.type == "release" then goto continue end
      if p.type == "density" then
        local pn = all_params[page_start + i + 2]
        if pn and pn.type == "chance" and col < 3 then
          local dx       = COLS[col+2]
          local x0       = cx - CR
          local x1       = dx + CR
          local y0       = cy - CR
          local W        = x1 - x0
          local IH       = CR * 2
          local sel_d    = sel_item == page_start + i
          local sel_c    = sel_item == page_start + i + 1
          local cval     = chance
          local half_W = math.floor(W / 2)
          local meter_y = y0 + IH - 1
          screen.level((sel_d or sel_c) and 8 or 3)
          screen.rect(x0, y0, W, IH); screen.stroke()
          local rain_amt = cval
          local n_drops  = math.floor(rain_amt * 14)
          for di = 0, n_drops-1 do
            local rx_rand = (math.sin(di * 2.7 + 1.1) + 1) / 2
            local base_x  = x0 + 2 + math.floor(rx_rand * (W-4))
            local t  = ((wave_phase * 1.2 + di * 0.61) % (math.pi*2)) / (math.pi*2)
            local ry = y0 + math.floor(t * IH)
            local rx = base_x + math.floor(t * 5)
            for si = 0, 5 do
              local sx = rx - si
              local sy = ry - si * 2
              if sx >= x0+1 and sx <= x1-1 and sy >= y0+1 and sy <= meter_y-1 then
                screen.level(math.max(1, (sel_c and 10 or 5) - si))
                screen.pixel(sx, sy); screen.fill()
              end
            end
          end
          for _, b in ipairs(note_birds) do
            local bx = x0 + 2 + math.floor(b.x * (W-4) / 38)
            local by = cy + b.y
            if bx >= x0+2 and bx <= x1-2 then
              local flap = math.sin(wave_phase * 8 + b.flap_phase) > 0
              screen.level(15)
              screen.pixel(bx, by); screen.fill()
              if flap then
                screen.pixel(bx-1, by-1); screen.fill()
                screen.pixel(bx+1, by-1); screen.fill()
              else
                screen.pixel(bx-1, by+1); screen.fill()
                screen.pixel(bx+1, by+1); screen.fill()
              end
            end
          end
          screen.font_size(7)
          if sel_d then screen.level(15); screen.rect(cx-14, cy+CR, 28, 8); screen.fill(); screen.level(0)
          else screen.level(5) end
          screen.move(cx, cy + CR + 6); screen.text_center("FLOCK")
          if sel_c then screen.level(15); screen.rect(dx-12, cy+CR, 24, 8); screen.fill(); screen.level(0)
          else screen.level(5) end
          screen.move(dx, cy + CR + 6); screen.text_center("RAIN")
          screen.level(2)
          screen.move(x0+1, meter_y); screen.line(x0+half_W-1, meter_y); screen.stroke()
          screen.move(x0+half_W, meter_y); screen.line(x1-1, meter_y); screen.stroke()
          local de = x0+1 + math.floor(val  * (half_W-2))
          local ce = x0+half_W + math.floor(cval * (half_W-1))
          screen.level(sel_d and 15 or 10)
          screen.move(x0+1, meter_y); screen.line(de, meter_y); screen.stroke()
          screen.level(sel_c and 15 or 10)
          screen.move(x0+half_W, meter_y); screen.line(ce, meter_y); screen.stroke()
          skip_count = 1
          goto continue
        end
      end
      if p.type == "chance" then goto continue end
      if p.id == "filter" then
        local res_v   = 1 - val
        local r_inner = math.max(2, val * (CR - 3) + 2)
        local r_i     = math.floor(r_inner)
        local spike   = res_v * (CR - r_inner - 1)
        local n = 8
        screen.level(is_sel and 15 or 10)
        screen.move(cx + r_i, cy)
        screen.circle(cx, cy, r_i); screen.fill()
        if spike > 0.5 then
          screen.level(is_sel and 15 or 13)
          for si = 0, n-1 do
            local angle = si / n * math.pi * 2
            local sp2 = spike * (1 + math.sin(wave_phase * 2 + si * 0.8) * 0.25 * res_v)
            local x1 = cx + math.floor(r_inner * math.cos(angle))
            local y1 = cy + math.floor(r_inner * math.sin(angle))
            local x2 = cx + math.floor((r_inner + sp2) * math.cos(angle))
            local y2 = cy + math.floor((r_inner + sp2) * math.sin(angle))
            screen.move(x1, y1); screen.line(x2, y2); screen.stroke()
          end
        end
        if val > 0.3 then
          local moon_a  = math.min(1, (val - 0.3) / 0.7)
          local craters = {
            {dx=3,  dy=-2, r=1.5},
            {dx=-3, dy=1,  r=1.2},
            {dx=1,  dy=4,  r=1.5},
            {dx=-2, dy=-3, r=1.0},
            {dx=5,  dy=2,  r=1.0},
            {dx=-1, dy=-5, r=0.8},
          }
          for _, c in ipairs(craters) do
            local cdist = math.sqrt(c.dx^2 + c.dy^2)
            if cdist + c.r + 0.5 < r_i then
              screen.level(math.max(1, math.floor(moon_a * 4)))
              screen.move(cx+c.dx+math.ceil(c.r), cy+c.dy)
              screen.circle(cx+c.dx, cy+c.dy, c.r); screen.fill()
              screen.level(math.max(3, math.floor(moon_a * 12)))
              screen.move(cx+c.dx+math.ceil(c.r), cy+c.dy)
              screen.circle(cx+c.dx, cy+c.dy, c.r); screen.stroke()
            end
          end
        end
        local lw = #lbl * 5 + 4
        local bx = cx - lw/2
        local mbx = cx - 9  -- fixed 19px bar, centered
        -- bar (always same style)
        screen.level(2); screen.rect(mbx, cy+CR+1, 19, 1); screen.fill()
        local bw = math.floor(val * 19)
        if bw > 0 then screen.level(10); screen.rect(mbx, cy+CR+1, bw, 1); screen.fill() end
        -- text highlight (text area only)
        if is_sel then
          screen.level(15); screen.rect(bx, cy+CR+2, lw, 7); screen.fill()
          screen.level(0)
        else
          screen.level(5)
        end
        screen.font_size(7)
        screen.move(cx, cy + CR + 8); screen.text_center(lbl)
        goto continue
      end
      if p.id == "spread" then
        for di = 0, 15 do
          if di % 2 == 0 then
            local a = di / 16 * math.pi * 2
            screen.level(is_sel and 10 or 4)
            screen.pixel(cx + math.floor(math.cos(a)*CR), cy + math.floor(math.sin(a)*CR))
            screen.fill()
          end
        end
        screen.level(is_sel and 15 or 12)
        screen.pixel(cx, cy); screen.fill()
        if val > 0.01 then
          local max_r = CR - 2
          local r = val * max_r
          local n_dir = 16
          for di = 0, n_dir - 1 do
            local base_angle = di / n_dir * math.pi * 2
            local angle = base_angle + math.sin(wave_phase * 0.7 + di * 0.5) * val * 0.15
            for layer = 1, 3 do
              local dist = (layer / 3) * r
                         + math.sin(wave_phase + di * 1.1 + layer * 2.3) * val * 0.8
              dist = math.max(0.5, math.min(r, dist))
              local px = cx + math.floor(dist * math.cos(angle) + 0.5)
              local py = cy + math.floor(dist * math.sin(angle) + 0.5)
              local lv = math.floor((1 - dist / (max_r + 1)) * (is_sel and 13 or 9))
              lv = math.max(2, lv)
              screen.level(lv)
              screen.pixel(px, py); screen.fill()
            end
          end
        end
        local lw = #lbl * 5 + 4
        local bx = cx - lw/2
        local mbx = cx - 9  -- fixed 19px bar, centered
        -- bar (always same style)
        screen.level(2); screen.rect(mbx, cy+CR+1, 19, 1); screen.fill()
        local bw = math.floor(val * 19)
        if bw > 0 then screen.level(10); screen.rect(mbx, cy+CR+1, bw, 1); screen.fill() end
        -- text highlight (text area only)
        if is_sel then
          screen.level(15); screen.rect(bx, cy+CR+2, lw, 7); screen.fill()
          screen.level(0)
        else
          screen.level(5)
        end
        screen.font_size(7)
        screen.move(cx, cy + CR + 8); screen.text_center(lbl)
        goto continue
      end
      if p.type == "gain" then
        local lw = #lbl * 5 + 4
        screen.font_size(7)
        if is_sel then screen.level(15); screen.rect(cx-lw/2, cy-8, lw, 8); screen.fill(); screen.level(0)
        else screen.level(4) end
        screen.move(cx, cy - 3); screen.text_center(lbl)
        local BW = CR * 2
        local BH = 5
        local bx = cx - BW/2
        local by = cy + 3
        screen.level(is_sel and 15 or 4)
        screen.rect(bx, by, BW, BH); screen.stroke()
        local fill_w = math.floor(val * (BW - 2))
        if fill_w > 0 then
          local bar_lv = val > 0.85 and 15 or (val > 0.65 and 11 or 7)
          screen.level(is_sel and math.min(15, bar_lv + 2) or bar_lv)
          screen.rect(bx+1, by+1, fill_w, BH-2); screen.fill()
        end
        goto continue
      end
      if p.type == "looper" then
        local lbl_w = #lbl * 5 + 4
        screen.font_size(7)
        if is_sel then screen.level(15); screen.rect(cx-lbl_w/2, cy-8, lbl_w, 8); screen.fill(); screen.level(0)
        else screen.level(5) end
        screen.move(cx, cy-3); screen.text_center(lbl)
        if looper_mode == 1 then
          local st  = loops[1].state
          local icy = cy + 4
          if st == "empty" then
            screen.level(is_sel and 6 or 2)
            screen.move(cx+2, icy); screen.circle(cx, icy, 2); screen.fill()
          elseif st == "recording" then
            local pulse = math.floor(math.abs(math.sin(wave_phase * 4)) * 15)
            screen.level(math.max(6, pulse))
            screen.move(cx+3, icy); screen.circle(cx, icy, 3); screen.fill()
          elseif st == "playing" then
            screen.level(is_sel and 15 or 11)
            screen.move(cx-2, icy-3); screen.line(cx+4, icy)
            screen.line(cx-2, icy+3); screen.line(cx-2, icy-3); screen.fill()
          elseif st == "stopped" then
            screen.level(is_sel and 10 or 5)
            screen.rect(cx-2, icy-2, 5, 5); screen.fill()
          end
        else
          local sel2   = looper_sel_slot
          local st    = loops[sel2].state
          local icon_y = cy + 3
          if st == "empty" then
            screen.level(is_sel and 5 or 2)
            screen.move(cx+4, icon_y); screen.circle(cx, icon_y, 3); screen.fill()
          elseif st == "recording" then
            local pulse = math.floor(math.abs(math.sin(wave_phase * 4)) * 15)
            screen.level(math.max(6, pulse))
            screen.move(cx+3, icon_y); screen.circle(cx, icon_y, 3); screen.fill()
          elseif st == "stopping" then
            local pulse = math.floor(math.abs(math.sin(wave_phase * 6)) * 8)
            screen.level(math.max(3, pulse))
            screen.move(cx+2, icon_y); screen.circle(cx, icon_y, 2); screen.fill()
          elseif st == "playing" then
            screen.level(is_sel and 15 or 11)
            screen.move(cx-2, icon_y-3); screen.line(cx+4, icon_y)
            screen.line(cx-2, icon_y+3); screen.line(cx-2, icon_y-3); screen.fill()
          elseif st == "stopped" then
            screen.level(is_sel and 10 or 5)
            screen.rect(cx-2, icon_y-2, 5, 5); screen.fill()
          end
          local dot_y = cy + CR + 2
          local dot_xs = {cx-3, cx+3}
          for tr = 1, 2 do
            local tst = loops[tr].state
            local is_sel_tr = (tr == sel2)
            local dot_lv
            if tst == "empty" then dot_lv = is_sel_tr and 6 or 2
            elseif tst == "recording" or tst == "stopping" then
              dot_lv = math.floor(math.abs(math.sin(wave_phase * 4 + tr)) * 12) + 3
            elseif tst == "playing" then dot_lv = is_sel_tr and 15 or 10
            elseif tst == "stopped" then dot_lv = is_sel_tr and 8 or 4
            else dot_lv = 2 end
            screen.level(dot_lv)
            if is_sel_tr then
              screen.move(dot_xs[tr]+2, dot_y)
              screen.circle(dot_xs[tr], dot_y, 1.5); screen.fill()
            else
              screen.pixel(dot_xs[tr], dot_y); screen.fill()
            end
          end
        end
        goto continue
      end
      if p.id == "intone" then
        local icon_cy    = cy
        local base_h     = 5
        local extra_h    = 4
        local base_w     = 6
        local extra_w    = 3
        local stripe_per = 5
        local stripe_ph  = math.floor(wave_phase * 4) % stripe_per
        local left_melt  = math.max(0, (0.5 - val) * 2)
        local right_melt = math.max(0, (val - 0.5) * 2)
        local base_lv    = is_sel and 14 or 9
        local centered   = math.abs(val - 0.5) < 0.02
        if centered then
          -- 中央: 中身をくり抜いた（黒い）ダイヤ = 輪郭のみ
          screen.level(base_lv)
          screen.move(cx - base_w, icon_cy)
          screen.line(cx,          icon_cy - base_h)
          screen.line(cx + base_w, icon_cy)
          screen.line(cx,          icon_cy + base_h)
          screen.line(cx - base_w, icon_cy)
          screen.stroke()
        else
          local left_h     = base_h + left_melt  * extra_h
          local right_h    = base_h + right_melt * extra_h
          local left_mw    = base_w + left_melt  * extra_w
          local right_mw   = base_w + right_melt * extra_w
          local max_h      = math.max(left_h, right_h)
          for row2 = math.floor(icon_cy - max_h), math.floor(icon_cy + max_h) do
            local dy    = math.abs(row2 - icon_cy)
            local lw    = dy < left_h  and math.floor((1-dy/left_h)  * left_mw)  or 0
            local rw    = dy < right_h and math.floor((1-dy/right_h) * right_mw) or 0
            if lw > 0 or rw > 0 then
              local base_w2 = dy < base_h and math.floor((1-dy/base_h)*base_w) or 0
              local prog    = dy / max_h
              local lv      = math.max(2, math.floor((1-prog*0.72)*base_lv))
              for x = cx - lw, cx + rw do
                local in_base = (x >= cx - base_w2 and x <= cx + base_w2)
                if in_base then
                  screen.level(lv)
                  screen.pixel(x, row2); screen.fill()
                else
                  if (x - row2 + stripe_ph + 100) % stripe_per < 2 then
                    screen.level(math.max(2, lv + 2))
                    screen.pixel(x, row2); screen.fill()
                  end
                end
              end
            end
          end
        end
        local lbl_w = #lbl * 5 + 4
        local bx_i = cx - lbl_w/2
        local mbx_i = cx - 9  -- fixed 19px bar, centered
        -- bar (always same style)
        screen.level(2); screen.rect(mbx_i, cy+CR+1, 19, 1); screen.fill()
        local bw = math.floor(val * 19)
        if bw > 0 then screen.level(10); screen.rect(mbx_i, cy+CR+1, bw, 1); screen.fill() end
        -- text highlight (text area only)
        if is_sel then
          screen.level(15); screen.rect(bx_i, cy+CR+2, lbl_w, 7); screen.fill()
          screen.level(0)
        else
          screen.level(6)
        end
        screen.font_size(7)
        screen.move(cx, cy + CR + 8); screen.text_center(lbl)
        goto continue
      end
      if p.type == "sc_rate" then
        local lbl_w = #lbl * 5 + 4
        if is_sel then screen.level(15); screen.rect(cx-lbl_w/2, cy-8, lbl_w, 8); screen.fill(); screen.level(0)
        else screen.level(6) end
        screen.font_size(7)
        screen.move(cx, cy-3); screen.text_center(lbl)
        screen.level(is_sel and 15 or 11)
        if sc_dir[looper_sel_slot] < 0 then
          screen.move(cx+6, cy-1); screen.line(cx-5, cy+4)
          screen.line(cx+6, cy+9); screen.line(cx+6, cy-1); screen.fill()
          screen.level(is_sel and 12 or 8)
          screen.move(cx-6, cy-1); screen.line(cx-6, cy+9); screen.stroke()
        else
          screen.move(cx-6, cy-1); screen.line(cx+5, cy+4)
          screen.line(cx-6, cy+9); screen.line(cx-6, cy-1); screen.fill()
          screen.level(is_sel and 12 or 8)
          screen.move(cx+6, cy-1); screen.line(cx+6, cy+9); screen.stroke()
        end
        goto continue
      end
      if p.type == "sc_speed" then
        screen.font_size(7)
        screen.level(is_sel and 15 or 6)
        screen.move(cx, cy-3); screen.text_center(lbl)
        local spd = sc_speed[looper_sel_slot]
        local norm
        if spd < 1.0 then norm = (spd - 0.25) / 0.75 * 0.5
        else norm = 0.5 + (spd - 1.0) / 3.0 * 0.5 end
        local bw       = 14
        local bx       = cx - bw / 2
        local ay       = cy + 5
        local ref_x    = cx
        local tip_x    = bx + math.floor(norm * bw)
        local lv       = is_sel and 15 or 11
        local at_center = math.abs(norm - 0.5) < 0.06
        screen.level(is_sel and 3 or 2)
        screen.move(bx, ay); screen.line(bx + bw, ay); screen.stroke()
        if tip_x > bx then
          screen.level(lv)
          screen.move(bx, ay); screen.line(tip_x, ay); screen.stroke()
        end
        if at_center then
          local flash = math.floor(8 + math.abs(math.sin(wave_phase * 5)) * 7)
          screen.level(flash)
          screen.move(ref_x + 3, ay); screen.circle(ref_x, ay, 3); screen.fill()
        else
          screen.level(is_sel and 6 or 4)
          screen.move(ref_x, ay - 3); screen.line(ref_x, ay + 3); screen.stroke()
          if norm > 0.5 then
            local ax2 = tip_x + 2
            screen.level(lv)
            screen.move(ax2 + 3, ay)
            screen.line(ax2, ay - 2); screen.line(ax2, ay + 2)
            screen.line(ax2 + 3, ay); screen.fill()
          else
            local ax2 = tip_x - 2
            screen.level(lv)
            screen.move(ax2 - 3, ay)
            screen.line(ax2, ay - 2); screen.line(ax2, ay + 2)
            screen.line(ax2 - 3, ay); screen.fill()
          end
        end
        goto continue
      end
      if p.type == "sc_level" then
        screen.font_size(7)
        screen.level(is_sel and 15 or 6)
        screen.move(cx, cy-3); screen.text_center(lbl)
        local bx = cx - CR + 1
        local bw = CR * 2 - 2
        local by = cy + 3
        local bh = 4
        screen.level(is_sel and 5 or 3)
        screen.rect(bx, by, bw, bh); screen.stroke()
        local fill_w = math.floor(val * (bw - 2))
        if fill_w > 0 then
          local bar_lv = val > 0.85 and 15 or (val > 0.5 and 11 or 7)
          screen.level(is_sel and math.min(15, bar_lv + 2) or bar_lv)
          screen.rect(bx+1, by+1, fill_w, bh-2); screen.fill()
        end
        goto continue
      end
      draw_opz_knob(cx, cy, val, vs, lbl, is_sel)
    end
    ::continue::
  end
  for pg = 0, 1 do
    screen.level(pg == cur_page and 15 or 3)
    screen.pixel(62 + pg * 5, 2); screen.fill()
  end
  screen.update()
end
