import { describe, expect, test } from 'bun:test';
import { readFileSync } from 'node:fs';
import path from 'node:path';

const ALLOWED_TOP_KEYS = new Set(['id', 'name', 'version', 'kind', 'description', 'author', 'themes']);
const ALLOWED_TOKENS = new Set([
  'background',
  'gradientFrom',
  'gradientTo',
  'ambientGlow',
  'ambientGlowSecondary',
  'text',
  'surface',
  'surfaceHover',
  'surfacePressed',
  'border',
  'textMuted',
  'accent',
  'accentHover',
  'accentPressed',
  'accentText',
  'focus',
  'selection',
  'success',
  'warning',
  'danger',
]);
const HEX_COLOR_RE = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;

describe('theme-starter manifest validation', () => {
  const manifestPath = path.join(import.meta.dir, 'reeve.plugin.json');
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));

  test('top-level fields match Reeve ThemePluginManifest contract', () => {
    for (const key of Object.keys(manifest)) {
      expect(ALLOWED_TOP_KEYS.has(key)).toBe(true);
    }
    expect(manifest.kind).toBe('theme');
    expect(manifest.id).toMatch(/^[a-z0-9][a-z0-9-]{0,63}$/);
    expect(manifest.version).toMatch(/^\d+\.\d+\.\d+/);
    expect(Array.isArray(manifest.themes)).toBe(true);
    expect(manifest.themes.length).toBeGreaterThanOrEqual(1);
  });

  test('light and dark palettes contain required tokens and valid hex colors', () => {
    for (const theme of manifest.themes) {
      expect(theme.id).toMatch(/^[a-z0-9][a-z0-9-]{0,63}$/);
      for (const mode of ['light', 'dark']) {
        const palette = theme[mode];
        expect(typeof palette.background).toBe('string');
        expect(typeof palette.text).toBe('string');
        for (const [token, value] of Object.entries(palette)) {
          expect(ALLOWED_TOKENS.has(token)).toBe(true);
          expect(value).toMatch(HEX_COLOR_RE);
        }
      }
    }
  });
});
