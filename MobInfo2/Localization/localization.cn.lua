--   
-- MobInfo 简体中文本地化
--
-- Contributed by: r0s0j
--

local _, MI2 = ...

if ( MI2.Locale == "zhCN" ) then

MI2_SpellSchools = { Arcane="奥术", Fire="火焰", Frost="冰霜", Shadow="暗影", Holy="神圣", Nature="自然" }

MI_TXT_WELCOME          = "欢迎使用 MobInfo"
MI_DESCRIPTION			= "在鼠标提示中添加敌人信息，并在目标框架上显示生命值/法力值信息"
MI_TXT_GENERAL_OPTIONS	= "此选项页面控制 MobInfo 插件的主要功能。其他选项页面可对各项功能进行详细配置。"
MI_TXT_GOLD   = " 金"
MI_TXT_SILVER = " 银"
MI_TXT_COPPER = " 铜"
MI_TXT_OPEN				= "打开"
MI_TXT_COMBINED			= "合并显示： "
MI_TXT_MOB_DB_SIZE		= "敌人数据库大小：  "
MI_TXT_ITEM_DB_SIZE		= "物品数据库大小：  "
MI_TXT_CUR_TARGET		= "当前目标：  "
MI_TXT_MH_DISABLED		= "MobInfo 警告：检测到独立的 MobHealth 插件。内部的敌人生命值功能已被禁用，请移除独立 MobHealth 插件后恢复。"
MI_TXT_MH_DISABLED2		= (MI_TXT_MH_DISABLED.."\n\n移除独立 MobHealth 不会丢失你的数据。\n\n优势：可移动的生命值/法力值显示，支持百分比，字体和大小均可调整。")
MI_TXT_MH_WOW_MODERN	= "在“至暗之夜”或“永恒”版本中无法使用目标框架生命值/法力值显示功能。\n\n暴雪限制了插件读取单位生命值与法力值的权限，导致插件无法展示该信息。\n\nMobInfo2 的其余全部功能（鼠标提示、数据库、拾取记录等）仍可正常工作。"
MI_TXT_CLR_ALL_CONFIRM	= "你确定要执行以下删除操作： "
MI_TXT_SEARCH_LEVEL		= "等级："
MI_TXT_SEARCH_MOBTYPE	= "类型："
MI_TXT_SEARCH_LOOTS		= "已拾取："
MI_TXT_TRIM_DOWN_CONFIRM = "警告：此操作将立即永久删除数据。确定要删除所有未标记为需要记录的敌人数据吗？"
MI_TXT_CLAM_MEAT		= "蚌肉"
MI_TXT_SHOWING			= "列表显示： "
MI_TXT_DROPPED_BY		= "掉落来源："
MI_TXT_IMMUNE			= "免疫："
MI_TXT_RESIST			= "抵抗："
MI_TXT_DEL_SEARCH_CONFIRM = "确定要从 MobInfo 数据库中删除搜索结果列表里的 %d 个敌人吗？"
MI_TXT_WRONG_LOC		= "错误：MobInfo 数据库语言版本与你的游戏客户端语言不匹配。修复前数据库将无法使用。"
MI_TXT_WRONG_DBVER		= "错误：你的 MobInfo 数据库版本过旧，不兼容当前版本。\n\nMobInfo 必须删除全部旧敌人数据。"
MI_TXT_UPGRADE_REQUIRED	= "警告：你的 MobInfo 数据库需要升级。\n\n请立刻备份你的保存变量文件。"
MI_TXT_PRICE			= "商人售价："
MI_TXT_TOOLTIP_MOVE		= "移动提示锚点只需\n点击并拖拽到屏幕新位置即可"
MI_TXT_ITEMFILTER		= "物品筛选"

MI2_CHAT_MOBRUNS = "试图逃跑"
MI2_TXT_MOBRUNS = "*逃跑*"

BINDING_HEADER_MI2HEADER	= "MobInfo"
BINDING_NAME_MI2CONFIG	= "打开 MobInfo 设置"

