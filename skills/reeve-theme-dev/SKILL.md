---
name: reeve-theme-dev
description: 设计、编写并校验 Reeve 外观主题插件（kind 为 theme）与对话生成式 UI 视觉风格插件（kind 为 genui-style）。当用户想要为 Reeve 定制配色方案、毛玻璃皮肤、浅色/深色双模式调色板、渐变背景与氛围光效，或定制对话内生成式 UI 交互卡片、图表色板、圆角密度风格（如 Catppuccin、Geist、shadcn 风格）时，务必使用此技能。
---

# Reeve 外观主题与生成式 UI 风格插件开发指南

Reeve 提供两类纯声明式 JSON 视觉扩展插件（完全不执行任何脚本代码，文件上限均为 `256 KiB`，且开启 `DisallowUnknownFields` 严格字段校验）：
- **工作台外观主题插件（`kind: "theme"`）**：定制全局窗口背景、液态玻璃表面、文字层级与氛围光晕（见下文第 1～4 节）。
- **生成式 UI 风格插件（`kind: "genui-style"`）**：独立定制对话流 `render_ui` 交互卡片、KPI 走势、多序列图表、表格与对比卡的圆角、密度、阴影及浅深双色板（桌面端与移动端同步生效）。**当用户需要开发 `genui-style` 风格插件时，请直接读取 `references/genui-style-plugins.md`**。

Reeve 的外观主题插件采用纯声明式 JSON（`kind: "theme"`），单个主题插件可包含 **1～20 套**子主题，每套子主题同时定义浅色（`light`）与深色（`dark`）调色板，完美融合 Reeve 的 Apple 原生液态玻璃（Liquid Glass）材质。

## 1. 清单结构与严格校验规则

在主题目录（如 `<theme-id>/reeve.plugin.json`）或独立 JSON 文件中编写，文件大小上限 **`256 KiB`**，且后端启用了 `DisallowUnknownFields()`（**严禁写入任何未定义的额外字段**，例如不要混入 `tools`、`entry`、`slots` 或 `permissions`）：

| 字段 | 必填 | 校验规则 |
| --- | --- | --- |
| `id` | 是 | 匹配 `^[a-z0-9][a-z0-9-]{0,63}$`（小写字母、数字与连字符，最长 64 字符，推荐以 `-theme` 结尾） |
| `name` | 是 | 插件包显示名称，1～120 字符 |
| `version` | 是 | 标准 SemVer 版本号，如 `"1.0.0"` |
| `kind` | 是 | 固定为 `"theme"` |
| `description` | 可选 | 主题设计风格说明（不超过 4000 字符） |
| `author` | 可选 | 作者或团队名称（不超过 200 字符） |
| `themes` | 是 | 数组，包含 **1～20 套**主题对象，子主题 `id` 不可重复且同样匹配 `^[a-z0-9][a-z0-9-]{0,63}$` |
| `themes[].light` | 是 | 浅色调色板对象，**必须包含 `background` 与 `text`**，其余未填项自动继承基底皮肤 |
| `themes[].dark` | 是 | 深色调色板对象，**必须包含 `background` 与 `text`**，其余未填项自动继承基底皮肤 |

### 颜色值格式规范

所有调色板颜色值必须严格匹配十六进制颜色正则 **`^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$`**（仅支持 `#RRGGBB` 或带 Alpha 透明度的 8 位 `#RRGGBBAA`；**不支持** 3 位简写 `#FFF`、`rgb(...)` 或 `hsl(...)`）。

---

## 2. 全部 19 个允许的调色板令牌（Tokens）

除下表列出的 19 个键名外，写入任何其他键名都会触发校验拒绝：

| 类别 | 令牌名 | 必填 | 设计建议与 Alpha 透明度技巧 |
| --- | --- | --- | --- |
| **画布与渐变** | `background` | **必填** | 窗口底层主背景色（6 位不透明 `#RRGGBB`） |
| | `gradientFrom` | 推荐 | 窗口背景线性渐变起始色（浅色宜极淡通透，深色宜深邃沉稳） |
| | `gradientTo` | 推荐 | 窗口背景线性渐变结束色 |
| | `ambientGlow` | 推荐 | 主氛围柔光光晕，强烈建议使用 8 位低透明度色值（如浅色 `#60A5FA33`、深色 `#3B82F62E`） |
| | `ambientGlowSecondary` | 推荐 | 次氛围柔光光晕（如 `#38BDF822`） |
| **毛玻璃表面** | `surface` | 推荐 | 卡片与浮动面板表面色，建议使用 8 位半透明（如浅色 `#FFFFFFD9`、深色 `#13223CE0`）呈现液态玻璃通透感 |
| | `surfaceHover` | 推荐 | 列表项/按钮悬停表面色 |
| | `surfacePressed` | 推荐 | 控件按下表面色 |
| | `border` | 推荐 | 卡片与分割线细边框色 |
| **文字层级** | `text` | **必填** | 主正文颜色，须与 `background` / `surface` 保持 WCAG AA（>= 4.5:1）以上对比度 |
| | `textMuted` | 推荐 | 次要说明、时间戳与辅助标签文字色 |
| **品牌强调与焦点** | `accent` | 推荐 | 主强调色（主按钮、激活指示器、链接） |
| | `accentHover` | 推荐 | 主强调悬停色 |
| | `accentPressed` | 推荐 | 主强调按下色 |
| | `accentText` | 推荐 | 落在 `accent` 实心按钮上的前景文字色（通常为 `#FFFFFF` 或高反差深色） |
| | `focus` | 推荐 | 输入框与键盘导航焦点环颜色 |
| | `selection` | 推荐 | 文本选中与高亮底色，务必带 Alpha 通道（如 `#2563EB24` / `#3B82F638`） |
| **语义状态色** | `success` | 推荐 | 成功/通过态（浅色偏深绿如 `#0F8A61`，深色偏亮翠绿如 `#34D399`） |
| | `warning` | 推荐 | 警告/待审批态（浅色偏琥珀棕如 `#B4690E`，深色偏暖金如 `#FBBF24`） |
| | `danger` | 推荐 | 危险/报错态（浅色偏深红如 `#D1344A`，深色偏珊瑚红如 `#FB7185`） |

