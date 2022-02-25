-- lerb

-- lerb v0.0.0
--
--
-- llllllll.co/t/lerb
--
--
--
--    ▼ instructions below ▼


MusicUtil=require("musicutil")
lattice=require("lattice")
s=require("sequins")
er=require("er")
grid_=include("lerb/lib/ggrid")

engine.name="Marimba"

function init()

  gg=grid_:new()
  local redrawer=metro.init()
  redrawer.time=1/15
  redrawer.count=-1
  redrawer.event=updater
  redrawer:start()

  scale_full=MusicUtil.generate_scale_of_length(0, 1, 15)
  
  -- initialize ers
  ers={}
  er_pulses={1,2,3,5,7,11,13,15}
  for i,v in ipairs(er_pulses) do
    table.insert(ers,s(er.gen(v,16,0)))
  end
  
  notes={
    -- TODO: erase all of these
    {ins=1,num=s{1,1,1,2,3,4},pattern=s{2,2,2,3,7,7},vel=s{80,80,40,80,80,40,80,80}},
    {ins=1},
    {ins=2},
    {ins=2},
    {ins=3},
    {ins=3},
    -- {ins=1,num=s{1,1,1,2,3,4},pattern=s{2,2,2,3,7,7},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=1,num=s{8,8,8,9},pattern=s{2,4,2,3},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=2,num=s{1,1,1,1,1,1,2},pattern=s{1,4,6,7,2,3,3},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=2,num=s{3,3,3,3,3,3,4},pattern=s{1,4,6,7,2,3,3},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=2,num=s{2,4,8,10,9,6,2,3,3,3},pattern=s{3,4,6,1,8,3,4,6,1,8},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=3,num=s{ 4, 4, 4, 6, 4, 4, 4, 5},pattern=s{5,5,1,2,4,7,7,7},vel=s{80,80,40,80,80,40,80,80}},
    -- {ins=3,num=s{12,12,12,14,13,12,12,11},pattern=s{5,5,1,2,4,7,7,7},vel=s{80,80,40,80,80,40,80,80}},
  }
  note_cur=2 -- TODO: this should be 1 initially
  ins_cur=1 -- TODO: this should be 1 also
  
  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  sequencer:new_pattern({
    action=function(t)
      local note_queue={}
      for i,note in ipairs(notes) do
        notes[i].played=false
        if note.num~=nil and note.pattern~=nil and note.ins~=nil then 
          -- local erpat=note.pattern.data[note.pattern.ix]   
          -- local trig=ers[erpat].data[ers[erpat].ix]
          -- hmmmmm I don't think I understand what I'm doing but it sounds cool
          local erpat=note.pattern.data[note.pattern.ix]   
          local trig=ers[erpat].data[ers[erpat].ix]
          if trig then 
            notes[i].pattern()
            local num=notes[i].num()
            local vel=notes[i].vel()
            notes[i].played=true
            notes[i].last_played={num=num,pattern=erpat}
            if note_queue[note.ins]==nil then 
              note_queue[note.ins]={}
            end
            table.insert(note_queue[note.ins],{num=num,vel=vel})
          end
        end
      end
      
      -- play the notes loaded in the queue
      for i,ns in pairs(note_queue) do 
        for j, note in ipairs(ns) do
          if j<=2 then -- two hands can only play two notes at a time
            local num=scale_full[note.num]+(12*(i+1)) -- TODO: octave should depend on instrument
            engine.play(i,num,note.vel)
          end
        end
      end
      -- iterate the ers
      for i,_ in ipairs(ers) do
        ers[i]()
      end
    end,
    division=1/16,
  })
  sequencer:hard_restart()

end

function note_add(note_num,er_num)
  if notes[note_cur]==nil then 
    notes[note_cur]={ins=ins_cur}
  end
  print("adding note "..note_num.." with er "..er_num.." to ins "..ins_cur)
  if notes[note_cur].num==nil then 
    -- setup new sequins
    notes[note_cur].num=s{note_num}
    notes[note_cur].pattern=s{er_num}
    notes[note_cur].vel=s{90,90,30,90,90,30,90,90} -- TODO make this configurable?
  else
    -- add to the current
    local d={table.unpack(notes[note_cur].num.data)}
    table.insert(d,note_num)
    notes[note_cur].num:settable(d)
    d={table.unpack(notes[note_cur].pattern.data)}
    table.insert(d,er_num)
    notes[note_cur].pattern:settable(d)
  end
end

function update_er()
  flag_update_er=nil
  for i,v in ipairs(er_pulses) do
    print(i,v)
    ers[i]:settable(er.gen(v,16,0))
  end
end

function enc(k,d)
  if k==1 then 
  elseif k==2 then 
  elseif k==3 then 
    -- rotate ers
    table.rotatex(er_pulses,d)
    flag_update_er=true
  end
end

function key(k,z)

end

function updater()
  if flag_update_er then 
    update_er()
  end

  redraw()
end

function redraw()
  screen.clear()
  screen.move(32,64)
  screen.text("lerb")
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end


function cleanup()

end


function table.get_rotation(t)
  local t2={}
  local v1=0
  for i,v in ipairs(t) do
    if i>1 then
      table.insert(t2,v)
    else
      v1=v
    end
  end
  table.insert(t2,v1)
  return t2
end

function table.rotate(t)
  for i,v in ipairs(table.get_rotation(t)) do
    t[i]=v
  end
end

function table.rotatex(t,d)
  if d<0 then
    table.reverse(t)
  end
  local d_abs=math.abs(d)
  if d_abs>0 then
    for i=1,d_abs do
      table.rotate(t)
    end
  end
  if d<0 then
    table.reverse(t)
  end
end

