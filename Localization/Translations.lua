local addonName = ...

_G["MultiLanguageTranslations"] = {}
local translationsFrame = CreateFrame("Frame")

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        _G["MultiLanguageTranslations"]["en"] = {
            description = "Description",
            objectives = "Quest Objectives",
            options = {
                generalOptionsTitle = "General options",
                languageDropdownLabel = "Select language:",
                interactionDropdownLabel = "Select interaction:",
                registerHotkeyDescriptionText = "Register Hotkey (right-click to unbind):",
                registerHotkeyNotBoundText = "Not bound",
                registerHotkeyPressButtonText = "Press button..",
                questOptionsTitle = "Quest options",
                questDisplayModeText = "Select quest display mode:",
                itemOptionsTitle = "Item options",
                spellOptionsTitle = "Spell options",
                npcOptionsTitle = "Npc options",
                enableText = "Enable",
                onlyDisplayNameText = "Only display name",
                languages = {
                    en = "English",
                    es = "Spanish",
                    fr = "French",
                    de = "German",
                    pt = "Portuguese",
                    ru = "Russian",
                    ko = "Korean",
                    cn = "Chinese (simplified)",
                    mx = "Spanish (Mexico)",
                    tw = 'Chinese (traditional)'
                },
                questDisplayModes = {
                    tooltip = "Tooltip",
                    replace = "Replace text"
                },
                interactionModes = {
                    hover = "Hover",
                    ["hover-hotkey"] = "Hover + hotkey"
                }
            }
        }

        _G["MultiLanguageTranslations"]["es"] = {
            description = "Descripción",
            objectives = "Objetivos de la misión",
            options = {
                generalOptionsTitle = "Opciones generales",
                languageDropdownLabel = "Seleccionar idioma:",
                interactionDropdownLabel = "Seleccionar interacción:",
                registerHotkeyDescriptionText = "Registrar tecla de acceso rápido (clic derecho para desasignar):",
                registerHotkeyNotBoundText = "No asignado",
                registerHotkeyPressButtonText = "Presiona el botón...",
                questOptionsTitle = "Opciones de misión",
                questDisplayModeText = "Seleccionar modo de visualización de la misión:",
                itemOptionsTitle = "Opciones de objeto",
                spellOptionsTitle = "Opciones de hechizo",
                npcOptionsTitle = "Opciones de NPC",
                enableText = "Habilitar",
                onlyDisplayNameText = "Mostrar solo el nombre",
                languages = {
                    en = "Inglés",
                    es = "Español",
                    fr = "Francés",
                    de = "Alemán",
                    pt = "Portugués",
                    ru = "Ruso",
                    ko = "Coreano",
                    cn = "Chino (simplificado)",
                    mx = "Español (México)",
                    tw = "Chino (tradicional)"

                },
                questDisplayModes = {
                    tooltip = "Información sobre herramientas",
                    replace = "Reemplazar texto"
                },
                interactionModes = {
                    hover = "Pasar el cursor",
                    ["hover-hotkey"] = "Pasar el cursor + tecla de acceso rápido"
                }
            }
        }

        _G["MultiLanguageTranslations"]["de"] = {
            description = "Beschreibung",
            objectives = "Quest-Ziele",
            options = {
                generalOptionsTitle = "Allgemeine Optionen",
                languageDropdownLabel = "Sprache auswählen:",
                interactionDropdownLabel = "Interaktion auswählen:",
                registerHotkeyDescriptionText = "Hotkey registrieren (Rechtsklick zum Aufheben der Bindung):",
                registerHotkeyNotBoundText = "Nicht zugewiesen",
                registerHotkeyPressButtonText = "Taste drücken...",
                questOptionsTitle = "Quest-Optionen",
                questDisplayModeText = "Quest-Anzeigemodus auswählen:",
                itemOptionsTitle = "Gegenstandsoptionen",
                spellOptionsTitle = "Zauberoptionen",
                npcOptionsTitle = "NPC-Optionen",
                enableText = "Aktivieren",
                onlyDisplayNameText = "Nur Anzeigename",
                languages = {
                    en = "Englisch",
                    es = "Spanisch",
                    fr = "Französisch",
                    de = "Deutsch",
                    pt = "Portugiesisch",
                    ru = "Russisch",
                    ko = "Koreanisch",
                    cn = "Chinesisch (vereinfacht)",
                    mx = "Spanisch (Mexiko)",
                    tw = "Chinesisch (traditionell)"
                },
                questDisplayModes = {
                    tooltip = "Tooltip",
                    replace = "Text ersetzen"
                },
                interactionModes = {
                    hover = "Hover",
                    ["hover-hotkey"] = "Hover + Hotkey"
                }
            }
        }

        _G["MultiLanguageTranslations"]["fr"] = {
            description = "Description",
            objectives = "Objectifs de la quête",
            options = {
                generalOptionsTitle = "Options générales",
                languageDropdownLabel = "Sélectionner la langue :",
                interactionDropdownLabel = "Sélectionner l'interaction :",
                registerHotkeyDescriptionText = "Enregistrer un raccourci clavier (clic droit pour dissocier) :",
                registerHotkeyNotBoundText = "Non attribué",
                registerHotkeyPressButtonText = "Appuyez sur un bouton...",
                questOptionsTitle = "Options de quête",
                questDisplayModeText = "Sélectionner le mode d'affichage de la quête :",
                itemOptionsTitle = "Options des objets",
                spellOptionsTitle = "Options des sorts",
                npcOptionsTitle = "Options des PNJ",
                enableText = "Activer",
                onlyDisplayNameText = "Afficher uniquement le nom",
                languages = {
                    en = "Anglais",
                    es = "Espagnol",
                    fr = "Français",
                    de = "Allemand",
                    pt = "Portugais",
                    ru = "Russe",
                    ko = "Coréen",
                    cn = "Chinois (simplifié)",
                    mx = "Espagnol (Mexique)",
                    tw = "Chinois (traditionnel)"
                },
                questDisplayModes = {
                    tooltip = "Info-bulle",
                    replace = "Remplacer le texte"
                },
                interactionModes = {
                    hover = "Survol",
                    ["hover-hotkey"] = "Survol + raccourci clavier"
                }
            }
        }

        _G["MultiLanguageTranslations"]["pt"] = {
            description = "Descrição",
            objectives = "Objetivos da missão",
            options = {
                generalOptionsTitle = "Opções gerais",
                languageDropdownLabel = "Selecionar idioma:",
                interactionDropdownLabel = "Selecionar interação:",
                registerHotkeyDescriptionText = "Registrar atalho de teclado (clique direito para desvincular):",
                registerHotkeyNotBoundText = "Não atribuído",
                registerHotkeyPressButtonText = "Pressione o botão...",
                questOptionsTitle = "Opções de missão",
                questDisplayModeText = "Selecionar modo de exibição da missão:",
                itemOptionsTitle = "Opções de item",
                spellOptionsTitle = "Opções de feitiço",
                npcOptionsTitle = "Opções de NPC",
                enableText = "Habilitar",
                onlyDisplayNameText = "Exibir apenas o nome",
                languages = {
                    en = "Inglês",
                    es = "Espanhol",
                    fr = "Francês",
                    de = "Alemão",
                    pt = "Português",
                    ru = "Russo",
                    ko = "Coreano",
                    cn = "Chinês (simplificado)",
                    mx = "Espanhol (México)",
                    tw = "Chinês (tradicional)"
                },
                questDisplayModes = {
                    tooltip = "Dica de ferramenta",
                    replace = "Substituir texto"
                },
                interactionModes = {
                    hover = "Passar o mouse",
                    ["hover-hotkey"] = "Passar o mouse + atalho"
                }
            }
        }

        _G["MultiLanguageTranslations"]["ru"] = {
            description = "Описание",
            objectives = "Цели задания",
            options = {
                generalOptionsTitle = "Общие настройки",
                languageDropdownLabel = "Выберите язык:",
                interactionDropdownLabel = "Выберите взаимодействие:",
                registerHotkeyDescriptionText = "Зарегистрировать горячую клавишу (щелкните правой кнопкой, чтобы отвязать):",
                registerHotkeyNotBoundText = "Не назначено",
                registerHotkeyPressButtonText = "Нажмите кнопку...",
                questOptionsTitle = "Настройки заданий",
                questDisplayModeText = "Выберите режим отображения задания:",
                itemOptionsTitle = "Настройки предметов",
                spellOptionsTitle = "Настройки заклинаний",
                npcOptionsTitle = "Настройки NPC",
                enableText = "Включить",
                onlyDisplayNameText = "Показывать только имя",
                languages = {
                    en = "Английский",
                    es = "Испанский",
                    fr = "Французский",
                    de = "Немецкий",
                    pt = "Португальский",
                    ru = "Русский",
                    ko = "Корейский",
                    cn = "Китайский (упрощённый)",
                    mx = "Испанский (Мексика)",
                    tw = "Китайский (традиционный)"
                },
                questDisplayModes = {
                    tooltip = "Подсказка",
                    replace = "Заменить текст"
                },
                interactionModes = {
                    hover = "Наведение",
                    ["hover-hotkey"] = "Наведение + горячая клавиша"
                }
            }
        }

        _G["MultiLanguageTranslations"]["cn"] = {
            description = "描述",
            objectives = "任务目标",
            options = {
                generalOptionsTitle = "常规选项",
                languageDropdownLabel = "选择语言：",
                interactionDropdownLabel = "选择交互方式：",
                registerHotkeyDescriptionText = "注册快捷键（右键单击取消绑定）：",
                registerHotkeyNotBoundText = "未绑定",
                registerHotkeyPressButtonText = "按下按钮...",
                questOptionsTitle = "任务选项",
                questDisplayModeText = "选择任务显示模式：",
                itemOptionsTitle = "物品选项",
                spellOptionsTitle = "法术选项",
                npcOptionsTitle = "NPC 选项",
                enableText = "启用",
                onlyDisplayNameText = "仅显示名称",
                languages = {
                    en = "英语",
                    es = "西班牙语",
                    fr = "法语",
                    de = "德语",
                    pt = "葡萄牙语",
                    ru = "俄语",
                    ko = "韩语",
                    cn = "中文（简体）",
                    mx = "西班牙语（墨西哥）",
                    tw = "中文（繁體）"
                },
                questDisplayModes = {
                    tooltip = "工具提示",
                    replace = "替换文本"
                },
                interactionModes = {
                    hover = "悬停",
                    ["hover-hotkey"] = "悬停 + 快捷键"
                }
            }
        }

        _G["MultiLanguageTranslations"]["ko"] = {
            description = "설명",
            objectives = "퀘스트 목표",
            options = {
                generalOptionsTitle = "일반 옵션",
                languageDropdownLabel = "언어 선택:",
                interactionDropdownLabel = "상호 작용 선택:",
                registerHotkeyDescriptionText = "단축키 등록 (우클릭으로 해제):",
                registerHotkeyNotBoundText = "미할당",
                registerHotkeyPressButtonText = "버튼을 누르세요...",
                questOptionsTitle = "퀘스트 옵션",
                questDisplayModeText = "퀘스트 표시 모드 선택:",
                itemOptionsTitle = "아이템 옵션",
                spellOptionsTitle = "주문 옵션",
                npcOptionsTitle = "NPC 옵션",
                enableText = "활성화",
                onlyDisplayNameText = "이름만 표시",
                languages = {
                    en = "영어",
                    es = "스페인어",
                    fr = "프랑스어",
                    de = "독일어",
                    pt = "포르투갈어",
                    ru = "러시아어",
                    ko = "한국어",
                    cn = "중국어(간체)",
                    mx = "스페인어(멕시코)",
                    tw = "중국어(번체)"
                },
                questDisplayModes = {
                    tooltip = "툴팁",
                    replace = "텍스트 교체"
                },
                interactionModes = {
                    hover = "마우스 오버",
                    ["hover-hotkey"] = "마우스 오버 + 단축키"
                }
            }
        }

        _G["MultiLanguageTranslations"]["mx"] = {
            description = "Descripción",
            objectives = "Objetivos de la misión",
            options = {
                generalOptionsTitle = "Opciones generales",
                languageDropdownLabel = "Seleccionar idioma:",
                interactionDropdownLabel = "Seleccionar interacción:",
                registerHotkeyDescriptionText = "Registrar tecla de acceso rápido (clic derecho para desvincular):",
                registerHotkeyNotBoundText = "No vinculada",
                registerHotkeyPressButtonText = "Presiona el botón..",
                questOptionsTitle = "Opciones de misión",
                questDisplayModeText = "Seleccionar modo de visualización de misión:",
                itemOptionsTitle = "Opciones de objeto",
                spellOptionsTitle = "Opciones de hechizo",
                npcOptionsTitle = "Opciones de NPC",
                enableText = "Habilitar",
                onlyDisplayNameText = "Mostrar solo el nombre",
                languages = {
                    en = "Inglés",
                    es = "Español",
                    fr = "Francés",
                    de = "Alemán",
                    pt = "Portugués",
                    ru = "Ruso",
                    ko = "Coreano",
                    cn = "Chino (simplificado)",
                    mx = "Español (México)",
                    tw = "Chino (tradicional)"
                },
                questDisplayModes = {
                    tooltip = "Sugerencia",
                    replace = "Sustituir texto"
                },
                interactionModes = {
                    hover = "Sostener",
                    ["hover-hotkey"] = "Sostener + tecla de acceso rápido"
                }
            }
        }

        _G["MultiLanguageTranslations"]["tw"] = {
            description = "描述",
            objectives = "任務目標",
            options = {
                generalOptionsTitle = "一般選項",
                languageDropdownLabel = "選擇語言：",
                interactionDropdownLabel = "選擇互動方式：",
                registerHotkeyDescriptionText = "註冊快捷鍵（右鍵取消綁定）：",
                registerHotkeyNotBoundText = "未綁定",
                registerHotkeyPressButtonText = "按下按鈕..",
                questOptionsTitle = "任務選項",
                questDisplayModeText = "選擇任務顯示模式：",
                itemOptionsTitle = "物品選項",
                spellOptionsTitle = "法術選項",
                npcOptionsTitle = "NPC選項",
                enableText = "啟用",
                onlyDisplayNameText = "僅顯示名稱",
                languages = {
                    en = "英文",
                    es = "西班牙文",
                    fr = "法文",
                    de = "德文",
                    pt = "葡萄牙文",
                    ru = "俄文",
                    ko = "韓文",
                    cn = "中文（簡體）",
                    mx = "西班牙文（墨西哥）",
                    tw = "中文（繁體）"
                },
                questDisplayModes = {
                    tooltip = "工具提示",
                    replace = "取代文字"
                },
                interactionModes = {
                    hover = "懸停",
                    ["hover-hotkey"] = "懸停 + 快捷鍵"
                }
            }
        }
    end
end

translationsFrame:RegisterEvent("ADDON_LOADED")
translationsFrame:SetScript("OnEvent", addonLoaded)
