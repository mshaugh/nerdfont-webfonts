# Nerd Font Web Fonts

[Nerd Font Web Fonts][nerdfonts] for [hterm][hterm].

## Included Fonts

The latest version of [Nerd Fonts][nerdfonts] is supported.

## Usage

For convenience there is `nerdfont-webfonts.css`, which contains font face
at-rules for all provided fonts.

### JavaScript

```javascript
term_.prefs_.set('font-family', '"FiraCode Nerd Font", monospace');
term_.prefs_.set('user-css', 'https://mshaugh.github.io/nerdfont-webfonts/build/firacode-nerd-font.css');
```

### Preferences Editor

* `font-family: "FiraCode Nerd Font", monospace`
* `user-css: https://mshaugh.github.io/nerdfont-webfonts/build/firacode-nerd-font.css`

## Font Ligatures

> By default, we disable ligatures. Some fonts actively enable them like
> macOS's Menlo (e.g. "ae" is rendered as “æ”). This messes up copying and
> pasting and is, arguably, not terribly legible for a terminal.

If you're using a font that supports ligatures and you want to use them, you
can enable them via the `user-css-text` field:

```css
x-row {
  text-rendering: optimizeLegibility;
  font-variant-ligatures: normal;
}
```


[hterm]: https://chromium.googlesource.com/apps/libapps/+/master/hterm
[nerdfonts]: https://www.nerdfonts.com/
