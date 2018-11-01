# Powerline Webfonts

[Powerline Webfonts](https://github.com/powerline/fonts) for [hterm](https://chromium.googlesource.com/apps/libapps/+/master/hterm).

## Included Fonts

* [DejaVu Sans Mono](https://github.com/powerline/fonts/tree/master/DejaVuSansMono)
* [Fira Code](https://github.com/tonsky/FiraCode)
* [Inconsolata](https://github.com/powerline/fonts/tree/master/Inconsolata)
* [Inconsolata-g](https://github.com/powerline/fonts/tree/master/Inconsolata-g)
* [Source Code Pro](https://github.com/powerline/fonts/tree/master/SourceCodePro)
* [Ubuntu Mono](https://github.com/powerline/fonts/tree/master/UbuntuMono)

## Usage

### JavaScript

```javascript
term_.prefs_.set('font-family', '"DejaVu Sans Mono", monospace');
term_.prefs_.set('user-css', 'https://mshaugh.github.io/powerline-webfonts/powerline-webfonts.css');
```

### Preferences Editor

* `font-family: "DejaVu Sans Mono", monospace`
* `user-css: https://mshaugh.github.io/powerline-webfonts/powerline-webfonts.css`

## Font Ligatures

> By default, we disable ligatures. Some fonts actively enable them like
> macOS's Menlo (e.g. "ae" is rendered as “æ”). This messes up copying and
> pasting and is, arguably, not terribly legible for a terminal.

If you're using a font that supports ligatures and you want to use them, you can enable them via the `user-css-text` field:

```css
x-row {
  text-rendering: optimizeLegibility;
  font-variant-ligatures: normal;
}
```
