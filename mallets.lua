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
-- engine.name="Marimba"

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
  screen.text("mallets")
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