---

## 3. 标准渐变主题模板（`reeve.plugin.json`）

```json
{
  "id": "misty-jade-theme",
  "name": "烟雨青玉",
  "version": "1.0.0",
  "kind": "theme",
  "author": "Custom Studio",
  "description": "温润通透的东方青玉渐变主题，适配浅色晨雾与深色墨玉双模式液态玻璃面板。",
  "themes": [
    {
      "id": "misty-jade",
      "name": "烟雨青玉",
      "light": {
        "background": "#EFF8F5",
        "gradientFrom": "#F6FCFA",
        "gradientTo": "#DAEFEB",
        "ambientGlow": "#10B9812E",
        "ambientGlowSecondary": "#14B8A621",
        "surface": "#FFFFFFD9",
        "surfaceHover": "#E6F5F0",
        "surfacePressed": "#D6ECE5",
        "border": "#C2E2D9",
        "text": "#0E2923",
        "textMuted": "#4B6E65",
        "accent": "#0D9488",
        "accentHover": "#0F766E",
        "accentPressed": "#115E59",
        "accentText": "#FFFFFF",
        "focus": "#14B8A6",
        "selection": "#0D948824",
        "success": "#0F8A61",
        "warning": "#B4690E",
        "danger": "#D1344A"
      },
      "dark": {
        "background": "#091715",
        "gradientFrom": "#071210",
        "gradientTo": "#112B27",
        "ambientGlow": "#14B8A62B",
        "ambientGlowSecondary": "#2DD4BF1F",
        "surface": "#102421E0",
        "surfaceHover": "#17332F",
        "surfacePressed": "#1E423C",
        "border": "#234B44",
        "text": "#ECFDF8",
        "textMuted": "#8FB5AC",
        "accent": "#2DD4BF",
        "accentHover": "#5EEAD4",
        "accentPressed": "#14B8A6",
        "accentText": "#06201C",
        "focus": "#2DD4BF",
        "selection": "#2DD4BF33",
        "success": "#34D399",
        "warning": "#FBBF24",
        "danger": "#FB7185"
      }
    }
  ]
}
```

---

## 4. 本地静态校验与导入步骤

生成主题文件后，先运行一段单行脚本确认零未知字段且所有颜色均符合 `#RRGGBB[AA]` 正则：

```bash
node -e '
const fs = require("node:fs");
const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const allowedTop = new Set(["id","name","version","kind","description","author","themes"]);
const allowedTok = new Set(["background","gradientFrom","gradientTo","ambientGlow","ambientGlowSecondary","text","surface","surfaceHover","surfacePressed","border","textMuted","accent","accentHover","accentPressed","accentText","focus","selection","success","warning","danger"]);
const hexRe = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;
for (const k of Object.keys(m)) if (!allowedTop.has(k)) throw new Error("未知顶层字段: " + k);
if (m.kind !== "theme" || !/^[a-z0-9][a-z0-9-]{0,63}$/.test(m.id)) throw new Error("id 或 kind 无效");
for (const t of m.themes) {
  for (const mode of ["light", "dark"]) {
    const p = t[mode] || {};
    if (!p.background || !p.text) throw new Error(`${t.id}.${mode} 缺少 background 或 text`);
    for (const [tk, val] of Object.entries(p)) {
      if (!allowedTok.has(tk) || !hexRe.test(val)) throw new Error(`${t.id}.${mode}.${tk} 颜色无效: ${val}`);
    }
  }
}
console.log("主题清单校验通过:", m.id, "共", m.themes.length, "套主题");
' ./<theme-dir>/reeve.plugin.json
```

**在 Reeve 中安装启用**：
打开 Reeve 桌面端 **「设置 → 外观 → 主题插件 → 导入主题插件」**，选择该目录或 `reeve.plugin.json` 文件即可一键导入并立即切换预览浅色/深色渐变效果。
