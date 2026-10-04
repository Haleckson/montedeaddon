-- =====================================================================
-- 本文件是 PeiFang 核心库 (LibStub: "PeiFang-1.0") 的「消费端」：
-- 提供 /pf 斜杠命令 与 可拖拽搜索面板。其它插件若不想要 UI，
-- 只需加载 PeiFang.lua（库）即可，不需要本文件。
--
-- 查询方式（游戏内输入）：
--   /pf                 打开 / 关闭搜索面板
--   /pf 3862            按 spellID 查询
--   /pf 14048           按 itemID 查询
--   /pf 符文布          按名称模糊查询
--
-- 面板布局（全部用游戏内实时数据，不依赖 PeiFangData 里的 itemName）：
--   以「配方树」形式展示：根节点=查询到的产出物（图标+名字+质量染色）；
--   其材料逐行列出（每行一个），若该材料本身可由专业制造，则作为子节点继续递归展开，
--   直到无法通过专业制造为止，形成树状分级结构。
--   每个有子节点的层级前有一个 +/- 折叠按钮，点击可展开/折叠该层级。
--   节点图标左上角角标：子节点显示「满足需求所需的总数量」(>1，已按父节点每次产出数折合配方次数)，根节点显示「一次产出数量」(>1)；数量为 1 不显示；
--   每行有斑马底色（偶/奇行透明度不同），鼠标移到任一行整行高亮，便于区分相邻行；
--   悬停图标/名字显示物品信息；点击（拍卖行开着 -> 按名字搜索，否则 -> 链接插入聊天输入框；
--   节点有配方者发 spelllink，纯材料发 itemlink）。
--   （无 itemID 的纯法术配方作为根节点单行显示：法术名，垂直居中，无图标/来源/技能点数、无子节点）
-- =====================================================================
local lib = LibStub("PeiFang-1.0") --[[@as PeiFangLib]]
assert(lib, "PeiFang-1.0 库未加载，请确认 PeiFang.lua 已先于 PeiFangUI.lua 加载")
local ADDON = ...
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local PFData = LibStub("PeiFangData-1.0")  -- 数据表库（含 update 抓取日期字段）
local UI = {}
local PF = "|cFF33CCFF[配方]|r"
local addonVersion = GetAddOnMetadata(ADDON, "Version")
-- 技能 ID -> 专业名称（用于显示名前缀，如「锻造：xxx」）
-- 取国服/零售通用 trade skill line ID；未知的 skillID 不显示前缀
local SKILL_NAMES = {
    [164] = "锻造",   [165] = "制皮",   [171] = "炼金",   [182] = "草药学",
    [185] = "烹饪",   [186] = "采矿",   [197] = "裁缝",   [202] = "工程学",
    [333] = "附魔",   [356] = "钓鱼",   [393] = "剥皮",   [755] = "珠宝加工",
    [773] = "铭文",   [794] = "考古学", [129] = "急救",
}

-- 专业名称前缀：已知 skillID 返回「专业名：」，否则返回空串
local function ProfessionPrefix(skillID)
    local n = skillID and SKILL_NAMES[skillID]
    return n and (n .. "：") or ""
end

-- 专业列表不内置：下拉框直接遍历 PeiFangData 的各 skillID（即已收录配方的专业），
-- 图标/名称用 C_TradeSkillUI.GetTradeSkillTexture / GetTradeSkillDisplayName 动态获取。
-- 这样只列出有数据的专业，且随服务器专业集合自动变化，无需维护 PROFESSIONS 表。

local INDENT    = 18   -- 树每级缩进像素
local NODE_ICON = 24   -- 树节点图标尺寸
local GAP       = 2
local HL_A      = 0.20    -- 悬停高亮透明度
local QUESTIONMARK = "Interface\\Icons\\INV_Misc_QuestionMark"   -- 物品/法术图标兜底

local panel
local msgText    -- 无结果/进度/报错 提示文本（覆盖在滚动区之上，默认隐藏）
local currentTrees = {}   -- 当前渲染的配方树（折叠状态保存在节点上；虚拟滚动按此扁平化）

-- ------------------------- 交互辅助 -------------------------

-- 发送链接：
--   1) 有激活的聊天输入框 -> 直接插入到光标处（ChatEdit_InsertLink 返回 true）
--   2) 没有激活的输入框 -> 打开默认聊天输入框并把链接填进去（ChatFrame_OpenChat）
local function SendToChat(link)
    if not link then return end
    if ChatEdit_InsertLink(link) then return end
    ChatFrame_OpenChat(link)
end

-- 悬停显示物品信息（数据已加载，可直接按 ID 取）
local function ShowItemTip(frame, itemID)
    if not itemID then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(itemID)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("AH 窗口打开：点击直接搜索", 0.6, 0.8, 1.0)
    GameTooltip:AddLine("AH 窗口关闭：点击发送配方或物品链接到聊天窗口", 0.6, 0.8, 1.0)
    GameTooltip:Show()
end

local function HideTip()
    GameTooltip:Hide()
end

