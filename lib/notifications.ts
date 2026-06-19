import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

const ANDROID_CHANNEL = 'reminders';

// Show reminders as banners even while the app is foregrounded.
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

/**
 * Ask for notification permission (and set up the Android channel).
 * Returns false on web, where reliable background reminders aren't supported.
 */
export async function ensurePermissions(): Promise<boolean> {
  if (Platform.OS === 'web') return false;

  let { granted } = await Notifications.getPermissionsAsync();
  if (!granted) {
    granted = (await Notifications.requestPermissionsAsync()).granted;
  }

  if (granted && Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync(ANDROID_CHANNEL, {
      name: 'Task reminders',
      importance: Notifications.AndroidImportance.HIGH,
    });
  }
  return granted;
}

/**
 * Schedule a repeating reminder. Returns the notification id, or null if it
 * couldn't be scheduled (e.g. web, or permission denied).
 */
export async function scheduleReminder(
  title: string,
  intervalMinutes: number
): Promise<string | null> {
  if (Platform.OS === 'web') return null;
  if (!(await ensurePermissions())) return null;

  // iOS requires a repeating time-interval of at least 60 seconds.
  const seconds = Math.max(60, Math.round(intervalMinutes * 60));

  return Notifications.scheduleNotificationAsync({
    content: {
      title: 'Task reminder',
      body: title || 'You have a task to finish',
      sound: true,
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
      seconds,
      repeats: true,
      channelId: Platform.OS === 'android' ? ANDROID_CHANNEL : undefined,
    },
  });
}

export async function cancelReminder(notificationId?: string): Promise<void> {
  if (!notificationId) return;
  try {
    await Notifications.cancelScheduledNotificationAsync(notificationId);
  } catch {
    // Already gone or invalid id — nothing to do.
  }
}
