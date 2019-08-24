import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_retry/dio_retry.dart';

class GarminException implements Exception {
  String message;
  GarminException(this.message);
  String toString() => "GarminException: $message";
}

class GarminClient {
  String username;
  String password;

  Dio dio;

  GarminClient(this.username, this.password);

  Future<void> connect() async {
    dio = Dio()
      ..interceptors.add(CookieManager(CookieJar()))
      ..interceptors.add(RetryInterceptor(
          dio: dio,
          options: RetryOptions(
            retries: 5,
            retryInterval: Duration(seconds: 10),
          )));

    await _authenticate();
  }

  void _authenticate() async {
    // Step 1: Post credentials
    Response auth_response = await dio.post('https://sso.garmin.com/sso/signin',
        queryParameters: {'service': 'https://connect.garmin.com/modern'},
        data: {'username': username, 'password': password, 'embed': 'false'},
        options: Options(
            contentType: ContentType.parse('application/x-www-form-urlencoded'),
            headers: {'origin': 'https://sso.garmin.com'}));
    if (auth_response.statusCode != 200) {
      throw GarminException('Login credentials not accepted');
    }

    // Step 2: Extract auth ticket url from response
    RegExp exp = RegExp(r'response_url\s*=\s*"(https:[^"]+)"');
    RegExpMatch match = exp.firstMatch(auth_response.data);
    if (match == null) {
      throw GarminException('No auth ticket URL found. Did you specify correct credentials?');
    }
    String url = match.group(1).replaceAll('\\', '');

    // Step 3: Visit ticket URL in order to grab session cookie
    // N.B. Code is complicated to allow for Garmin's weird auth flow
    // with multiple redirects eventually landing on the original URL.
    // Todo: open ticket on Dio repo arguing Redirect Loops should be possible.
    Response claim_response;
    bool isRedirect = true;
    while (isRedirect) {
      claim_response = await dio.get(url,
          options: Options(
              followRedirects: false,
              validateStatus: (status) {
                return status < 400; // Work-around to not throw error on 302s
              }));
      // Can't use response.isRedirect because 302s are deprecated and not marked as redirects
      if (claim_response.statusCode == 302) {
        url = claim_response.headers['location'][0];
      } else {
        isRedirect = false;
      }
    }
    if (claim_response.statusCode != 200) {
      throw GarminException('Failed to get session through auth ticket URL');
    }
  }

  Future<List<int>> list_activities([String activityType = '']) async {
    try {
      return await _fetch_activities(0, 100, activityType);
    } on DioError {
      if (activityType == '') {
        throw GarminException('Failed to fetch activities');
      } else {
        throw GarminException('Failed to fetch activities of type $activityType');
      }
    }
  }

  Future<List<int>> _fetch_activities(int index, int batch, String activityType) async {
    List<int> ids = [];

    Response response = await dio.get(
        'https://connect.garmin.com/modern/proxy/activitylist-service/activities/search/activities',
        queryParameters: {'start': index, 'limit': batch, 'activityType': activityType});

    List<dynamic> data = response.data;
    data.forEach((x) => ids.add(x['activityId']));
    if (data.length == batch) {
      ids.addAll(await _fetch_activities(index + batch, batch, activityType));
    }

    return ids;
  }

  Future<Map<String, dynamic>> get_activity_summary(int activity_id) async {
    Response response;
    bool hadException = false;

    try {
      response = await dio.get('https://connect.garmin.com/modern/proxy/activity-service/activity/$activity_id');
    } on DioError {
      hadException = true;
    }

    if (hadException || response.statusCode != 200) {
      throw GarminException('Failed to get summary for activity $activity_id');
    }

    return response.data;
  }

  Future<Map<String, dynamic>> get_activity_details(int activity_id) async {
    Response response;
    bool hadException = false;

    try {
      response =
          await dio.get('https://connect.garmin.com/modern/proxy/activity-service/activity/$activity_id/details');
    } on DioError {
      hadException = true;
    }

    if (hadException || response.statusCode != 200) {
      throw GarminException('Failed to get details for activity $activity_id');
    }

    return response.data;
  }

  Future<Map<String, dynamic>> get_activity_splits(int activity_id) async {
    Response response;
    bool hadException = false;

    try {
      response = await dio.get('https://connect.garmin.com/modern/proxy/activity-service/activity/$activity_id/splits');
    } on DioError {
      hadException = true;
    }

    if (hadException || response.statusCode != 200) {
      throw GarminException('Failed to get splits for activity $activity_id');
    }

    return response.data;
  }

  Future<List<dynamic>> get_activity_hr_zones(int activity_id) async {
    Response response;
    bool hadException = false;

    try {
      response =
          await dio.get('https://connect.garmin.com/modern/proxy/activity-service/activity/$activity_id/hrTimeInZones');
    } on DioError {
      hadException = true;
    }

    if (hadException || response.statusCode != 200) {
      throw GarminException('Failed to get heart rate zones for activity $activity_id');
    }

    return response.data;
  }
}
