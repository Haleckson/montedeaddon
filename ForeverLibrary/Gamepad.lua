local _, A = ...
local scope,focus,ring,notesMode
local dirs={PADDUP={0,1},PADDDOWN={0,-1},PADDLEFT={-1,0},PADDRIGHT={1,0},PADLSTICKUP={0,1},PADLSTICKDOWN={0,-1},PADLSTICKLEFT={-1,0},PADLSTICKRIGHT={1,0}}
local filters={"Missing","Carried","Tracked","Suggested","All"}
function A.GamepadAvailable()
    local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if loaded and loaded("ConsolePort") then return false end
    return A.db and A.db.controller~=false and C_GamePad and C_GamePad.IsEnabled and C_GamePad.IsEnabled() or false
end
local function Root()
    if not A.GamepadAvailable() or (InCombatLockdown and InCombatLockdown()) or (WorldMapFrame and WorldMapFrame:IsShown()) then return end
    if A.rewardsFrame and A.rewardsFrame:IsShown() then return A.rewardsFrame end
    if scope and A.tracker and A.tracker:IsShown() then return A.tracker end
    if A.frame and A.frame:IsShown() then return A.frame end
end
function A.GamepadPick(from,items,dx,dy)
    local best,score
    for _,item in ipairs(items) do
        if item.frame~=from.frame then
            local vx,vy=item.x-from.x,item.y-from.y
            local along=vx*dx+vy*dy
            local value=along+math.abs(vx*dy-vy*dx)*2.5
            if along>1 and (not score or value<score) then best,score=item,value end
        end
    end
    return best
end
local function Center(frame)
    local x,y=frame:GetCenter()
    if x then local scale=frame:GetEffectiveScale(); return x*scale,y*scale end
