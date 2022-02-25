local GGrid={}


function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  return m
end


function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end
  if col>1 and on then
    if mode_cur==MODE_REC then 
      note_add(col-1,row)
    end
  elseif col==1 and row<=2 and on then
    note_left_right=row
    note_cur=(ins_cur-1)*2+note_left_right
  elseif col==1 and row<=6 and on then
    ins_cur=row-2
    note_cur=(ins_cur-1)*2+note_left_right
  elseif col==1 and row==8 and on then
    mode_cur=mode_cur+1
    if mode_cur>2 then
      mode_cur=0
    end    
  end
end


function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=0--self.visual[row][col]-1
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- illuminate current patterns for current instrument
  local rows_playing={}
  local current_instrument=notes[note_cur].ins
  for notei, n in ipairs(notes) do
    if n.ins==current_instrument and n.note_er~=nil and n.cur~=nil then 
      local addin=(notei%2+1)==note_left_right and 1 or 2
      for _, v in ipairs(n.note_er.data) do
        local row=v[2]
        local col=v[1]
        self.visual[row][col+1]=util.clamp(self.visual[row][col+1]+addin,0,13)
        -- if n.played and col==n.last_played.num and row==n.last_played.pattern then
        --   self.visual[row][col+1]=addin*7
        -- end
      end
      -- if n.played then 
      --   rows_playing[n.last_played.pattern]=true
      --   -- for row=1,8 do
      --   --   self.visual[row][n.last_played.num+1]=util.clamp(self.visual[row][n.last_played.num+1]+2,0,15)
      --   -- end
      -- end
    end
  end

  if note_queue_last~=nil then
    for _, note in ipairs(note_queue_last) do
      if note.ins==ins_cur then 
        self.visual[note.pattern][note.num+1]=7
        rows_playing[note.pattern]=true
      end
    end
  end

  -- for row,_ in pairs(rows_playing) do 
  --   for col=2,16 do 
  --     if self.visual[row][col]==0 then
  --       self.visual[row][col]=er_last[row][col-1] and 1 or 0
  --     end
  --   end
  -- end

  -- illuminate current note
  self.visual[note_left_right][1]=15
  self.visual[ins_cur+2][1]=15

  -- illuminate current mode
  self.visual[8][1]=mode_cur*5
  
  -- illuminate currently pressed button
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=15
  end

  return self.visual
end


function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

return GGrid
