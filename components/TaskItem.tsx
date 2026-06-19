import { memo } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { colors } from '../constants/theme';
import { TaskNode } from '../types/task';
import { useTaskStore } from '../store/taskStore';
import { AnimatedCheckbox } from './AnimatedCheckbox';

const INDENT = 18;

function TaskItemBase({
  node,
  onOpenReminder,
}: {
  node: TaskNode;
  onOpenReminder: (id: string) => void;
}) {
  const setTitle = useTaskStore((s) => s.setTitle);
  const toggleComplete = useTaskStore((s) => s.toggleComplete);
  const toggleCollapse = useTaskStore((s) => s.toggleCollapse);
  const addTask = useTaskStore((s) => s.addTask);
  const remove = useTaskStore((s) => s.remove);

  const hasKids = node.children.length > 0;
  const reminderOn = node.reminder?.enabled;

  return (
    <View style={[styles.row, { marginLeft: node.depth * INDENT }]}>
      {hasKids ? (
        <Pressable
          onPress={() => toggleCollapse(node.id)}
          hitSlop={8}
          style={styles.chevronBtn}
        >
          <Text style={styles.chevron}>{node.collapsed ? '▸' : '▾'}</Text>
        </Pressable>
      ) : (
        <View style={styles.chevronBtn} />
      )}

      <AnimatedCheckbox
        completed={node.completed}
        onToggle={() => toggleComplete(node.id)}
      />

      <TextInput
        style={[styles.title, node.completed && styles.titleDone]}
        value={node.title}
        onChangeText={(text) => setTitle(node.id, text)}
        placeholder="New task"
        placeholderTextColor={colors.muted}
        multiline
      />

      <Pressable
        onPress={() => onOpenReminder(node.id)}
        hitSlop={6}
        style={styles.action}
      >
        <Text style={[styles.actionIcon, reminderOn && styles.actionIconActive]}>
          {reminderOn ? `🔔 ${node.reminder?.intervalMinutes}m` : '🔕'}
        </Text>
      </Pressable>

      <Pressable
        onPress={() => addTask(node.id, '')}
        hitSlop={6}
        style={styles.action}
      >
        <Text style={styles.plus}>＋</Text>
      </Pressable>

      <Pressable onPress={() => remove(node.id)} hitSlop={6} style={styles.action}>
        <Text style={styles.remove}>✕</Text>
      </Pressable>
    </View>
  );
}

export const TaskItem = memo(TaskItemBase);

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 14,
    paddingVertical: 10,
    paddingHorizontal: 10,
    marginBottom: 8,
    gap: 8,
  },
  chevronBtn: {
    width: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chevron: { color: colors.muted, fontSize: 14 },
  title: {
    flex: 1,
    fontSize: 16,
    color: colors.text,
    paddingVertical: 0,
  },
  titleDone: {
    color: colors.muted,
    textDecorationLine: 'line-through',
  },
  action: { paddingHorizontal: 2 },
  actionIcon: { fontSize: 13, color: colors.muted },
  actionIconActive: { color: colors.primary, fontWeight: '700' },
  plus: { fontSize: 18, color: colors.primary, fontWeight: '700' },
  remove: { fontSize: 15, color: colors.muted },
});
