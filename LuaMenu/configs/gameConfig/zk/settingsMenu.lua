local invertZoomMult = -1

local TRUE = "true"
local FALSE = "false"

local lupsFileTarget = "lups.cfg"
local cmdcolorsFileTarget = "cmdcolors.txt"

local function UpdateLups(_, conf)
	conf = conf or (WG.Chobby and WG.Chobby.Configuration)
	local settings = conf and conf.settingsMenuValues
	if not settings then
		return
	end

	local lupsFileName = settings.ShaderDetail_file or "LuaMenu/configs/gameConfig/zk/lups/lups3.cfg"
	local lupsAirJetDisabled = ((settings.LupsAirJet == "On") and FALSE) or TRUE
	local lupsRibbonDisabled = ((settings.LupsRibbon == "On") and FALSE) or TRUE
	local lupsNanoParticlesDisabled = ((settings.LupsNanoParticles == "Cloud") and FALSE) or TRUE

	local LupsShieldShaderDisabled = ((settings.LupsShieldShader == "Off") and TRUE) or FALSE
	local LupsShieldHighQualityDisabled = ((settings.LupsShieldShader == "Default") and FALSE) or TRUE
	local lupsWaterRefractEnabled = ((settings.LupsWaterSettings == "Refraction" or settings.LupsWaterSettings == "Refract and Reflect") and 1) or 0
	local lupsWaterReflectEnabled = ((settings.LupsWaterSettings == "Reflection" or settings.LupsWaterSettings == "Refract and Reflect") and 1) or 0

	local sourceFile = VFS.LoadFile(lupsFileName)

	sourceFile = sourceFile:gsub("__AIR_JET__", lupsAirJetDisabled)
	sourceFile = sourceFile:gsub("__RIBBON__", lupsRibbonDisabled)
	sourceFile = sourceFile:gsub("__NANO_PARTICLES__", lupsNanoParticlesDisabled)
	sourceFile = sourceFile:gsub("__SHIELD_SPHERE_COLOR__", LupsShieldShaderDisabled)
	sourceFile = sourceFile:gsub("__SHIELD_SPHERE_HIGH_QUALITY__", LupsShieldHighQualityDisabled)
	sourceFile = sourceFile:gsub("__ENABLE_REFRACT__", lupsWaterRefractEnabled)
	sourceFile = sourceFile:gsub("__ENABLE_REFLECT__", lupsWaterReflectEnabled)

	local settingsFile = io.open(lupsFileTarget, "w")
	settingsFile:write(sourceFile)
	settingsFile:close()
end

local function UpdateCmdcolors(_, conf)
	conf = conf or (WG.Chobby and WG.Chobby.Configuration)
	local settings = conf and conf.settingsMenuValues
	if not settings then
		return
	end

	local cmdAlpha = (settings.CommandAlpha or 70)/100
	local cmdAlphaDark
	if cmdAlpha >= 0.7 then
		cmdAlphaDark = cmdAlpha + 0.1
	elseif cmdAlpha >= 0.6 then
		cmdAlphaDark = cmdAlpha + 0.05
	else
		cmdAlphaDark = cmdAlpha + 0.02
	end
	
	local queueIconAlpha = (settings.QueueIconAlpha or 50)/100

	local cmdcolorsFileName = "LuaMenu/configs/gameConfig/zk/cmdcolors/cmdcolors_source.txt"
	local sourceFile = VFS.LoadFile(cmdcolorsFileName)

	sourceFile = sourceFile:gsub("__CMD_ALPHA__", cmdAlpha)
	sourceFile = sourceFile:gsub("__CMD_ALPHA_DARK__", cmdAlphaDark)
	sourceFile = sourceFile:gsub("__QUEUE_ICON_ALPHA__", queueIconAlpha)

	local settingsFile = io.open(cmdcolorsFileTarget, "w")
	settingsFile:write(sourceFile)
	settingsFile:close()
	
	return {
		CmdAlpha = cmdAlpha,
		CmdAlphaDark = cmdAlphaDark,
		CmdIconAlpha = queueIconAlpha,
	}
end

local function GetUiScaleParameters()
	local realWidth, realHeight = Spring.Orig.GetViewSizes()
	local defaultUiScale = 100
	if realHeight > 1900 then
		defaultUiScale = 200
	elseif realHeight > 1220 or realWidth > 2500 then
		defaultUiScale = 125
	end
	local maxUiScale = math.max(2, realWidth/1000)*100
	local minUiScale = math.min(0.5, realWidth/4000)*100
	return defaultUiScale, maxUiScale, minUiScale
end

local defaultUiScale, maxUiScale, minUiScale = GetUiScaleParameters()

