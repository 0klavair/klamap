import Foundation

/// JSON style strings for Google Maps SDK. These follow Google's documented
/// styling spec: https://developers.google.com/maps/documentation/style-reference
/// Apply via `GMSMapView.mapStyle = try? GMSMapStyle(jsonString: ...)`.
enum MapStylePresets {

    /// Hide every label (road names, POI names, transit, administrative). Roads,
    /// POIs themselves and other geometry stay visible.
    static let noLabels = """
    [
      { "elementType": "labels", "stylers": [{ "visibility": "off" }] }
    ]
    """

    /// Hide all POIs (icons + labels). Roads, road labels and natural features stay.
    static let noPOI = """
    [
      { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
      { "featureType": "transit.station", "stylers": [{ "visibility": "off" }] }
    ]
    """

    /// "Minimal" map for wallpapers — no labels, no POI, no transit lines.
    /// Just geography, roads (without names) and water.
    static let minimal = """
    [
      { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
      { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
      { "elementType": "labels", "stylers": [{ "visibility": "off" }] },
      { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "visibility": "off" }] }
    ]
    """

    /// Dark Apple-Maps-night-mode-ish style (without labels for wallpaper use).
    static let dark = """
    [
      { "elementType": "geometry", "stylers": [{ "color": "#1d2c4d" }] },
      { "elementType": "labels", "stylers": [{ "visibility": "off" }] },
      { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#8ec3b9" }] },
      { "featureType": "landscape", "elementType": "geometry", "stylers": [{ "color": "#23395d" }] },
      { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
      { "featureType": "poi.park", "elementType": "geometry", "stylers": [{ "color": "#023e58" }] },
      { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#304a7d" }] },
      { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#2c6675" }] },
      { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{ "color": "#255763" }] },
      { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
      { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#0e1626" }] }
    ]
    """

    /// Vintage / sepia look without labels.
    static let retro = """
    [
      { "elementType": "geometry", "stylers": [{ "color": "#ebe3cd" }] },
      { "elementType": "labels", "stylers": [{ "visibility": "off" }] },
      { "elementType": "labels.text.fill", "stylers": [{ "color": "#523735" }] },
      { "elementType": "labels.text.stroke", "stylers": [{ "color": "#f5f1e6" }] },
      { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{ "color": "#c9b2a6" }] },
      { "featureType": "administrative.land_parcel", "elementType": "geometry.stroke", "stylers": [{ "color": "#dcd2be" }] },
      { "featureType": "landscape.natural", "elementType": "geometry", "stylers": [{ "color": "#dfd2ae" }] },
      { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
      { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#f5f1e6" }] },
      { "featureType": "road.arterial", "elementType": "geometry", "stylers": [{ "color": "#fdfcf8" }] },
      { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#f8c967" }] },
      { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{ "color": "#e9bc62" }] },
      { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
      { "featureType": "water", "elementType": "geometry.fill", "stylers": [{ "color": "#b9d3c2" }] }
    ]
    """

    /// Lookup table by enum case for the settings UI preview.
    static let allPresets: [(name: String, json: String)] = [
        ("No labels", noLabels),
        ("No POI", noPOI),
        ("Minimal", minimal),
        ("Dark", dark),
        ("Retro", retro)
    ]
}
