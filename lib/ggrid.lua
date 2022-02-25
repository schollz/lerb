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
  if col<16 and on then
    note_add(col,row) -- defined as global
  elseif col==16 and row<=6 then
    note_cur=row
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
  local current_instrument=notes[note_cur].ins
  for notei, n in ipairs(notes) do
    if n.ins==current_instrument and n.pattern~=nil and n.num~=nil then 
      local rows={}
      local cols={}
      for _, v in ipairs(n.pattern.data) do
        table.insert(rows,v)
      end
      for _, v in ipairs(n.num.data) do
        table.insert(cols,v)
      end
      for i,_ in ipairs(rows) do
        self.visual[rows[i]][cols[i]]=util.clamp(self.visual[rows[i]][cols[i]]+2,0,15)
      end
      if n.played then 
        for row=1,8 do
          self.visual[row][n.last_played.num]=util.clamp(self.visual[row][n.last_played.num]+2,0,15)
        end
      end
    end
  end

  -- illuminate current note
  self.visual[note_cur][16]=15
  
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