-- 拍卖行打开时，按物品名在「购买(Browse)」页签搜索。
-- 说明：经对比零售与无限服 Blizzard_AuctionHouseUI 源码，两者的 AuctionHouseFrame:SetSearchText
--       同源（无限服 toc 亦加载 mainline 的 Shared 模块），均「只填词、不触发搜索」；真正发起查询的是
--       手动点搜索钮 / 回车，即调用 SearchBar:StartSearch()。故这里填词后必须显式 StartSearch()，
--       而非依赖 OnTextChanged 自动搜（旧版「填字与发查询同帧会打断」的判断已证伪，故移除原 0.05s 帧延迟）。
--       若 SetSearchText 未生效（返回非 true），则直接用 C_AuctionHouse.SendBrowseQuery 兜底，
--       不依赖搜索框文本，保证一定能搜到。仅保留「节流系统未就绪」时的 0.5s 等待。
local function AH_SearchByName(name)
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then return end
    if not (C_AuctionHouse and C_AuctionHouse.SendBrowseQuery) then return end
    if not (name and name ~= "") then return end

    -- 先切到「购买(Browse)」页签（购买页签通常是第一个；失败不影响实际搜索）
    pcall(function()
        local ts = AuctionHouseFrame.TabSystem
        if ts and ts.tabs and ts.tabs[1] and ts.tabs[1].Click then
            ts.tabs[1]:Click()
        end
    end)

    -- 真正发起搜索（立即执行，无额外帧延迟）：
    --   1) SetSearchText 填词成功 -> StartSearch() / 点搜索钮发 Browse 查询；
    --   2) SetSearchText 未生效 -> 直接 C_AuctionHouse.SendBrowseQuery 兜底（不依赖搜索框文本）。
    local function doSearch()
        local setOk, setRet = pcall(function()
            if AuctionHouseFrame.SetSearchText then
                return AuctionHouseFrame:SetSearchText(name)
            elseif AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox then
                AuctionHouseFrame.SearchBar.SearchBox:SetText(name)
                return true
            end
            return false
        end)
        local textApplied = (setOk and setRet == true)

        if textApplied then
            -- 填词成功：显式发起 Browse 搜索（等价于手动点搜索钮 / 回车）
            pcall(function()
                if AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.StartSearch then
                    AuctionHouseFrame.SearchBar:StartSearch()
                elseif AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchButton then
                    AuctionHouseFrame.SearchBar.SearchButton:Click()
                else
                    C_AuctionHouse.SendBrowseQuery({
                        searchString = name,
                        sorts = {
                            { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false },
                            { sortOrder = Enum.AuctionHouseSortOrder.Name,  reverseSort = false },
                        },
                    })
                end
            end)
        else
            -- 填词失败：直接发 Browse 查询兜底，不依赖搜索框文本
            pcall(function()
                C_AuctionHouse.SendBrowseQuery({
                    searchString = name,
                    sorts = {
                        { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false },
                        { sortOrder = Enum.AuctionHouseSortOrder.Name,  reverseSort = false },
                    },
                })
            end)
        end
    end

    -- 仅针对「服务器节流就绪」做等待：未就绪时查询会被节流丢弃，故延迟 0.5s；否则立即搜索。
    if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        C_Timer.After(0.5, doSearch)
    else
        doSearch()
    end
end

-- 点击物品图标：AH 打开 -> 在 AH 购买页签按名字搜索；否则 -> 把物品链接插入聊天输入框
local function OnItemClick(itemID, name, link)
    if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
        AH_SearchByName(name)
    else
        SendToChat(link)
    end
end

-- 创建一个图标按钮（可带右下角数量角标、悬停提示、点击行为）
local function MakeIcon(parent, size, iconID, outCount, needCount, onEnter, onLeave, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b:SetNormalTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    -- 高亮层：铺满整个按钮。默认 UI-Common-MouseHilight 是圆环贴图（四周透明），
    -- hover 时只亮内圈、不覆盖全按钮；这里用显式全尺寸半透明叠加层，确保整块点亮。
    local hl = b:CreateTexture(nil, "ARTWORK")
    hl:SetAllPoints(b)
    hl:SetColorTexture(1, 1, 1, 0.28)
    hl:SetBlendMode("ADD")
    b:SetHighlightTexture(hl)
    if onEnter  then b:SetScript("OnEnter",  onEnter)  end
    if onLeave  then b:SetScript("OnLeave",  onLeave)  end
    if onClick  then b:SetScript("OnClick",  onClick)  end
    -- 左上角角标：本节点一次配方能产出的数量（即下一级制造能产出的数量），>1 才显示
    if outCount and outCount > 1 then
        local badge = b:CreateFontString(nil, "OVERLAY")
        badge:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
        badge:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
        badge:SetText(outCount)
        b.outBadge = badge
    end
    -- 右下角角标：上一级需要本材料的总数量，>1 才显示（根节点无此值故不显示）
    if needCount and needCount > 1 then
        local badge = b:CreateFontString(nil, "OVERLAY")
        badge:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
        badge:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
        badge:SetText(needCount)
        b.needBadge = badge
    end
    return b
end

-- ------------------------- 单行渲染 -------------------------

-- 技能点数（彩色数字，不画图块）：把 rec.colors 的 r1~r4 渲染为对应颜色的数字，横向排列
local function RenderColorNumbers(parent, x, topY, colors)
    if not colors then return end
    local COLOR_TIERS = {
        { "r1", 1.00, 0.25, 0.25 },  -- 红(橙) 技能点
        { "r2", 1.00, 0.85, 0.00 },  -- 黄
        { "r3", 0.20, 0.85, 0.20 },  -- 绿
        { "r4", 0.60, 0.60, 0.60 },  -- 灰
    }
    local parts = {}
    for _, t in ipairs(COLOR_TIERS) do
        local v = colors[t[1]]
        if v then
            local hex = string.format("FF%02X%02X%02X",
                math.floor(t[2] * 255 + 0.5),
                math.floor(t[3] * 255 + 0.5),
                math.floor(t[4] * 255 + 0.5))
            tinsert(parts, "|c" .. hex .. v .. "|r")
        end
    end
    if #parts == 0 then return end
    local cfs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- 字号再调小一点（相对 GameFontNormalSmall 默认的 10 降到 9）
    local f, _, fl = cfs:GetFont()
    if f then cfs:SetFont(f, 10, fl) end
    cfs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -topY)
    cfs:SetText(table.concat(parts, "   "))
end

-- 通过 itemID 找可制造的配方（取第一条）；找不到返回 nil（即该物品为原材料/非制造产出）
local function FindRecipe(itemID)
    if not itemID then return nil end
    local list = lib:GetByItemID(itemID)
    if list and #list > 0 then return list[1] end
    return nil
end