MI2_FRAME_TEXTS = {}
MI2_FRAME_TEXTS["MI2_FrmTooltipContent"]	= "敌人鼠标提示内容"
MI2_FRAME_TEXTS["MI2_FrmHealthOptions"]		= "敌人生命值选项"
MI2_FRAME_TEXTS["MI2_FrmDatabaseOptions"]	= "数据库设置"
MI2_FRAME_TEXTS["MI2_FrmHealthValueOptions"]= "生命值"
MI2_FRAME_TEXTS["MI2_FrmManaValueOptions"]	= "法力值"
MI2_FRAME_TEXTS["MI2_FrmSearchOptions"]		= "搜索选项"
MI2_FRAME_TEXTS["MI2_FrmImportDatabase"]	= "导入外部 MobInfo 数据库"
MI2_FRAME_TEXTS["MI2_FrmItemTooltip"]		= "物品鼠标提示选项"
MI2_FRAME_TEXTS["MI2_FrmTooltipLayout"]		= "MobInfo 提示窗口布局"

---------------------------
-- 鼠标提示选项/内容
---------------------------
MI_TXT_HEALTH		= "生命值"
MI_HLP_HEALTH		= "显示敌人生命值信息（当前/最大）"
MI_TXT_MANA			= "法力值"
MI_HLP_MANA			= "显示敌人法力/怒气/能量信息（当前/最大）"
MI_TXT_KILLS		= "击杀数"
MI_HLP_KILLS		= "显示你击杀该敌人的次数\n击杀计数按每个角色独立计算并保存"
MI_TXT_LOOTS		= "拾取数"
MI_HLP_LOOTS		= "显示该敌人被拾取的次数"
MI_TXT_COINS		= "平均金币"
MI_HLP_COINS		= "显示该敌人平均掉落的金币\n总金币累加后除以拾取次数。\n（无金币掉落时不显示）"
MI_TXT_ITEMVAL		= "物品均价"
MI_HLP_ITEMVAL		= "显示该敌人平均掉落物品的价值\n总物品价值累加后除以拾取次数。\n（无物品掉落时不显示）"
MI_TXT_MOBVAL		= "总价值"
MI_HLP_MOBVAL		= "显示敌人总的平均价值\n平均金币与平均物品价值之和"
MI_TXT_XP			= "经验"
MI_HLP_XP			= "显示该敌人提供的经验值\n为你上次击杀该敌人获得的实际经验。\n（灰色等级敌人不显示）"
MI_TXT_TO_LEVEL		= "升级需击杀"
MI_HLP_TO_LEVEL		= "显示升到下一级还需要击杀多少\n数值基于你刚刚击杀的这个敌人计算。\n（灰色等级敌人不显示）"
MI_TXT_EMPTY_LOOTS	= "空拾取"
MI_HLP_EMPTY_LOOTS	= "显示空尸体数量（数量/百分比）\n拾取无掉落物的尸体时该计数就会增加"
MI_TXT_CLOTH_DROP	= "布料"
MI_HLP_CLOTH_DROP	= "显示该敌人掉落布料的概率"
MI_TXT_CLASS		= "职业"
MI_HLP_CLASS		= "显示敌人职业"
MI_TXT_DAMAGE		= "伤害"
MI_HLP_DAMAGE		= "显示敌人伤害区间（最小/最大）与每秒伤害 DPS\n伤害区间和 DPS 按角色独立统计保存。\nDPS 会随每一场战斗缓慢更新"
MI_TXT_QUALITY		= "物品"
MI_OPT_QUALITY		= "掉落品质统计"
MI_HLP_QUALITY		= "显示掉落物品质与掉落百分比\n统计掉落物中 5 种品质分类的物品数量。无掉落的分类不会显示。百分比为该品质物品的掉落几率。"
MI_TXT_LOCATION		= "地点"
MI_HELP_LOCATION	= "显示敌人所在地点\n需要开启位置记录功能才会生效"
MI_TXT_LOWHEALTH	= "逃跑指示"
MI_HELP_LOWHEALTH	= "标记生命值偏低就会逃跑的敌人\n仅在这类敌人的提示框内显示一行红色提示文字"
MI_OPT_RESISTS		= "抵抗与免疫"
MI_TXT_RESISTS		= "抵抗"
MI_TXT_IMMUN		= "免疫"
MI_HELP_RESISTS		= "在鼠标提示中显示抵抗与免疫数据\n在鼠标提示中添加了记录到的敌人对各系法术抵抗、免疫信息"
MI_TXT_ITEMLIST		= "基础拾取物品列表"
MI_HELP_ITEMLIST	= "显示全部基础拾取物品的名称与数量\n基础拾取不含布料和剥皮产物。\n需要开启拾取物品记录功能"
MI_TXT_CLOTHSKIN	= "布料与剥皮拾取"
MI_HELP_CLOTHSKIN	= "显示布料和剥皮产物的名称与数量\n需要开启拾取物品记录功能"

