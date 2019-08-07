import 'package:args/args.dart';
import 'package:garmin_client/garmin_client.dart';

main(List<String> arguments) async {
  final parser = ArgParser()..addOption('username', abbr: 'u')..addOption('password', abbr: 'p');
  final argResults = parser.parse(arguments);

  var garmin_client = GarminClient(argResults['username'], argResults['password']);
  await garmin_client.connect();

  // Gets a list of all activity ids, sorted in reverse chronological order
  var activities = await garmin_client.list_activities();

  print('You\'ve done ${activities.length} activities');

  // Gets the activity summary of the latest activity
  // var latest_summary = await garmin_client.get_activity_summary(activities.first);

  // Gets the activity details of the latest activity
  // var latest_details = await garmin_client.get_activity_details(activities.first);

  // Gets the splits for the latest activity
  // var latest_splits = await garmin_client.get_activity_splits(activities.first);

  // Gets the heart rate zones for the latest activity
  // var latest_hr_zones = await garmin_client.get_activity_hr_zones(activities.first);

  // Gets a list of all cycling activity (any Garmin activity type accepted)
  // var cycling_activities = await garmin_client.list_activities('cycling');
}
