-- mallets

-- mallets v0.0.0
--
--
-- llllllll.co/t/mallets
--
--
--
--    ▼ instructions below ▼

MusicUtil=require("musicutil")
lattice=require("lattice")
s=require("sequins")
er=require("er")
grid_=include("mallets/lib/ggrid")

local mxsamples_=include("mx.samples2/lib/mx.samples2")
engine.name="MxSamples2"

shift=false
MODE_ERASE=0
MODE_PLAY=1
MODE_REC=2

function init()
  mxsamples=mxsamples_:new()
  params:set("mxsamples_release",0.25)

  gg=grid_:new()
  local redrawer=metro.init()
  redrawer.time=1/15
  redrawer.count=-1
  redrawer.event=updater
  redrawer:start()

  scale_full=MusicUtil.generate_scale_of_length(0,1,15)
  -- https://www.ottogumaelius.com/about-marimba
  scale_full={0,2,4,5,6,7,9,11,12,14,16,17,18,19,21,23,24}
  -- initialize ers
  ers={}
  er_last={}
  er_pulses={1,2,3,5,7,11,13,15}
  for i,v in ipairs(er_pulses) do
    table.insert(ers,s(er.gen(v,16,0)))
    er_last[i]={false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
  end

  notes={
    {ins=1},
    {ins=1},
    {ins=2},
    {ins=2},
    {ins=3},
    {ins=3},
    {ins=4},
    {ins=4},
  }
  note_cur=1
  ins_cur=4
  note_left_right=1
  mode_cur=MODE_REC
  note_enc=1
  er_enc=6

  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  local step=-1
  sequencer:new_pattern({
    action=function(t)
      local note_queue={}
      for i,note in ipairs(notes) do
        notes[i].played=false
        if note.note_er~=nil and note.cur~=nil and note.ins~=nil then
          -- local erpat=note.pattern.data[note.pattern.ix]
          -- local trig=ers[erpat].data[ers[erpat].ix]
          local erpat=note.cur[2]
          local trig=ers[erpat].data[ers[erpat].ix]
          if trig then
            local vel=notes[i].vel()
            notes[i].played=true
            notes[i].last_played={num=note.cur[1],pattern=note.cur[2]}
            if note_queue==nil then
              note_queue={}
            end
            table.insert(note_queue,{ins=note.ins,num=note.cur[1],pattern=erpat,vel=vel,left=i%2==1})
            notes[i].cur=notes[i].note_er()
          end
        end
      end

      -- if in play mode, load current notes in queue
      if mode_cur==MODE_PLAY then
        for k,_ in pairs(gg.pressed_buttons) do
          local row_,col_=k:match("(%d+),(%d+)")
          local col=tonumber(col_)
          if col>1 then
            local erpat=tonumber(row_)
            local trig=ers[erpat].data[ers[erpat].ix]
            if trig then
              local vel=120
              local note=col-1
              if note_queue==nil then
                note_queue={}
              end
              table.insert(note_queue,{ins=ins_cur,num=note,pattern=erpat,vel=120,left=false})
            end
          end
        end
      end

      -- turn off notes loaded in the queue
      if note_queue_last~=nil then
        for _,note in ipairs(note_queue_last) do
          local num=scale_full[note.num]+(12*(note.ins+1))
          mxsamples:off({name=note.left and "marimba_red" or "marimba_white",midi=num,velocity=note.vel})
        end
        note_queue_last=nil
      end
      if next(note_queue)~=nil then
        note_queue_last=table.clone(note_queue)
      end

      -- play the notes loaded in the queue
      for _,note in ipairs(note_queue) do
        local num=scale_full[note.num]+(12*(note.ins))
        mxsamples:on({name=note.left and "marimba_red" or "marimba_white",midi=num,velocity=note.vel})
        -- engine.play(note.ins,num,note.vel)
      end

      -- iterate the ers
      step=step+1
      for i,_ in ipairs(ers) do
        for j,v in ipairs(er_last[i]) do
          if j>1 then
            er_last[i][j-1]=v
          end
        end
        er_last[i][15]=ers[i]()
      end
    end,
    division=1/16,
  })
  sequencer:hard_restart()

  note_left_right=1
  note_add(1,7)
  note_add(1,2)
  note_left_right=2
  note_add(15,8)
end

function note_add(note_num,er_num)
  note_cur=(ins_cur-1)*2+note_left_right
  if notes[note_cur]==nil then
    notes[note_cur]={ins=ins_cur}
  end
  print("adding note "..note_num.." with er "..er_num.." to ins "..ins_cur)
  if notes[note_cur].note_er==nil then
    -- setup new sequins
    notes[note_cur].note_er=s({{note_num,er_num}})
    notes[note_cur].vel=s{90,90,30,90,90,30,90,90} -- TODO make this configurable?
    notes[note_cur].cur=notes[note_cur].note_er()
  else
    -- add to the current
    local d={table.unpack(notes[note_cur].note_er.data)}
    table.insert(d,{note_num,er_num})
    notes[note_cur].note_er:settable(d)
  end
  notes[note_cur].note_er:reset()
  print(note_cur,note_cur+(note_cur%2==1 and 1 or-1))
  if notes[note_cur+(note_cur%2==1 and 1 or-1)].note_er~=nil then
    notes[note_cur+(note_cur%2==1 and 1 or-1)].note_er:reset()
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
    if d==0 then 
      do return end 
    end
    d=d>0 and 1 or -1
    note_left_right=note_left_right+d
    if note_left_right>2 and ins_cur<4 then 
      note_left_right=1
      ins_cur=ins_cur+1
    end
    if note_left_right<1 and ins_cur>1 then 
      note_left_right=2
      ins_cur=ins_cur-1
    end
    if note_left_right<1 then 
      note_left_right=1
    elseif note_left_right>2 then 
      note_left_right=2
    end
  elseif k==2 then
    note_enc=util.clamp(note_enc+d,1,15)
  elseif k==3 and shift then
    -- rotate ers
    table.rotatex(er_pulses,d)
    flag_update_er=true
  elseif k==3 and not shift then
    er_enc=util.clamp(er_enc+d,1,8)
  end
end

function key(k,z)
  if k==1 then
    shift=z==1
  elseif k==2 and z==1 then
  elseif k==3 and z==1 then 
    note_add(note_enc,er_enc)  
  end
end

function draw_marimba()
  local active_notes={}
  if note_queue_last~=nil then
    for _, note in ipairs(note_queue_last) do
      if note.ins==ins_cur and (note.left==(note_left_right%2==1)) then 
        active_notes[note.num]=true
      end
    end
  end
  local height=35
  local width=7
  local x=5
  local ymid=42
  local top_positions={}
  local bot_positions={}
  for i=1,15 do
    local y=math.floor(ymid-height/2)
    screen.rect(x,y,width,height)
    screen.level(5)
    screen.fill()
    if active_notes[i] then
      screen.rect(x,y,width,height)
      screen.level(15)
      screen.fill()
    end
    if i==note_enc then
      -- screen.line_width(0.5)
      screen.rect(x+1,y+1,width-1,height-1)
      screen.level(15)
      screen.stroke()
    end
    table.insert(top_positions,{x+width/2,y+height})
    table.insert(bot_positions,{x+width/2,y})
    height=height-1
    x=x+8
  end

end

function updater()
  if flag_update_er then
    update_er()
  end

  redraw()
end

function redraw()
  screen.clear()
  -- screen.aa(1)
  screen.level(15)
  screen.move(5,10)
  screen.text("instrument: "..ins_cur)
  screen.move(5,18)
  screen.text("hand: "..(note_left_right==1 and "left" or "right"))
  screen.move(124,10)
  screen.level(er_last[er_enc][15] and 15 or 2) 
  screen.text_right("er: "..er_enc)
  draw_marimba()
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

function table.reverse(t)
  local len=#t
  for i=len-1,1,-1 do
    t[len]=table.remove(t,i)
  end
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

function table.clone(org)
  return {table.unpack(org)}
end
