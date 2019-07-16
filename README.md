# garmin_connect

A Dart library for integrating against Garmin Connect.

Garmin Connect does not provide a modern and public API. This tool is simulating a browser, and manually logs into the Garmin website to scrape activities. Use at your own risk.

Heavily inspired by the excellent [Garmin Connect activity backup tool](https://github.com/petergardfjall/garminexport).

## Usage

A simple usage example:

```dart
import 'package:garmin_client/garmin_client.dart';

main() {
    var garmin_client = GarminClient(MY_USERNAME, MY_PASSWORD);
    await garmin_client.connect();

  // Gets a list of all activity ids, sorted in reverse chronological order
  var activities = await garmin_client.list_activities();

  // Gets the activity summary of the latest activity
  var latest_summary = await garmin_client.get_activity_summary(activities.first);
}
```
