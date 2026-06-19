# Tasks

A mobile-first todo app built with Expo (React Native) — one codebase running on
iOS, Android, and the web. This is **v1**, focused on three things:

1. **Nested, collapsible task tree** — tap `＋` on any task to add a subtask under it,
   indent as deep as you like, and tap the chevron (`▾` / `▸`) to fold a branch.
2. **A satisfying check animation** — the checkbox fill and checkmark bloom from the
   center, with a little confetti burst on completion. Un-checking reverses it.
3. **Per-task interval reminders** — tap the bell on a task to be reminded every _N_
   minutes. On iOS/Android these are real repeating local notifications that fire even
   when the app is closed.

Tasks are stored **on-device** (no account needed) and persist between launches.

## Run it

```bash
npm install
npx expo start
```

Then open it on your phone with the **Expo Go** app (scan the QR code), or press `w`
to open the web version in a browser.

> Reminders: the repeating-notification feature runs on the native iOS/Android app.
> The web preview can render everything else but does not schedule background reminders.

## Project layout

```
app/                 expo-router screens
  _layout.tsx        root layout; requests notification permission on launch
  index.tsx          main task list + add bar
components/
  TaskItem.tsx       one row: chevron, checkbox, title, reminder/add/delete actions
  AnimatedCheckbox.tsx  bloom checkmark + confetti
  Confetti.tsx       reanimated particle burst
  ReminderModal.tsx  pick a reminder interval
store/
  taskStore.ts       zustand store, persisted to AsyncStorage
lib/
  tree.ts            build/flatten the task tree from a flat list
  notifications.ts   permissions + scheduling repeating reminders
types/task.ts        Task / TaskNode types
constants/theme.ts   colors
```

Tasks are kept as a **flat list** with a `parentId`; the visual tree is built in memory
(`lib/tree.ts`), which keeps persistence and reordering simple.

## Not in v1 (planned next)

Calendar tab, an analytics dashboard (completion rates, time-of-day slip patterns),
cloud sync + accounts, drag-to-reorder, and app-store distribution.
