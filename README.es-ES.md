

<div align="center">

# 🌍 babel.nvim

**Traduce texto sin salir de Neovim**

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-57A143?style=for-the-badge&logo=neovim&logoColor=white&color=a6e3a1)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-2C2D72?style=for-the-badge&logo=lua&logoColor=white&color=89b4fa)](https://lua.org)
[![License](https://img.shields.io/badge/License-MIT-pink?style=for-the-badge&color=f5c2e7)](./LICENSE)

</div>

---

<!-- TODO: Añadir demostración GIF -->
<!-- ![Demo](assets/demo.gif) -->

## ✨ Características

- 🔤 Traduce texto seleccionado o palabra bajo el cursor
- 🪟 Múltiples modos de visualización (float, picker)
- 🔍 Detección automática del selector instalado
- 📋 Copia la traducción al portapapeles con `y`
- ⚡ Traducción asíncrona (no bloqueante)

### Selectores compatibles

| Selector | Estado |
|--------|:------:|
| Flotante nativo | ✅ |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | ✅ |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | ✅ |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | ✅ |
| [mini.pick](https://github.com/echasnovski/mini.pick) | ✅ |

## ⚡ Requisitos

- Neovim >= 0.9.0
- `curl`

**Opcional** (para visualización con selector):

- snacks.nvim, telescope.nvim, fzf-lua o mini.pick

## 📦 Instalación

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "acidsugarx/babel.nvim",
  version = "*", -- recomendado para la última etiqueta, no main
  opts = {
    target = "ru",  -- idioma objetivo
  },
  keys = {
    { "<leader>tr", mode = "v", desc = "Traducir selección" },
    { "<leader>tw", desc = "Traducir palabra" },
  },
}
```

## ⚙️ Configuración

### Configuración mínima

```lua
require("babel").setup({
  target = "ru",
})
```

### Opciones completas

<details>
<summary>Configuración predeterminada</summary>

```lua
require("babel").setup({
  source = "auto",        -- idioma de origen (detección automática)
  target = "ru",          -- idioma objetivo
  provider = "google",    -- proveedor de traducción: "google", "deepl"
  network = {
    connect_timeout = 5,   -- tiempo de espera de conexión en segundos
    request_timeout = 15,  -- tiempo máximo de solicitud en segundos
  },
  cache = {
    enabled = false,       -- habilitar caché de traducción en memoria
    limit = 200,           -- entradas máximas en caché
  },
  history = {
    enabled = false,       -- mantener historial de traducciones en memoria
    limit = 20,            -- entradas máximas guardadas
  },
  fallback_chain = {
    deepl = { "google" }, -- si DeepL falla, probar Google
    google = {},
  },
  display = "float",      -- "float" o "picker"
  picker = "auto",        -- "auto", "telescope", "fzf", "snacks", "mini"
  float = {
    border = "rounded",
    mode = "center", -- "center" o "cursor"
    max_width = 80,
    max_height = 20,
    enter = true, -- enfocar la ventana flotante (false = ver sin entrar)
    auto_close = false, -- cerrar flotante al mover el cursor en el búfer de origen
    auto_close_ms = 0, -- retraso de auto-cierre, 0 = deshabilitado
    pin = true, -- permitir alternar anclaje con `p` cuando auto-cierre está habilitado
    copy_original = false, -- permitir copiar texto original con `Y`
    nvim_open_win = {}, -- opciones extra para nvim_open_win() (anula valores predeterminados)
  },
  keymaps = {
    translate = "<leader>tr",
    translate_word = "<leader>tw",
    lang = "<leader>tl",
    swap = "<leader>ts",
  },
  -- Configuración del proveedor DeepL (opcional)
  deepl = {
    api_key = nil,        -- o usar la variable de entorno DEEPL_API_KEY
    pro = nil,            -- nil = detección automática, true = Pro, false = Free
    formality = "default", -- "default", "more", "less", "prefer_more", "prefer_less"
  },
})
```

</details>

### Opciones

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `source` | string | `"auto"` | Idioma de origen (detección automática) |
| `target` | string | `"ru"` | Código de idioma objetivo |
| `provider` | string | `"google"` | Proveedor de traducción: `"google"`, `"deepl"` |
| `network.connect_timeout` | number | `5` | Tiempo de espera de conexión (segundos) |
| `network.request_timeout` | number | `15` | Tiempo de espera de solicitud (segundos) |
| `cache.enabled` | boolean | `false` | Habilitar caché de traducción en memoria |
| `cache.limit` | number | `200` | Entradas máximas en caché |
| `history.enabled` | boolean | `false` | Habilitar historial de traducciones en memoria |
| `history.limit` | number | `20` | Entradas máximas de historial almacenadas |
| `fallback_chain` | table | `{ deepl = {"google"}, google = {} }` | Cadena de respaldo por proveedor |
| `display` | string | `"float"` | Modo de visualización: `"float"` o `"picker"` |
| `picker` | string | `"auto"` | Selector: `"auto"`, `"telescope"`, `"fzf"`, `"snacks"`, `"mini"` |
| `float.mode` | string | `"center"` | Ajuste flotante: `"center"` o `"cursor"` |
| `float.enter` | boolean | `true` | Enfocar ventana flotante (`false` = ver sin entrar) |
| `float.auto_close` | boolean | `false` | Cerrar flotante al mover el cursor en el búfer de origen |
| `float.auto_close_ms` | number | `0` | Tiempo de auto-cierre en ms (`0` deshabilita) |
| `float.pin` | boolean | `true` | Habilitar tecla de anclaje (`p`) cuando auto-cierre está activo |
| `float.copy_original` | boolean | `false` | Habilitar copiar texto original con `Y` |
| `float.nvim_open_win` | table | `{}` | Opciones extra para `nvim_open_win()` de la ventana flotante |
| `deepl.api_key` | string | `nil` | Clave API de DeepL (o usar `DEEPL_API_KEY`) |
| `deepl.pro` | boolean | `nil` | Forzar endpoint Pro/Free (`nil` = detección automática por clave) |
| `deepl.formality` | string | `"default"` | Formalidad: `"default"`, `"more"`, `"less"`, `"prefer_more"`, `"prefer_less"` |
| `keymaps.lang` | string | `"<leader>tl"` | Abrir selector de idioma |
| `keymaps.swap` | string | `"<leader>ts"` | Intercambiar idiomas de origen y objetivo |
| `languages` | table | `nil` | Anular lista de idiomas predeterminada (nil = usar predeterminados) |

### Ajuste flotante que sigue al cursor

Para una ventana emergente más pequeña que siga a tu cursor, usa:

```lua
require("babel").setup({
  float = {
    mode = "cursor",
    max_width = 60,
    max_height = 10,
  },
})
```

### Modo vista rápida (sin entrar + auto-cierre)

Muestra una ventana emergente de traducción sin entrar en ella. El flotante se cierra automáticamente al mover el cursor la próxima vez:

```lua
require("babel").setup({
  float = {
    mode = "cursor",
    enter = false,
    auto_close = true,
  },
})
```

### Selector de idioma

Cambia los idiomas de origen y objetivo de forma interactiva:

```lua
-- Mediante comando
:BabelLang

-- Mediante atajo (predeterminado <leader>tl)
-- Presiona <leader>tl, selecciona origen y luego objetivo

-- Intercambiar origen ↔ objetivo
:BabelSwap
-- o presiona <leader>ts

-- Desde dentro de la ventana flotante de traducción, presiona L
```

Anular la lista de idiomas:

```lua
require("babel").setup({
  languages = {
    auto = "Detección automática",
    en = "Inglés",
    ru = "Ruso",
  },
})
```

### Personalización del tiempo de espera de red

Puedes ajustar los tiempos de espera de las solicitudes del proveedor para redes lentas o inestables:

```lua
require("babel").setup({
  network = {
    connect_timeout = 3,
    request_timeout = 25,
  },
})
```

### Historial de traducciones

Puedes mantener las traducciones exitosas más recientes en memoria:

```lua
require("babel").setup({
  history = {
    enabled = true,
    limit = 50,
  },
})
```

### Cadena de respaldo y caché

Puedes controlar el comportamiento de respaldo del proveedor y habilitar la caché en memoria:

```lua
require("babel").setup({
  provider = "deepl",
  fallback_chain = {
    deepl = { "google" },
    google = {},
  },
  cache = {
    enabled = true,
    limit = 500,
  },
})
```

### Personalización de la ventana flotante

Puedes anular los ajustes predeterminados del flotante de Babel pasando opciones directamente a `nvim_open_win()`:

```lua
require("babel").setup({
  float = {
    max_width = 60,
    max_height = 10,
    nvim_open_win = {
      relative = "cursor",
      row = 1,
      col = 0,
      anchor = "NW",
      border = "single",
      title = " Babel ",
    },
  },
})
```

### Códigos de idioma

<details>
<summary>Códigos de idioma comunes</summary>

| Código | Idioma |
|------|----------|
| `en` | Inglés |
| `ru` | Ruso |
| `de` | Alemán |
| `fr` | Francés |
| `es` | Español |
| `it` | Italiano |
| `pt` | Portugués |
| `zh` | Chino |
| `ja` | Japonés |
| `ko` | Coreano |
| `ar` | Árabe |
| `hi` | Hindi |
| `tr` | Turco |
| `pl` | Polaco |
| `uk` | Ucraniano |

</details>

## 🚀 Uso

### Atajos de teclado

| Atajo | Modo | Descripción |
|--------|------|-------------|
| `<leader>tr` | Visual | Traducir selección |
| `<leader>tw` | Normal | Traducir palabra bajo el cursor |
| `<leader>tl` | Normal | Abrir selector de idioma |
| `<leader>ts` | Normal | Intercambiar origen ↔ objetivo |
| `<leader>th` | Normal | Historial de traducciones |

### Comandos

| Comando | Descripción |
|---------|-------------|
| `:Babel [texto]` | Traducir el texto proporcionado |
| `:[rango]Babel` | Traducir rango de líneas seleccionado (ej. `:10,20Babel`) |
| `:BabelWord` | Traducir palabra bajo el cursor |
| `:BabelRepeat` | Repetir última entrada de traducción |
| `:BabelLang` | Abrir selector de idioma (origen → objetivo) |
| `:BabelSwap` | Intercambiar idiomas de origen y objetivo |
| `:BabelHistory` | Examinar historial de traducciones |
| `:BabelHistoryClear` | Borrar historial de traducciones |

### Dentro de la ventana de traducción

| Tecla | Acción |
|-----|--------|
| `q` / `<Esc>` / `<CR>` | Cerrar ventana |
| `y` | Copiar traducción al portapapeles |
| `Y` | Copiar texto original (si `float.copy_original = true`) |
| `p` | Anclar/desanclar temporizador de auto-cierre (si está habilitado) |
| `L` | Abrir selector de idioma |
| `H` | Abrir historial de traducciones |
| `j` / `k` | Desplazarse |

## 🌐 Proveedores

| Proveedor | Estado | Clave API | Notas |
|----------|:------:|:-------:|-------|
| Google Translate | ✅ | No | Predeterminado, API no oficial |
| [DeepL](https://deepl.com) | 🧪 | Sí (nivel gratuito) | Mejor calidad, 500k caracteres/mes gratis |
| [LibreTranslate](https://libretranslate.com) | 🔜 | No | Código abierto, alojable localmente |
| [Yandex](https://translate.yandex.ru) | 🔜 | Sí | Excelente para ruso |
| [Lingva](https://lingva.ml) | 🔜 | No | Proxy de Google, sin límites de tasa |

### Capacidades del proveedor

Puedes inspeccionar las capacidades del proveedor desde Lua:

```lua
local caps = require("babel").get_provider_capabilities()
-- caps.google.supports_formality == false
-- caps.deepl.supports_formality == true

local deepl = require("babel").get_provider_capabilities("deepl")
```

> **🧪 Pruebas:** El proveedor DeepL está implementado pero necesita pruebas. Si tienes una clave API de DeepL y quieres ayudar a probar, por favor [abre un issue](https://github.com/acidsugarx/babel.nvim/issues) con tu retroalimentación!

<details>
<summary>Configuración de DeepL</summary>

1. Obtén una clave API gratuita en [deepl.com/pro#developer](https://www.deepl.com/pro#developer) (500k caracteres/mes gratis)

2. Configura la clave API (elige uno):

   **Opción A:** Variable de entorno
   ```bash
   export DEEPL_API_KEY="tu-clave-api-aqui"
   ```

   **Opción B:** En la configuración
   ```lua
   require("babel").setup({
     provider = "deepl",
     deepl = {
       api_key = "tu-clave-api-aqui",
     },
   })
   ```

3. El endpoint (Free/Pro) se detecta automáticamente desde el sufijo de la clave (`:fx` = Free). Puedes anularlo con `deepl.pro = true/false`.

4. Si no se encuentra ninguna clave API, babel.nvim retrocederá automáticamente a Google Translate con una advertencia.

</details>

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Siéntete libre de:

- 🐛 Reportar errores
- 💡 Sugerir características
- 🔧 Enviar pull requests

Si usas asistentes de código IA, consulta `AGENTS.md` para la arquitectura del proyecto, puertas de calidad y lista de cambios seguros.

## 🙏 Agradecimientos

Gracias al increíble ecosistema de plugins de Neovim:

- [folke](https://github.com/folke) por [snacks.nvim](https://github.com/folke/snacks.nvim) y [lazy.nvim](https://github.com/folke/lazy.nvim)
- [nvim-telescope](https://github.com/nvim-telescope) por [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [ibhagwan](https://github.com/ibhagwan) por [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [echasnovski](https://github.com/echasnovski) por [mini.nvim](https://github.com/echasnovski/mini.nvim)

## 📝 Licencia

[MIT](./LICENSE) © Ilya Gilev
