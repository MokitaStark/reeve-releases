# 生成式 UI 风格插件规范（`kind: "genui-style"`）

Reeve 支持在对话流中通过 `render_ui` 原生渲染交互式生成式 UI 卡片（KPI 指标与 Sparkline 走势、柱状/折线/面积/环形图表、可排序状态表格、方案对比卡、时间线、核对清单与分段标签页）。除了离线内置的 5 套预设（`Reeve 原生`、`shadcn/ui`、`Linear 极客`、`Editorial 出版物`、`Terminal 工程`）外，开发者可通过纯声明式的 `kind: "genui-style"` 插件扩展独立视觉风格，**在桌面端与移动端同步生效**，且完全不执行任何脚本代码。

## 1. 顶层清单结构与严格校验规则

编写 `<style-plugin-id>/reeve.plugin.json`（上限 **`256 KiB`**，启用 `DisallowUnknownFields()`，**禁止混入 `tools`、`entry`、`slots`、`themes` 等非本规范字段**）：

| 字段 | 必填 | 校验规则 |
| --- | --- | --- |
| `id` | 是 | `^[a-z0-9][a-z0-9-]{0,63}$`（推荐以 `-genui-style` 结尾） |
| `name` | 是 | 插件包显示名称，1～120 字符 |
| `version` | 是 | 标准 SemVer 版本号，如 `"1.0.0"` |
| `kind` | 是 | 固定为 `"genui-style"` |
| `description` | 可选 | 风格设计说明（不超过 4000 字符） |
| `author` | 可选 | 作者或团队名称（不超过 200 字符） |
| `styles` | 是 | 数组，包含 **1～20 套**风格对象；每项 `id` 不可重复且匹配 `^[a-z0-9][a-z0-9-]{0,63}$`，`name` 1～120 字符，`description` 不超过 500 字符 |

---

## 2. 几何与图表美学令牌（`styles[].tokens`）

所有字段均可选，未指定项继承基底默认值，但填写时必须落在允许范围内：

| 令牌名 | 类型 | 允许范围 / 枚举值 | 作用说明 |
| --- | --- | --- | --- |
| `cardRadius` | number | `0` ～ `28` | 生成式 UI 外层主卡片圆角半径（px） |
| `blockRadius` | number | `0` ～ `28` | 内部子区块（KPI 磁贴、图表框、对比卡）圆角半径（px） |
| `controlRadius` | number | `0` ～ `999` | 卡片内交互按钮与分段控件圆角半径（px） |
| `badgeRadius` | number | `0` ～ `999` | 状态徽标圆角（`999` 为胶囊圆角，`2`～`6` 为硬朗工程角） |
| `borderWidth` | number | `0` ～ `4` | 卡片与子区块边框线宽（px） |
| `density` | string | `"compact"` \| `"normal"` \| `"relaxed"` | 排版紧凑度与留白密度 |
| `shadow` | string | `"none"` \| `"subtle"` \| `"elevated"` | 卡片立体投影层级 |
| `tableStriped` | boolean | `true` \| `false` | 数据表格是否开启奇偶斑马纹底色 |
| `monoEmphasis` | boolean | `true` \| `false` | 徽标、轴标签与元信息是否强制使用等宽字体强调 |
| `chartBarRadius` | number | `0` ～ `16` | 柱状图与迷你走势柱顶部圆角（px） |
| `chartCurve` | string | `"monotone"` \| `"linear"` | 折线/面积图平滑插值曲线或锐利折线 |
| `chartAreaOpacity` | number | `0` ～ `1` | 面积图填充不透明度（如 `0.18`） |
| `recommendStyle` | string | `"top_bar"` \| `"border"` \| `"filled"` | 方案对比卡中 `recommended: true` 推荐项的高亮呈现方式 |

---

## 3. 浅色与深色双模式色板（`styles[].light` 与 `styles[].dark`）

所有颜色值必须严格匹配 **`^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$`**（6 位 `#RRGGBB` 或 8 位 `#RRGGBBAA`）：

| 令牌名 | 类型 | 作用说明 |
| --- | --- | --- |
| `cardBg` | string | 生成式卡片主背景色 |
| `cardBorder` | string | 生成式卡片外边框色 |
| `subSurfaceBg` | string | KPI 磁贴、图表区、对比子卡片背景色 |
| `subSurfaceBorder` | string | 子区块细边框色 |
| `accent` | string | 强调焦点色（选中态、走势高亮、推荐标记） |
| `primaryBg` | string | 卡片主动作按钮背景色 |
| `primaryText` | string | 落在 `primaryBg` 按钮上的文字色 |
| `mutedText` | string | 指标标签、坐标轴与辅助说明文字色 |
| `badgeBg` | string | 卡片徽标背景色 |
| `badgeText` | string | 卡片徽标前景文字色 |
| `tableHeaderBg` | string | 表格表头背景色 |
| `tableStripeBg` | string | 表格斑马纹行背景色（推荐带 Alpha 如 `#DCE0E866`） |
| `chartColors` | string[] | 图表多序列调色板数组（**最多 8 种颜色**） |

---

## 4. 完整示例与导入方式

```json
{
  "id": "nordic-frost-genui-style",
  "name": "北极冰川 GenUI",
  "version": "1.0.0",
  "kind": "genui-style",
  "author": "Custom Studio",
  "description": "清冽克制的北欧冰蓝数据卡片与多序列图表配色体系。",
  "styles": [
    {
      "id": "nordic-frost",
      "name": "北极冰川",
      "description": "清透冷调 · 10px 圆角 · 平滑曲线图表",
      "tokens": {
        "cardRadius": 12,
        "blockRadius": 8,
        "controlRadius": 8,
        "badgeRadius": 999,
        "borderWidth": 1,
        "density": "normal",
        "shadow": "subtle",
        "tableStriped": true,
        "monoEmphasis": false,
        "chartBarRadius": 4,
        "chartCurve": "monotone",
        "chartAreaOpacity": 0.2,
        "recommendStyle": "top_bar"
      },
      "light": {
        "cardBg": "#F8FAFC",
        "cardBorder": "#DCE4EE",
        "subSurfaceBg": "#F1F5F9",
        "subSurfaceBorder": "#E2E8F0",
        "accent": "#0284C7",
        "primaryBg": "#0F172A",
        "primaryText": "#FFFFFF",
        "mutedText": "#64748B",
        "badgeBg": "#E0F2FE",
        "badgeText": "#0369A1",
        "tableHeaderBg": "#F1F5F9",
        "tableStripeBg": "#E2E8F066",
        "chartColors": ["#0284C7", "#0D9488", "#6366F1", "#F59E0B", "#EC4899"]
      },
      "dark": {
        "cardBg": "#0F172A",
        "cardBorder": "#1E293B",
        "subSurfaceBg": "#162033",
        "subSurfaceBorder": "#263449",
        "accent": "#38BDF8",
        "primaryBg": "#38BDF8",
        "primaryText": "#082F49",
        "mutedText": "#94A3B8",
        "badgeBg": "#0C4A6E",
        "badgeText": "#7DD3FC",
        "tableHeaderBg": "#162033",
        "tableStripeBg": "#1E293B80",
        "chartColors": ["#38BDF8", "#2DD4BF", "#818CF8", "#FBBF24", "#F472B6"]
      }
    }
  ]
}
```

**在 Reeve 中导入与实时预览**：
打开桌面端 **「设置 → 生成式 UI → 生成式 UI 风格插件 → 导入风格包」**，选择该目录或 `reeve.plugin.json` 文件，即可在顶部实时预览窗查看 KPI、柱状图与交互控件效果，并在桌面端与已配对手机端同步生效。
