local _, LIB = ...

local texturePath = "Interface\\AddOns\\ArcaneWizardLibrary\\assets\\frames\\"
local tabTexturePath = texturePath .. "tabs\\"
local solidBackgroundStyles = LIB.BackgroundData.solidStyles
local backgroundTileSize = 256
local nineSliceCoordinates = {
	{ 0, 0.25, 0, 0.25 },
	{ 0.25, 0.75, 0, 0.25 },
	{ 0.75, 1, 0, 0.25 },
	{ 0, 0.25, 0.25, 0.75 },
	{ 0.25, 0.75, 0.25, 0.75 },
	{ 0.75, 1, 0.25, 0.75 },
	{ 0, 0.25, 0.75, 1 },
	{ 0.25, 0.75, 0.75, 1 },
	{ 0.75, 1, 0.75, 1 }
}
local silverBorderStyle = {
	path = texturePath .. "popup-border-silver.tga",
	coordinates = nineSliceCoordinates,
	sliceSize = 16
}
local goldBorderStyle = {
	path = texturePath .. "popup-border-gold.tga",
	coordinates = nineSliceCoordinates,
	sliceSize = 16
}

LIB.FrameData = {
	window = {
		minimumWidth = 128,
		minimumHeight = 96,
		portraitMinimumWidth = 192,
		portraitMinimumHeight = 128,
		sliceSize = 22,
		frameBrightness = 1,
		frameOutsets = {
			right = 1,
			bottom = 1
		},
		backgroundInsets = {
			left = 1,
			right = 1,
			top = 21,
			bottom = 1
		},
		contentInsets = {
			left = 8,
			right = 8,
			top = 35,
			bottom = 8
		},
		title = {
			height = 21,
			horizontalInset = 24,
			topOffset = 2,
			background = {
				path = texturePath .. "title-bar.tga",
				height = 21,
				leftInset = 2,
				rightInset = 1,
				topOffset = 2
			},
			transition = {
				leftInset = 2,
				rightInset = 1,
				topOffset = 23
			}
		},
		closeButton = {
			template = "ArcaneWizardLibrary_WindowCloseButtonTemplate",
			horizontalOffset = 3,
			verticalOffset = 4
		}
	},
	titleTransitionStyles = {
		shadow = {
			shadowColors = {
				{ red = 0, green = 0, blue = 0, alpha = 0.35 },
				{ red = 0, green = 0, blue = 0, alpha = 0.31 },
				{ red = 0, green = 0, blue = 0, alpha = 0.28 },
				{ red = 0, green = 0, blue = 0, alpha = 0.25 },
				{ red = 0, green = 0, blue = 0, alpha = 0.22 },
				{ red = 0, green = 0, blue = 0, alpha = 0.19 },
				{ red = 0, green = 0, blue = 0, alpha = 0.16 },
				{ red = 0, green = 0, blue = 0, alpha = 0.13 },
				{ red = 0, green = 0, blue = 0, alpha = 0.105 },
				{ red = 0, green = 0, blue = 0, alpha = 0.08 },
				{ red = 0, green = 0, blue = 0, alpha = 0.06 },
				{ red = 0, green = 0, blue = 0, alpha = 0.04 },
				{ red = 0, green = 0, blue = 0, alpha = 0.022 },
				{ red = 0, green = 0, blue = 0, alpha = 0.01 }
			}
		},
		["strong-shadow"] = {
			shadowColors = {
				{ red = 0, green = 0, blue = 0, alpha = 0.6 },
				{ red = 0, green = 0, blue = 0, alpha = 0.54 },
				{ red = 0, green = 0, blue = 0, alpha = 0.49 },
				{ red = 0, green = 0, blue = 0, alpha = 0.44 },
				{ red = 0, green = 0, blue = 0, alpha = 0.39 },
				{ red = 0, green = 0, blue = 0, alpha = 0.34 },
				{ red = 0, green = 0, blue = 0, alpha = 0.29 },
				{ red = 0, green = 0, blue = 0, alpha = 0.24 },
				{ red = 0, green = 0, blue = 0, alpha = 0.19 },
				{ red = 0, green = 0, blue = 0, alpha = 0.15 },
				{ red = 0, green = 0, blue = 0, alpha = 0.11 },
				{ red = 0, green = 0, blue = 0, alpha = 0.075 },
				{ red = 0, green = 0, blue = 0, alpha = 0.04 },
				{ red = 0, green = 0, blue = 0, alpha = 0.02 }
			}
		},
		line = {
			shadowColors = {}
		}
	},
	popup = {
		minimumWidth = 64,
		minimumHeight = 48,
		sliceSize = 22,
		frameBrightness = 1,
		frameOutsets = {
			right = 1,
			bottom = 1
		},
		backgroundInsets = {
			left = 1,
			right = 1,
			top = 1,
			bottom = 1
		},
		contentInsets = {
			left = 10,
			right = 10,
			top = 10,
			bottom = 10
		},
		closeButton = {
			template = "ArcaneWizardLibrary_PopupCloseButtonTemplate",
			border = {
				horizontalOffset = 3,
				verticalOffset = 4
			},
			borderless = {
				horizontalOffset = -4,
				verticalOffset = -4
			}
		}
	},
	portrait = {
		size = 64,
		imageSize = 50,
		offsetX = 20,
		offsetY = -20,
		maskPath = texturePath .. "portrait-mask.tga",
		borderPath = texturePath .. "portrait-border.tga",
		backgroundColor = {
			red = 0.035,
			green = 0.035,
			blue = 0.035
		}
	},
		tabs = {
		states = {
			normal = {
				text = { 1, 0.82, 0.15 },
				textOffset = 0
			},
			highlight = {
				text = { 1, 0.92, 0.35 },
				textOffset = 0
			},
			pushed = {
				text = { 0.95, 0.72, 0.12 },
				textOffset = -1
			},
			selected = {
				text = { 1, 1, 1 },
				textOffset = 0
			},
			disabled = {
				text = { 0.45, 0.44, 0.42 },
				textOffset = 0
			}
		},
		placement = {
			height = 24,
			selectedHeight = 28,
			minimumWidth = 72,
			horizontalPadding = 10,
			spacing = 3,
			capWidth = 8,
			anchorPoint = "TOPLEFT",
			relativePoint = "BOTTOMLEFT",
			offsetX = 12,
			offsetY = -1,
			textures = {
				normal = tabTexturePath .. "bottom-normal.tga",
				highlight = tabTexturePath .. "bottom-highlight.tga",
				pushed = tabTexturePath .. "bottom-pushed.tga",
				selected = tabTexturePath .. "bottom-selected.tga",
				disabled = tabTexturePath .. "bottom-disabled.tga"
			}
		}
	},
	backgroundStyles = {
		["solid-black"] = solidBackgroundStyles["solid-black"],
		["solid-dark"] = solidBackgroundStyles["solid-dark"],
		["solid-library"] = solidBackgroundStyles["solid-library"],
		panel = {
			path = texturePath .. "background-panel.tga",
			tileSize = backgroundTileSize
		}
	},
	popupBorderStyles = {
		library = {
			path = texturePath .. "popup-border-library.tga",
			coordinates = nineSliceCoordinates
		},
		silver = silverBorderStyle,
		gold = goldBorderStyle
	},
	windowBorderStyles = {
		library = {
			path = texturePath .. "window-border.tga",
			coordinates = nineSliceCoordinates
		},
		silver = silverBorderStyle,
		gold = goldBorderStyle
	}
}
