import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { Reminder, Task } from '../types/task';
import { getDescendantIds, nextOrder } from '../lib/tree';
import { scheduleReminder, cancelReminder } from '../lib/notifications';

let counter = 0;
const uid = () =>
  `${Date.now().toString(36)}-${(counter++).toString(36)}-${Math.random()
    .toString(36)
    .slice(2, 7)}`;

type TaskState = {
  tasks: Task[];
  hydrated: boolean;

  addTask: (parentId: string | null, title: string) => string;
  setTitle: (id: string, title: string) => void;
  toggleComplete: (id: string) => void;
  toggleCollapse: (id: string) => void;
  remove: (id: string) => void;
  /** Set a repeating reminder (minutes), or pass null to clear it. */
  setReminder: (id: string, intervalMinutes: number | null) => Promise<void>;
  /** Internal: shallow-merge fields into a task's reminder. */
  _patchReminder: (id: string, patch: Partial<Reminder>) => void;
};

export const useTaskStore = create<TaskState>()(
  persist(
    (set, get) => ({
      tasks: [],
      hydrated: false,

      addTask: (parentId, title) => {
        const id = uid();
        const task: Task = {
          id,
          parentId,
          title,
          completed: false,
          collapsed: false,
          order: nextOrder(get().tasks, parentId),
          createdAt: Date.now(),
          completedAt: null,
        };
        // Adding a child to a collapsed parent expands it so the child is visible.
        set((s) => ({
          tasks: s.tasks
            .map((t) => (t.id === parentId ? { ...t, collapsed: false } : t))
            .concat(task),
        }));
        return id;
      },

      setTitle: (id, title) =>
        set((s) => ({
          tasks: s.tasks.map((t) => (t.id === id ? { ...t, title } : t)),
        })),

      toggleComplete: (id) => {
        const task = get().tasks.find((t) => t.id === id);
        if (!task) return;
        const completed = !task.completed;

        set((s) => ({
          tasks: s.tasks.map((t) =>
            t.id === id
              ? { ...t, completed, completedAt: completed ? Date.now() : null }
              : t
          ),
        }));

        // A completed task shouldn't keep nagging; pause its reminder.
        // Re-opening it reschedules, if a reminder is configured.
        const reminder = task.reminder;
        if (!reminder?.enabled) return;
        (async () => {
          if (completed) {
            await cancelReminder(reminder.notificationId);
            get()._patchReminder(id, { notificationId: undefined });
          } else if (!reminder.notificationId) {
            const notificationId = await scheduleReminder(
              task.title,
              reminder.intervalMinutes
            );
            get()._patchReminder(id, { notificationId: notificationId ?? undefined });
          }
        })();
      },

      toggleCollapse: (id) =>
        set((s) => ({
          tasks: s.tasks.map((t) =>
            t.id === id ? { ...t, collapsed: !t.collapsed } : t
          ),
        })),

      remove: (id) => {
        const { tasks } = get();
        const ids = new Set([id, ...getDescendantIds(tasks, id)]);
        // Cancel any reminders attached to the removed subtree.
        tasks
          .filter((t) => ids.has(t.id))
          .forEach((t) => cancelReminder(t.reminder?.notificationId));
        set((s) => ({ tasks: s.tasks.filter((t) => !ids.has(t.id)) }));
      },

      setReminder: async (id, intervalMinutes) => {
        const task = get().tasks.find((t) => t.id === id);
        if (!task) return;

        // Clear any existing schedule first.
        await cancelReminder(task.reminder?.notificationId);

        if (intervalMinutes == null) {
          set((s) => ({
            tasks: s.tasks.map((t) =>
              t.id === id ? { ...t, reminder: undefined } : t
            ),
          }));
          return;
        }

        // Don't schedule for an already-completed task; store the config so it
        // activates if the task is re-opened.
        const notificationId = task.completed
          ? null
          : await scheduleReminder(task.title, intervalMinutes);

        set((s) => ({
          tasks: s.tasks.map((t) =>
            t.id === id
              ? {
                  ...t,
                  reminder: {
                    intervalMinutes,
                    enabled: true,
                    notificationId: notificationId ?? undefined,
                  },
                }
              : t
          ),
        }));
      },

      _patchReminder: (id, patch) =>
        set((s) => ({
          tasks: s.tasks.map((t) =>
            t.id === id && t.reminder
              ? { ...t, reminder: { ...t.reminder, ...patch } }
              : t
          ),
        })),
    }),
    {
      name: 'taskapp-store-v1',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (s) => ({ tasks: s.tasks }),
      onRehydrateStorage: () => (state) => {
        if (state) state.hydrated = true;
      },
    }
  )
);
