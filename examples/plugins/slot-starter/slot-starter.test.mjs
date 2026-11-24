import { describe, expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';
import { activate, deactivate, onSlotAction, renderSlot, slots, tools } from './index.mjs';

const manifest = JSON.parse(readFileSync(new URL('./reeve.plugin.json', import.meta.url), 'utf8'));

describe('Reeve slot-starter 全插槽示例插件', () => {
  test('清单声明覆盖全部 7 个标准插槽且模块导出对应处理器', () => {
    const locations = manifest.slots.map((s) => s.slot);
    expect(locations).toEqual([
      'conversation.composer.dock',
      'conversation.header.utilities',
      'main',
      'sidebar.nav',
      'right_panel',
      'conversation.starter',
      'conversation.message.footer',
    ]);
    for (const s of manifest.slots) {
      expect(typeof slots[s.id]?.render).toBe('function');
      expect(typeof slots[s.id]?.action).toBe('function');
    }
    expect(typeof tools.slot_starter_status).toBe('function');
  });

  test('renderSlot 返回合规宣言式 UI 树与 SVG 节点', async () => {
    await activate({});
    const dock = await renderSlot('composer-quickbar', { projectName: '示例项目', conversationMode: 'create' });
    expect(dock.view?.type).toBe('row');
    expect(dock.view?.children.some((c) => c.type === 'svg' && String(c.svg).includes('<svg'))).toBe(true);

    const main = await renderSlot('workspace', { projectName: '示例项目', conversationMode: 'create' });
    expect(main.view?.type).toBe('column');
    expect(main.badgeText).toBe('2');

    const status = await tools.slot_starter_status({}, { projectName: '示例项目' });
    expect(status.ok).toBe(true);
    expect(status.supportedSlots.length).toBe(7);
    await deactivate();
  });

  test('onSlotAction 支持新增条目、切换状态、回填输入框与收藏消息', async () => {
    const added = await onSlotAction('workspace', 'add_idea', {}, { state: { draftIdea: '新插件创意' } });
    expect(added.state.ideas.some((i) => i.title === '新插件创意')).toBe(true);
    expect(added.state.draftIdea).toBe('');
    expect(added.toast).toContain('已添加');

    const inserted = await onSlotAction('quick-notes', 'insert_note', {}, { state: { noteText: '检查安全边界' } });
    expect(inserted.insertText).toBe('检查安全边界');

    const pinned = await onSlotAction(
      'message-pin',
      'collect_message',
      { messageId: 'm1', conversationId: 'c1', content: '这是助手生成的结构化方案总结' },
      {},
    );
    expect(pinned.toast).toContain('共 1 条');
  });
});
