import { describe, expect, test } from 'bun:test';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { activate, deactivate, resolveInsideWorkspace, tools } from './index.mjs';

const manifest = JSON.parse(readFileSync(new URL('./reeve.plugin.json', import.meta.url), 'utf8'));

describe('Reeve quick-starter 入门插件示例', () => {
  test('清单工具与模块导出完全一致', () => {
    const manifestToolNames = manifest.tools.map((item) => item.name).sort();
    const exportedToolNames = Object.keys(tools).sort();
    expect(exportedToolNames).toEqual(manifestToolNames);
  });

  test('严格阻止工作区路径穿越', () => {
    expect(() => resolveInsideWorkspace('/tmp/demo-project', '../secret')).toThrow();
    expect(resolveInsideWorkspace('/tmp/demo-project', 'src').relative).toBe('src');
  });

  test('支持 activate、只读检查、写入笔记与 deactivate', async () => {
    const root = mkdtempSync(path.join(tmpdir(), 'reeve-starter-'));
    try {
      writeFileSync(path.join(root, 'README.md'), '# Demo\n', 'utf8');
      const ctx = { project: { id: 'proj_demo', rootPath: root } };
      await activate(ctx);

      const summary = await tools.inspect_workspace({}, ctx);
      expect(summary.projectId).toBe('proj_demo');
      expect(summary.items.some((i) => i.name === 'README.md' && i.type === 'file')).toBe(true);

      const saved = await tools.write_note({ title: '架构笔记', content: '已完成 Worker IPC 联调。' }, ctx);
      expect(saved.ok).toBe(true);
      expect(saved.path).toBe(path.join('.reeve', 'notes', '架构笔记.md'));
      const content = readFileSync(path.join(root, saved.path), 'utf8');
      expect(content).toContain('# 架构笔记');

      await deactivate();
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });
});
