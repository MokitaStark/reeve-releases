// Reeve slot-starter 示例插件
// 重要约束：stdio Worker 通过 stdout 传输 JSON-RPC 行协议，禁止使用 console.log 打印普通文本！

const runtimeIdeas = [
  { id: 'idea-1', title: '为项目新增构建状态顶栏胶囊', done: true },
  { id: 'idea-2', title: '用 right_panel 面板实时预览结构化输出', done: false },
];

const collectedSnippets = [];

function escapeXml(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildPulseSparkSVG(ratio) {
  const clamped = Math.max(0, Math.min(1, Number(ratio) || 0));
  const fillW = Math.round(clamped * 76);
  return `<svg width="96" height="20" viewBox="0 0 96 20" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="1" y="4" width="94" height="12" rx="6" stroke="currentColor" stroke-opacity="0.3" stroke-width="1.2"/>
  <rect x="3" y="6" width="${Math.max(8, fillW)}" height="8" rx="4" fill="#3b82f6"/>
  <circle cx="${Math.min(89, Math.max(10, fillW + 5))}" cy="10" r="3" fill="#22c55e"/>
</svg>`;
}

function normalizedState(rawState) {
  const state = rawState && typeof rawState === 'object' ? { ...rawState } : {};
  if (typeof state.pulseCount !== 'number' || Number.isNaN(state.pulseCount)) {
    state.pulseCount = collectedSnippets.length;
  }
  if (typeof state.noteText !== 'string') {
    state.noteText = '记录灵感草稿，可随时回填到对话输入框…';
  }
  if (!Array.isArray(state.ideas)) {
    state.ideas = runtimeIdeas.map((item) => ({ ...item }));
  }
  return state;
}

export async function activate() {
  // 无后台常驻资源需初始化，保持轻量就绪即可
}

export async function deactivate() {
  // 退出时无需额外清理
}

export const tools = {
  async slot_starter_status(_args, ctx) {
    return {
      ok: true,
      pluginId: 'slot-starter',
      projectName: ctx?.project?.name || ctx?.projectName || '',
      ideaCount: runtimeIdeas.length,
      collectedCount: collectedSnippets.length,
      supportedSlots: [
        'conversation.composer.dock',
        'conversation.header.utilities',
        'main',
        'sidebar.nav',
        'right_panel',
        'conversation.starter',
        'conversation.message.footer',
      ],
    };
  },
};

export async function renderSlot(slotId, ctx = {}) {
  const state = normalizedState(ctx.state);
  const doneCount = state.ideas.filter((i) => i.done).length;
  const totalCount = Math.max(1, state.ideas.length);
  const ratio = doneCount / totalCount;
  const projectLabel = ctx.projectName || ctx.project?.name || '当前工作区';
  const modeLabel = ctx.conversationMode || 'work';

  switch (slotId) {
    case 'composer-quickbar':
      return {
        badgeText: `${doneCount}/${state.ideas.length}`,
        state,
        view: {
          type: 'row',
          gap: 8,
          align: 'center',
          children: [
            {
              type: 'svg',
              width: 18,
              height: 18,
              svg: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="9" stroke="#3b82f6" stroke-width="2"/><path d="M12 7v5l3 2" stroke="#22c55e" stroke-width="2" stroke-linecap="round"/></svg>',
            },
            { type: 'badge', text: `灵感 ${doneCount}/${state.ideas.length}`, tone: 'accent' },
            {
              type: 'button',
              label: '填入评审提示',
              variant: 'quiet',
              icon: 'compose',
              action: {
                type: 'insert_text',
                text: '请从架构一致性、可维护性与边界异常处理三个维度审视当前方案：',
              },
            },
            {
              type: 'button',
              label: '随手便签',
              variant: 'quiet',
              icon: 'plugin',
              action: { type: 'open_slot', target: 'quick-notes' },
            },
          ],
        },
      };

    case 'status-capsule':
      return {
        badgeText: `脉冲 ${state.pulseCount}`,
        state,
        view: {
          type: 'column',
          gap: 8,
          children: [
            {
              type: 'row',
              justify: 'between',
              align: 'center',
              children: [
                { type: 'text', text: `项目：${projectLabel}`, size: 'sm', weight: 'semibold' },
                { type: 'svg', width: 96, height: 20, svg: buildPulseSparkSVG(ratio) },
              ],
            },
            {
              type: 'progress',
              label: '灵感收敛进度',
              value: `${doneCount}/${state.ideas.length}`,
              progress: ratio,
            },
            {
              type: 'row',
              gap: 8,
              children: [
                {
                  type: 'button',
                  label: '记录一次脉冲 (+1)',
                  variant: 'primary',
                  action: { type: 'dispatch', handler: 'bump_pulse' },
                },
                {
                  type: 'button',
                  label: '打开主工作台',
                  variant: 'quiet',
                  action: { type: 'open_slot', target: 'workspace' },
                },
              ],
            },
          ],
        },
      };

    case 'workspace':
      return {
        badgeText: `${state.ideas.length}`,
        state,
        view: {
          type: 'column',
          gap: 12,
          children: [
            {
              type: 'row',
              gap: 10,
              wrap: true,
              children: [
                {
                  type: 'stat',
                  label: '当前进度',
                  value: `${doneCount} / ${state.ideas.length}`,
                  meta: `会话模式：${modeLabel}`,
                  tone: 'accent',
                  grow: 1,
                },
                {
                  type: 'stat',
                  label: '脉冲次数',
                  value: String(state.pulseCount),
                  meta: `已收藏回复 ${collectedSnippets.length} 条`,
                  tone: 'success',
                  grow: 1,
                },
              ],
            },
            {
              type: 'card',
              title: '新增灵感条目',
              subtitle: `作用域：${projectLabel}`,
              children: [
                {
                  type: 'row',
                  gap: 8,
                  align: 'end',
                  children: [
                    {
                      type: 'input',
                      field: 'draftIdea',
                      placeholder: '输入一个想法或待验证的插件能力…',
                      grow: 1,
                      action: { type: 'dispatch', handler: 'add_idea' },
                    },
                    {
                      type: 'button',
                      label: '添加到清单',
                      variant: 'primary',
                      action: { type: 'dispatch', handler: 'add_idea' },
                    },
                  ],
                },
              ],
            },
            {
              type: 'card',
              title: '灵感 checklist',
              meta: '点击条目切换完成状态',
              children: [
                {
                  type: 'progress',
                  label: '总体完成度',
                  value: `${Math.round(ratio * 100)}%`,
                  progress: ratio,
                },
                ...state.ideas.map((item) => ({
                  type: 'list_item',
                  key: item.id,
                  icon: item.done ? 'tasks' : 'spark',
                  tone: item.done ? 'success' : 'muted',
                  title: item.title,
                  meta: item.done ? '已完成' : '待处理',
                  action: {
                    type: 'dispatch',
                    handler: 'toggle_idea',
                    payload: { ideaId: item.id },
                  },
                })),
              ],
            },
            {
              type: 'collapsible',
              title: '最近收藏的消息片段',
              children: collectedSnippets.length
                ? collectedSnippets.slice(-3).map((snip, idx) => ({
                    type: 'code',
                    key: `snip-${idx}`,
                    language: escapeXml(snip.conversationId || 'message'),
                    content: snip.preview,
                  }))
                : [{ type: 'empty', title: '暂无收藏', subtitle: '点击任意助手回复底部的「收藏灵感」按钮即可收入此处。' }],
            },
          ],
        },
      };

    case 'quick-notes':
      return {
        badgeText: state.noteText ? '已记录' : '',
        state,
        view: {
          type: 'column',
          gap: 10,
          children: [
            {
              type: 'card',
              title: '随手灵感便签',
              subtitle: `当前模式：${modeLabel}`,
              children: [
                {
                  type: 'textarea',
                  field: 'noteText',
                  label: '便签正文',
                  placeholder: '记录临时需求或提示词片段…',
                },
                {
                  type: 'row',
                  gap: 8,
                  wrap: true,
                  children: [
                    {
                      type: 'button',
                      label: '保存便签',
                      variant: 'primary',
                      action: { type: 'dispatch', handler: 'save_note' },
                    },
                    {
                      type: 'button',
                      label: '写入对话输入框',
                      variant: 'quiet',
                      action: { type: 'dispatch', handler: 'insert_note' },
                    },
                  ],
                },
              ],
            },
          ],
        },
      };

    case 'starter-tips':
      return {
        badgeText: '7 插槽示例',
        state,
        view: {
          type: 'column',
          gap: 8,
          children: [
            {
              type: 'text',
              text: '你可以直接使用创造模式编写插件，挂载到输入框停靠区、顶栏胶囊、右侧分栏或全幅工作台。',
              tone: 'muted',
              wrap: true,
            },
            {
              type: 'row',
              gap: 8,
              wrap: true,
              children: [
                {
                  type: 'button',
                  label: '打开灵感工作台',
                  variant: 'primary',
                  action: { type: 'open_slot', target: 'workspace' },
                },
                {
                  type: 'button',
                  label: '带入扩展提示词',
                  variant: 'quiet',
                  action: {
                    type: 'insert_text',
                    text: '请参考 slot-starter 示例，在当前项目中生成一个带统计卡片和右侧面板的项目检查插件。',
                  },
                },
              ],
            },
          ],
        },
      };

    case 'message-pin':
      return {
        badgeText: collectedSnippets.length > 0 ? String(collectedSnippets.length) : '',
        state,
        view: {
          type: 'badge',
          text: '收藏到灵感工作台',
          tone: 'accent',
        },
      };

    default:
      return {
        state,
        view: { type: 'empty', title: '未知插槽', subtitle: `未定义插槽 ${slotId}` },
      };
  }
}

export async function onSlotAction(slotId, handler, payload = {}, ctx = {}) {
  const state = normalizedState(ctx.state);

  switch (handler) {
    case 'bump_pulse': {
      state.pulseCount += 1;
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return { ...rendered, state, toast: `脉冲计数已更新为 ${state.pulseCount}` };
    }
    case 'add_idea': {
      const rawDraft = payload?.field === 'draftIdea' ? payload.value : (payload?.draftIdea ?? state.draftIdea);
      const title = String(rawDraft || '').trim();
      if (!title) {
        return { state, toast: '请先输入灵感内容' };
      }
      state.ideas = [...state.ideas, { id: `idea-${Date.now()}`, title, done: false }];
      state.draftIdea = '';
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return { ...rendered, state, toast: '已添加到灵感清单' };
    }
    case 'toggle_idea': {
      const targetId = String(payload?.ideaId || '');
      state.ideas = state.ideas.map((item) => (item.id === targetId ? { ...item, done: !item.done } : item));
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return { ...rendered, state };
    }
    case 'save_note': {
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return { ...rendered, state, toast: '灵感便签已暂存' };
    }
    case 'insert_note': {
      const text = String(state.noteText || '').trim();
      if (!text) {
        return { state, toast: '便签为空，无可写入内容' };
      }
      return { state, insertText: text, toast: '已将便签写入对话输入框' };
    }
    case 'collect_message': {
      const rawContent = String(payload?.content || '').trim();
      const preview = rawContent ? rawContent.slice(0, 160) : '（空白消息）';
      collectedSnippets.push({
        messageId: String(payload?.messageId || ''),
        conversationId: String(payload?.conversationId || ''),
        preview,
      });
      state.pulseCount += 1;
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return {
        ...rendered,
        state,
        toast: `已收藏回复摘要（共 ${collectedSnippets.length} 条）`,
      };
    }
    default: {
      const rendered = await renderSlot(slotId, { ...ctx, state });
      return { ...rendered, state };
    }
  }
}

const slotIDs = [
  'composer-quickbar',
  'status-capsule',
  'workspace',
  'quick-notes',
  'starter-tips',
  'message-pin',
];

export const slots = Object.fromEntries(
  slotIDs.map((slotId) => [
    slotId,
    {
      render: (ctx) => renderSlot(slotId, ctx),
      action: (handler, payload, ctx) => onSlotAction(slotId, handler, payload, ctx),
    },
  ]),
);