local settingsConfig = {
	{
		name = "Graphics",
		presets = {
			{
				name = "Compat.",
				settings = {
					WaterType = "Basic",
					WaterQuality = "Low",
					DeferredRendering = "Off",
					UnitReflections = "Off",
					Shadows = "None",
					ShadowMapSize = "1024",
					ShadowDetail = "Low",
					ParticleLimit = "2000",
					TerrainDetail = "Minimal",
					SoftParticles = "Compatibility",
					VegetationDetail = "Minimal",
					FeatureFade = "On",
					CompatibilityMode = "On",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "Off",
					VSync = "Off",
					ShaderDetail = "Minimal",
					LupsAirJet = "Off",
					LupsRibbon = "Off",
					LupsNanoParticles = "Beam",
					LupsShieldShader = "Off",
					LupsWaterSettings = "Off",
					FancySky = "Off",
					UseNewChili = "Off",
				}
			},
			{
				name = "Lowest",
				settings = {
					WaterType = "Reflective",
					WaterQuality = "Low",
					DeferredRendering = "Off",
					UnitReflections = "Low",
					Shadows = "None",
					ShadowMapSize = "1024",
					ShadowDetail = "Low",
					ParticleLimit = "6000",
					TerrainDetail = "Low",
					SoftParticles = "Enabled",
					VegetationDetail = "Low",
					FeatureFade = "On",
					CompatibilityMode = "Off",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "Low",
					VSync = "Off",
					ShaderDetail = "Minimal",
					LupsAirJet = "Off",
					LupsRibbon = "Off",
					LupsNanoParticles = "Beam",
					LupsShieldShader = "Off",
					LupsWaterSettings = "Off",
					FancySky = "Off",
					UseNewChili = "Off",
				}
			},
			{
				name = "Low",
				settings = {
					WaterType = "Bumpmapped",
					WaterQuality = "Low",
					DeferredRendering = "Off",
					UnitReflections = "Low",
					Shadows = "Units Only",
					ShadowMapSize = "2048",
					ShadowDetail = "Low",
					ParticleLimit = "12000",
					TerrainDetail = "Low",
					SoftParticles = "Enabled",
					VegetationDetail = "Low",
					FeatureFade = "On",
					CompatibilityMode = "Off",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "Low",
					VSync = "Off",
					ShaderDetail = "Low",
					LupsAirJet = "Off",
					LupsRibbon = "On",
					LupsNanoParticles = "Beam",
					LupsShieldShader = "Default",
					LupsWaterSettings = "Off",
					FancySky = "Off",
					UseNewChili = "Off",
				}
			},
			{
				name = "Medium",
				settings = {
					WaterType = "Bumpmapped",
					WaterQuality = "Medium",
					DeferredRendering = "On",
					UnitReflections = "Medium",
					Shadows = "Units and Terrain",
					ShadowMapSize = "2048",
					ShadowDetail = "Medium",
					ParticleLimit = "15000",
					TerrainDetail = "Medium",
					SoftParticles = "Enabled",
					VegetationDetail = "Medium",
					FeatureFade = "On",
					CompatibilityMode = "Off",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "Low",
					VSync = "Off",
					ShaderDetail = "Medium",
					LupsAirJet = "On",
					LupsRibbon = "On",
					LupsNanoParticles = "Cloud",
					LupsShieldShader = "Default",
					LupsWaterSettings = "Off",
					FancySky = "Off",
					UseNewChili = "Off",

				}
			},
			{
				name = "High",
				settings = {
					WaterType = "Bumpmapped",
					WaterQuality = "High",
					DeferredRendering = "On",
					UnitReflections = "Medium",
					Shadows = "Units and Terrain",
					ShadowMapSize = "8192",
					ShadowDetail = "High",
					ParticleLimit = "25000",
					TerrainDetail = "High",
					SoftParticles = "Enabled",
					VegetationDetail = "High",
					FeatureFade = "On",
					CompatibilityMode = "Off",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "High",
					VSync = "Off",
					ShaderDetail = "High",
					LupsAirJet = "On",
					LupsRibbon = "On",
					LupsNanoParticles = "Cloud",
					LupsShieldShader = "Default",
					LupsWaterSettings = "Off",
					FancySky = "Off",
					UseNewChili = "Off",
				}
			},
			{
				name = "Ultra",
				settings = {
					WaterType = "Bumpmapped",
					WaterQuality = "Ultra",
					DeferredRendering = "On",
					UnitReflections = "Ultra",
					Shadows = "Units and Terrain",
					ShadowMapSize = "16384",
					ShadowDetail = "Ultra",
					ParticleLimit = "50000",
					TerrainDetail = "Ultra",
					SoftParticles = "Enabled",
					VegetationDetail = "Ultra",
					FeatureFade = "Off",
					CompatibilityMode = "Off",
					AtiIntelCompatibility_2 = "Automatic",
					AntiAliasing = "High",
					VSync = "Off",
					ShaderDetail = "Ultra",
					LupsAirJet = "On",
					LupsRibbon = "On",
					LupsNanoParticles = "Cloud",
					LupsShieldShader = "Default",
					LupsWaterSettings = "Refract and Reflect",
					FancySky = "On",
					UseNewChili = "Off",
				}
			},
		},

		-- FIXME: this list is in dire need of resorting
		settings = {
			{
				name = "DisplayMode",
				humanName = "Ingame Display Mode",
				displayModeToggle = true,
			},
			{
				name = "LobbyDisplayMode",
				humanName = "Menu Display Mode",
				lobbyDisplayModeToggle = true,
			},
			{
				name = "ActiveGraphicsLabel",
				humanName = "Graphics Driver Selected: ",
				isLabelSetting = true,
				desc = Platform.gpuVendor,
				size = 2,
			},
			{
				name = "AtiIntelCompatibility_2",
				humanName = "ATI/Intel Compatibility",
				options = {
					{
						name = "On",
						applyFunction = function(_, conf)
							conf:UpdateFixedSettings(conf.AtiIntelSettingsOverride)
							Spring.Echo("Set ATI/intel/other non-nvidia compatibility state: Enabled")
							return
						end
					},
					{
						name = "Automatic",
						applyFunction = function(_, conf)
							if conf:GetIsNotRunningNvidia() then
								conf:UpdateFixedSettings(conf.AtiIntelSettingsOverride)
								Spring.Echo("Set ATI/intel/other non-nvidia compatibility state: Enabled (Automatic)")
								return
							end
							conf:UpdateFixedSettings()
							Spring.Echo("Set ATI/intel/other non-nvidia compatibility state: Disabled (Automatic)")
							return
						end
					},
					{
						name = "Off",
						applyFunction = function(_, conf)
							conf:UpdateFixedSettings()
							Spring.Echo("Set ATI/intel/other non-nvidia compatibility state: Disabled")
							return
						end
					},
				},
			},
			{
				name = "AntiAliasing",
				humanName = "Anti Aliasing",
				options = {
					{
						name = "Off",
						apply = {
							MSAALevel = 1, -- Required, see https://springrts.com/mantis/view.php?id=5625
							FSAA = 0,
							SmoothLines = 0,
							SmoothPoints = 0,
						}
					},
					{
						name = "Low",
						apply = {
							MSAALevel = 4,
							FSAA = 1,
							SmoothLines = 1,
							SmoothPoints = 1,
						}
					},
					{
						name = "Low/Medium",
						apply = {
							MSAALevel = 4,
							FSAA = 1,
							SmoothLines = 2,
							SmoothPoints = 2,
						}
					},
					{
						name = "Medium",
						apply = {
							MSAALevel = 6,
							FSAA = 1,
							SmoothLines = 2,
							SmoothPoints = 2,
						}
					},
					{
						name = "High",
						apply = {
							MSAALevel = 8,
							FSAA = 1,
							SmoothLines = 3,
							SmoothPoints = 3,
						}
					},
					{
						name = "Very High",
						apply = {
							MSAALevel = 16,
							FSAA = 1,
							SmoothLines = 6,
							SmoothPoints = 6,
						}
					},
				},
			},
			{
				name = "LupsAirJet",
				humanName = "Aircraft Jets",
				options = {
					{
						name = "On",
						applyFunction = UpdateLups,
					},
					{
						name = "Off",
						applyFunction = UpdateLups,
					},
				},
			},
			{
				name = "LupsRibbon",
				humanName = "Aircraft Wing Trails",
				options = {
					{
						name = "On",
						applyFunction = UpdateLups,
					},
					{
						name = "Off",
						applyFunction = UpdateLups,
					},
				},
			},
			{
				name = "CompatibilityMode",
				humanName = "Compatibility Mode",
				options = {
					{
						name = "On",
						apply = {
							LoadingMT = 0,
							AdvUnitShading = 0,
							AdvMapShading = 0,
							LuaShaders = 0,
							ForceDisableShaders = 1,
							UsePBO = 0,
							["3DTrees"] = 0,
							MaxDynamicMapLights = 0,
							MaxDynamicModelLights = 0,
							ROAM = 1,
						}
					},
					{
						name = "Off",
						apply = {
							LoadingMT = 0, -- See https://github.com/spring/spring/commit/bdd6b641960759ccadf3e7201e37f2192d873791
							AdvUnitShading = 1,
							AdvMapShading = 1,
							LuaShaders = 1,
							ForceDisableShaders = 0,
							UsePBO = 1,
							["3DTrees"] = 1,
							MaxDynamicMapLights = 1,
							MaxDynamicModelLights = 1,
							ROAM = 1, --Maybe ROAM = 0 when the new renderer is fully developed
						}
					},
				},
			},
			{
				name = "LupsNanoParticles",
				humanName = "Construction Effect",
				options = {
					{
						name = "Cloud",
						applyFunction = UpdateLups,
					},
					{
						name = "Beam",
						applyFunction = UpdateLups,
					},
				},
			},
			{
				name = "DeferredRendering",
				humanName = "Deferred Rendering",
				options = {
					{
						name = "On",
						apply = {
							AllowDeferredModelRendering = 1,
							AllowDeferredMapRendering = 1,
						}
					},
					{
						name = "Off",
						apply = {
							AllowDeferredModelRendering = 0,
							AllowDeferredMapRendering = 0,
						}
					},
				},
			},
			{
				name = "UseNewChili",
				humanName = "Experimental Interface Renderer",
				options = {
					{
						name = "Off",
						apply = {
							ZKUseNewChiliRTT = 0,
						}
					},
					{
						name = "On",
						apply = {
							ZKUseNewChiliRTT = 1,
						}
					},
				},
			},
			{
				name = "MaxDynamicMapLights",
				humanName = "Max DynamicMap Lights",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 5,
				stepValue = 1,
				applyFunction = function(value)
					return {
						MaxDynamicMapLights = value,
					}
				end,
			},
			{
				name = "MaxDynamicModelLights",
				humanName = "Max Model Lights",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 5,
				stepValue = 1,
				applyFunction = function(value)
					return {
						MaxDynamicMapLights = value,
					}
				end,
			},
			{
				name = "MinDrawFPS",
				humanName = "Minimal FPS",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 1,
				maxValue = 100,
				stepValue = 1,
				applyFunction = function(value)
					return {
						MinDrawFPS = value,
					}
				end,
			},
			{
				name = "MinSimDrawBalance",
				humanName = "Minimal Draw vs Sim",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0.05,
				maxValue = 0.95,
				stepValue = 0.01,
				applyFunction = function(value)
					return {
						MinSimDrawBalance = value,
					}
				end,
			},
			{
				name = "UnitGhostIconsDimming",
				humanName = "Ghost Building Alpha",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				stepValue = 0.05,
				maxValue = 1,
				applyFunction = function(value)
					return {
						UnitGhostIconsDimming = value,
					}
				end,
			},
			{
				name = "UnitTransparency",
				humanName = "Unit Transparency",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 1,
				stepValue = 0.01,
				applyFunction = function(value)
					return {
						UnitTransparency = value,
					}
				end,
			},
			{
				name = "MaxTextureAtlasSize",
				humanName = "Texture Atlas size",
				options = {
					{
						name="512",
						apply = {
							MaxTextureAtlasSizeX = 512,
							MaxTextureAtlasSizeY = 512,
						}
					},
					{
						name="1024",
						apply = {
							MaxTextureAtlasSizeX = 1024,
							MaxTextureAtlasSizeY = 1024,
						}
					},
					{
						name="2048",
						apply = {
							MaxTextureAtlasSizeX = 2048,
							MaxTextureAtlasSizeY = 2048,
						}
					},
					{
						name="4096 (Default)",
						apply = {
							MaxTextureAtlasSizeX = 4096,
							MaxTextureAtlasSizeY = 4096,
						}
					},
					{
						name="8192",
						apply = {
							MaxTextureAtlasSizeX = 8192,
							MaxTextureAtlasSizeY = 8192,
						}
					},
					{
						name="16384",
						apply = {
							MaxTextureAtlasSizeX = 16384,
							MaxTextureAtlasSizeY = 16384,
						}
					},
					{
						name="32768",
						apply = {
							MaxTextureAtlasSizeX = 32768,
							MaxTextureAtlasSizeY = 32768,
						}
					},
				},
			},
			{
				name = "CompressTextures",
				humanName = "Compress Textures",
				options = {
					{
						name = "Off",
						apply = {
							CompressTextures = 0,
						}
					},
					{
						name = "On",
						apply = {
							CompressTextures = 1,
						}
					},
				},
			},
			{
				name = "TextureMemPoolSize",
				humanName = "Texture Mem Pool Size",
				options = {
					{
						name = "0",
						apply = {
							TextureMemPoolSize = 0,
						}
					},
					{
						name = "512 (Default)",
						apply = {
							TextureMemPoolSize = 512,
						}
					},
					{
						name = "1024",
						apply = {
							TextureMemPoolSize = 1024,
						}
					},
					{
						name = "2048",
						apply = {
							TextureMemPoolSize = 2048,
						}
					},
					{
						name = "4096",
						apply = {
							TextureMemPoolSize = 4096,
						}
					},
				},
			},
			{
				name = "HighResTextures",
				humanName = "High Res Textures",
				options = {
					{
						name = "On (Default)",
						apply = {
							HighResInfoTexture = 1,
						}
					},
					{
						name = "Off",
						apply = {
							HighResInfoTexture = 0,
						}
					},
				},
			},
			{
				name = "HighResLos",
				humanName = "High Res Los",
				options = {
					{
						name = "On",
						apply = {
							HighResLos = 1,
						}
					},
					{
						name = "Off",
						apply = {
							HighResLos = 0,
						}
					},
				},
			},
			-- {
			--  name = "CustomFSAA",
			--  humanName = "Custom FSAA",
			--  options = {
			--      {
			--          name = "On",
			--          apply = {
			--              FSAA = 1,
			--          },
			--      },
			--      {
			--          name = "Off",
			--          apply = {
			--              FSAA = 0,
			--          },

			--      },
			--  },
			-- },

			-- {
			--  name = "CustomMSAALevel",
			--  humanName = "Custom MSAA Level",
			--  isNumberSetting = true,
			--  minValue = 0,
			--  maxValue = 32,
			--  applyFunction = function(value, conf)
			--      conf = conf or (WG.Chobby and WG.Chobby.Configuration)
			--      local MSAALevel = 8
			--      if conf  then
			--          MSAALevel = conf.MSAALevel or MSAALevel
			--      end
			--      return {
			--          MSAALevel = value or MSAALevel,
			--      }
			--  end,
			-- },
			-- {
			--  name = "CustomSmoothPoints",
			--  humanName = "Custom Smooth Points",
			--  isNumberSetting = true,
			--  minValue = 0,
			--  maxValue = 6,
			--  applyFunction = function(value, conf)
			--      conf = conf or (WG.Chobby and WG.Chobby.Configuration)
			--      local SmoothPoints = 1
			--      if conf then
			--          SmoothPoints = conf.SmoothPoints or SmoothPoints
			--      end
			--      return {
			--          SmoothPoints = value or SmoothPoints,
			--      }
			--  end,
			-- },
			-- {
			--  name = "CustomSmoothLines",
			--  humanName = "Custom Smooth Lines",
			--  isNumberSetting = true,
			--  minValue = 0,
			--  maxValue = 6,
			--  applyFunction = function(value, conf)
			--      conf = conf or (WG.Chobby and WG.Chobby.Configuration)
			--      local SmoothLines = 1
			--      if conf  then
			--          SmoothLines = conf.SmoothLines or SmoothLines
			--      end
			--      return {
			--          SmoothLines = value or SmoothLines,
			--      }
			--  end,
			-- },
			{
				name = "FancySky",
				humanName = "Fancy Sky",
				options = {
					{
						name = "On",
						apply = {
							DynamicSky = 1,
							AdvSky = 1,
						}
					},
					{
						name = "Off",
						apply = {
							DynamicSky = 0,
							AdvSky = 0,
						}
					},
				},
			},
			{
				name = "ParticleLimit",
				humanName = "Particle Limit",
				options = {
					{
						name = "200",
						apply = {
							MaxParticles = 200
						}
					},
					{
						name = "500",
						apply = {
							MaxParticles = 500
						}
					},
					{
						name = "2000",
						apply = {
							MaxParticles = 2000
						}
					},
					{
						name = "4000",
						apply = {
							MaxParticles = 4000
						}
					},
					{
						name = "6000",
						apply = {
							MaxParticles = 6000
						}
					},
					{
						name = "9000",
						apply = {
							MaxParticles = 9000
						}
					},
					{
						name = "12000",
						apply = {
							MaxParticles = 12000
						}
					},
					{
						name = "15000",
						apply = {
							MaxParticles = 15000
						}
					},
					{
						name = "20000",
						apply = {
							MaxParticles = 15000
						}
					},
					{
						name = "25000",
						apply = {
							MaxParticles = 25000
						}
					},
					{
						name = "35000",
						apply = {
							MaxParticles = 25000
						}
					},
					{
						name = "50000",
						apply = {
							MaxParticles = 50000
						}
					},
				},
			},
			{
				name = "NanoParticleLimit",
				humanName = "Nano Particle Limit",
				options = {
					{
						name = "200",
						apply = {
							MaxNanoParticles = 200
						}
					},
					{
						name = "500",
						apply = {
							MaxNanoParticles = 500
						}
					},
					{
						name = "2000",
						apply = {
							MaxNanoParticles = 2000
						}
					},
					{
						name = "4000",
						apply = {
							MaxNanoParticles = 4000
						}
					},
					{
						name = "6000",
						apply = {
							MaxNanoParticles = 6000
						}
					},
					{
						name = "9000",
						apply = {
							MaxNanoParticles = 9000
						}
					},
					{
						name = "12000",
						apply = {
							MaxNanoParticles = 12000
						}
					},
					{
						name = "15000",
						apply = {
							MaxNanoParticles = 15000
						}
					},
					{
						name = "20000",
						apply = {
							MaxNanoParticles = 20000
						}
					},
					{
						name = "25000",
						apply = {
							MaxNanoParticles = 25000
						}
					},
					{
						name = "35000",
						apply = {
							MaxNanoParticles = 35000
						}
					},
					{
						name = "50000",
						apply = {
							MaxNanoParticles = 50000
						}
					},
				},
			},
			{
				name = "FeatureFade",
				humanName = "Rock and Wreck Fade",
				options = {
					{
						name = "On",
						apply = {
							FeatureDrawDistance = 6000,
							FeatureFadeDistance = 4500,
						}
					},
					{
						name = "Off",
						apply = {
							FeatureDrawDistance = 600000,
							FeatureFadeDistance = 600000,
						}
					},
					{
						name = "No Feature",
						apply = {
							FeatureDrawDistance = 0,
							FeatureFadeDistance = 0,
						}
					},

				},
			},
			{
				name = "ShaderDetail",
				humanName = "Shader Detail",
				fileTarget = lupsFileTarget,
				applyFunction = UpdateLups,
				options = {
					{
						name = "Minimal",
						file = "LuaMenu/configs/gameConfig/zk/lups/lups0.cfg"
					},
					{
						name = "Low",
						file = "LuaMenu/configs/gameConfig/zk/lups/lups1.cfg"
					},
					{
						name = "Medium",
						file = "LuaMenu/configs/gameConfig/zk/lups/lups2.cfg"
					},
					{
						name = "High",
						file = "LuaMenu/configs/gameConfig/zk/lups/lups3.cfg"
					},
					{
						name = "Ultra",
						file = "LuaMenu/configs/gameConfig/zk/lups/lups4.cfg"
					},
				},
			},
			{
				name = "LupsWaterSettings",
				humanName = "Shaders Affected by Water",
				options = {
					{
						name = "Off",
						applyFunction = UpdateLups,
					},
					{
						name = "Refraction",
						applyFunction = UpdateLups,
					},
					{
						name = "Reflection",
						applyFunction = UpdateLups,
					},
					{
						name = "Refract and Reflect",
						applyFunction = UpdateLups,
					},
				},
			},
			{
				name = "LupsShieldShader",
				humanName = "Shield Effect Shader",
				options = {
					{
						name = "Default",
						applyFunction = UpdateLups,
					},
					{
						name = "Simple",
						applyFunction = UpdateLups,
					},
					{
						name = "Off",
						applyFunction = UpdateLups,
					},
				},
			},
			{
				name = "Shadows",
				humanName = "Shadows",
				options = {
					{
						name = "None",
						apply = {
							Shadows = 0
						}
					},
					{
						name = "Only unit lighting",
						apply = {
							Shadows = 6 -- or 7
						}
					},
					{
						name = "Units",
						apply = {
							Shadows = 2 -- or 3
						}
					},
					{
						name = "Terrain",
						apply = {
							Shadows = 4 -- or 5
						}
					},
					{
						name = "Units and Terrain",
						apply = {
							Shadows = 1
						}
					},
				},
			},
			{
				name = "ShadowMapSize",
				humanName = "Shadow Map Size",
				options = {
					{
						name = "1024",
						apply = {
							ShadowMapSize = 1024
						}
					},
					{
						name = "2048",
						apply = {
							ShadowMapSize = 2048
						}
					},
					{
						name = "4096",
						apply = {
							ShadowMapSize = 4096
						}
					},
					{
						name = "8192",
						apply = {
							ShadowMapSize = 8192
						}
					},
					{
						name = "16384",
						apply = {
							ShadowMapSize = 16384
						}
					},
				},
			},
			{
				name = "SoftParticles",
				humanName = "Soft Particles",
				options = {
					{
						name = "Disabled",
						apply = {
							SoftParticles = 0
						}
					},
					{
						name = "Compatibility",
						apply = {
							SoftParticles = 1
						}
					},
					{
						name = "Enabled",
						apply = {
							SoftParticles = 2
						}
					},
				},
			},
			{
				name = "TerrainDetail",
				humanName = "Terrain Detail",
				options = {
					{
						name = "Super low",
						apply = {
							GroundScarAlphaFade = 0,
							GroundDecals = 0,
							GroundDetail = 25,
						}
					},
					{
						name = "Minimal",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 0,
							GroundDetail = 50,
						}
					},
					{
						name = "Low",
						apply = {
							GroundScarAlphaFade = 0,
							GroundDecals = 1,
							GroundDetail = 70,
						}
					},
					{
						name = "Medium",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 2,
							GroundDetail = 90,
						}
					},
					{
						name = "High",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 5,
							GroundDetail = 120,
						}
					},
					{
						name = "Ultra",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 10,
							GroundDetail = 180,
						}
					},
				},
			},
			{
				name = "UnitReflections",
				humanName = "Unit Reflection Quality",
				options = {
					{
						name="Off",
						apply = {
							CubeTexSizeReflection = 1,
							CubeTexSizeSpecular = 1,
						}
					},
					{
						name="Low",
						apply = {
							CubeTexSizeReflection = 64,
							CubeTexSizeSpecular = 64,
						}
					},
					{
						name="Medium",
						apply = {
							CubeTexSizeReflection = 128,
							CubeTexSizeSpecular = 128,
						}
					},
					{
						name="High",
						apply = {
							CubeTexSizeReflection = 256,
							CubeTexSizeSpecular = 256,
						}
					},
					{
						name="Ultra",
						apply = {
							CubeTexSizeReflection = 1024,
							CubeTexSizeSpecular = 1024,
						}
					},
				},
			},
			{
				name = "VegetationDetail",
				humanName = "Vegetation Detail",
				options = {
					{
						name = "Inexistant",
						apply = {
							TreeRadius = 100,
							GrassDetail = 0,
							["3DTrees"] = 0,
						}
					},
					{
						name = "Minimal",
						apply = {
							TreeRadius = 1000,
							GrassDetail = 0,
						}
					},
					{
						name = "Low",
						apply = {
							TreeRadius = 1000,
							GrassDetail = 0,
						}
					},
					{
						name = "Medium",
						apply = {
							TreeRadius = 1200,
							GrassDetail = 0,
						}
					},
					{
						name = "High",
						apply = {
							TreeRadius = 1500,
							GrassDetail = 0,
						}
					},
					{
						name = "Ultra",
						apply = {
							TreeRadius = 2500,
							GrassDetail = 0,
						}
					},
					{
						name = "Ridiculous",
						apply = {
							TreeRadius = 2500,
							GrassDetail = 0,
						}
					},
				},
			},
			{
				name = "VSync",
				humanName = "Vertical Sync",
				options = {
					{
						name = "Standard",
						apply = {
							VSync = 1,
						}
					},
					{
						name = "Adaptive",
						apply = {
							VSync = -1,
						}
					},
					{
						name = "Off",
						apply = {
							VSync = 0,
						}
					},
				},
			},

			{
				name = "WaterType",
				humanName = "Water Type",
				options = {
					{
						name = "Basic",
						apply = {
							Water = 0,
						}
					},
					{
						name = "Reflective",
						apply = {
							Water = 1,
						}
					},
					{
						name = "Refractive",
						apply = {
							Water = 2,
						}
					},
					--{
					--  name = "Dynamic",
					--  apply = {
					--      Water = 3,
					--  }
					--},
					{
						name = "Bumpmapped",
						apply = {
							Water = 4,
						}
					},
				},
			},
			{
				name = "WaterQuality",
				humanName = "Water Quality",
				options = {
					{
						name = "Super Low",
						apply = {
							BumpWaterAnisotropy = 0,
							BumpWaterBlurReflection = 0,
							BumpWaterReflection = 0,
							BumpWaterRefraction = 0,
							BumpWaterDepthBits = 8,
							BumpWaterShoreWaves = 0,
							BumpWaterTexSizeReflection = 32,
						}
					},
					{
						name = "Low",
						apply = {
							BumpWaterAnisotropy = 0,
							BumpWaterBlurReflection = 0,
							BumpWaterReflection = 0,
							BumpWaterRefraction = 0,
							BumpWaterDepthBits = 16,
							BumpWaterShoreWaves = 0,
							BumpWaterTexSizeReflection = 64,
						}
					},
					{
						name = "Medium",
						apply = {
							BumpWaterAnisotropy = 0,
							BumpWaterBlurReflection = 1,
							BumpWaterReflection = 1,
							BumpWaterRefraction = 1,
							BumpWaterDepthBits = 24,
							BumpWaterShoreWaves = 1,
							BumpWaterTexSizeReflection = 128,
						}
					},
					{
						name = "High",
						apply = {
							BumpWaterAnisotropy = 2,
							BumpWaterBlurReflection = 1,
							BumpWaterReflection = 2,
							BumpWaterRefraction = 1,
							BumpWaterDepthBits = 32,
							BumpWaterShoreWaves = 1,
							BumpWaterTexSizeReflection = 256,
						}
					},
					{
						name = "Ultra",
						apply = {
							BumpWaterAnisotropy = 2,
							BumpWaterBlurReflection = 1,
							BumpWaterReflection = 2,
							BumpWaterRefraction = 2,
							BumpWaterDepthBits = 32,
							BumpWaterShoreWaves = 1,
							BumpWaterTexSizeReflection = 1024,
						}
					},
				},
			},
		},
	},
	{
		name = "Game",
		presets = {
			{
				name = "Default",
				settings = {
					--IconDistance = 151,
					InterfaceScale = defaultUiScale,
					MouseZoomSpeed = 25,
					InvertZoom = "Off",
					HardwareCursor = "On",



					TextToSpeech = "On",
					EdgeScroll = "On",
					CommandAlpha = 60,
					QueueIconAlpha = 45,
					MiddlePanSpeed = 15,
					CameraPanSpeed = 50,
					NetworkSettings = "Balanced",
					SmoothBuffer = "Off",
				}
			},
		},
		settings = {
			--{
			--  name = "IconDistance",
			--  humanName = "Icon Distance",
			--  isNumberSetting = true,
			--  applyName = "UnitIconDist",
			--  minValue = 0,
			--  maxValue = 10000,
			--  springConversion = function(value)
			--      return value
			--  end,
			--},
			{
				name = "SetCoreAffinity",
				humanName = "Set Core Affinity For Main Thread",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 3,
				stepValue = 1,
				applyFunction = function(value)
					return {
						SetCoreAffinity = value,
					}
				end,
			},
			-- {
			--  name = "SetCoreAffinitySim",
			--  humanName = "Set Core Affinity For Sim",
			--  options = {
			--      {
			--          name = "0",
			--          apply = {
							
			--              SetCoreAffinitySim = 0,
			--          }
			--      },
			--      {
			--          name = "1",
			--          apply = {
			--              SetCoreAffinitySim = 1,
			--          }
			--      },
			--  },
			-- },
			-- {
			-- 	name = "WorkerThreadCount",
			-- 	humanName = "Worker Threads",
			-- 	options = {
			-- 		{
			-- 			name = "Default",
			-- 			apply = {
							
			-- 				WorkerThreadCount = -1,
			-- 			}
			-- 		},
			-- 		{
			-- 			name = "1",
			-- 			apply = {
			-- 				WorkerThreadCount = 1,
			-- 			}
			-- 		},
			-- 	},
			-- },
			{
				name = "WorkerThreadCount",
				humanName = "Worker Threads",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = -1,
				maxValue = 10,
				stepValue = 1,
				applyFunction = function(value)
					return {
						WorkerThreadCount = value,
					}
				end,
			},
			{
				name = "PathingThreadCount",
				humanName = "Pathing Threads",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 10,
				stepValue = 1,
				applyFunction = function(value)
					return {
						PathingThreadCount = value,
					}
				end,
			},
			{
				name = "AnimationMT",
				humanName = "Animation Multi Threaded",
				options = {
					{
						name = "On (Default)",
						apply = {
							AnimationMT = 1,
						}
					},
					{
						name = "Off",
						apply = {
							
							AnimationMT = 0,
						}
					},
				},
			},
			{
				name = "PreLoadModels",
				humanName = "PreLoad Models",
				options = {
					{
						name = "On (Default)",
						apply = {
							PreLoadModels = 1,
						}
					},
					{
						name = "Off",
						apply = {
							
							PreLoadModels = 0,
						}
					},
				},
			},
			{
				name = "UseLuaMemPools",
				humanName = "Preallocate Lua Memory",
				options = {
					{
						name = "On (Default)",
						apply = {
							UseLuaMemPools = 1,
						}
					},
					{
						name = "Off",
						apply = {
							UseLuaMemPools = 0,
						}
					},
				},
			},
			{
				name = "SmoothTimeOffset",
				humanName = "Frame Smoothing",
				isNumberSetting = true,
				minValue = -1,
				maxValue = 20,
				applyFunction = function(value)
					return {
						SmoothTimeOffset = value,
					}
				end,
			},
			{
				name = "UpdateBoundingVolumeMT",
				humanName = "Bounding Vol Multi Threaded",
				options = {
					{
						name = "On (Default)",
						apply = {
							UpdateBoundingVolumeMT = 1,
						}
					},
					{
						name = "Off",
						apply = {
							UpdateBoundingVolumeMT = 0,
						}
					},
				},
			},
			{
				name = "UpdateWeaponVectorsMT",
				humanName = "Update Weap Vec Multi Threaded",
				options = {
					{
						name = "On (Default)",
						apply = {
							UpdateWeaponVectorsMT = 1,
						}
					},
					{
						name = "Off",
						apply = {
							UpdateWeaponVectorsMT = 0,
						}
					},
				},
			},
			{
				name = "LoadingMT",
				humanName = "Load Game in separate thread",
				options = {
					{
						name = "Off (Default)",
						apply = {
							LoadingMT = 0,
						}
					},
					{
						name = "On",
						apply = {
							LoadingMT = 1,
						}
					},
				},
			},
			{

				name = "ThreadPinPolicy",
				humanName = "Thread Pin Policy",
				options = {
					{
						name = "Off",
						apply = {
							ThreadPinPolicy = 0,
						}
					},
					{
						name = "System Default (Default)",
						apply = {
							
							ThreadPinPolicy = 1,
						}
					},
					{
						name = "Exclusive Perf Core",
						apply = {
							
							ThreadPinPolicy = 2,
						}
					},
					{
						name = "Share Perf Core",
						apply = {
							
							ThreadPinPolicy = 3,
						}
					},
				},
			},
			{
				name = "InterfaceScale",
				humanName = "Game Interface Scale",
				isNumberSetting = true,
				minValue = minUiScale,
				maxValue = maxUiScale,
				isPercent = true,
				applyFunction = function(value)
					if Spring.GetGameName() ~= "" then
						Spring.SendLuaUIMsg("SetInterfaceScale " .. value)
					end
					return {
						interfaceScale = value,
					}
				end,
			},
			{
				name = "MouseZoomSpeed",
				humanName = "Mouse Zoom Speed",
				isNumberSetting = true,
				applyName = "ScrollWheelSpeed",
				minValue = 1,
				maxValue = 500,
				springConversion = function(value)
					return value*invertZoomMult
				end,
			},
			{
				name = "InvertZoom",
				humanName = "Invert Zoom",
				options = {
					{
						name = "On",
						applyFunction = function(_, conf)
							conf = conf or (WG.Chobby and WG.Chobby.Configuration)
							if not conf then
								return {}
							end
							invertZoomMult = 1
							local currentZoom = conf.settingsMenuValues["MouseZoomSpeed"] or 25
							return {
								ScrollWheelSpeed = currentZoom,
							}
						end
					},
					{
						name = "Off",
						applyFunction = function(_, conf)
							conf = conf or (WG.Chobby and WG.Chobby.Configuration)
							if not conf then
								return {}
							end
							invertZoomMult = -1
							local currentZoom = conf.settingsMenuValues["MouseZoomSpeed"] or 25
							return {
								ScrollWheelSpeed = currentZoom * -1,
							}
						end
					},
				},
			},
			{
				name = "HardwareCursor",
				humanName = "Hardware Cursor",
				options = {
					{
						name = "On",
						apply = {
							HardwareCursor = 1,
						}
					},
					{
						name = "Off",
						apply = {
							HardwareCursor = 0,
						}
					},
				},
			},
			{
				name = "TextToSpeech",
				humanName = "Text To Speech",
				options = {
					{
						name = "On",
						applyFunction = function(_, conf)
							conf = conf or (WG.Chobby and WG.Chobby.Configuration)
							if not conf then
								return {}
							end
							conf:SetConfigValue("enableTextToSpeech", true)
							return false
						end
					},
					{
						name = "Off",
						applyFunction = function(_, conf)
							conf = conf or (WG.Chobby and WG.Chobby.Configuration)
							if not conf then
								return false
							end
							conf:SetConfigValue("enableTextToSpeech", false)
							return false
						end
					},
				},
			},
			{
				name = "EdgeScroll",
				humanName = "Screen Edge Scroll",
				options = {
					{
						name = "On",
						apply = {
							FullscreenEdgeMove = 1,
							WindowedEdgeMove = 1,
						}
					},
					{
						name = "Off",
						apply = {
							FullscreenEdgeMove = 0,
							WindowedEdgeMove = 0,
						}
					},
				},
			},
			{
				name = "EdgeMoveDynamic",
				humanName = "Edge Dynamic Scroll",
				options = {
					{
						name = "On",
						apply = {
							EdgeMoveDynamic = 1,
							EdgeMoveWidth = 0.10,
						}
					},
					{
						name = "Off",
						apply = {
							EdgeMoveDynamic = 0,
							EdgeMoveWidth = 0,
						}
					},
				},
			},
			 -- ALREADY SETTABLE IN SETTINGS/INTERFACE/COMMAND
			-- {
			--  name = "MouseDragCircleCommandThreshold",
			--  humanName = "Area Command Threshold",
			--  isNumberSetting = true,
			--  minValue = 0,
			--  maxValue = 50,
			--  applyFunction = function(value, conf)
			--      conf = conf or (WG.Chobby and WG.Chobby.Configuration)
			--      local MouseDragCircleCommandThreshold = 7
			--      if conf and conf.game_settings then
			--          MouseDragCircleCommandThreshold = conf.game_settings.MouseDragCircleCommandThreshold or MouseDragCircleCommandThreshold
			--      end
			--      return {
			--          MouseDragCircleCommandThreshold = value,
			--      }
			--  end,
			-- },
			{
				name = "CommandAlpha",
				humanName = "Command Line Alpha (%)",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 10,
				maxValue = 100,
				stepValue = 1,
				applyFunction = UpdateCmdcolors
			},
			{
				name = "QueueIconAlpha",
				humanName = "Command Icon Alpha (%)",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 10,
				maxValue = 100,
				stepValue = 1,
				applyFunction = UpdateCmdcolors
			},
			{
				name = "MiddlePanSpeed",
				humanName = "Middle Click Pan Speed",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 1000,
				stepValue = 10,
				applyFunction = function(value, conf)
					conf = conf or (WG.Chobby and WG.Chobby.Configuration)
					local camPan = 50
					if conf and conf.game_settings then
						camPan = conf.game_settings.OverheadScrollSpeed or camPan
					end
					value = value*(-1/200)
					return {
						MiddleClickScrollSpeed = value/camPan,
					}
				end,
			},
			{
				name = "CameraPanSpeed",
				humanName = "Camera Pan Speed",
				isNumberSetting = true,
				isSliderSetting = true,
				minValue = 0,
				maxValue = 1000,
				stepValue = 10,
				applyFunction = function(value, conf)
					conf = conf or (WG.Chobby and WG.Chobby.Configuration)
					local middleScroll = 10
					if conf and conf.settingsMenuValues then
						middleScroll = conf.settingsMenuValues.MiddlePanSpeed or middleScroll
					end
					middleScroll = middleScroll*(-1/200)
					return {
						MiddleClickScrollSpeed = middleScroll/value,
						OverheadScrollSpeed = value,
						RotOverheadScrollSpeed = value,
						CamFreeScrollSpeed = value,
						FPSScrollSpeed = value,
					}
				end,
			},
			{
				name = "NetworkSettings",
				humanName = "Network Connection",
				options = {
					{
						name = "Reliable",
						apply = {
							NetworkLossFactor = 0,
							LinkOutgoingBandwidth = 65536,
							LinkIncomingSustainedBandwidth = 2048,
							LinkIncomingPeakBandwidth = 32768,
							LinkIncomingMaxPacketRate = 64,
						}
					},
					{
						name = "Balanced",
						apply = {
							NetworkLossFactor = 1,
							LinkOutgoingBandwidth = 131072,
							LinkIncomingSustainedBandwidth = 65536,
							LinkIncomingPeakBandwidth = 65536,
							LinkIncomingMaxPacketRate = 512,
						}
					},
					{
						name = "Fast",
						apply = {
							NetworkLossFactor = 2,
							LinkOutgoingBandwidth = 262144,
							LinkIncomingSustainedBandwidth = 262144,
							LinkIncomingPeakBandwidth = 262144,
							LinkIncomingMaxPacketRate = 2048,
						}
					},
				},
			},
			{
				name = "SmoothBuffer",
				humanName = "Smooth Buffer",
				options = {
					{
						name = "On",
						apply = {
							UseNetMessageSmoothingBuffer = 1,
						}
					},
					{
						name = "Off",
						apply = {
							UseNetMessageSmoothingBuffer = 0,
						}
					},
				},
			},
			{
				name = "GcRate",
				humanName = "GC Rate",
				options = {
					{
						name = "Highest performance",
						apply = {
							LuaGarbageCollectionMemLoadMult = 1,
						}
					},
					{
						name = "Higher performance",
						apply = {
							LuaGarbageCollectionMemLoadMult = 1.7,
						}
					},
					{
						name = "More performance",
						apply = {
							LuaGarbageCollectionMemLoadMult = 2.4,
						}
					},
					{
						name = "Recommended",
						apply = {
							LuaGarbageCollectionMemLoadMult = 3.2,
						}
					},
					{
						name = "More Stability",
						apply = {
							LuaGarbageCollectionMemLoadMult = 4,
						}
					},
					{
						name = "Higher Stability",
						apply = {
							LuaGarbageCollectionMemLoadMult = 6,
						}
					},
					{
						name = "Highest Stability",
						apply = {
							LuaGarbageCollectionMemLoadMult = 10,
						}
					},
				},
			},
			{
				name = "GcTimeMult",
				humanName = "GC Time Mult",
				options = {
					{
						name = "Highest performance",
						apply = {
							LuaGarbageCollectionRunTimeMult = 1,
						}
					},
					{
						name = "Higher Performance",
						apply = {
							LuaGarbageCollectionRunTimeMult = 1.4,
						}
					},
					{
						name = "More Performance",
						apply = {
							LuaGarbageCollectionRunTimeMult = 1.7,
						}
					},
					{
						name = "Recommended",
						apply = {
							LuaGarbageCollectionRunTimeMult = 2,
						}
					},
					{
						name = "More Stability",
						apply = {
							LuaGarbageCollectionRunTimeMult = 3,
						}
					},
					{
						name = "Higher Stability",
						apply = {
							LuaGarbageCollectionRunTimeMult = 4,
						}
					},
					{
						name = "Highest Stability",
						apply = {
							LuaGarbageCollectionRunTimeMult = 5,
						}
					},
				},
			},
			{
				name = "GCControl",
				humanName = "Set Garbage Collector rate",
				options = {
					{
						name = "1/frame",
						apply = {
							
							LuaGCControl = 0,
						}
					},
					{
						name = "30/sec",
						apply = {
							LuaGCControl = 1,
						}
					},
				},
			},
			{
				name = "HangTimeout",
				humanName = "Hang Timeout",
				options = {
					{
						name = "Normal",
						apply = {
							HangTimeout = 30,
						}
					},
					{
						name = "Forgiving",
						apply = {
							HangTimeout = 75,
						},
					},
				},
			},
		},
	},
}

