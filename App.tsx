import { useEffect, useMemo, useState } from 'react';
import {
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';

import { colors } from './constants/theme';
import { flattenVisible } from './lib/tree';
import { useTaskStore } from './store/taskStore';
import { TaskItem } from './components/TaskItem';
import { ReminderModal } from './components/ReminderModal';
import { ensurePermissions } from './lib/notifications';

function Home() {
  const insets = useSafeAreaInsets();
  const tasks = useTaskStore((s) => s.tasks);
  const addTask = useTaskStore((s) => s.addTask);
  const setReminder = useTaskStore((s) => s.setReminder);

  const [draft, setDraft] = useState('');
  const [reminderFor, setReminderFor] = useState<string | null>(null);

  const visible = useMemo(() => flattenVisible(tasks), [tasks]);

  const reminderTask = reminderFor
    ? tasks.find((t) => t.id === reminderFor)
    : undefined;

  const remaining = tasks.filter((t) => !t.completed).length;

  const submitDraft = () => {
    const title = draft.trim();
    if (!title) return;
    addTask(null, title);
    setDraft('');
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={[styles.container, { paddingTop: insets.top + 12 }]}>
        <Text style={styles.heading}>Tasks</Text>
        <Text style={styles.sub}>
          {remaining === 0
            ? 'All clear ✨'
            : `${remaining} task${remaining === 1 ? '' : 's'} to go`}
        </Text>

        <View style={styles.addBar}>
          <TextInput
            style={styles.addInput}
            value={draft}
            onChangeText={setDraft}
            placeholder="Add a task…"
            placeholderTextColor={colors.muted}
            onSubmitEditing={submitDraft}
            returnKeyType="done"
          />
          <Pressable style={styles.addBtn} onPress={submitDraft}>
            <Text style={styles.addBtnText}>Add</Text>
          </Pressable>
        </View>

        <FlatList
          data={visible}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TaskItem node={item} onOpenReminder={setReminderFor} />
          )}
          contentContainerStyle={styles.listContent}
          keyboardShouldPersistTaps="handled"
          ListEmptyComponent={
            <Text style={styles.empty}>
              No tasks yet. Add one above, then tap ＋ on a task to nest subtasks
              under it.
            </Text>
          }
        />
      </View>

      <ReminderModal
        visible={reminderFor != null}
        taskTitle={reminderTask?.title ?? ''}
        currentInterval={reminderTask?.reminder?.intervalMinutes}
        onSelect={(minutes) => {
          if (reminderFor) setReminder(reminderFor, minutes);
          setReminderFor(null);
        }}
        onClose={() => setReminderFor(null)}
      />
    </KeyboardAvoidingView>
  );
}

export default function App() {
  useEffect(() => {
    ensurePermissions();
  }, []);

  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      <Home />
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.bg },
  container: { flex: 1, paddingHorizontal: 16 },
  heading: { fontSize: 32, fontWeight: '800', color: colors.text },
  sub: { fontSize: 15, color: colors.muted, marginTop: 2, marginBottom: 16 },
  addBar: { flexDirection: 'row', gap: 10, marginBottom: 16 },
  addInput: {
    flex: 1,
    backgroundColor: colors.card,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.border,
  },
  addBtn: {
    paddingHorizontal: 22,
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: 14,
  },
  addBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
  listContent: { paddingBottom: 40 },
  empty: {
    color: colors.muted,
    fontSize: 15,
    textAlign: 'center',
    marginTop: 40,
    lineHeight: 22,
    paddingHorizontal: 20,
  },
});
