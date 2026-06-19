import { useEffect, useState } from 'react';
import {
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { colors } from '../constants/theme';

const PRESETS = [5, 10, 15, 30, 60];

export function ReminderModal({
  visible,
  taskTitle,
  currentInterval,
  onSelect,
  onClose,
}: {
  visible: boolean;
  taskTitle: string;
  currentInterval?: number;
  /** minutes to set, or null to turn the reminder off. */
  onSelect: (intervalMinutes: number | null) => void;
  onClose: () => void;
}) {
  const [custom, setCustom] = useState('');

  useEffect(() => {
    if (visible) setCustom(currentInterval ? String(currentInterval) : '');
  }, [visible, currentInterval]);

  const applyCustom = () => {
    const n = Math.round(Number(custom));
    if (Number.isFinite(n) && n >= 1) onSelect(n);
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <Pressable style={styles.backdrop} onPress={onClose}>
        <Pressable style={styles.sheet} onPress={() => {}}>
          <View style={styles.handle} />
          <Text style={styles.title}>Remind me</Text>
          <Text style={styles.subtitle} numberOfLines={1}>
            {taskTitle || 'this task'}
          </Text>

          {Platform.OS === 'web' && (
            <Text style={styles.webNote}>
              Repeating reminders run on the iOS/Android app, not the web preview.
            </Text>
          )}

          <View style={styles.presetRow}>
            {PRESETS.map((m) => {
              const active = currentInterval === m;
              return (
                <Pressable
                  key={m}
                  onPress={() => onSelect(m)}
                  style={[styles.chip, active && styles.chipActive]}
                >
                  <Text style={[styles.chipText, active && styles.chipTextActive]}>
                    {m}m
                  </Text>
                </Pressable>
              );
            })}
          </View>

          <View style={styles.customRow}>
            <TextInput
              style={styles.input}
              value={custom}
              onChangeText={setCustom}
              keyboardType="number-pad"
              placeholder="Every… minutes"
              placeholderTextColor={colors.muted}
              onSubmitEditing={applyCustom}
              returnKeyType="done"
            />
            <Pressable style={styles.setBtn} onPress={applyCustom}>
              <Text style={styles.setBtnText}>Set</Text>
            </Pressable>
          </View>

          {currentInterval != null && (
            <Pressable style={styles.offBtn} onPress={() => onSelect(null)}>
              <Text style={styles.offBtnText}>Turn off reminder</Text>
            </Pressable>
          )}
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(20,20,30,0.35)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 32,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.border,
    marginBottom: 14,
  },
  title: { fontSize: 20, fontWeight: '800', color: colors.text },
  subtitle: { fontSize: 14, color: colors.muted, marginTop: 2, marginBottom: 16 },
  webNote: {
    fontSize: 12,
    color: colors.muted,
    backgroundColor: colors.bg,
    borderRadius: 10,
    padding: 10,
    marginBottom: 14,
  },
  presetRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 999,
    backgroundColor: colors.bg,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { color: colors.text, fontWeight: '700' },
  chipTextActive: { color: '#FFFFFF' },
  customRow: { flexDirection: 'row', gap: 10, marginTop: 16 },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
    color: colors.text,
    backgroundColor: colors.bg,
  },
  setBtn: {
    paddingHorizontal: 20,
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  setBtnText: { color: '#FFFFFF', fontWeight: '800', fontSize: 15 },
  offBtn: { marginTop: 18, alignItems: 'center', paddingVertical: 8 },
  offBtnText: { color: colors.danger, fontWeight: '700', fontSize: 15 },
});