--------------------
-- 通用选项
--------------------
MI2_OPTIONS = {};
MI2_OPTIONS["MI2_OptSaveBasicInfo"] = 
{ text = "记录并存储敌人详细信息";
help = "开启或关闭记录游戏中遇到并击杀敌人的详细数据。\n数据用于鼠标提示展示敌人详情，也可以用 MobInfo 的搜索工具查找敌人。\n同时也能为物品显示“掉落来源”信息。\n\n前往数据库选项页设置详细记录规则和维护数据库。\n\n如果你不想 MobInfo 保存敌人数据，可以关闭此选项。\n关闭记录不会删除已有数据库；如需删除数据库，请前往数据库设置页面。" }

MI2_OPTIONS["MI2_OptShowMobInfo"] = 
{ text = "在鼠标提示中显示敌人信息"; 
help = "开启后在 MobInfo 提示框展示敌人信息。\n前往鼠标提示选项页选择要展示的项目。\n关闭此选项将不再显示敌人信息与 MobInfo 提示框。" }

MI2_OPTIONS["MI2_OptUseGameTT"] = 
{ text = "使用游戏原生提示框，而不是 MobInfo 提示框"; 
help = "MobInfo 默认使用一套布局优化、可移动的专属提示窗口。\n开启本选项后，敌人信息将直接附加到游戏原生提示框，\nMobInfo 专属提示窗口会被禁用。" }

MI2_OPTIONS["MI2_OptShowWhileInCombat"] = 
{ text = "战斗中也显示敌人信息";
help = "关闭后，战斗状态下 MobInfo 敌人信息将不会显示。\n鼠标提示框及 MobInfo 提示框都不会显示敌人信息。\n默认战斗中提示框也显示敌人信息。" }

MI2_OPTIONS["MI2_OptShowItemInfo"] = 
{ text = "在物品提示框中显示附加信息"; 
help = "开启后在物品鼠标提示上展示相关数据。\n前往提示设置页选择展示项目。\n关闭则不会为物品提示增加任何 MobInfo 内容。" }

MI2_OPTIONS["MI2_OptShowTargetInfo"] = 
{ text = "在目标框架显示敌人信息（生命/法力等）"; 
help = "在目标框架显示生命、法力等数值。\n（该功能与第三方单位框体插件冲突）\n前往目标框架设置页面配置显示内容与位置。\n关闭后，不在目标框架上展示 MobInfo 信息。" }

MI2_OPTIONS["MI2_OptShowMMButton"] = 
{ text = "显示小地图按钮"; 
help = "显示 / 隐藏 MobInfo 小地图按钮" }

MI2_OPTIONS["MI2_OptMMButtonPos"] = 
{ text = "小地图按钮位置"; 
help = "拖动滑块调整 MobInfo 小地图按钮的位置" }

--------------------
-- 其他选项
--------------------
MI2_OPTIONS["MI2_OptShowIGrey"] = 
{ text = ""; help = "提示框中显示灰色（粗糙）物品" }
MI2_OPTIONS["MI2_OptShowIWhite"] = 
{ text = ""; help = "提示框中显示白色（普通）物品" }
MI2_OPTIONS["MI2_OptShowIGreen"] = 
{ text = ""; help = "提示框中显示绿色（优秀）物品" }
MI2_OPTIONS["MI2_OptShowIBlue"] = 
{ text = ""; help = "提示框中显示蓝色（精良）物品" }
MI2_OPTIONS["MI2_OptShowIPurple"] = 
{ text = ""; help = "提示框中显示紫色（史诗）物品" }

MI2_OPTIONS["MI2_OptMouseTooltip"] = 
{ text = "提示框跟随鼠标"; help = "MobInfo 提示框显示于鼠标光标位置，跟随鼠标移动。" }

MI2_OPTIONS["MI2_OptHideAnchor"] = 
{ text = "隐藏提示框锚点图标"; help = "隐藏 MobInfo 提示框的小 MI 图标。\n打开设置面板或者关闭本选项时锚点会重新显示。" }

MI2_OPTIONS["MI2_OptShowCombined"] = 
{ text = "合并敌人信息"; help = "提示框内显示合并模式提示文字\n提示当前已开启合并模式，并列出被合并统计的敌人的所有等级。" }

MI2_OPTIONS["MI2_OptSmallFont"] = 
{ text = "使用更小字体"; help = "MobInfo 提示框内使用小号文字" }

MI2_OPTIONS["MI2_OptTooltipMode"] = 
{ text = "提示框位置"; help = "MobInfo 提示框相对于锚点的位置";
choice1="左上"; choice2="左下"; choice3="右上"; choice4="右下"; choice5="上方居中"; choice6="下方居中" }

