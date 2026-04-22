import '../notification_dialog_widget.dart';
void checkAndShowSoundDialog(BuildContext context) async {
  final shown = box.read('sound_dialog_shown') ?? false;

  if (!shown) {
    await box.write('sound_dialog_shown', true);
    if (context.mounted) {
      NotificationSoundDialog.show(context);
    }
  }
}