local settingsDefault = {
	WaterType = "Bumpmapped",
	WaterQuality = "Medium",
	DeferredRendering = "On",
	UnitReflections = "Medium",
	Shadows = "Units and Terrain",
	ShadowMapSize = "2048",
	ShadowDetail = "Medium",
	ParticleLimit = "15000",
	NanoParticleLimit = "15000",
	TerrainDetail = "Medium",
	SoftParticles = "Enabled",
	VegetationDetail = "Medium",
	FeatureFade = "Off",
	CompatibilityMode = "Off",
	AtiIntelCompatibility_2 = "Automatic",
	AntiAliasing = "Low",
	VSync = "Off",
	ShaderDetail = "Medium",
	LupsAirJet = "On",
	LupsRibbon = "On",
	LupsNanoParticles = "Cloud",
	LupsShieldShader = "Default",
	LupsWaterSettings = "Off",
	FancySky = "Off",
	UseNewChili = "Off",
	--IconDistance = 151,
	InterfaceScale = defaultUiScale,
	MouseZoomSpeed = 25,
	InvertZoom = "Off",
	HardwareCursor = "On",
	TextToSpeech = "On",
	EdgeScroll = "On",
	CommandAlpha = 70,
	QueueIconAlpha = 50,
	MiddlePanSpeed = 15,
	CameraPanSpeed = 50,
	NetworkSettings = "Balanced",
	SmoothBuffer = "Off",
	GcRate = "Recommended",
	GcTimeMult = "Recommended",
	PathingThreadCount = -1,
	WorkerThreadCount = -1,
	UpdateBoundingVolumeMT = "On (Default)",
	UpdateWeaponVectorsMT = "On (Default)",
	AnimationMT = "On (Default)",
	PreloadModels = "On (Default)",
	LoadingMT = "On (Default)",
	ThreadPinPolicy = "System Default (Default)",
	MinDrawFPS = 5,
	MinSimDrawBalance = 15,
	UnitGhostIconsDimming = 80,
	UnitTransparency = 70,
	MaxTextureAtlasSize = "4096 (Default)",
	SmoothTimeOffset = 1,
	UseLuaMemPools = "On (Default)",
	TextureMemPoolSize = "512 (Default)",
	HighResTextures = "On (Default)",
	MaxDynamicMapLights = 1,
	MaxDynamicModelLights = 1,
	SetCoreAffinity = 0,
	
}