MI2_OPTIONS["MI2_OptCompactMode"] =
{ text = "双列紧凑提示框"; help = "使用双列紧凑布局展示敌人信息。\n提示框宽度会略增加，但整体高度大幅缩短。\n总宽度存在上限，过长内容会单独占一行。" }

MI2_OPTIONS["MI2_OptOtherTooltip"] =
{ text = "隐藏原生提示框"; help = "当使用 MobInfo 提示展示敌人信息时，隐藏游戏原生提示。" }

MI2_OPTIONS["MI2_OptSearchMinLevel"] = 
{ text = "最低"; help = "搜索条件 - 敌人最低等级"; }
MI2_OPTIONS["MI2_OptSearchMaxLevel"] = 
{ text = "最高"; help = "搜索条件 - 敌人最高等级（须小于 66）"; }
MI2_OPTIONS["MI2_OptSearchNormal"] = 
{ text = "普通"; help = "搜索结果包含普通敌人"; }
MI2_OPTIONS["MI2_OptSearchElite"] = 
{ text = "精英"; help = "搜索结果包含精英敌人"; }
MI2_OPTIONS["MI2_OptSearchBoss"] = 
{ text = "首领"; help = "搜索结果包含首领敌人"; }
MI2_OPTIONS["MI2_OptSearchRare"] = 
{ text = "稀有"; help = "搜索结果包含稀有敌人"; }
MI2_OPTIONS["MI2_OptSearchRareElite"] = 
{ text = "稀有精英"; help = "搜索结果包含稀有精英敌人"; }
MI2_OPTIONS["MI2_OptSearchMinLoots"] = 
{ text = "最少"; help = "敌人最少拾取次数条件"; }
MI2_OPTIONS["MI2_OptSearchMaxLoots"] = 
{ text = "最多"; help = "敌人最多拾取次数条件"; }

MI2_OPTIONS["MI2_OptSearchMobName"] = 
{ text = "敌人名称"; help = "输入完整或部分敌人名称进行搜索";
info = '留空代表不按敌人名称过滤；输入 "*" 代表匹配全部。'; }

MI2_OPTIONS["MI2_OptSearchItemName"] = 
{ text = "物品名称"; help = "输入完整或部分物品名称进行搜索";
info = '留空将搜索全部物品'; }

MI2_OPTIONS["MI2_OptSortByValue"] = 
{ text = "按收益排序"; help = "搜索列表按击杀敌人的收益排序";
info = '按击杀该敌人可获得的收益高低排序。'; }

MI2_OPTIONS["MI2_OptSortByItem"] = 
{ text = "按物品掉落数量排序"; help = "搜索列表按目标物品掉落数量排序";
info = '按敌人掉落指定物品的数量进行排序。'; }

MI2_OPTIONS["MI2_OptItemTooltip"] =
{ text = "物品提示框列出掉落敌人"; help = "在物品鼠标提示中显示哪些敌人会掉落该物品";
info = "鼠标悬停物品时，列出所有会掉落它的敌人，附带掉落数量与百分比。" }

MI2_OPTIONS["MI2_OptShowItemPrice"] =
{ text = "显示商人出售价格"; help = "在物品提示框显示该物品的商人售价" }

MI2_OPTIONS["MI2_OptCombinedMode"] = 
{ text = "合并同名敌人"; help = "合并同名但不同等级敌人的数据";
info = "开启后，同名不同等级敌人的数据会合并累加，并在提示框中显示启用指示。" }

MI2_OPTIONS["MI2_OptKeypressMode"] = 
{ text = "按住 ALT 键显示敌人信息"; help = "只有按住 ALT 键时，才显示 MobInfo 敌人信息。" }

MI2_OPTIONS["MI2_OptItemFilter"] = 
{ text = ""; help = "设置提示框拾取物品筛选表达式";
info = "仅在敌人提示中显示名称包含筛选文本的物品。\n例如输入“布料”，只会显示名字带布料的物品。\n留空显示全部物品。" }

MI2_OPTIONS["MI2_OptSaveAllPartyKills"] = 
{ text = "记录小队击杀"; help = "记录你与小队成员完成的击杀";
info = "通常小队击杀敌人后，如果你或你的宠物没有造成伤害，该击杀不会被记录。" }