end
local function Collect(root,out)
    for _,child in ipairs({root:GetChildren()}) do
        if child:IsVisible() then
            if child:IsObjectType("Button") and child:IsMouseEnabled() and child:IsEnabled() then
                local x,y=Center(child)
                if x then out[#out+1]={frame=child,x=x,y=y} end
            end
            Collect(child,out)
        end
    end
    return out
end
local function Reveal(target)
    local parent=target:GetParent()
    while parent and parent~=UIParent do
        if parent:IsObjectType("ScrollFrame") then
            local top,bottom=target:GetTop(),target:GetBottom()
            local vt,vb=parent:GetTop(),parent:GetBottom()
            if top and bottom and vt and vb then
                local ratio=target:GetEffectiveScale()/parent:GetEffectiveScale()
                top,bottom=top*ratio,bottom*ratio
                local offset=parent:GetVerticalScroll()
                if top>vt then offset=offset-(top-vt)-4 elseif bottom<vb then offset=offset+(vb-bottom)+4 end
                parent:SetVerticalScroll(math.max(0,math.min(parent:GetVerticalScrollRange(),offset)))
                if parent.SyncScrollBar then parent:SyncScrollBar() end
            end
        end
        parent=parent:GetParent()
    end
end
local function SetFocus(target)
    if focus then local leave=focus:GetScript("OnLeave"); if leave then leave(focus) end end
    focus=target
    if not target then if ring then ring:Hide() end; return end
    Reveal(target)
    if not ring then
        ring=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
        ring:EnableMouse(false)
        ring:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
        ring:SetBackdropBorderColor(1,0.82,0.25,1)
    end
    ring:SetParent(target)
    ring:ClearAllPoints()
    ring:SetPoint("TOPLEFT",target,"TOPLEFT",-3,3)
    ring:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",3,-3)
    ring:SetFrameStrata(target:GetFrameStrata())
    ring:SetFrameLevel(target:GetFrameLevel()+6)
    ring:Show()
    local enter=target:GetScript("OnEnter"); if enter then enter(target) end
end
local function Valid(root)
    if not focus or not focus:IsVisible() or not focus:IsEnabled() then return false end
    local parent=focus
    while parent do if parent==root then return true end; parent=parent:GetParent() end
    return false
end
local function Default(root)
    for _,row in ipairs(root.rows or {}) do if row:IsVisible() and (root==A.tracker or row.book==A.selected) then return row end end
    for _,row in ipairs(root.rows or {}) do if row:IsVisible() then return row end end
    if root.cards then return root.cards[1] end
    local items=Collect(root,{})
    return items[1] and items[1].frame
end
function A.UpdateGamepad()
    if not A.frame or not A.frame.gamepad then return end
    local root=Root()
    if root~=A.frame then notesMode=nil end
    if A.frame.padHint then
        A.frame.padHint:SetText(notesMode and "Notes: LT/RT scroll | Right stick click or B: return to book navigation" or "D-pad: focus | A: select/map | X: track | B: back | Y: rewards | LB/RB: filters | LT/RT: books | R-stick click: notes")
    end
    for _,owner in ipairs({A.frame,A.rewardsFrame,A.tracker}) do
        local pad=owner.gamepad
        if pad and pad.EnableGamePadButton and not (InCombatLockdown and InCombatLockdown()) then
            pad:SetPropagateKeyboardInput(true)
            pad:EnableGamePadButton(owner==root)
        end
        if owner.padHint then owner.padHint:SetShown(owner==root) end
    end
    if not root then SetFocus(nil) elseif not Valid(root) then SetFocus(Default(root)) end
end
local function StepBook(root,delta)
    local rows={}
    for _,row in ipairs(root.rows or {}) do if row:IsVisible() then rows[#rows+1]=row end end
    if #rows==0 then return end
    local index=0
    for i,row in ipairs(rows) do if row==focus or (root==A.frame and row.book==A.selected) then index=i; break end end
    local row=rows[math.max(1,math.min(#rows,index+delta))]
    if root==A.frame then row:Click("LeftButton") end
    SetFocus(row)
end
function A.GamepadButton(button)
    local root=Root()
    if not root then return false end
    local dir=dirs[button]
    if dir then
        if not Valid(root) then SetFocus(Default(root))
        else
            local x,y=Center(focus)
            if x then local nextItem=A.GamepadPick({frame=focus,x=x,y=y},Collect(root,{}),dir[1],dir[2]); if nextItem then SetFocus(nextItem.frame) end end
        end
    elseif button=="PAD1" then
        if Valid(root) then focus:Click("LeftButton") else SetFocus(Default(root)) end
    elseif button=="PAD2" then
        if notesMode then notesMode=nil
        elseif root==A.tracker then scope=nil else root:Hide() end
    elseif button=="PAD3" then
        if Valid(root) and focus.book then A.ToggleTrack(focus.book)
        elseif root==A.frame and A.selected then A.ToggleTrack(A.selected)
        else return false end
    elseif button=="PAD4" then
        if root==A.tracker then scope=nil; A.ToggleWindow()
        elseif root==A.frame then A.rewardsFrame:Show()
        else A.Navigate(A.Librarian()) end
    elseif button=="PADLSHOULDER" or button=="PADRSHOULDER" then
        if root~=A.frame then return false end
        local index=1
        for i,name in ipairs(filters) do if name==A.filter then index=i end end
        local delta=button=="PADLSHOULDER" and -1 or 1
        A.frame.filters[filters[(index-1+delta)%#filters+1]]:Click("LeftButton")
        SetFocus(nil)
    elseif button=="PADLTRIGGER" or button=="PADRTRIGGER" then
        if root==A.frame and notesMode then
            local scroll=A.frame.noteScroll
            local step=button=="PADLTRIGGER" and -60 or 60
            scroll:SetVerticalScroll(math.max(0,math.min(scroll:GetVerticalScrollRange(),scroll:GetVerticalScroll()+step)))
            scroll:SyncScrollBar()
            return true
        end
        if not root.rows then return false end
        StepBook(root,button=="PADLTRIGGER" and -1 or 1)
    elseif button=="PADRSTICK" then
        if root~=A.frame then return false end
        notesMode=not notesMode
        A.frame.padHint:SetText(notesMode and "Notes: LT/RT scroll | Right stick click or B: return to book navigation" or "D-pad: focus | A: select/map | X: track | B: back | Y: rewards | LB/RB: filters | LT/RT: books | R-stick click: notes")
    else return false end
    A.UpdateGamepad()
    return true
end
function A.GamepadTrackerMode(on)
    if on then
        if not A.GamepadAvailable() or (InCombatLockdown and InCombatLockdown()) then
            DEFAULT_CHAT_FRAME:AddMessage("Library Scout: Enable native gamepad input and leave combat to navigate the tracker. ConsolePort uses its own cursor.")
            return
        end
        A.db.showTracker=true
        A.frame:Hide(); A.rewardsFrame:Hide()
        scope=true
        A.RefreshTracker()
    else scope=nil end
    SetFocus(nil)
    A.UpdateGamepad()
end
function A.CreateGamepad()
    if A.frame.gamepad then return end
    for _,owner in ipairs({A.frame,A.rewardsFrame,A.tracker}) do
        local pad=CreateFrame("Frame",nil,owner)
        owner.gamepad=pad
        if pad.EnableGamePadButton then
            pad:SetScript("OnGamePadButtonDown",function(self,button)
                if InCombatLockdown and InCombatLockdown() then return end
                self:SetPropagateKeyboardInput(true)
                if Root()==owner then self:SetPropagateKeyboardInput(not A.GamepadButton(button)) end
            end)
            pad:SetScript("OnGamePadButtonUp",function(self)
                if not (InCombatLockdown and InCombatLockdown()) then self:SetPropagateKeyboardInput(true) end
            end)
        end
        owner:HookScript("OnShow",A.UpdateGamepad)
        owner:HookScript("OnHide",function() if owner==A.tracker then scope=nil end; A.UpdateGamepad() end)
        owner.padHint=owner:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        owner.padHint:SetPoint("TOP",owner,"BOTTOM",0,-7)
        owner.padHint:SetText(owner==A.rewardsFrame and "A: action / item tooltip on focus | B: back | Y: librarian map" or owner==A.tracker and "D-pad: focus | A: map | X: untrack | B: exit navigation | Y: journal | LT/RT: books" or "D-pad: focus | A: select/map | X: track | B: back | Y: rewards | LB/RB: filters | LT/RT: books | R-stick click: notes")
        owner.padHint:Hide()
    end
    local events=A.frame.gamepad
    for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","GAME_PAD_CONNECTED","GAME_PAD_DISCONNECTED","GAME_PAD_ACTIVE_CHANGED","CVAR_UPDATE"}) do pcall(events.RegisterEvent,events,event) end
    events:SetScript("OnEvent",function(_,event) if event=="PLAYER_REGEN_DISABLED" or event=="GAME_PAD_DISCONNECTED" then scope=nil; SetFocus(nil) end; A.UpdateGamepad() end)
    A.UpdateGamepad()
end
BINDING_HEADER_FOREVERLIBRARYSCOUT="Forever Library Scout"
BINDING_NAME_LIBRARYSCOUT_JOURNAL="Toggle book journal"
BINDING_NAME_LIBRARYSCOUT_TRACKER="Navigate book tracker"
function LibraryScoutToggleJournal() A.ToggleWindow() end
function LibraryScoutNavigateTracker() if not A.frame then A.BuildUI() end; A.GamepadTrackerMode(not scope) end