-- 递归构建配方树：node = 某产出物（itemID 可能为空=纯法术），其 children 为材料；
-- 材料若本身可制造则继续展开，否则作为叶子。visited 防止循环（如 A 的材料又含 A 自身）。
-- 关键：向下传递材料数量时，按父节点「每次配方产出 outCount 个」折合制造次数，
--       即 子材料需要数 = ceil(父需要数 / 父每次产出数) × 每次消耗数，避免重复计数。
local function BuildNode(rec, needCount, depth, visited)
    local node = {
        itemID    = rec.itemID,            -- 可能为空（纯法术配方，无产出物）
        needCount = needCount,             -- 满足上层需求所需的本物品总数量（根节点为 nil）
        outCount  = rec.itemCount,         -- 本配方一次产出的数量（用于根节点角标）
        spellID   = rec.spellID,
        skillID   = rec.skillID,
        source    = rec.source,
        colors    = rec.colors,
        depth     = depth,
        isSpell   = (rec.itemID == nil),
        expanded  = (depth == 0),          -- 默认只展开根节点，其余层级由用户点击展开
    }
    if rec.reagents and #rec.reagents > 0 then
        node.children = {}
        -- 制造本节点所需的「配方次数」：
        --   根节点 = 1 次（查询的配方本身，按「一次产出」计，角标另显 outCount）；
        --   子节点 = 向上取整(需要的物品数 / 每次产出数)，因为一次制造可产出 outCount 个。
        local outCount = (rec.itemCount and rec.itemCount > 0) and rec.itemCount or 1
        local crafts = (depth == 0) and 1 or math.ceil(needCount / outCount)
        -- rec.reagents 为扁平数组 { itemID, needCount, itemID, needCount, ... }（数据文件紧凑化，降内存）
        for k = 1, #rec.reagents, 2 do
            local mid   = rec.reagents[k]
            local mneed = rec.reagents[k + 1] or 1
            local childNeed = crafts * mneed
            local childRec = FindRecipe(mid)
            if childRec and not visited[mid] then
                visited[mid] = true
                tinsert(node.children, BuildNode(childRec, childNeed, depth + 1, visited))
                visited[mid] = nil
            else
                -- 原材料（无配方）或循环保护：作为叶子节点，needCount 为已折合的总数量
                tinsert(node.children, { itemID = mid, needCount = childNeed, depth = depth + 1,
                    expanded = false })
            end
        end
    end
    return node
end

-- 收集整棵树里所有需要加载的物品 ID（去重），用于「全部就绪后再渲染」
local function CollectItems(node, set)
    if node.itemID then set[node.itemID] = true end
    if node.children then
        for _, c in ipairs(node.children) do CollectItems(c, set) end
    end
end

-- 渲染单个树节点（含其子树，若展开）；返回 下一行起始 y 与 下一行序号
-- rowIndex 用于斑马底色：偶/奇行透明度不同，方便区分相邻行。
-- ------------------------- 虚拟化滚动：行模板 + 扁平化 -------------------------
-- 不再为每个节点 CreateFrame 建一行（那样行数多时全部控件常驻、滚动卡顿）。
-- 改用 Blizzard 标准虚拟滚动：WowScrollBoxList + SetDataProvider + SetElementInitializer，
-- 只实例化视口内约 20 行并滚动时复用（行高固定，ScrollBox 自动回收离屏行）。
-- 每个节点在「物品数据全部加载完」后解析一次图标/名字/链接（ResolveNode），
-- 扁平化（BuildFlatList，尊重展开状态）成数组交给数据提供器；行帧复用只更新显示。

-- 复用行帧的子控件（每帧只建一次）：整行底纹 + 折叠按钮 + 图标按钮(含角标) + 名称
local function InitRowFrame(frame)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(1, 1, 1, 1)

    frame.toggle = CreateFrame("Button", nil, frame)
    frame.toggle:SetSize(14, 14)
    frame.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    frame.toggle.arrow = frame.toggle:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.toggle.arrow:SetAllPoints(frame.toggle)
    frame.toggle.arrow:SetJustifyH("CENTER"); frame.toggle.arrow:SetJustifyV("MIDDLE")
    frame.toggle:SetScript("OnClick", function()
        local nd = frame.node
        if nd and nd.children and #nd.children > 0 then
            nd.expanded = not nd.expanded
            UI.RebuildFlat()   -- 折叠/展开无需重新加载数据，重扁平化即可
        end
    end)

    frame.icon = CreateFrame("Button", nil, frame)
    frame.icon:SetSize(NODE_ICON, NODE_ICON)
    local hl = frame.icon:CreateTexture(nil, "ARTWORK")
    hl:SetAllPoints(frame.icon); hl:SetColorTexture(1, 1, 1, 0.28); hl:SetBlendMode("ADD")
    frame.icon:SetHighlightTexture(hl)
    frame.icon.outBadge = frame.icon:CreateFontString(nil, "OVERLAY")
    frame.icon.outBadge:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 1, -1)
    frame.icon.outBadge:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
    frame.icon.needBadge = frame.icon:CreateFontString(nil, "OVERLAY")
    frame.icon.needBadge:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", -1, 1)
    frame.icon.needBadge:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
    frame.icon:SetScript("OnEnter", function(self)
        local nd = frame.node
        if not nd or not nd.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if nd.isSpell then GameTooltip:SetHyperlink(nd.link) else ShowItemTip(self, nd.itemID) end
        GameTooltip:Show()
    end)
    frame.icon:SetScript("OnLeave", HideTip)
    frame.icon:SetScript("OnClick", function()
        local nd = frame.node
        if nd then OnItemClick(nd.itemID, nd.dispName, nd.link) end
    end)

    frame.name = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.name:EnableMouse(true)
    frame.name:SetScript("OnMouseUp", function()
        local nd = frame.node
        if nd then OnItemClick(nd.itemID, nd.dispName, nd.link) end
    end)

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function() frame.bg:SetAlpha(HL_A) end)
    frame:SetScript("OnLeave", function() frame.bg:SetAlpha(frame.baseAlpha or 0) end)
    frame:SetScript("OnMouseUp", function()
        local nd = frame.node
        if nd then OnItemClick(nd.itemID, nd.dispName, nd.link) end
    end)

    frame.built = true