MI2_OPTIONS["MI2_OptAllOn"] = 
{ text = "全部开启"; help = "把所有 MobInfo 显示选项全部打开"; }
MI2_OPTIONS["MI2_OptAllOff"] = 
{ text = "全部关闭"; help = "把所有 MobInfo 显示选项全部关闭"; }
MI2_OPTIONS["MI2_OptDefault"] = 
{ text = "默认设置"; help = "显示一套默认的敌人信息配置" }
MI2_OPTIONS["MI2_OptBtnDone"] = 
{ text = "关闭"; help = "关闭 MobInfo 设置窗口" }

MI2_OPTIONS["MI2_OptTargetHealth"] = 
{ text = "显示生命值"; help = "在目标框架显示生命值" }
MI2_OPTIONS["MI2_OptTargetMana"] = 
{ text = "显示法力值"; help = "在目标框架显示法力值" }
MI2_OPTIONS["MI2_OptHealthPercent"] = 
{ text = "显示百分比"; help = "在目标框架生命值后附加百分比" }
MI2_OPTIONS["MI2_OptManaPercent"] = 
{ text = "显示百分比"; help = "在目标框架法力值后附加百分比" }
MI2_OPTIONS["MI2_OptHealthPosX"] = 
{ text = "水平位置"; help = "调整目标框架生命值的横向偏移" }
MI2_OPTIONS["MI2_OptHealthPosY"] = 
{ text = "垂直位置"; help = "调整目标框架生命值的纵向偏移" }
MI2_OPTIONS["MI2_OptManaPosX"] = 
{ text = "水平位置"; help = "调整目标框架法力值的横向偏移" }
MI2_OPTIONS["MI2_OptManaPosY"] = 
{ text = "垂直位置"; help = "调整目标框架法力值的纵向偏移" }

MI2_OPTIONS["MI2_OptTargetFont"] = 
{ text = "字体"; help = "设置目标框架生命值/法力值字体";
choice1= "数字字体"; choice2="游戏字体"; choice3="物品文本字体" }

MI2_OPTIONS["MI2_OptTargetFontSize"] = 
{ text = "字号"; help = "设置目标框架生命值/法力值字号" }

MI2_OPTIONS["MI2_OptClearTarget"] = 
{ text = "删除目标数据"; help = "从数据库删除当前选中目标的记录。" }
MI2_OPTIONS["MI2_OptClearMobDb"] = 
{ text = "清空敌人数据库"; help = "删除敌人数据库全部内容。" }
MI2_OPTIONS["MI2_OptClearHealthDb"] = 
{ text = "清空生命值数据库"; help = "删除敌人生命值数据库全部内容。" }
MI2_OPTIONS["MI2_OptClearPlayerDb"] = 
{ text = "清空玩家生命值数据库"; help = "删除玩家生命值数据库全部内容。" }

MI2_OPTIONS["MI2_OptSaveItems"] = 
{ text = "记录该品质及以上的敌人掉落信息："; help = "开启后记录敌人掉落的详细信息。";
info = "你可以选择需要记录的物品品质等级。"; }

MI2_OPTIONS["MI2_OptSaveCharData"] = 
{ text = "记录角色独立的敌人数据"; help = "按角色分别记录敌人数据";
info = "控制以下数据是否保存：\n击杀次数、最小/最大伤害、DPS、敌人经验。\n这四项数据每个角色独立存储，只能整体开启或关闭。" }

MI2_OPTIONS["MI2_OptSaveResist"] = 
{ text = "记录抵抗与免疫数据"; help = "记录敌人对各系法术的抵抗、免疫情况。";
info = "统计各系法术命中成功 vs 被抵抗的次数。" }

MI2_OPTIONS["MI2_OptSaveCompressed"] = 
{ text = "登出时压缩数据库。"; help = "数据库体积过大时，建议开启压缩存储。";
info = "开启会产生加载和保存延迟。\n遇到“数据表溢出”报错时，请恢复备份并开启此选项。" }

MI2_OPTIONS["MI2_OptItemsQuality"] = 
{ text = ""; help = "记录选中品质及更高品质的拾取物品";
choice1 = "灰色及以上"; choice2="白色及以上"; choice3="绿色及以上" }

MI2_OPTIONS["MI2_OptTrimDownMobData"] = 
{ text = "精简敌人数据库体积"; help = "删除未标记需要保存的数据来减小数据库大小。";
info = "删除数据库中所有不在记录规则内的冗余数据。" }

MI2_OPTIONS["MI2_OptImportMobData"] = 
{ text = "开始导入"; help = "将外部敌人数据库导入本地数据库";
info = "重要：阅读导入说明！\n导入之前务必备份你自己的 MobInfo 数据库！" }

