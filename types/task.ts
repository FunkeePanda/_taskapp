export type Reminder = {
  /** How often to nag, in minutes. */
  intervalMinutes: number;
  enabled: boolean;
  /** OS-scheduled notification id, so we can cancel/reschedule it. */
  notificationId?: string;
};

export type Task = {
  id: string;
  parentId: string | null;
  title: string;
  completed: boolean;
  /** Whether this node's children are folded in the UI. */
  collapsed: boolean;
  /** Ordering among siblings. */
  order: number;
  createdAt: number;
  completedAt: number | null;
  reminder?: Reminder;
};

/** A task with its computed tree position, built in memory from the flat list. */
export type TaskNode = Task & {
  depth: number;
  children: TaskNode[];
};
