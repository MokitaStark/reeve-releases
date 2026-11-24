import { mkdir, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

let runtimeState = {
  activatedAt: null,
  projectId: null,
};

/** 校验目标路径始终位于项目工作区之内，防止目录穿越。 */
export function resolveInsideWorkspace(rootPath, subPath = '.') {
  const base = path.resolve(rootPath || '.');
  const resolved = path.resolve(base, subPath || '.');
  const rel = path.relative(base, resolved);
  if (rel.startsWith('..') || path.isAbsolute(rel)) {
    throw new Error('不允许访问项目工作区之外的路径');
  }
  return { base, resolved, relative: rel || '.' };
}

/** 清理标题中的非法文件名字符。 */
export function sanitizeNoteFilename(title) {
  const raw = String(title || '').trim();
  const safe = raw.replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').replace(/^\.+/, '').slice(0, 80);
  return (safe || 'note') + '.md';
}

/** 启用插件时触发：禁止在此阶段向 stdout 打印非 JSON 文本。 */
export async function activate(context) {
  runtimeState = {
    activatedAt: new Date().toISOString(),
    projectId: context?.project?.id || null,
  };
}

/** 停用或退出插件时触发：用于关闭连接、定时器等资源。 */
export async function deactivate() {
  runtimeState = { activatedAt: null, projectId: null };
}

export const tools = {
  async inspect_workspace(args = {}, context = {}) {
    const rootPath = context?.project?.rootPath;
    if (!rootPath) {
      throw new Error('缺少项目工作区路径 context.project.rootPath');
    }
    const target = resolveInsideWorkspace(rootPath, args.subDir || '.');
    const entries = await readdir(target.resolved, { withFileTypes: true });
    const items = entries
      .filter((entry) => entry.name !== '.git' && entry.name !== 'node_modules')
      .slice(0, 100)
      .map((entry) => ({
        name: entry.name,
        type: entry.isDirectory() ? 'dir' : 'file',
      }));
    return {
      projectId: context?.project?.id || '',
      directory: target.relative,
      count: items.length,
      items,
      activatedAt: runtimeState.activatedAt,
    };
  },

  async write_note(args = {}, context = {}) {
    const rootPath = context?.project?.rootPath;
    if (!rootPath) {
      throw new Error('缺少项目工作区路径 context.project.rootPath');
    }
    const title = String(args.title || '').trim();
    const content = String(args.content || '');
    if (!title) {
      throw new Error('笔记标题 title 不能为空');
    }
    const notesDir = resolveInsideWorkspace(rootPath, '.reeve/notes').resolved;
    await mkdir(notesDir, { recursive: true });
    const filePath = path.join(notesDir, sanitizeNoteFilename(title));
    await writeFile(filePath, `# ${title}\n\n${content}\n`, 'utf8');
    return {
      ok: true,
      path: path.relative(path.resolve(rootPath), filePath),
      title,
    };
  },
};
