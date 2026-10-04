local _, LIB = ...

local texturePath = "Interface\\AddOns\\ArcaneWizardLibrary\\assets\\controls\\"
local colors = LIB.UIStyleData.colors

LIB.ControlData = {
	button = {
		height = 22,
		minimumWidth = 44,
		defaultWidth = 100,
		capWidth = 11,
		defaultStyle = "classic",
		styles = {
			classic = {
				normal = {
					texture = texturePath .. "button-normal.tga",
					text = { 1, 0.82, 0.15 }
				},
				highlight = {
					texture = texturePath .. "button-highlight.tga",
					text = { 1, 0.92, 0.35 }
				},
				pushed = {
					texture = texturePath .. "button-pushed.tga",
					text = { 0.95, 0.72, 0.12 }
				},
				disabled = {
					texture = texturePath .. "button-disabled.tga",
					text = { 0.45, 0.44, 0.42 }
				}
			},
			red = {
				normal = {
					texture = texturePath .. "button-red-normal.tga",
					text = { 1, 0.82, 0.15 }
				},
				highlight = {
					texture = texturePath .. "button-red-highlight.tga",
					text = { 1, 0.92, 0.35 }
				},
				pushed = {
					texture = texturePath .. "button-red-pushed.tga",
					text = { 0.95, 0.72, 0.12 }
				},
				disabled = {
					texture = texturePath .. "button-red-disabled.tga",
					text = { 0.45, 0.44, 0.42 }
				}
			}
		}
	},
	selection = {
		height = 22,
		minimumWidth = 44,
		iconSize = 18,
		textOffset = 24,
		optionSpacing = 4,
		textColors = {
			normal = { 1, 0.82, 0.15 },
			highlight = { 1, 0.92, 0.35 },
			disabled = { 0.45, 0.44, 0.42 }
		},
		textures = {
			checkbox = {
				normal = texturePath .. "checkbox-normal.tga",
				pushed = texturePath .. "checkbox-pushed.tga",
				disabled = texturePath .. "checkbox-disabled.tga",
				highlight = texturePath .. "checkbox-highlight.tga",
				checked = texturePath .. "checkbox-checked.tga",
				disabledChecked = texturePath .. "checkbox-disabled-checked.tga"
			},
			option = {
				normal = texturePath .. "option-normal.tga",
				pushed = texturePath .. "option-pushed.tga",
				disabled = texturePath .. "option-disabled.tga",
				highlight = texturePath .. "option-highlight.tga",
				checked = texturePath .. "option-checked.tga",
				disabledChecked = texturePath .. "option-disabled-checked.tga"
			}
		}
	},
	input = {
		height = 24,
		minimumWidth = 80,
		capWidth = 8,
		textLeftInset = 10,
		textRightInset = 24,
		clearButton = {
			size = 16,
			rightInset = 4,
			textures = {
				normal = texturePath .. "input-clear-normal.tga",
				highlight = texturePath .. "input-clear-highlight.tga",
				pushed = texturePath .. "input-clear-pushed.tga"
			}
		},
		textColors = {
			normal = { 0.92, 0.9, 0.84 },
			highlight = { 1, 0.96, 0.84 },
			focused = { 1, 1, 1 },
			placeholder = { 0.5, 0.48, 0.44 },
			disabled = { 0.45, 0.44, 0.42 }
		},
		textures = {
			normal = texturePath .. "input-normal.tga",
			highlight = texturePath .. "input-highlight.tga",
			focused = texturePath .. "input-focused.tga",
			disabled = texturePath .. "input-disabled.tga"
		}
	},
	dropdown = {
		height = 24,
		minimumWidth = 80,
		capWidth = 8,
		arrowSize = 19,
		textLeftInset = 10,
		textRightInset = 30,
		menuPadding = 4,
		menuRowHeight = 22,
		menuDividerHeight = 8,
		menuMaximumHeight = 286,
		menuMaximumWidth = 320,
		menuScrollStep = 22,
		submenuSpacing = 2,
		menuIconSize = 16,
		menuIndicatorSize = 14,
		menuTextColors = {
			normal = { 0.92, 0.90, 0.84 },
			highlight = { 1, 1, 1 },
			disabled = { 0.45, 0.44, 0.42 }
		},
		menuColors = {
			background = { 0.035, 0.035, 0.032, 0.98 },
			border = colors.edge,
			highlight = { 0.34, 0.27, 0.10, 0.75 },
			divider = colors.base,
			scrollTrack = colors.dark,
			scrollThumb = colors.edge
		},
		textColors = {
			normal = { 1, 0.82, 0.15 },
			highlight = { 1, 0.92, 0.35 },
			selected = { 1, 1, 1 },
			disabled = { 0.45, 0.44, 0.42 }
		},
		textures = {
			normal = texturePath .. "dropdown-normal.tga",
			highlight = texturePath .. "dropdown-highlight.tga",
			pushed = texturePath .. "dropdown-pushed.tga",
			disabled = texturePath .. "dropdown-disabled.tga",
			arrowNormal = texturePath .. "dropdown-arrow-normal.tga",
			arrowHighlight = texturePath .. "dropdown-arrow-highlight.tga",
			arrowPushed = texturePath .. "dropdown-arrow-pushed.tga",
			arrowDisabled = texturePath .. "dropdown-arrow-disabled.tga",
			submenuArrow = texturePath .. "submenu-arrow.tga"
		}
	}
}
