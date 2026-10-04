-- Reference the running client's spellbook atlas; no extracted or bundled Blizzard art.
local addon=...
local Art={};_G[addon.."NativeBookArt"]=Art
function Art.Apply(texture,host)
    local book=host and (host.SpellBookFrame or host)
    local source=book and (book.BookBGHalved or book.BookBGRight or book.BookBGLeft)
    local atlas=source and source.GetAtlas and source:GetAtlas()
    -- The stock minimized page is the complete bordered single-page artwork.
    if not atlas and C_Texture and C_Texture.GetAtlasInfo and
        C_Texture.GetAtlasInfo("spellbook-background-evergreen-right") then
        atlas="spellbook-background-evergreen-right"
    end
    if atlas and texture.SetAtlas then
        texture:SetAtlas(atlas,false)
    elseif source and source.GetTexture and source:GetTexture() then
        texture:SetTexture(source:GetTexture())
        if source.GetTexCoord then texture:SetTexCoord(source:GetTexCoord()) end
    else
        -- Neutral, readable fallback. Never substitute unrelated quest art.
        texture:SetColorTexture(.82,.72,.52,1)
        return false
    end
    if texture.SetGradient and CreateColor then
        texture:SetGradient("VERTICAL",CreateColor(1,1,1,1),CreateColor(1,1,1,1))
    end
    texture:SetVertexColor(1,1,1,1)
    return true
end

function Art.Layer(texture,content,root,state)
    if not state.nativeBookBackdrop then
        state.nativeBookBackdrop=CreateFrame("Frame",nil,root)
        state.nativeBookBackdrop:SetAllPoints(root)
        state.nativeBookBackdrop:SetFrameLevel(root:GetFrameLevel()+1)
        content:SetFrameLevel(root:GetFrameLevel()+2)
    end
    state.nativeBookBackdrop:Show()
    texture:SetParent(state.nativeBookBackdrop)
    texture:SetDrawLayer("BACKGROUND",0)
    texture:SetAlpha(1)
end

function Art.Fonts(host)
    local result={name=_G.SystemFont_Med3 or _G.GameFontNormal,sub=_G.GameFontNormalSmall}
    local book=host and (host.SpellBookFrame or host)
    local count=0
    local function Visit(frame,depth)
        if not frame or depth>7 or count>200 then return end
        count=count+1
        if frame.Name and frame.Name.GetFont and frame.SubName and frame.SubName.GetFont then
            result.name=frame.Name;result.sub=frame.SubName;return true
        end
        if frame.GetChildren then
            for _,child in ipairs({frame:GetChildren()}) do if Visit(child,depth+1) then return true end end
        end
    end
    Visit(book,0)
    return result
end
function Art.CopyFont(target,source)
    if not target or not source or not source.GetFont then return end
    local path,size,flags=source:GetFont()
    if path then target:SetFont(path,size,flags or "") end
    if source.GetShadowColor and target.SetShadowColor then target:SetShadowColor(source:GetShadowColor()) end
    if source.GetShadowOffset and target.SetShadowOffset then target:SetShadowOffset(source:GetShadowOffset()) end
end

function Art.Pager(root,label,prev,nextButton,host,index,count)
    local book=host and (host.SpellBookFrame or host)
    local paging=book and book.PagedSpellsFrame and book.PagedSpellsFrame.PagingControls
    Art.CopyFont(label,paging and (paging.Text or paging.PageText) or _G.SystemFont_Med3 or _G.GameFontNormal)
    label:SetTextColor(.10,.07,.03,1)
    label:ClearAllPoints();label:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",-114,54)
    label:SetText(("Page %d/%d"):format(index,math.max(1,count)));label:Show()
    local function Style(button,source,direction)
        button.__exstyleSkip=true
        for _,key in ipairs({"edge","bg","hl","label"}) do if button[key] then button[key]:Hide() end end
        button:SetSize(24,24);button:Show()
        for _,state in ipairs({"Normal","Pushed","Disabled","Highlight"}) do
            local setter=button["Set"..state.."Texture"]
            local getter=source and source["Get"..state.."Texture"]
            local texture=getter and getter(source)
            if setter then
                if texture and texture.GetTexture and texture:GetTexture() then
                    setter(button,texture:GetTexture())
                    local own=button["Get"..state.."Texture"](button)
                    if own and texture.GetTexCoord then own:SetTexCoord(texture:GetTexCoord()) end
                else
                    local suffix=state=="Normal" and "Up" or state=="Pushed" and "Down" or state
                    setter(button,"Interface\\Buttons\\UI-SpellbookIcon-"..direction.."Page-"..suffix)
                end
            end
        end
    end
    Style(prev,paging and (paging.PrevPageButton or paging.PreviousPageButton),"Prev")
    Style(nextButton,paging and paging.NextPageButton,"Next")
    prev:ClearAllPoints();prev:SetPoint("LEFT",label,"RIGHT",10,0)
    nextButton:ClearAllPoints();nextButton:SetPoint("LEFT",prev,"RIGHT",10,0)
    prev:SetEnabled(index>1);nextButton:SetEnabled(index<count)
end
