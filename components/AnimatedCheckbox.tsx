import { useEffect, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';

import { colors } from '../constants/theme';
import { Confetti } from './Confetti';

/**
 * A round checkbox whose fill + checkmark bloom from the center, with a
 * confetti burst on completion. Tapping reverses the animation.
 */
export function AnimatedCheckbox({
  completed,
  onToggle,
}: {
  completed: boolean;
  onToggle: () => void;
}) {
  const progress = useSharedValue(completed ? 1 : 0);
  const [burst, setBurst] = useState(0);
  const prev = useRef(completed);

  useEffect(() => {
    progress.value = withSpring(completed ? 1 : 0, {
      damping: 12,
      stiffness: 180,
    });
    // Only celebrate the false -> true transition.
    if (completed && !prev.current) setBurst((n) => n + 1);
    prev.current = completed;
  }, [completed]);

  const fillStyle = useAnimatedStyle(() => ({
    opacity: progress.value,
    transform: [{ scale: progress.value }],
  }));

  return (
    <Pressable
      onPress={onToggle}
      hitSlop={8}
      accessibilityRole="checkbox"
      accessibilityState={{ checked: completed }}
      style={styles.ring}
    >
      <Animated.View style={[styles.fill, fillStyle]}>
        <Text style={styles.check}>✓</Text>
      </Animated.View>
      <View pointerEvents="none">
        <Confetti trigger={burst} />
      </View>
    </Pressable>
  );
}

const SIZE = 26;

const styles = StyleSheet.create({
  ring: {
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
    borderWidth: 2,
    borderColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fill: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    borderRadius: SIZE / 2,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  check: {
    color: colors.check,
    fontSize: 15,
    fontWeight: '800',
    lineHeight: 18,
  },
});