local settingsNames = {}
for i = 1, #settingsConfig do
	local subSettings = settingsConfig[i].settings
	for j = 1, #subSettings do
		local data = subSettings[j]
		settingsNames[data.name] = data
		if data.options then
			data.optionNames = {}
			for k = 1, #data.options do
				data.optionNames[data.options[k].name] = data.options[k]
			end
		end
	end
end

local function DefaultPresetFunc()
	local gameDefault = settingsConfig[2].presets[1].settings

	if Platform then
		local gpuMemorySize = Platform.gpuMemorySize or 0
		if gpuMemorySize == 0 then
			-- Apparently gpuMemorySize only exists on nvidia
			if Platform.glVersionShort and string.sub(Platform.glVersionShort or "3", 1, 1) ~= "3" then
				-- Medium
				Spring.Echo("Medium settings preset", Platform.glVersionShort)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[4].settings, true)
			else
				-- Default to Low
				Spring.Echo("Low settings preset", Platform.glVersionShort)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[3].settings, true)
			end
		else
			-- gpuMemorySize is in KB even though wiki claims MB.
			if gpuMemorySize < 1024*1024 then
				-- Minimal
				Spring.Echo("Minimal settings preset", gpuMemorySize)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[2].settings, true)
			elseif gpuMemorySize < 2048*1024 then
				-- Low
				Spring.Echo("Low settings preset", gpuMemorySize)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[3].settings, true)
			elseif gpuMemorySize == 2048*1024 then
				-- Medium
				Spring.Echo("Medium settings preset", gpuMemorySize)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[4].settings, true)
			else
				-- High
				Spring.Echo("High settings preset", gpuMemorySize)
				return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[5].settings, true)
			end
		end
	end

	-- Default to Medium
	Spring.Echo("Medium settings preset", Platform, (Platform or {}).gpuMemorySize, (Platform or {}).glVersionShort)
	return Spring.Utilities.MergeTable(gameDefault, settingsConfig[1].presets[4].settings, true)
end

return settingsConfig, settingsNames, settingsDefault, DefaultPresetFunc