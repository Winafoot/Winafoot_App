// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:core_kosmos/core_kosmos.dart';

abstract class GoogleMapController {
  static Future<List<LocationModel>> placeAutocomplete(
      String query, String language,
      [String country = "fr"]) async {
    final GoogleMapConfig? googleController =
        getAppModel().dependencies.packages["google_map"] as GoogleMapConfig?;
    assert(googleController?.googleMapApiKey != null,
        "GoogleMapConfig.googleMapApiKey is null, you need to set it in your config with 'google_map': GoogleMapConfig()");

    final String mapKey = googleController!.googleMapApiKey!;
    final autocompleteUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$mapKey&language=$language&components=country:$country';
    final autocompleteRes = await http.get(Uri.parse(autocompleteUrl));
    if (autocompleteRes.statusCode != 200) {
      return [];
    }
    final res = <LocationModel>[];

    for (final prediction in json.decode(autocompleteRes.body)['predictions']) {
      final placeId = prediction['place_id'];
      final placeUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?key=$mapKey&place_id=$placeId&fields=geometry,formatted_address,address_components';
      final placeRes = await http.get(
        Uri.parse(placeUrl),
        headers: {
          "Accept": "application/json",
          "Access-Control_Allow_Origin": "*",
        },
      );

      if (placeRes.statusCode != 200) {
        continue;
      }

      final place = json.decode(placeRes.body);
      res.add(LocationModel.fromGooglePlace(prediction, place));
    }
    return res;
  }
}
