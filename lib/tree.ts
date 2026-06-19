import { Task, TaskNode } from '../types/task';

/** Build the nested tree from a flat task list, sorting siblings by `order`. */
export function buildTree(tasks: Task[]): TaskNode[] {
  const byId = new Map<string, TaskNode>();
  tasks.forEach((t) => byId.set(t.id, { ...t, depth: 0, children: [] }));

  const roots: TaskNode[] = [];
  byId.forEach((node) => {
    const parent = node.parentId ? byId.get(node.parentId) : undefined;
    if (parent) {
      parent.children.push(node);
    } else {
      roots.push(node);
    }
  });

  const sortRec = (nodes: TaskNode[], depth: number) => {
    nodes.sort((a, b) => a.order - b.order);
    nodes.forEach((n) => {
      n.depth = depth;
      sortRec(n.children, depth + 1);
    });
  };
  sortRec(roots, 0);
  return roots;
}

/**
 * Flatten the tree into display order, skipping the children of collapsed nodes.
 * This is what the list renders.
 */
export function flattenVisible(tasks: Task[]): TaskNode[] {
  const out: TaskNode[] = [];
  const walk = (nodes: TaskNode[]) => {
    for (const n of nodes) {
      out.push(n);
      if (!n.collapsed && n.children.length) walk(n.children);
    }
  };
  walk(buildTree(tasks));
  return out;
}

/** All descendant ids of a task (used for cascade delete). */
export function getDescendantIds(tasks: Task[], id: string): string[] {
  const childrenOf = new Map<string | null, Task[]>();
  tasks.forEach((t) => {
    const arr = childrenOf.get(t.parentId) ?? [];
    arr.push(t);
    childrenOf.set(t.parentId, arr);
  });

  const result: string[] = [];
  const walk = (pid: string) => {
    for (const child of childrenOf.get(pid) ?? []) {
      result.push(child.id);
      walk(child.id);
    }
  };
  walk(id);
  return result;
}

export function hasChildren(tasks: Task[], id: string): boolean {
  return tasks.some((t) => t.parentId === id);
}

/** Next sibling order for a given parent. */
export function nextOrder(tasks: Task[], parentId: string | null): number {
  const siblings = tasks.filter((t) => t.parentId === parentId);
  return siblings.length ? Math.max(...siblings.map((s) => s.order)) + 1 : 0;
}