MI2_OPTIONS["MI2_OptDeleteSearch"] = 
{ text = "删除"; help = "删除搜索结果列表内全部敌人记录";
info = "警告：此操作不可撤销，请谨慎操作！\n建议删除前先备份 MobInfo 数据库。" }

MI2_OPTIONS["MI2_OptImportOnlyNew"] = 
{ text = "仅导入未知敌人"; help = "只导入本地数据库不存在的敌人";
info = "开启后不会修改本地已有的敌人记录，只新增从未见过的敌人，可以导入部分重叠的外部数据库而不会产生数据错乱。" }

MI2_OPTIONS["MI2_SearchResultFrameTab1"] = 
{ text = "敌人列表"; help = ""; }
MI2_OPTIONS["MI2_SearchResultFrameTab2"] = 
{ text = "物品列表"; help = ""; }

MI2_OPTIONS["MI2_OptionsTabFrameTab1"] = 
{ text = "鼠标提示"; help = "配置敌人提示框显示项目"; }
MI2_OPTIONS["MI2_OptionsTabFrameTab2"] = 
{ text = "目标框架"; help = "配置目标框架生命值/法力值显示"; }
MI2_OPTIONS["MI2_OptionsTabFrameTab3"] = 
{ text = "数据库"; help = "数据库管理设置"; }
MI2_OPTIONS["MI2_OptionsTabFrameTab4"] = 
{ text = "搜索"; help = "在数据库内进行搜索"; }
MI2_OPTIONS["MI2_OptionsTabFrameTab5"] = 
{ text = "通用"; help = "MobInfo 插件通用设置"; }

MI2_TXT_Summary = "MobInfo 拾取统计"
MI2_TXT_Price= { text="价格",tooltipText="如有拍卖行数据，则使用拍卖行总价" }
MI2_TXT_AverageValue= { text="平均单价",tooltipText="单件平均价值（优先读取拍卖行价格）" }
MI2_TXT_LootName = { text="名称", tooltipText="拾取物品名称" }
MI2_TXT_SourceName = { text="名称", tooltipText="来源名称" }
MI2_TXT_SourceType = { text="类型", tooltipText="来源类型（生物/载具/游戏物体）" }
MI2_TXT_Vendor = { text="商人总价",tooltipText="商人出售总价格" }
MI2_TXT_AverageVendor= { text="商人平均价",tooltipText="单件商人平均售价" }
MI2_TXT_Quantity = { text="#",tooltipText="拾取次数" }
MI2_TXT_NumMobs = { text="#敌人",tooltipText="敌人数量" }
MI2_TXT_NumNonMobs = { text="#非敌人",tooltipText="非敌人来源数量" }
MI2_TXT_DropRate = { text="掉落%",tooltipText="掉落率：本次统计中，每个敌人的物品掉落概率" }
MI2_TXT_Time = { text="时间",tooltipText="距上次拾取时间" }
MI2_TXT_ID = { text="ID",tooltipText="内部ID" }
MI2_TXT_FilterMoney = "金币"
MI2_TXT_NumItems = { text="#物品",tooltipText="拾取记录数" }
MI2_TXT_NumSources = { text="#",tooltipText="来源总数" }
MI2_TXT_NumUniqueItems = { text="#种类",tooltipText="掉落物种类数量" }
MI2_TXT_SummaryReset = { text = "重置", tooltipText="重置 MobInfo 拾取统计窗口"; }
MI2_TXT_ResetOnLogin = { text = "登录时重置统计", tooltipText = "勾选则每次登录清空拾取统计；取消勾选将恢复上一次游戏会话的统计。" }

MI2_TXT_SummaryFont = {
  [1] = { font = GameFontWhiteTiny2, text = "超小", tooltipText="结果列表使用超小字体" },
  [2] = { font = GameFontWhiteTiny, text = "很小", tooltipText="结果列表使用很小字体" },
  [3] = { font = GameFontNormalSmall, text = "小", tooltipText="结果列表使用小字体" },
  [4] = { font = GameFontNormal, text = "普通", tooltipText="结果列表使用普通字体" },
  [5] = { font= GameFontNormalLarge, text = "大", tooltipText="结果列表使用大字体" }
}

MI2_TXT_ToggleOptions = "|cffffff00点击|r 打开 MobInfo 设置"
MI2_TXT_ToggleSummary = "|cffffff00右键点击|r 切换 MobInfo 拾取统计窗口"

end