end

-- 复用行帧：每次分配给新节点时刷新显示（不新建子控件）
local function UpdateRowFrame(frame, node)
    frame.node = node
    local indent = node.depth * INDENT
    local xIcon  = indent + 16
    local rowH   = NODE_ICON + GAP

    frame.baseAlpha = (node._rowIndex % 2 == 0) and 0.10 or 0.0
    frame.bg:SetAlpha(frame.baseAlpha)

    if node.children and #node.children > 0 then
        frame.toggle:Show()
        frame.toggle:SetPoint("TOPLEFT", frame, "TOPLEFT", indent, -5)
        frame.toggle.arrow:SetText(node.expanded and "-" or "+")
    else
        frame.toggle:Hide()
    end

    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", xIcon, -((rowH - NODE_ICON) / 2))
    frame.icon:SetNormalTexture(node.iconTex or QUESTIONMARK)
    if node.outCount and node.outCount > 1 then frame.icon.outBadge:SetText(node.outCount); frame.icon.outBadge:Show() else frame.icon.outBadge:Hide() end
    if node.needCount and node.needCount > 1 then frame.icon.needBadge:SetText(node.needCount); frame.icon.needBadge:Show() else frame.icon.needBadge:Hide() end

    frame.name:SetPoint("LEFT", frame.icon, "RIGHT", 6, 0)
    frame.name:SetText(ProfessionPrefix(node.skillID) .. node.dispName)
    if node.isSpell then
        frame.name:SetTextColor(1, 0.82, 0)
    elseif node.quality and ITEM_QUALITY_COLORS[node.quality] then
        local qc = ITEM_QUALITY_COLORS[node.quality]
        frame.name:SetTextColor(qc.r, qc.g, qc.b)
    else
        frame.name:SetTextColor(1, 1, 1)
    end
end

-- 解析节点显示数据（图标/名字/链接/品质），物品加载全部完成后调用一次；
-- 虚拟滚动的行帧只读取这些已解析字段，不在滚动时再做异步加载。
local function ResolveNode(node)
    if node.isSpell then
        local sInfo = node.spellID and C_Spell.GetSpellInfo(node.spellID)
        node.iconTex  = (sInfo and (sInfo.iconID or sInfo.icon)) or QUESTIONMARK
        node.dispName = (sInfo and sInfo.name) or ("#" .. (node.spellID or "?"))
        node.link     = node.spellID and C_Spell.GetSpellLink(node.spellID)
        node.quality  = nil
    else
        local iName, iLink, iRarity, _, _, _, _, _, _, iTex = C_Item.GetItemInfo(node.itemID)
        node.iconTex  = iTex or QUESTIONMARK
        node.dispName = iName or ("#" .. (node.itemID or "?"))
        node.link     = iLink
        node.quality  = iRarity
    end
    if node.children then
        for _, c in ipairs(node.children) do ResolveNode(c) end
    end
end

