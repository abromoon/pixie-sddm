# Pixie — где что и как запускается

Сводка о том, как устроен вход (login screen) и блокировка (lock screen) на
Linux применительно к этому проекту, какие есть ограничения и что где работает.

---

## 1. Два независимых компонента Pixie

| Компонент | Каталог | Кто рисует | Когда появляется |
|---|---|---|---|
| SDDM-тема | `src/` | `sddm-greeter` | вход при загрузке / выходе из сессии |
| KDE lock screen | `lockscreen/` | `kscreenlocker_greet` | блокировка сессии (`Super+L`) |

Это **разные рантаймы** с разным API, поэтому одна тема не может работать и
там, и там:

| | SDDM | kscreenlocker (KDE) |
|---|---|---|
| Вход в систему | `sddm.login(user, pass, session)` | `authenticator.respond(pass)` |
| Юзер / аватар | `userModel`, `sessionModel` | `kscreenlocker_userName` / `kscreenlocker_userImage` |
| Suspend / ошибки | `sddm.suspend()`, `sddm.onLoginFailed` | `root.suspendToRam()`, `authenticator.onFailed` |
| Конфиг | `theme.conf` (строки) | `config.xml` (Bool/Color) |

---

## 2. Display managers на Linux (экран входа)

SDDM — лишь один из нескольких DM, и «по умолчанию» у каждого DE/дистрибутива
свой:

| DM | Где по умолчанию | Темизация |
|---|---|---|
| **GDM** | GNOME (Ubuntu, Fedora) | почти не темизируется |
| **SDDM** | KDE Plasma | лидер по количеству тем (QML) |
| **LightDM** | Xfce, MATE, старые Ubuntu | есть гриттеры (GTK/QML) |
| **LXDM / greetd** | нишевые, DIY | минимализм |

Pixie — тема именно под **SDDM**, поэтому работает только там, где вход
обслуживает SDDM (или где его можно поставить).

По умолчанию у **Arch** и **NixOS** DM нет — обе системы DIY:

- **Arch** — ставишь `sddm` сам; в `archinstall`/гайдах под KDE обычно SDDM.
- **NixOS** — декларативно: `services.displayManager.sddm.enable = true;`
  (или `gdm`, `lightdm`).

---

## 3. Lock screen по DE/композитору

Замок рисует **окружение**, а не SDDM:

| DE / композитор | Замок | Порт Pixie |
|---|---|---|
| KDE Plasma 5 | `kscreenlocker` | ✅ `lockscreen/` |
| KDE Plasma 6 | `kscreenlocker` | ❌ нужен отдельный порт |
| GNOME | `gnome-shell` | ❌ |
| Hyprland | `hyprlock` | ❌ |
| sway | `swaylock` / `swaylock-effects` | ❌ |
| i3 / X11 WM | `i3lock` / `slock` | ❌ |

Универсального «одного замка на всех» нет — под каждый композитор свой локер.

---

## 4. Матрица совместимости

### SDDM-тема (`src/`)

| ОС | Гретер | Qt | Ветка | Установка |
|---|---|---|---|---|
| NixOS | `sddm-greeter-qt6` | Qt6 | `main` | `flake.nix` |
| Arch | `sddm-greeter-qt6` | Qt6 | `main` | `install.sh` |
| Debian | `sddm-greeter` | Qt5 | `qt5` | `install.sh` |
| Kubuntu | `sddm-greeter` | Qt5 | `qt5` | `install.sh` |

`install.sh` сам определяет гретер (`sddm-greeter-qt6` vs `sddm-greeter`) и
переключает ветку; на NixOS предлагает использовать flake.

### Сводно

| Компонент | Nix | Arch | Debian | Kubuntu | X11 | Wayland | Ограничение |
|---|---|---|---|---|---|---|---|
| SDDM-тема | ✅ flake/Qt6 | ✅ Qt6 | ✅ Qt5 | ✅ Qt5 | ✅ | ✅ (SDDM 0.20+) | ветка по Qt гретера |
| Lock screen | ✗¹ | ✅ Plasma 5 | ✅ Plasma 5 | ✅ Plasma 5.27 | ✅ | ✅ | только KDE Plasma 5 |

¹ на NixOS возможен при ручной настройке Plasma 5, но flake порт не пакует.

### По серверу дисплея

- **SDDM-тема** — чистый QML, от X11/Wayland не зависит. Wayland ограничен
  самим SDDM (Wayland-гретер с 0.20, экспериментальный), а не темой.
- **KDE lock screen** — работает и на X11, и на Wayland.

---

## 5. Ограничения компонентов в SDDM-теме

Тема — это **только QML** внутри `sddm-greeter`, поэтому жёсткие рамки:

1. **Один входной файл** — `metadata.desktop` `MainScript=Main.qml`; без
   бинарников и исполняемых скриптов.
2. **Только QtQuick-импорты** — `QtQuick`, `QtQuick.Controls`,
   `QtQuick.Layouts`, `QtGraphicalEffects` (Qt5) / `QtQuick.Effects` +
   `MultiEffect` (Qt6). KDE/Plasma/Kirigami компонентов **нет**.
3. **Фиксированные глобальные объекты** — `sddm`, `userModel`, `sessionModel`,
   `battery`, `keyboard`, `config`. Остальное отсутствует (отсюда
   `typeof ... !== "undefined"` в коде).
4. **Нет произвольного доступа к системе** — выполнять команды нельзя; чтение
   файлов только через `XMLHttpRequest file://`.
5. **Ассеты локально** — шрифты/картинки по относительным путям
   (`assets/fonts/…`).
6. **Одно окно на экран** — мульти-монитор = по гретеру на каждый экран.
7. **Qt-версия привязана к гретеру** — отсюда ветки `main` (Qt6) и `qt5` (Qt5).
8. **`config` — только строки** из `theme.conf`; отдельного UI настроек нет.

---

## 6. Замена KDE-замка на hyprlock

`hyprlock` работает **только на Hyprland** (wlroots/Wayland) — заменить им
`kscreenlocker` в KDE Plasma нельзя. Но для Hyprland порт стиля Pixie тривиален:

- один TOML-файл `~/.config/hypr/hyprlock.conf` (без QML/C++);
- встроенные виджеты покрывают всё: `background` (обои + blur), `label`
  (часы/дата), `input-field` (пароль), `image`/`shape` (аватар).

Чего нет из коробки: авто-акцент из обоев (Material You) и сложных анимаций —
цвета задаются вручную, кастомные эффекты через C++-плагин.

---

## 7. Arch и NixOS — как с замком

Единого замка нет — всё зависит от запущенного композитора:

- **Arch + KDE** → `kscreenlocker`, но уже **Plasma 6 (Qt6)**, поэтому текущий
  порт `lockscreen/` (Plasma 5/Qt5) не работает.
- **Arch + Hyprland** → `hyprlock`.
- **NixOS** → определяется конфигом (какой DE включён), замок следует за DE.

Итог: `lockscreen/` практически полезен на Kubuntu/Debian с Plasma 5; для
Arch/NixOS актуальнее порт под Plasma 6 или `hyprlock`-конфиг.
