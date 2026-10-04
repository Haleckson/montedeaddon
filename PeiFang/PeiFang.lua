-- =====================================================================
-- 本文件只提供「数据 + 查询功能」，不创建任何 UI / 斜杠命令。
-- 通过 LibStub 注册，其它插件可直接引用：
--
--   local PeiFang = LibStub("PeiFang-1.0")
--   local recs = PeiFang:GetByItemID(14048)   -- 返回 {record, ...}
--   local rec  = PeiFang:GetBySpellID(3862)   -- 返回 record | nil
--   local list = PeiFang:SearchByName("符文布")-- 返回 {record, ...}
--   local r, k = PeiFang:Lookup("3862")       -- 自动判别 spell/item/name
--   local data = PeiFang:GetData()            -- 原始 PeiFangData 嵌套表
--
-- 游戏内搜索面板 / 斜杠命令在 PeiFangUI.lua（可选加载）。
--
-- 记录结构（PeiFangData[skillID][spellID]）：
--   type("spell"|"item"), itemID(可为 nil), itemName(英文配方名), itemCount,
--   source, colors = { r1?, r2?, r3?, r4? }  -- 红/黄/绿/灰，只写存在的档位
--   reagents = { itemID, needCount, itemID, needCount, ... }  -- 扁平数组（数据文件紧凑化，减少子表、降内存）
-- =====================================================================

local MAJOR, MINOR = "PeiFang-1.0", 1

-- ------------------------- 类型注解（LuaLS / EmmyLua） -------------------------
-- 用 ---@class 显式声明库类型，避免「向 PeiFang-1.0 引用注入字段」的静态诊断。
-- 其它插件可通过 ---@type PeiFangLib 引用本库获得方法补全。

---@class PeiFangRecord
---@field spellID  number|nil   -- 仅作展示回退，数据本身以 PeiFangData[skillID][spellID] 的键存储
---@field type     string       -- "spell" | "item"
---@field itemID   number|nil   -- 产出物 itemID（spell 类型为 nil）
---@field itemName string       -- 配方/产出英文名
---@field itemCount number      -- 单次产出数量
---@field source   string       -- 来源：Trainer / Vendor / Drop / Quest ...
---@field colors   table|nil    -- { r1?, r2?, r3?, r4? } 红/黄/绿/灰技能点（只写存在的档位）
---@field reagents table        -- { itemID, needCount, itemID, needCount, ... } 扁平数组（位置式，步进2取 第1=itemID 第2=数量）

---@class PeiFangLib
---@field GetBySpellID fun(self: PeiFangLib, spellID: number|string): PeiFangRecord?
---@field GetByItemID  fun(self: PeiFangLib, itemID: number|string): PeiFangRecord[]
---@field SearchByName fun(self: PeiFangLib, name: string): PeiFangRecord[]
---@field Lookup       fun(self: PeiFangLib, query: string|number): PeiFangRecord|PeiFangRecord[]|nil, "spell"|"item"|"name"|"notfound"|"empty"
---@field GetData      fun(self: PeiFangLib): table
---@field RebuildIndex fun(self: PeiFangLib): nil

local lib = LibStub:NewLibrary(MAJOR, MINOR) --[[@as PeiFangLib]]
if not lib then return end   -- 已有更新版本，跳过

-- 数据表通过 LibStub 取用（PeiFangData-1.0 库，本身即嵌套表 [skillID][spellID]），
-- 不依赖任何业务全局变量。唯一引用的全局是 SavedVariables 缓存 PeiFangNameCache（见下方），
-- 用于跨会话持久化「/pfname 刷新得到的物品名」，避免重复延迟加载。
---@type table
local PeiFangData = LibStub("PeiFangData-1.0")
assert(PeiFangData, "PeiFangData-1.0 库未加载，请确认 PeiFangData.lua 已先于 PeiFang.lua 加载")

-- 物品名称缓存（SavedVariables，跨会话持久化，由 /pfname 刷新命令写入）。
-- 结构：PeiFangNameCache[skillID][spellID] = { type, itemID, itemName, itemCount, source, colors, reagents }，
-- 与 PeiFangData 完全一致（数字键），仅 itemName 字段为 /pfname 在游戏内取到的最新名称。
-- Wow 在插件加载前已把上次保存的值恢复到全局 _G.PeiFangNameCache；此处确保全局存在以便落盘。
_G.PeiFangNameCache = _G.PeiFangNameCache or {}
---@type table
local NameCache = _G.PeiFangNameCache

-- 运行期索引（保证查询 O(1)）
-- itemIndex:  itemID -> { {skillID, spellID}, ... }   -- 一个物品可由多个配方/专业制造，故存为列表
-- spellIndex: spellID -> skillID                      -- spellID 全局唯一，无歧义
local itemIndex  = {}
local spellIndex = {}
local built = false