-- 把配方树扁平化为「可见顺序」数组（只展开 expanded 的子节点），并为每行写入 _rowIndex 供斑马底色
local function BuildFlatList(trees)
    local flat, idx = {}, 0
    local function walk(n)
        idx = idx + 1
        n._rowIndex = idx
        flat[#flat + 1] = n
        if n.expanded and n.children then
            for _, c in ipairs(n.children) do walk(c) end
        end
    end
    for _, root in ipairs(trees) do walk(root) end
    return flat
end

-- 折叠/展开后：重新扁平化并刷新数据提供器（保留滚动位置）
function UI.RebuildFlat()
    if not panel or not currentTrees then return end
    panel.scroll:SetDataProvider(CreateDataProvider(BuildFlatList(currentTrees)), true)
end

-- ------------------------- 搜索面板 -------------------------

-- 选中「专业」下拉框中的某专业：取 PeiFangData[skillID] 全部配方，按名字升序后渲染。
-- 该专业无数据（PeiFangData 未收录）时给出可见提示，而不是空白。
local function ShowProfessionRecipes(prof)
    local data = lib:GetData()
    local recipes = data and data[prof.id]
    if not recipes then
        UI.ShowMessage(PF .. " 专业「" .. prof.name .. "」暂无配方数据（PeiFangData 未收录）")
        return
    end
    local list = {}
    for _, rec in pairs(recipes) do
        tinsert(list, rec)
    end
    if #list == 0 then
        UI.ShowMessage(PF .. " 专业「" .. prof.name .. "」暂无配方数据")
        return
    end
    -- 按名字升序（itemName 优先；纯法术配方无 itemName 时排到末尾）
    table.sort(list, function(a, b)
        local an = a.itemName or "\255"
        local bn = b.itemName or "\255"
        return an < bn
    end)
    local ok, err = pcall(UI.LoadAndRender, list)
    if not ok then
        UI.ShowMessage(PF .. " 渲染出错: " .. tostring(err))
    end
end

local function BuildPanel()
    if panel then return end
    local w, h = 440, 500
    -- 注意：零售 9.0+ 的帧若要使用 SetBackdrop/SetBackdropColor，必须混入 BackdropTemplate，
    -- 否则 f.SetBackdrop 为 nil、下面 if 分支不执行，背景永远不透明。
    local f = CreateFrame("Frame", "PeiFangFrame", UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    -- f:RegisterForDrag("LeftButton")
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnMouseDown",  function(self) self:StartMoving() end)
    f:Hide()

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0, 0, 0, 1)
        f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    else
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.80)
        local bd = f:CreateTexture(nil, "BORDER")
        bd:SetAllPoints(); bd:SetColorTexture(0.3, 0.3, 0.3, 1)
    end

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("配方查询 (PeiFang)——|cffffffff"..addonVersion)

    local src = f:CreateFontString(nil, "ARTWORK")
    src:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -34)
    src:SetJustifyH("LEFT")
    src:SetFont(GameFontNormal:GetFont(), 12)
    src:SetText("数据来源：wowhead，更新日期：" .. ((PFData and PFData.update) or "未知"))
    src:SetTextColor(0.7, 0.7, 0.7)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)

    -- 左上角「使用说明」信息按钮：悬停显示插件用法与其它插件引用方式
    local infoBtn = CreateFrame("Button", nil, f)
    infoBtn:SetSize(18, 18)
    infoBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    infoBtn:SetNormalTexture(616343)
    -- local infoTex = infoBtn:CreateTexture(nil, "ARTWORK")
    -- infoTex:SetAllPoints(infoBtn)
    -- infoTex:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    local infoHL = infoBtn:CreateTexture(nil, "HIGHLIGHT")
    infoHL:SetAllPoints(infoBtn)
    infoHL:SetColorTexture(1, 1, 1, 0.30)
    infoHL:SetBlendMode("ADD")
    infoBtn:SetHighlightTexture(infoHL)
    infoBtn:SetScript("OnEnter", function(self)
        -- 提示框右上角对齐搜索面板(f)左上角，向左上方展开
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 0)
        GameTooltip:SetText("配方(PeiFang)查询使用说明", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("支持查询所有专业配方(数据来源：wowhead)", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("斜杠命令：", 1, 0.85, 0.4)
        GameTooltip:AddLine("　/pf            打开 / 关闭搜索面板", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("　/pf 14048      按 itemID 查询", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("　/pf 3862       按 spellID 查询", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("　/pf 符文布     按名称模糊查询", 0.85, 0.85, 0.85)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("面板内：输入物品ID/spellID/名称，回车或点「查询」；", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("拍卖行开启时，点图标 / 名称可直接搜索。", 0.85, 0.85, 0.85)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("其它插件引用方法（LibStub）：", 1, 0.85, 0.4)
        GameTooltip:AddLine("　local PeiFang = LibStub(\"PeiFang-1.0\")", 0.5, 0.9, 0.5)
        GameTooltip:AddLine("　local recs = PeiFang:GetByItemID(14048)   -- 返回 {record, ...}", 0.5, 0.9, 0.5)
        GameTooltip:AddLine("　local rec  = PeiFang:GetBySpellID(3862)   -- 返回 record | nil", 0.5, 0.9, 0.5)
        GameTooltip:AddLine("　local list = PeiFang:SearchByName(\"符文布\")-- 返回 {record, ...}", 0.5, 0.9, 0.5)
        GameTooltip:AddLine("　local r, k = PeiFang:Lookup(\"3862\")       -- 自动判别 spell/item/name", 0.5, 0.9, 0.5)
        GameTooltip:AddLine("　local data = PeiFang:GetData()            -- 原始 PeiFangData 嵌套表", 0.5, 0.9, 0.5)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("作者：潇湘凌风")
        GameTooltip:Show()
    end)
    infoBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 左侧「专业」下拉框（WowStyle1DropdownTemplate）：图标 + 名字，按 skillID 升序。
    -- 选中后从 PeiFangData[skillID] 取该专业全部配方，按名字升序渲染。
    local profDropdown = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    profDropdown:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -50)
    profDropdown:SetSize(130, 24)
    profDropdown:SetDefaultText("选择专业")
    local selectedSkill = nil
    profDropdown:SetupMenu(function(_, rootDescription)
        -- 专业列表来自 PeiFangData 的 skillID 集合，图标/名称由 C_TradeSkillUI 动态获取。
        -- 按 skillID 升序；每个迭代用局部变量 sel/name 承接，避免 Lua 5.1 for 循环变量单一 upvalue 的闭包陷阱。
        local ids = {}
        for id, data in pairs(PFData) do
            if type(data) == "table" and next(data) then
                table.insert(ids, id)
            end
        end
        sort(ids)
        for _, id in ipairs(ids) do
            local sel  = id
            local name = C_TradeSkillUI.GetTradeSkillDisplayName(id) or ("专业 #" .. id)
            local icon = C_TradeSkillUI.GetTradeSkillTexture(id) or QUESTIONMARK
            local text = ("|T%s:16:16:0:0|t %s"):format(icon, name)
            rootDescription:CreateRadio(text,
                function() return selectedSkill == sel end,
                function()
                    selectedSkill = sel
                    ShowProfessionRecipes({ id = sel, name = name })
                end)
        end
    end)

    -- 标准 SearchBoxTemplate：自带左侧搜索图标(searchIcon)、清空按钮(clearButton)、
    -- 灰字占位(Instructions，空内容时自动显示)。占位/图标/清空按钮均由模板原生脚本处理，
    -- 这里只补充「聚焦全选文本」与「回车提交」，不覆盖模板原生的 OnTextChanged / OnEditFocusLost / 占位逻辑。
    -- 位置右移给左侧专业下拉框让位（下拉 140 + 间距 6 + 本框 180 = 326，查询钮再接右侧）。
    local edit = CreateFrame("EditBox", "PeiFangInput", f, "SearchBoxTemplate")
    edit:SetSize(200, 24)
    edit:SetPoint("TOPLEFT", f, "TOPLEFT", 152, -50)
    edit:SetAutoFocus(false)
    -- 自定义中文占位提示（模板默认是全局字符串 SEARCH；OnLoad 已设过，这里覆盖为插件文案）
    edit.Instructions:SetText("物品ID/技能ID/名称")

    -- 聚焦时：恢复模板原生行为（图标高亮 + 显示清空按钮），并选中全部文本方便直接覆盖输入。
    -- 不调用原生 SearchBoxTemplate_OnEditFocusGained，改为内联其两条逻辑，避免依赖全局函数名。
    edit:SetScript("OnEditFocusGained", function(self)
        if self.searchIcon then self.searchIcon:SetVertexColor(1, 1, 1) end
        if self.clearButton then self.clearButton:Show() end
        self:HighlightText()
    end)

    -- 回车提交查询（模板默认 OnEnterPressed 只 ClearFocus，不搜索）；空内容不搜
    local function submitQuery()
        local t = edit:GetText()
        if t == "" then
            edit:ClearFocus()
            return
        end
        UI.presentResult(t)
        edit:ClearFocus()
    end
    edit:SetScript("OnEnterPressed", submitQuery)

    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(64, 24)
    btn:SetPoint("LEFT", edit, "RIGHT", 6, 0)
    btn:SetText("查询")
    btn:SetScript("OnClick", submitQuery)


    -- 现代 WoW 虚拟滚动：WowScrollBoxList（ScrollBoxListMixin，支持数据提供器虚拟化）
    -- + MinimalScrollBar。只实例化视口内约 20 行并滚动时复用，行数再多也不卡；
    -- 行帧由 SetElementInitializer 创建/复用（见上方 InitRowFrame / UpdateRowFrame）。
    local scroll = CreateFrame("Frame", "PeiFangScrollBox", f, "WowScrollBoxList")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -86)   -- 上移：与上方专业/搜索行（底部约 -74）保持约 12px 行间距
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 14)   -- 右侧留 11px：滚动条往左移 5px、并与行保持 2px 间隙不重叠

    local scrollBar = CreateFrame("EventFrame", "PeiFangScrollBar", f, "MinimalScrollBar")

    -- 选择「列表视图」工厂：WowScrollBoxList（ScrollBoxListMixin）在 SetView 里要求 view 是完整
    -- ListView（带 RegisterCallback / OnDataChanged / SetElementExtent / SetElementInitializer）。
    -- 拆分版客户端用 CreateScrollBoxListLinearView（真正的列表视图）；旧版客户端没有该函数时，
    -- CreateScrollBoxLinearView 本身即列表视图，直接回退使用。
    local scrollView = (CreateScrollBoxListLinearView and CreateScrollBoxListLinearView())
                        or CreateScrollBoxLinearView()
    scrollView:SetPanExtent(40)                  -- 鼠标滚轮一次滚动幅度
    -- 设置固定行高：不同客户端版本 SetElementExtent 可用性不同，逐一兜底
    -- （零售/经典：scrollView:SetElementExtent；部分版本仅有 SetElementExtentCalculator；
    --   个别版本需走 scroll:SetElementExtent；再不行直接写 view.elementExtent 字段，布局按此读取）
    if scrollView.SetElementExtent then
        scrollView:SetElementExtent(NODE_ICON + GAP)
    elseif scrollView.SetElementExtentCalculator then
        scrollView:SetElementExtentCalculator(function() return NODE_ICON + GAP end)
    elseif scroll.SetElementExtent then
        scroll:SetElementExtent(NODE_ICON + GAP)
    else
        scrollView.elementExtent = math.max(NODE_ICON + GAP, 1)
    end

    if scrollView.SetElementInitializer then
        scrollView:SetElementInitializer("Frame", function(frame, node)
            if not frame.built then InitRowFrame(frame) end
            UpdateRowFrame(frame, node)
        end)
    elseif scrollView.SetElementFactory then
        scrollView:SetElementFactory(function(factory, elementData)
            factory("Frame", function(frame, node)
                if not frame.built then InitRowFrame(frame) end
                UpdateRowFrame(frame, node)
            end)
        end)
    end

    ScrollUtil.InitScrollBoxWithScrollBar(scroll, scrollBar, scrollView)
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scroll, scrollBar)  -- 不需要滚动时隐藏滚动条
    -- 关键修复：InitScrollBoxWithScrollBar 会重新把滚动条锚定到 scroll 右缘，导致与行重叠；
    -- 这里在初始化之后重新显式锚定：滚动条位于 scroll 右侧外 2px，不与行重叠。
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT",    scroll, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 0)
    scrollBar:SetWidth(16)

    -- 无结果/进度/报错 提示文本（覆盖在滚动区之上，默认隐藏）
    msgText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    msgText:SetPoint("TOPLEFT", scroll, "TOPLEFT", 12, -12)
    msgText:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", -12, 12)
    msgText:SetJustifyH("LEFT"); msgText:SetJustifyV("TOP")
    msgText:SetWordWrap(true)
    msgText:Hide()

    f.edit      = edit
    f.scroll    = scroll
    f.scrollBar = scrollBar
    f.msgText   = msgText
    panel = f
end
-- ------------------------- 数据加载（全部就绪后才渲染） -------------------------


local function RenderResults()
    if not panel then BuildPanel() end
    -- 物品加载已全部完成：解析每个节点的图标/名字/链接（一次），再扁平化交给虚拟滚动
    for _, root in ipairs(currentTrees) do
        pcall(ResolveNode, root)
    end
    local flat = BuildFlatList(currentTrees)
    if #flat == 0 then
        panel.scroll:SetDataProvider(CreateDataProvider({}))
        UI.ShowMessage(PF .. " 无有效配方可显示（数据可能不完整或记录格式异常）")
        return
    end
    msgText:Hide()
    panel.scroll:SetDataProvider(CreateDataProvider(flat))
    panel:Show()
end
UI.RenderResults = RenderResults

-- 物品加载监听器（文件级、只建一次）：监听 ITEM_DATA_LOAD_RESULT 事件，对「本次请求的物品」
-- 无论加载成功(success=true)还是失败(success=false)都递减 pending 并推进渲染。
-- 原因：某些物品服务器不再返回数据（如 itemID 17：DoesItemExistByID 为 true，但 success:false、
-- GetItemInfo 永不返回），ContinueOnItemLoad 的回调永不触发，会导致 pending 永不到 0、渲染卡死、
-- 表现为搜索「没有任何反应」。改用事件后每次请求都有确定的成功/失败回调，彻底消除卡死。
-- 参考：https://warcraft.wiki.gg/wiki/ItemMixin （Warning 段）与 https://warcraft.wiki.gg/wiki/ITEM_DATA_LOAD_RESULT
local itemLoadState = nil   -- 当前搜索的加载状态：{ pending, loadSet, finish }
local itemLoadFrame = CreateFrame("Frame")
itemLoadFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
itemLoadFrame:SetScript("OnEvent", function(_, _, iid, success)
    if not itemLoadState then return end
    if not itemLoadState.loadSet[iid] then return end   -- 非本次请求的物品（旧搜索遗留等）忽略
    itemLoadState.loadSet[iid] = nil
    itemLoadState.pending = itemLoadState.pending - 1
    if itemLoadState.pending <= 0 then
        local fn = itemLoadState.finish
        itemLoadState = nil
        fn()
    end
end)

local function LoadAndRender(records)
    if not panel then BuildPanel() end
    -- 构建配方树（已含循环保护），并收集整棵树需要加载的全部物品 ID
    currentTrees = {}
    local itemSet = {}
    for _, rec in ipairs(records) do
        -- 逐条 pcall：某条记录（如 reagents 异常、非法 itemID）构建失败时，跳过它而非拖垮整批结果
        local ok, root = pcall(BuildNode, rec, nil, 0, {})
        if ok and root then
            tinsert(currentTrees, root)
            CollectItems(root, itemSet)
        end
    end
    if #currentTrees == 0 then
        -- 全部记录都无法构建（数据可能不完整）→ 给出可见提示，而不是空白
        UI.ShowMessage(PF .. " 无有效配方可显示（数据可能不完整或记录格式异常）")
        return
    end

    local finished = false
    local function finish()
        if finished then return end
        finished = true
        RenderResults()
    end

    -- 本次需要加载的物品（去重后集合），用于事件回调中判定「是否本次请求」
    local loadSet = {}
    for iid in pairs(itemSet) do loadSet[iid] = true end

    if next(loadSet) == nil then
        finish()   -- 无需加载任何物品，直接渲染
        return
    end

    -- 用 ITEM_DATA_LOAD_RESULT 事件统一推进（成功/失败都触发），不再依赖 ContinueOnItemLoad 的回调
    -- （后者对服务器不返回数据的物品永不回调，会卡死）。每个 itemID 用 ContinueWithCancelOnItemLoad
    -- 触发加载请求，回调空函数即可——递减交给事件处理。
    -- 关键（两阶段）：必须先把 pending 全部计数完，再发加载请求。若边计数边请求，当物品数据
    -- 已缓存时 ITEM_DATA_LOAD_RESULT 会在 ContinueWithCancelOnItemLoad 调用过程中同步触发，
    -- pending 被提前减到 0、itemLoadState 置 nil，循环下一轮再索引它就崩
    -- （表现为“渲染出错: attempt to index upvalue 'itemLoadState' (a nil value)”）。
    itemLoadState = { pending = 0, loadSet = loadSet, finish = finish }
    for _ in pairs(loadSet) do
        itemLoadState.pending = itemLoadState.pending + 1
    end
    -- 用快照列表发请求：事件同步触发时回调会从 loadSet 移除条目，直接 pairs(loadSet)
    -- 遍历同一张表可能跳过个别物品、导致其数据不加载（渲染时只能显示 #itemID 兜底）。
    local list = {}
    for iid in pairs(loadSet) do list[#list + 1] = iid end
    for _, iid in ipairs(list) do
        if not itemLoadState then break end   -- 请求过程中全部同步完成（itemLoadState 已置 nil），提前结束
        local it = Item:CreateFromItemID(iid)
        it:ContinueWithCancelOnItemLoad(function() end)
    end
    -- 超时兜底：极端情况下事件未触发（如服务器异常），3 秒后强制渲染；
    -- 未加载成功的物品在渲染时 GetItemInfo 返回 nil，已用 "#itemID" + 问号图标兜底，不会崩。
    C_Timer.After(3, function()
        if itemLoadState and itemLoadState.loadSet == loadSet then
            itemLoadState = nil
            finish()
        end
    end)
end
UI.LoadAndRender = LoadAndRender
-- 简单文本提示（未找到等）
-- 无结果 / 进度 / 报错 提示：覆盖在滚动区之上的文本（虚拟滚动列表清空）
local function ShowMessage(msg)
    if not panel then BuildPanel() end
    panel.scroll:SetDataProvider(CreateDataProvider({}))
    msgText:SetText(msg)
    msgText:Show()
    panel:Show()
end
UI.ShowMessage = ShowMessage
local function PeiFang_TogglePanel()
    if not panel then BuildPanel() end
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

-- ------------------------- 结果入口（声明于其依赖函数之后，且为局部函数） -------------------------

-- 查询入口：支持 物品ID / 技能ID / 名称。供搜索面板按钮与斜杠命令调用。
-- 本函数为局部函数，不会污染全局 _G；其调用的 PeiFang_TogglePanel / ShowMessage /
-- LoadAndRender 均已在上方声明。本函数的调用方（BuildPanel 按钮回调、SlashCmdList）
-- 均在运行时触发，故局部引用可正常解析。
local function presentResult(query)
    query = strtrim(query or "")
    if query == "" then PeiFang_TogglePanel(); return end

    local result, kind = lib:Lookup(query)
    local records
    if result == nil then
        records = nil
    elseif kind == "spell" then
        records = { result }
    else
        records = result
    end
    if not records or #records == 0 then
        ShowMessage(PF .. " 未找到配方: " .. query
            .. "\n（可尝试更短的关键词）")
        return
    end
    -- 先加载全部 spell/item 数据，全部就绪后统一渲染；
    -- 用 pcall 包裹，渲染异常时给出可见错误提示，而不是整片空白。
    local ok, err = pcall(LoadAndRender, records)
    if not ok then
        ShowMessage(PF .. " 渲染出错: " .. tostring(err))
    end
end
UI.presentResult = presentResult

-- ------------------------- 刷新物品名称（延迟加载 + 缓存） -------------------------
-- 用法：/pfname
-- 遍历 PeiFangData 所有记录，对每个 itemID 用 Item:CreateFromItemID + ContinueOnItemLoad 延迟加载，
-- 取到名字后写回 rec.itemName；无 itemID 的纯法术配方则用 Spell:CreateFromSpellID + ContinueOnSpellLoad
-- 取 spell 名回填。进度实时提示；完成后整份「itemName 缓存」写入 SavedVariables(PeiFangNameCache)，
-- 下次启动自动生效（WoW 沙盒无法直接改写 PeiFangData.lua，故以 SavedVariables 作本地缓存）。
local function RefreshItemNames()
    local data = lib:GetData()
    local tasks    = {}   -- 所有需要取名的记录 { skillID, spellID, rec }
    local itemSet  = {}   -- 去重 itemID
    local spellSet = {}   -- 去重 spellID（纯法术 fallback）
    for skillID, recipes in pairs(data) do
        if type(recipes) == "table" then
            for spellID, rec in pairs(recipes) do
                tinsert(tasks, { skillID = skillID, spellID = spellID, rec = rec })
                if rec.itemID then
                    itemSet[rec.itemID] = true
                elseif rec.spellID then
                    spellSet[rec.spellID] = true
                end
            end
        end
    end
    local totalItems = 0
    for _ in pairs(itemSet)  do totalItems  = totalItems  + 1 end
    local totalSpells = 0
    for _ in pairs(spellSet) do totalSpells = totalSpells + 1 end
    local total = totalItems + totalSpells
    if total == 0 then
        ShowMessage(PF .. " 没有需要刷新的物品/配方")
        return
    end
    ShowMessage(PF .. " 开始刷新物品名称：共 " .. total .. " 个（物品 " .. totalItems
        .. " + 法术 " .. totalSpells .. "），请稍候…")
    local done = 0
    local flushed = false
    local function FlushCache()
        if flushed then return end
        flushed = true
        -- 全部就绪：把整份 PeiFangData 镜像写入 SavedVariables 缓存（WoW 退出时自动落盘）。
        -- 缓存结构与 PeiFangData 完全一致：cache[skillID][spellID] = { type, itemID, itemName, itemCount, source, colors, reagents }，
        -- 仅 itemName 字段替换为本次在游戏内取到的最新名称，其余字段原样复制。
        local cache = _G.PeiFangNameCache or {}
        _G.PeiFangNameCache = cache
        for skillID, recipes in pairs(data) do
            if type(recipes) == "table" then
                cache[skillID] = cache[skillID] or {}
                for spellID, rec in pairs(recipes) do
                    cache[skillID][spellID] = {
                        type      = rec.type,
                        itemID    = rec.itemID,
                        itemName  = rec.itemName,   -- 已替换为 /pfname 取到的游戏内名称
                        itemCount = rec.itemCount,
                        source    = rec.source,
                        colors    = rec.colors,
                        reagents  = rec.reagents,
                    }
                end
            end
        end
        ShowMessage(PF .. " 物品名称刷新完成，已缓存到 SavedVariables（下次启动自动生效）")
    end
    local function report()
        done = done + 1
        if done % 20 == 0 or done == total then
            ShowMessage(PF .. " 进度 " .. done .. " / " .. total)
        end
        if done == total then FlushCache() end
    end
    -- 兜底：若个别 itemID 失效导致回调永不触发，超时后强制落盘已获取的名称
    C_Timer.After(30, function()
        if done < total then
            FlushCache()
            ShowMessage(PF .. " 部分物品加载超时（" .. done .. "/" .. total .. "），已缓存已获取的名称")
        end
    end)
    -- 物品：延迟加载后取 GetItemInfo 名字，回填所有引用该 itemID 的记录
    -- 个别 itemID 在本地客户端无效时 ContinueOnItemLoad 可能抛错；用 pcall 兜底跳过，仍计入进度，
    -- 保证计数始终推进（30s 兜底与缓存落盘不受影响）。
    for itemID in pairs(itemSet) do
        local ok = pcall(function()
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                local name = C_Item.GetItemInfo(itemID)
                if name then
                    for _, t in ipairs(tasks) do
                        if t.rec.itemID == itemID then
                            t.rec.itemName = name
                        end
                    end
                end
                report()
            end)
        end)
        if not ok then
            report()   -- itemID 无效：跳过加载，保持原 itemName
        end
    end
    -- 纯法术配方：取 spell 名回填（同样延迟加载 spell 数据）
    -- 关键修复：部分 spellID（如 1252979）在本地客户端数据中不存在，CreateFromSpellID 返回空 spell 对象后
    -- 调用 ContinueOnSpellLoad 会抛 "Usage: NonEmptySpell:ContinueOnLoad" 错误。此处先 GetSpellInfo 试探
    -- （已缓存则直接回填），未命中再 pcall 包裹延迟加载；无效 spellID 直接跳过，保持原 itemName。
    for spellID in pairs(spellSet) do
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            for _, t in ipairs(tasks) do
                if not t.rec.itemID and t.rec.spellID == spellID then
                    t.rec.itemName = info.name
                end
            end
            report()
        else
            local ok = pcall(function()
                local spell = Spell:CreateFromSpellID(spellID)
                spell:ContinueOnSpellLoad(function()
                    local sInfo = C_Spell.GetSpellInfo(spellID)
                    local name = sInfo and sInfo.name
                    if name then
                        for _, t in ipairs(tasks) do
                            if not t.rec.itemID and t.rec.spellID == spellID then
                                t.rec.itemName = name
                            end
                        end
                    end
                    report()
                end)
            end)
            if not ok then
                report()   -- spellID 在本地客户端不存在：跳过加载，保持原 itemName（如 "#spellID"）
            end
        end
    end
end

SLASH_PEIFANGNAME1 = "/pfname"
SlashCmdList["PEIFANGNAME"] = function()
    RefreshItemNames()
end

-- ------------------------- 斜杠命令 -------------------------
SLASH_PEIFANG1 = "/pf"
SlashCmdList["PEIFANG"] = function(msg)
    msg = strtrim(msg or "")
    if msg == "" or msg == "panel" or msg == "ui" then
        PeiFang_TogglePanel()
        return
    end
    presentResult(msg)
end

-- ------------------------- 初始化 -------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        BuildPanel()
        DEFAULT_CHAT_FRAME:AddMessage(PF .. " 已加载，输入 /pf 打开搜索面板")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
