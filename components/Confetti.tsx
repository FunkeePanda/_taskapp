import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, {
  SharedValue,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

import { confettiColors } from '../constants/theme';

const COUNT = 12;
const PARTICLES = Array.from({ length: COUNT }, (_, i) => {
  const angle = (i / COUNT) * Math.PI * 2;
  return {
    color: confettiColors[i % confettiColors.length],
    dx: Math.cos(angle) * (24 + Math.random() * 16),
    dy: Math.sin(angle) * (24 + Math.random() * 16),
    size: 5 + Math.random() * 3,
  };
});

function Particle({
  p,
  t,
}: {
  p: (typeof PARTICLES)[number];
  t: SharedValue<number>;
}) {
  const style = useAnimatedStyle(() => ({
    opacity: 1 - t.value,
    transform: [
      { translateX: p.dx * t.value },
      // slight downward drift, like gravity.
      { translateY: p.dy * t.value + 10 * t.value * t.value },
      { scale: 1 - 0.3 * t.value },
    ],
  }));
  return (
    <Animated.View
      style={[
        styles.particle,
        { backgroundColor: p.color, width: p.size, height: p.size },
        style,
      ]}
    />
  );
}

/** A one-shot confetti burst that replays whenever `trigger` increments. */
export function Confetti({ trigger }: { trigger: number }) {
  const t = useSharedValue(0);

  useEffect(() => {
    if (trigger <= 0) return;
    t.value = 0;
    t.value = withTiming(1, { duration: 650 });
  }, [trigger]);

  if (trigger <= 0) return null;

  return (
    <View pointerEvents="none" style={styles.layer}>
      {PARTICLES.map((p, i) => (
        <Particle key={i} p={p} t={t} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  layer: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  particle: {
    position: 'absolute',
    borderRadius: 4,
  },
});