local function BuildIndex()
    wipe(itemIndex)
    wipe(spellIndex)
    for skillID, recipes in pairs(PeiFangData) do
        if type(recipes) == "table" then
            for spellID, rec in pairs(recipes) do
                rec.spellID = spellID   -- 运行期补全 spellID：数据文件不存储，仅用于 UI 取图标/名字/链接
                rec.skillID = skillID  -- 运行期补全 skillID：仅用于 UI 显示专业名称前缀
                -- 应用 SavedVariables 缓存的物品名（/pfname 刷新写入，结构与 PeiFangData 一致）：
                -- 仅覆盖 itemName 字段，其余字段以数据文件为准。键用数字（与 PeiFangData 一致），
                -- 并兼容 SavedVariables 重载时整数键可能被读成字符串的极端情况。
                local skT = NameCache[skillID] or NameCache[tostring(skillID)]
                local cached = skT and (skT[spellID] or skT[tostring(spellID)])
                if cached and cached.itemName then
                    rec.itemName = cached.itemName
                end
                if rec and rec.itemID then
                    if not itemIndex[rec.itemID] then
                        itemIndex[rec.itemID] = {}
                    end
                    tinsert(itemIndex[rec.itemID], { skillID = skillID, spellID = spellID })
                end
                spellIndex[spellID] = skillID
            end
        end
    end
    built = true
end

local function EnsureIndex()
    if not built then BuildIndex() end
end

-- ------------------------- 查询 API（方法） -------------------------

-- 按 spellID 查询（spellID 全局唯一，返回单条 record 或 nil）
function lib:GetBySpellID(spellID)
    EnsureIndex()
    spellID = tonumber(spellID)
    local skillID = spellIndex[spellID]
    if skillID and PeiFangData[skillID] then
        return PeiFangData[skillID][spellID]
    end
    return nil
end

-- 按 itemID 查询（同一 itemID 可由多个配方/专业制造，返回 record 列表，空则 {}）
function lib:GetByItemID(itemID)
    EnsureIndex()
    itemID = tonumber(itemID)
    local refs = itemIndex[itemID]
    if not refs then return {} end
    local out = {}
    for _, ref in ipairs(refs) do
        local rec = PeiFangData[ref.skillID] and PeiFangData[ref.skillID][ref.spellID]
        if rec then tinsert(out, rec) end
    end
    return out
end

-- 按名称模糊查询（匹配 itemName，忽略大小写），返回 record 列表
function lib:SearchByName(name)
    EnsureIndex()
    local res = {}
    name = strlower(strtrim(name or ""))
    if name == "" then return res end
    for _, recipes in pairs(PeiFangData) do
        if type(recipes) == "table" then
            for _, rec in pairs(recipes) do
                local a = rec.itemName and strlower(rec.itemName) or ""
                -- 第 4 个参数 true = 纯文本匹配（不把 name 当 Lua 模式），避免关键词含 % ( ) 等魔法字符时抛 "malformed pattern"
                if strfind(a, name, 1, true) then
                    tinsert(res, rec)
                end
            end
        end
    end
    return res
end

-- 自动判别查询：数字先当 spellID 再当 itemID；否则按名称
-- 返回 (result, kind)，kind ∈ "spell" | "item" | "name" | "notfound" | "empty"
function lib:Lookup(query)
    if query == nil then return nil, "empty" end
    local q = strtrim(tostring(query))
    if q == "" then return nil, "empty" end
    local num = tonumber(q)
    if num then
        local rec = self:GetBySpellID(num)
        if rec then return rec, "spell" end
        rec = self:GetByItemID(num)
        if rec then return rec, "item" end
        return nil, "notfound"
    end
    local res = self:SearchByName(q)
    return res, "name"
end

-- 返回原始数据结构 PeiFangData[skillID][spellID]
function lib:GetData()
    return PeiFangData
end

-- 强制重建索引（数据在加载后发生变化时调用）
function lib:RebuildIndex()
    BuildIndex()
end

-- ------------------------- 向后兼容全局函数 -------------------------
-- 保留全局函数，方便旧代码或聊天框直接调用（内部委托给库方法）
PeiFang_GetBySpellID = function(spellID) return lib:GetBySpellID(spellID) end
PeiFang_GetByItemID  = function(itemID)   return lib:GetByItemID(itemID) end
PeiFang_SearchByName = function(name)     return lib:SearchByName(name) end
PeiFang_Lookup       = function(query)    return lib:Lookup(query) end

-- 首次加载时建立索引
BuildIndex()

---@type PeiFangLib
_G.PeiFang = lib   -- 额外的全局快捷引用（与 LibStub 等价，已带类型）
