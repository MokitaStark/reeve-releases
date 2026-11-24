import { describe, expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';
import path from 'node:path';

const ALLOWED_TOP_KEYS = new Set(['id', 'name', 'version', 'kind', 'description', 'author', 'styles']);
const ALLOWED_PALETTE_KEYS = new Set([
  'cardBg',
  'cardBorder',
  'subSurfaceBg',
  'subSurfaceBorder',
  'accent',
  'primaryBg',
  'primaryText',
  'mutedText',
  'badgeBg',
  'badgeText',
  'tableHeaderBg',
  'tableStripeBg',
  'chartColors',
]);
const HEX_COLOR_RE = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;

describe('genui-style-starter manifest validation', () => {
  const manifest = JSON.parse(readFileSync(path.join(import.meta.dir, 'reeve.plugin.json'), 'utf8'));

  test('matches GenUIStylePluginManifest top-level and token constraints', () => {
    for (const key of Object.keys(manifest)) {
      expect(ALLOWED_TOP_KEYS.has(key)).toBe(true);
    }
    expect(manifest.kind).toBe('genui-style');
    expect(manifest.id).toMatch(/^[a-z0-9][a-z0-9-]{0,63}$/);
    expect(manifest.styles.length).toBeGreaterThanOrEqual(1);

    for (const style of manifest.styles) {
      expect(style.id).toMatch(/^[a-z0-9][a-z0-9-]{0,63}$/);
      expect(['', 'compact', 'normal', 'relaxed']).toContain(style.tokens?.density || '');
      expect(['', 'none', 'subtle', 'elevated']).toContain(style.tokens?.shadow || '');
      expect(['', 'monotone', 'linear']).toContain(style.tokens?.chartCurve || '');
      expect(['', 'top_bar', 'border', 'filled']).toContain(style.tokens?.recommendStyle || '');

      for (const mode of ['light', 'dark']) {
        const palette = style[mode] || {};
        for (const [k, v] of Object.entries(palette)) {
          expect(ALLOWED_PALETTE_KEYS.has(k)).toBe(true);
          if (k === 'chartColors') {
            expect(Array.isArray(v)).toBe(true);
            expect(v.length).toBeLessThanOrEqual(8);
            for (const c of v) expect(c).toMatch(HEX_COLOR_RE);
          } else {
            expect(v).toMatch(HEX_COLOR_RE);
          }
        }
      }
    }
  });
});
