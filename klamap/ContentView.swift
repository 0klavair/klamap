import Foundation
import SwiftUI
import Combine
@preconcurrency import MapKit
import CoreLocation
import AVFoundation
import Photos
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import GameController
import WebKit
import UIKit
import Darwin
import CoreImage
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

// MARK: - Localization System
struct Localization {
    static var current: LocalizationStrings {
        let lang = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "system"
        switch lang {
        case "fr":
            return FrenchStrings()
        case "en":
            return EnglishStrings()
        default:
            // System language detection
            let preferredLang = Locale.preferredLanguages.first ?? "en"
            if preferredLang.starts(with: "fr") {
                return FrenchStrings()
            } else {
                return EnglishStrings()
            }
        }
    }
}

protocol LocalizationStrings {
    // App Info
    var appName: String { get }
    var appDescription: String { get }
    
    // Main UI
    var pointsAndTrajectory: String { get }
    var map: String { get }
    var resolutionAndImages: String { get }
    var preview: String { get }
    var quickActions: String { get }
    var settings: String { get }
    
    // Points Section
    var points: String { get }
    var setA: String { get }
    var setB: String { get }
    var moveMapInstruction: String { get }
    var controllerCompatibility: String { get }
    
    // Duration & Timing
    var durationAndTiming: String { get }
    var duration: String { get }
    var seconds: String { get }
    var durationHint: String { get }
    var trafficMode: String { get }
    var advancedSettings: String { get }
    var approximateTrip: String { get }
    var distance: String { get }
    var animationDurationNote: String { get }
    
    // Camera & Tracking
    var cameraAndTracking: String { get }
    var viewAngle: String { get }
    var keepCentered: String { get }
    var curvedPath: String { get }
    var curvature: String { get }
    var followRealRoute: String { get }
    var transport: String { get }
    var car: String { get }
    var walk: String { get }
    var transit: String { get }
    var computingRoute: String { get }
    var lightMapNote: String { get }
    
    // Map Section
    var style: String { get }
    var standard: String { get }
    var muted: String { get }
    var hybrid: String { get }
    var pointsOfInterest: String { get }
    var hideRoadLabels: String { get }
    var searchAddress: String { get }
    var searchHint: String { get }
    var lightModeHint: String { get }
    
    // Resolution & Format
    var resolution: String { get }
    var native: String { get }
    var aspect: String { get }
    var device: String { get }
    var custom: String { get }
    var orientation: String { get }
    var portrait: String { get }
    var landscape: String { get }
    var oversampling: String { get }
    var oversamplingDescription: String { get }
    var imageFormat: String { get }
    var compression: String { get }
    var noCompression: String { get }
    var maxCompression: String { get }
    var quality: String { get }
    var lossyCompression: String { get }
    
    // Video Section
    var video: String { get }
    var videoFormat: String { get }
    var pngSequence: String { get }
    var bitrate: String { get }
    var frames: String { get }
    var fixedNumber: String { get }
    var frameCount: String { get }
    var frameCountDescription: String { get }
    
    // Timing
    var timing: String { get }
    var curve: String { get }
    var linear: String { get }
    var easeIn: String { get }
    var easeOut: String { get }
    var easeInOut: String { get }
    var smoothstep: String { get }
    var smootherstep: String { get }
    var cubicBezier: String { get }
    var intro: String { get }
    var outro: String { get }
    
    // Actions
    var createImage: String { get }
    var singleHighQualityImage: String { get }
    var createVideo: String { get }
    var exportZIP: String { get }
    var imageSequence: String { get }
    var setABFirst: String { get }
    var exportTracking: String { get }
    var exportPreset: String { get }
    var importPreset: String { get }
    var openSettings: String { get }
    
    // Rendering
    var preparing: String { get }
    var exportImage: String { get }
    var exportVideo: String { get }
    var exportZip: String { get }
    var cancelRender: String { get }
    var cancelling: String { get }
    var renderComplete: String { get }
    var exportZipComplete: String { get }
    var saveToFiles: String { get }
    var backToMenu: String { get }
    var accessGallery: String { get }
    var returnToApp: String { get }
    var errorDuringRender: String { get }
    var close: String { get }
    var renderingImage: String { get }
    var encoding: String { get }
    var savingToPhotos: String { get }
    var frame: String { get }
    
    // Errors
    var defineABBeforeExport: String { get }
    var defineABBeforeImage: String { get }
    var defineABBeforeVideo: String { get }
    var defineABBeforeSequence: String { get }
    var defineAtLeastOnePoint: String { get }
    var routeError: String { get }
    var addressNotFound: String { get }
    var searchError: String { get }
    var noFramesToGenerate: String { get }
    var folderCreationError: String { get }
    var imageWriteError: String { get }
    var zipCreationError: String { get }
    var exportError: String { get }
    var exportCancelled: String { get }
    var photosAccessDenied: String { get }
    var renderError: String { get }
    var encodingError: String { get }
    var presetReadError: String { get }
    var trackingExportError: String { get }
    var presetExportError: String { get }
    
    // Settings
    var language: String { get }
    var system: String { get }
    var french: String { get }
    var english: String { get }
    var languageNote: String { get }
    var controllerSettings: String { get }
    var panSensitivity: String { get }
    var tiltSensitivity: String { get }
    var deadZone: String { get }
    var controllerNote: String { get }
    var networksAndGitHub: String { get }
    var replaceURLsNote: String { get }
    var introduction: String { get }
    var reviewIntroduction: String { get }
    var introductionNote: String { get }
    
    // Traffic Settings
    var advancedTraffic: String { get }
    var lightsAndStops: String { get }
    var stopDensity: String { get }
    var stopDuration: String { get }
    var speedVariations: String { get }
    var variability: String { get }
    var variabilityNote: String { get }
    
    // Onboarding
    var accessApplication: String { get }
    var networksAndCode: String { get }
    var launching: String { get }
    
    // Easter Egg
    var howDidYouFindThis: String { get }
    var easterEggExplanation: String { get }
    
    // Alerts
    var experimentalHybridMode: String { get }
    var hybridModeWarning: String { get }
    var ok: String { get }
    var savedToPhotos: String { get }
    
    // Additional
    var width: String { get }
    var height: String { get }
    var tip: String { get }
    var yourZipFile: String { get }
}

struct FrenchStrings: LocalizationStrings {
    // App Info
    let appName = "Klamap"
    let appDescription = "Crée des trajets animés entre A et B avec Apple Plans, en mode CarPlay 3D, et exporte-les en vidéo ou séquence d'images pour tes fonds d'écran ou montages."
    
    // Main UI
    let pointsAndTrajectory = "Points & trajectoire"
    let map = "Carte"
    let resolutionAndImages = "Résolution & Images"
    let preview = "Aperçu"
    let quickActions = "Actions rapides"
    let settings = "Réglages"
    
    // Points Section
    let points = "Points"
    let setA = "Définir A"
    let setB = "Définir B"
    let moveMapInstruction = "Déplace la carte et définis A et B avec les boutons ci-dessus."
    let controllerCompatibility = "Compatibilité manette : tu peux contrôler la caméra avec une manette (sensibilité et zone morte sont réglables dans Réglages)."
    
    // Duration & Timing
    let durationAndTiming = "Durée & Timing"
    let duration = "Durée"
    let seconds = "Secondes"
    let durationHint = "La durée est saisie en secondes (ex : 120 = 2 min)."
    let trafficMode = "Mode circulation (algorithme)"
    let advancedSettings = "Paramètres avancés"
    let approximateTrip = "Trajet approx.: %d min en %@"
    let distance = "Distance: %.1f km"
    let animationDurationNote = "La durée d'animation reste indépendante : ajustez-la librement ci-dessus."
    
    // Camera & Tracking
    let cameraAndTracking = "Caméra & Suivi"
    let viewAngle = "Angle de vue"
    let keepCentered = "Garder centré"
    let curvedPath = "Chemin courbé"
    let curvature = "Courbure"
    let followRealRoute = "Suivre la route réelle (ligne bleue)"
    let transport = "Transport"
    let car = "Voiture"
    let walk = "À pied"
    let transit = "Transports"
    let computingRoute = "Calcul de l'itinéraire…"
    let lightMapNote = "Pour une carte claire, change aussi le mode sombre/clair de l'appareil dans les réglages système."
    
    // Map Section
    let style = "Style"
    let standard = "Standard"
    let muted = "Discret"
    let hybrid = "Hybride"
    let pointsOfInterest = "Points d'intérêt"
    let hideRoadLabels = "Masquer les noms des routes"
    let searchAddress = "Rechercher une adresse"
    let searchHint = "Astuce: Essayez \"Tour Eiffel\" ou une adresse."
    let lightModeHint = "Astuce: pour une carte claire, passe aussi l'appareil en mode clair dans les Réglages."
    
    // Resolution & Format
    let resolution = "Résolution"
    let native = "Native"
    let aspect = "Format"
    let device = "Appareil"
    let custom = "Personnalisé"
    let orientation = "Orientation"
    let portrait = "Portrait"
    let landscape = "Paysage"
    let oversampling = "Sur-échantillonnage"
    let oversamplingDescription = "Le sur-échantillonnage rend à une résolution plus élevée puis réduit pour des résultats plus nets."
    let imageFormat = "Format d'image"
    let compression = "Compression"
    let noCompression = "0 = pas de compression (rapide)"
    let maxCompression = "9 = compression maximale (fichier plus petit)"
    let quality = "Qualité"
    let lossyCompression = "HEIC/JPEG utilisent une compression avec perte."
    
    // Video Section
    let video = "Vidéo"
    let videoFormat = "Format vidéo"
    let pngSequence = "Séquence PNG (non compressé)"
    let bitrate = "Débit"
    let frames = "Images"
    let fixedNumber = "Nombre fixe"
    let frameCount = "Images: "
    let frameCountDescription = "Le trajet utilisera exactement ce nombre d'images, indépendamment du FPS."
    
    // Timing
    let timing = "Timing"
    let curve = "Courbe"
    let linear = "Linéaire"
    let easeIn = "Accélération"
    let easeOut = "Décélération"
    let easeInOut = "Accél-Décél"
    let smoothstep = "Lissage"
    let smootherstep = "Lissage+"
    let cubicBezier = "Bézier cubique"
    let intro = "Intro"
    let outro = "Outro"
    
    // Actions
    let createImage = "Créer image"
    let singleHighQualityImage = "Image haute qualité unique"
    let createVideo = "Créer vidéo"
    let exportZIP = "Exporter ZIP"
    let imageSequence = "Séquence d'images"
    let setABFirst = "Définir A & B d'abord"
    let exportTracking = "Exporter suivi"
    let exportPreset = "Exporter preset"
    let importPreset = "Importer preset"
    let openSettings = "Ouvrir les réglages"
    
    // Rendering
    let preparing = "Préparation…"
    let exportImage = "Export image…"
    let exportVideo = "Export vidéo…"
    let exportZip = "Export ZIP…"
    let cancelRender = "Annuler le rendu"
    let cancelling = "Annulation en cours…"
    let renderComplete = "Rendu terminé"
    let exportZipComplete = "Export ZIP terminé"
    let saveToFiles = "Enregistrer dans Fichiers"
    let backToMenu = "Retour au menu"
    let accessGallery = "Accéder à la galerie"
    let returnToApp = "Retourner sur l'app"
    let errorDuringRender = "Erreur pendant le rendu"
    let close = "Fermer"
    let renderingImage = "Rendu de l'image…"
    let encoding = "Encodage"
    let savingToPhotos = "Enregistrement Photos…"
    let frame = "Image"
    
    // Errors
    let defineABBeforeExport = "Définis les points A et B avant d'exporter."
    let defineABBeforeImage = "Définis les points A et B avant d'exporter une image."
    let defineABBeforeVideo = "Définis les points A et B avant d'exporter une vidéo."
    let defineABBeforeSequence = "Définis les points A et B avant d'exporter une séquence ZIP."
    let defineAtLeastOnePoint = "Définis au moins A ou B avant d'exporter le tracking."
    let routeError = "Erreur itinéraire"
    let addressNotFound = "Adresse introuvable"
    let searchError = "Erreur de recherche"
    let noFramesToGenerate = "Aucune image à générer."
    let folderCreationError = "Erreur création dossier séquence"
    let imageWriteError = "Erreur écriture image"
    let zipCreationError = "Erreur création ZIP"
    let exportError = "Erreur export"
    let exportCancelled = "Export annulé."
    let photosAccessDenied = "Accès Photos refusé"
    let renderError = "Erreur de rendu image"
    let encodingError = "Erreur encodage image"
    let presetReadError = "Impossible de lire le preset."
    let trackingExportError = "Erreur export tracking"
    let presetExportError = "Erreur export preset"
    
    // Settings
    let language = "Langue"
    let system = "Système"
    let french = "Français"
    let english = "English"
    let languageNote = "La langue de l'interface s'appliquera au prochain lancement."
    let controllerSettings = "Contrôles manette"
    let panSensitivity = "Sensibilité panoramique"
    let tiltSensitivity = "Sensibilité inclinaison"
    let deadZone = "Zone morte (joystick)"
    let controllerNote = "Tu peux ajuster la sensibilité et la zone morte de la manette. Les valeurs par défaut restent celles que tu utilises déjà (sensibilité 1.0, zone morte ~0.15)."
    let networksAndGitHub = "Réseaux & GitHub"
    let replaceURLsNote = "Remplace les URL ci-dessus par tes vrais liens (GitHub, Instagram, Discord)."
    let introduction = "Introduction"
    let reviewIntroduction = "Revoir l'introduction"
    let introductionNote = "Permet d'afficher à nouveau l'écran d'accueil avec ta présentation et les liens."
    
    // Traffic Settings
    let advancedTraffic = "Circulation avancée"
    let lightsAndStops = "Feux et arrêts"
    let stopDensity = "Densité des arrêts"
    let stopDuration = "Durée des arrêts"
    let speedVariations = "Variations de vitesse"
    let variability = "Variabilité"
    let variabilityNote = "Plus la variabilité est élevée, plus la vitesse fluctue (bouchons, ralentissements)."
    
    // Onboarding
    let accessApplication = "Accéder à l'application"
    let networksAndCode = "Réseaux & code"
    let launching = "Lancement…"
    
    // Easter Egg
    let howDidYouFindThis = "Comment t'as trouvé ça ?"
    let easterEggExplanation = "Tu as déclenché un easter egg caché en tapant « klavair » dans la recherche."
    
    // Alerts
    let experimentalHybridMode = "Mode hybride expérimental"
    let hybridModeWarning = "Le mode hybride utilise une vue 3D. Les points A et B peuvent sembler mal alignés par rapport au centre visuel, surtout avec un angle (pitch) élevé."
    let ok = "OK"
    let savedToPhotos = "Enregistré dans Photos"
    
    // Additional
    let width = "Largeur"
    let height = "Hauteur"
    let tip = "Astuce"
    let yourZipFile = "Ton fichier ZIP contient toutes les images de la séquence."
}

struct EnglishStrings: LocalizationStrings {
    // App Info
    let appName = "Klamap"
    let appDescription = "Create animated routes between A and B with Apple Maps, in 3D CarPlay mode, and export them as videos or image sequences for your wallpapers or edits."
    
    // Main UI
    let pointsAndTrajectory = "Points & trajectory"
    let map = "Map"
    let resolutionAndImages = "Resolution & Images"
    let preview = "Preview"
    let quickActions = "Quick Actions"
    let settings = "Settings"
    
    // Points Section
    let points = "Points"
    let setA = "Set A"
    let setB = "Set B"
    let moveMapInstruction = "Move the map and set A and B using the buttons above."
    let controllerCompatibility = "Controller compatibility: you can control the camera with a gamepad (sensitivity and deadzone are adjustable in Settings)."
    
    // Duration & Timing
    let durationAndTiming = "Duration & Timing"
    let duration = "Duration"
    let seconds = "Seconds"
    let durationHint = "Duration is entered in seconds (e.g. 120 = 2 min)."
    let trafficMode = "Traffic mode (algorithm)"
    let advancedSettings = "Advanced settings"
    let approximateTrip = "Approx. trip: %d min by %@"
    let distance = "Distance: %.1f km"
    let animationDurationNote = "Animation duration remains independent: adjust it freely above."
    
    // Camera & Tracking
    let cameraAndTracking = "Camera & Tracking"
    let viewAngle = "View angle"
    let keepCentered = "Keep centered"
    let curvedPath = "Curved path"
    let curvature = "Curvature"
    let followRealRoute = "Follow real route (blue line)"
    let transport = "Transport"
    let car = "Car"
    let walk = "Walk"
    let transit = "Transit"
    let computingRoute = "Computing route…"
    let lightMapNote = "For a light map, also change the device's dark/light mode in system settings."
    
    // Map Section
    let style = "Style"
    let standard = "Standard"
    let muted = "Muted"
    let hybrid = "Hybrid"
    let pointsOfInterest = "Points of Interest"
    let hideRoadLabels = "Hide road labels"
    let searchAddress = "Search for an address"
    let searchHint = "Tip: Try \"Eiffel Tower\" or an address."
    let lightModeHint = "Tip: for a light map, also set your device to light mode in Settings."
    
    // Resolution & Format
    let resolution = "Resolution"
    let native = "Native"
    let aspect = "Aspect"
    let device = "Device"
    let custom = "Custom"
    let orientation = "Orientation"
    let portrait = "Portrait"
    let landscape = "Landscape"
    let oversampling = "Oversampling"
    let oversamplingDescription = "Oversampling renders at higher resolution then downsamples for sharper results."
    let imageFormat = "Image format"
    let compression = "Compression"
    let noCompression = "0 = no compression (fast)"
    let maxCompression = "9 = maximum compression (smaller file)"
    let quality = "Quality"
    let lossyCompression = "HEIC/JPEG use lossy compression."
    
    // Video Section
    let video = "Video"
    let videoFormat = "Video format"
    let pngSequence = "PNG sequence (uncompressed)"
    let bitrate = "Bitrate"
    let frames = "Frames"
    let fixedNumber = "Fixed number"
    let frameCount = "Frames: "
    let frameCountDescription = "The route will use exactly this number of frames, regardless of FPS."
    
    // Timing
    let timing = "Timing"
    let curve = "Curve"
    let linear = "Linear"
    let easeIn = "Ease In"
    let easeOut = "Ease Out"
    let easeInOut = "Ease In-Out"
    let smoothstep = "Smoothstep"
    let smootherstep = "Smootherstep"
    let cubicBezier = "Cubic Bézier"
    let intro = "Intro"
    let outro = "Outro"
    
    // Actions
    let createImage = "Create image"
    let singleHighQualityImage = "Single high-quality image"
    let createVideo = "Create video"
    let exportZIP = "Export ZIP"
    let imageSequence = "Image sequence"
    let setABFirst = "Set A & B first"
    let exportTracking = "Export tracking"
    let exportPreset = "Export preset"
    let importPreset = "Import preset"
    let openSettings = "Open settings"
    
    // Rendering
    let preparing = "Preparing…"
    let exportImage = "Export image…"
    let exportVideo = "Export video…"
    let exportZip = "Export ZIP…"
    let cancelRender = "Cancel render"
    let cancelling = "Cancelling…"
    let renderComplete = "Render complete"
    let exportZipComplete = "ZIP export complete"
    let saveToFiles = "Save to Files"
    let backToMenu = "Back to menu"
    let accessGallery = "Access gallery"
    let returnToApp = "Return to app"
    let errorDuringRender = "Error during render"
    let close = "Close"
    let renderingImage = "Rendering image…"
    let encoding = "Encoding"
    let savingToPhotos = "Saving to Photos…"
    let frame = "Frame"
    
    // Errors
    let defineABBeforeExport = "Define points A and B before exporting."
    let defineABBeforeImage = "Define points A and B before exporting an image."
    let defineABBeforeVideo = "Define points A and B before exporting a video."
    let defineABBeforeSequence = "Define points A and B before exporting a ZIP sequence."
    let defineAtLeastOnePoint = "Define at least A or B before exporting tracking."
    let routeError = "Route error"
    let addressNotFound = "Address not found"
    let searchError = "Search error"
    let noFramesToGenerate = "No frames to generate."
    let folderCreationError = "Sequence folder creation error"
    let imageWriteError = "Image write error"
    let zipCreationError = "ZIP creation error"
    let exportError = "Export error"
    let exportCancelled = "Export cancelled."
    let photosAccessDenied = "Photos access denied"
    let renderError = "Image render error"
    let encodingError = "Image encoding error"
    let presetReadError = "Cannot read preset."
    let trackingExportError = "Tracking export error"
    let presetExportError = "Preset export error"
    
    // Settings
    let language = "Language"
    let system = "System"
    let french = "Français"
    let english = "English"
    let languageNote = "The interface language will apply on next launch."
    let controllerSettings = "Controller settings"
    let panSensitivity = "Pan sensitivity"
    let tiltSensitivity = "Tilt sensitivity"
    let deadZone = "Dead zone (joystick)"
    let controllerNote = "You can adjust the controller sensitivity and dead zone. Default values are those you're already using (sensitivity 1.0, dead zone ~0.15)."
    let networksAndGitHub = "Networks & GitHub"
    let replaceURLsNote = "Replace the URLs above with your real links (GitHub, Instagram, Discord)."
    let introduction = "Introduction"
    let reviewIntroduction = "Review introduction"
    let introductionNote = "Shows the welcome screen again with your presentation and links."
    
    // Traffic Settings
    let advancedTraffic = "Advanced traffic"
    let lightsAndStops = "Lights and stops"
    let stopDensity = "Stop density"
    let stopDuration = "Stop duration"
    let speedVariations = "Speed variations"
    let variability = "Variability"
    let variabilityNote = "Higher variability means more speed fluctuations (traffic jams, slowdowns)."
    
    // Onboarding
    let accessApplication = "Access application"
    let networksAndCode = "Networks & code"
    let launching = "Launching…"
    
    // Easter Egg
    let howDidYouFindThis = "How did you find this?"
    let easterEggExplanation = "You triggered a hidden easter egg by typing 'klavair' in the search."
    
    // Alerts
    let experimentalHybridMode = "Experimental hybrid mode"
    let hybridModeWarning = "Hybrid mode uses 3D view. Points A and B may appear misaligned from the visual center, especially with high pitch angle."
    let ok = "OK"
    let savedToPhotos = "Saved to Photos"
    
    // Additional
    let width = "Width"
    let height = "Height"
    let tip = "Tip"
    let yourZipFile = "Your ZIP file contains all the sequence images."
}

// MARK: - Missing helpers & placeholders added for buildability

// Generic helper stubs and placeholders to fix unresolved identifiers
fileprivate func oversampleOptions() -> [Double] { [1.0, 1.25, 1.5, 2.0, 3.0, 4.0, 5.0] }

fileprivate func mapStyleForLive(_ style: WallpaperMakerView.LiveMapStyle = .standard) -> MapStyle {
    if #available(iOS 17, *) {
        switch style {
        case .standard:
            // Style Apple Maps classique
            return .standard(elevation: .realistic, emphasis: .automatic)
        case .muted:
            // Variante désaturée / plus neutre
            return .standard(elevation: .realistic, emphasis: .muted)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    } else {
        // Fallback iOS < 17 : pas de contrôle fin sur l'emphasis
        switch style {
            case .standard, .muted:
                return .standard
            case .hybrid:
                return .hybrid
        }
    }
}

// MARK: - Root
struct RootView: View {
    var body: some View {
        NavigationStack { WallpaperMakerView() }
    }
}

// Entry view expected by previews or App entry point
struct ContentView: View {
    var body: some View { RootView() }
}

// MARK: - Location helper
@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var location: CLLocation?
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            self?.location = locations.last
        }
    }
}

// MARK: - Wallpaper maker (unique screen)
struct WallpaperMakerView: View {
    let L = Localization.current
    
    // MARK: - Preview helpers
    private func applyPreview(_ t: CGFloat) {
        let p = pathPoint(t)
        let cam = MapCamera(centerCoordinate: p.coord,
                            distance: p.pose.distance,
                            heading: p.pose.heading,
                            pitch: p.pose.pitch)
        previewPos = .camera(cam)
    }

    // CarPlay-like camera: third-person, low angle, slightly ahead of the blue route when useRoutePath is on.
    private func pathPoint(_ t: CGFloat) -> (coord: CLLocationCoordinate2D, pose: CamPose) {
        // Clamp base progress 0…1
        let clamped = max(0, min(1, t))

        // Applique le profil de circulation si activé
        let profT: CGFloat = simulateTraffic ? trafficProfileProgress(clamped) : clamped


        // Camera lead: la caméra regarde légèrement plus loin sur la route (effet CarPlay)
        // On pousse un peu plus quand on suit la route réelle pour bien voir la ligne bleue.
        let cameraLead: CGFloat = useRoutePath ? 0.06 : 0.02
        let tCamera = min(1, profT + cameraLead)

        let a = pointA ?? crosshairCenter ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let b = pointB ?? a
        let pA = poseA ?? currentPose
        let pB = poseB ?? currentPose

        let coord: CLLocationCoordinate2D
        var headingFromRoute: CLLocationDirection? = nil

        if useRoutePath, routeCoordinates.count >= 2 {
            // Échantillonne le point de caméra le long de la polyline
            let totalSegments = routeCoordinates.count - 1
            let fIndex = tCamera * CGFloat(totalSegments)
            let i0 = max(0, min(totalSegments - 1, Int(floor(fIndex))))
            let i1 = min(totalSegments, i0 + 1)
            let localT = fIndex - CGFloat(i0)

            let c0 = routeCoordinates[i0]
            let c1 = routeCoordinates[i1]

            coord = CLLocationCoordinate2D(
                latitude: lerp(c0.latitude, c1.latitude, localT),
                longitude: lerp(c0.longitude, c1.longitude, localT)
            )
            headingFromRoute = bearing(from: c0, to: c1)
        } else {
            // Pas de route réelle : simple interpolation A→B
            coord = CLLocationCoordinate2D(
                latitude: lerp(a.latitude, b.latitude, tCamera),
                longitude: lerp(a.longitude, b.longitude, tCamera)
            )
        }

        // Base: interpolation entre la pose de départ et d'arrivée
        let baseDist = lerp(pA.distance, pB.distance, profT)
        let basePitch = lerp(pA.pitch, pB.pitch, profT)

        var dist = baseDist
        var pitch = basePitch

        if useRoutePath {
            // Mode CarPlay : caméra en troisième personne, proche de la route
            // On force une distance et un pitch cohérents, indépendants des poses A/B.
            let minDist: CLLocationDistance = 250
            let maxDist: CLLocationDistance = 800

            if poseA == nil && poseB == nil {
                // Valeur par défaut si aucune pose spécifique n'a été capturée
                dist = 500
            } else {
                // On ramène la distance dans une plage raisonnable
                dist = max(minDist, min(maxDist, baseDist))
            }

            // Pitch élevé (vue quasi horizontale) pour effet 3ème personne
            pitch = 70
        }

        let baseHead = lerpAngle(pA.heading, pB.heading, profT)
        let head = headingFromRoute ?? baseHead

        return (coord, CamPose(distance: dist, pitch: pitch, heading: head))
    }

    @inline(__always) private func lerp<T: BinaryFloatingPoint>(_ a: T, _ b: T, _ t: CGFloat) -> T {
        a + (b - a) * T(t)
    }

    @inline(__always) private func lerpAngle(_ a: CLLocationDirection, _ b: CLLocationDirection, _ t: CGFloat) -> CLLocationDirection {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return a + d * CLLocationDirection(t)
    }

    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * cos(lat2) + sin(lat1) * sin(lat2) * cos(dLon)
        var brng = atan2(y, x) * 180 / .pi
        if brng < 0 { brng += 360 }
        return brng
    }

    /// Profil de progression simulant une circulation réelle (ralentissements, arrêts)
    private func trafficProfileProgress(_ t: CGFloat) -> CGFloat {
        let x = max(0, min(1, t))
        if x == 0 || x == 1 { return x }

        // Profil de base : smoothstep pour démarrage/arrêt doux
        var y = x * x * (3 - 2 * x)

        // Nombre d'arrêts virtuels en fonction de la densité
        let baseStops = 2
        let extraStops = Int(round(trafficStopDensity * 2)) // 0…2
        let stopCount = baseStops + extraStops

        // Largeur et impact des arrêts
        let stopWidth: CGFloat = 0.04 + 0.12 * CGFloat(trafficStopDuration) // 0.04…0.16
        let jitterAmplitude: CGFloat = 0.2 + 0.5 * CGFloat(trafficSpeedJitter) // 0.2…0.7

        var slowdown: CGFloat = 0
        if stopCount > 0 {
            for i in 0..<stopCount {
                let center = CGFloat(i + 1) / CGFloat(stopCount + 1)
                let d = abs(x - center)
                if d < stopWidth {
                    let n = 1 - d / stopWidth // 0..1
                    slowdown += n * n         // bosse quadratique
                }
            }
        }

        if slowdown > 0 {
            let factor = min(0.7, slowdown * jitterAmplitude)
            // On freine localement la progression sans la rendre complètement plate
            y = y * (1 - factor * 0.5)
        }

        return max(0, min(1, y))
    }

    // Force Map to rebuild when style/3D/POI change
    private var liveMapIdentity: String {
        "\(liveStyle.rawValue)-\((pitchDeg > 1) ? "3d" : "2d")-\(showPOI ? "poi" : "npoi")-\(hideRoadLabels ? "nroad" : "road")"
    }
    
    // MARK: - Quick actions
    private var mainActionButtonsBody: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let canRenderPath = (pointA != nil && pointB != nil)

        return LazyVGrid(columns: columns, spacing: 12) {
            actionTile(
                icon: "photo.on.rectangle",
                title: L.createImage,
                subtitle: L.singleHighQualityImage
            ) {
                hapticButtonTap(style: .medium)
                guard pointA != nil && pointB != nil else {
                    errorText = L.defineABBeforeImage
                    return
                }
                outputMode = .image
                showRenderOverlay = true
                renderFinished = false
                progressLabel = L.exportImage
                Task { await makeBothWallpapers() }
            }

            actionTile(
                icon: "film",
                title: L.createVideo,
                subtitle: canRenderPath ? "MP4 H.264" : L.setABFirst,
                disabled: false
            ) {
                hapticButtonTap(style: .medium)
                guard pointA != nil && pointB != nil else {
                    errorText = L.defineABBeforeVideo
                    return
                }
                outputMode = .video
                showRenderOverlay = true
                renderFinished = false
                progressLabel = L.exportVideo
                Task { await makePathVideo() }
            }

            actionTile(
                icon: "doc.zipper",
                title: L.exportZIP,
                subtitle: canRenderPath ? L.imageSequence : L.setABFirst,
                disabled: false
            ) {
                // Vibration comme les autres
                hapticButtonTap(style: .light)

                // Avertissement si A/B manquants (comme les autres exports)
                guard pointA != nil && pointB != nil else {
                    errorText = L.defineABBeforeSequence
                    return
                }

                // Paramètres par défaut pour export séquence
                imageFormatEnum = .png
                videoFormatEnum = .h264
                oversample = 1.0
                pngCompressionLevel = 1
                fps = 60

                // Export de séquence d'images
                capPlaygroundFileURL = nil
                outputMode = .sequence

                showRenderOverlay = true
                renderFinished = false
                progressLabel = L.exportZip

                Task { await exportImageSequence() }
            }
        }
    }

    @ViewBuilder private func actionTile(
        icon: String? = nil,
        assetName: String? = nil,
        title: String,
        subtitle: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let assetName = assetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }

                Text(title)
                    .font(.body)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(disabled)
    }
    
    // Preview aspect helper
    private func previewAspect() -> CGFloat {
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        let native = screen?.nativeBounds.size ?? CGSize(width: 1179, height: 2556)
        switch aspect {
        case .device:
            return native.width / native.height
        case .r16x9:
            return 16.0/9.0
        case .r4x3:
            return 4.0/3.0
        case .r1x1:
            return 1.0
        case .custom:
            if let w = Double(wCustom), let h = Double(hCustom), w > 0, h > 0 { return CGFloat(w/h) }
            return native.width / native.height
        }
    }

    // Ratio cible basé sur l'option d'aspect (force portrait pour "Appareil" sur iPhone)
    private func targetAspect() -> CGFloat {
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        let native = screen?.nativeBounds.size ?? CGSize(width: 1179, height: 2556)
        switch aspect {
        case .device:
            // Force portrait for device native on iPhone as requested
            let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
            return portrait.width / portrait.height
        case .r16x9:
            let base: CGFloat = 16.0/9.0
            return orientation == .portrait ? (1.0 / base) : base
        case .r4x3:
            let base: CGFloat = 4.0/3.0
            return orientation == .portrait ? (1.0 / base) : base
        case .r1x1:
            return 1.0
        case .custom:
            if let w = Double(wCustom), let h = Double(hCustom), w > 0, h > 0 {
                let base = CGFloat(w/h)
                return orientation == .portrait ? (1.0 / max(base, 0.0001)) : base
            }
            let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
            return portrait.width / portrait.height
        }
    }

    // Ratio + taille nominale fixe pour un aperçu toujours petit
    private func exportPreviewMetrics() -> (aspect: CGFloat, baseSize: CGFloat) {
        let a = targetAspect()
        let base: CGFloat = 140 // taille de référence (toujours petite)
        return (a, base)
    }

    // Calcule la résolution exportée en pixels selon la résolution + aspect + orientation
    private func exportPixelSize() -> CGSize {
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        let native = screen?.nativeBounds.size ?? CGSize(width: 1179, height: 2556)

        // Landscape aspect ratio (width/height >= 1) for canonical math
        func landscapeAspect() -> CGFloat {
            switch aspect {
            case .device:
                let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
                // Convert portrait ratio to landscape reference (invert if < 1)
                let r = portrait.width / portrait.height
                return max(r, 1.0)
            case .r16x9: return 16.0/9.0
            case .r4x3:  return 4.0/3.0
            case .r1x1:  return 1.0
            case .custom:
                if let w = Double(wCustom), let h = Double(hCustom), w > 0, h > 0 {
                    return max(CGFloat(w/h), 0.0001)
                }
                let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
                let r = portrait.width / portrait.height
                return max(r, 1.0)
            }
        }

        let a = landscapeAspect()

        switch resolution {
        case .native:
            // Force portrait for native phone resolution as requested
            let w = min(native.width, native.height)
            let h = max(native.width, native.height)
            return CGSize(width: round(w * oversample), height: round(h * oversample))
        case .p1080:
            let base = CGFloat(1080)
            if aspect == .device {
                // If device aspect requested with 1080, keep portrait and scale proportionally
                let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
                let r = portrait.width / portrait.height
                let w = base
                let h = round(base / max(r, 0.0001))
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            }
            if orientation == .landscape {
                let h = base
                let w = round(h * a)
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            } else {
                let w = base
                let h = round(w / max(a, 0.0001))
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            }
        case .p4k:
            let base = CGFloat(2160)
            if aspect == .device {
                let portrait = CGSize(width: min(native.width, native.height), height: max(native.width, native.height))
                let r = portrait.width / portrait.height
                let w = base
                let h = round(w / max(r, 0.0001))
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            }
            if orientation == .landscape {
                let h = base
                let w = round(h * a)
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            } else {
                let w = base
                let h = round(w / max(a, 0.0001))
                return CGSize(width: round(w * oversample), height: round(h * oversample))
            }
        }
    }

    @StateObject private var loc = LocationManager()
    @State private var sharedCamera: MapCamera? = nil

    // Map interaction
    @State private var mapPos: MapCameraPosition = .automatic
    @State private var crosshairCenter: CLLocationCoordinate2D? = nil

    // Points & camera pose capture
    struct CamPose { var distance: CLLocationDistance; var pitch: CGFloat; var heading: CLLocationDirection }

    @State private var currentPose = CamPose(distance: 900, pitch: 45, heading: 0)
    @State private var pointA: CLLocationCoordinate2D? = nil
    @State private var pointB: CLLocationCoordinate2D? = nil
    @State private var poseA: CamPose? = nil
    @State private var poseB: CamPose? = nil


    // Options
    @State private var seconds: Int = 4
    @State private var fps: Int = 60       // up to 120
    @State private var bitrate: Int = 20

    enum FrameCountMode: String, CaseIterable, Identifiable {
        case duration
        case fixedFrames
        var id: String { rawValue }
    }
    @State private var frameCountMode: FrameCountMode = .duration
    @State private var fixedFrameCount: Int = 300

    enum ResolutionOption: String, CaseIterable, Identifiable { case native, p1080, p4k; var id: String { rawValue } }
    @State private var resolution: ResolutionOption = .native
    enum AspectOption: String, CaseIterable, Identifiable { case device, r16x9, r4x3, r1x1, custom; var id: String { rawValue } }
    @State private var aspect: AspectOption = .device

    enum OrientationOption: String, CaseIterable, Identifiable { case portrait, landscape; var id: String { rawValue } }
    @State private var orientation: OrientationOption = .portrait

    @State private var wCustom: String = ""   // pixels
    @State private var hCustom: String = ""
    @State private var oversample: Double = 1.0      // sur-échantillonnage (1.0…5.0)

    // Stub states for new top menu sections
    @State private var imageFormat: String = "png"
    @State private var imageQuality: Double = 0.9 // 0.6...1.0 for JPEG/HEIC
    @State private var pngCompressionLevel: Int = 6

    @State private var videoFormat: String = "hevc8"

    enum ImageFormat: String, CaseIterable, Identifiable { case png, jpeg, heic, tiff; var id: String { rawValue } }
    enum VideoFormat: String, CaseIterable, Identifiable { case hevc8, hevc10, h264, proRes422, proRes422HQ, prores4444, uncompressedSequence; var id: String { rawValue } }

    // Existing state for mapping enum types (keep for internal logic)
    @State private var videoFormatEnum: VideoFormat = .h264
    @State private var imageFormatEnum: ImageFormat = .png

    @State private var renderProgress: Double = 0.0

    // Curve & follow
    @State private var splineEnabled = false
    @State private var splineCurvature: CGFloat = 0.25
    @State private var keepCentered = true

    // Trajet routier avec ligne bleue
    enum RouteTransportMode: String, CaseIterable, Identifiable {
        case automobile
        case walking
        case transit
        var id: String { rawValue }
    }
    @State private var useRoutePath: Bool = false
    @State private var routeMode: RouteTransportMode = .automobile
    @State private var routePolyline: MKPolyline? = nil
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var isComputingRoute: Bool = false
    @State private var routeTravelTime: TimeInterval? = nil       // secondes de trajet réel approx.
    @State private var routeDistance: CLLocationDistance? = nil    // mètres de trajet approx.

    // Simulation de circulation (feux, ralentissements)
    @State private var simulateTraffic: Bool = false
    @State private var showTrafficSettings: Bool = false
    @State private var trafficStopDensity: Double = 0.6    // 0 = quasi aucun arrêt, 1 = beaucoup
    @State private var trafficStopDuration: Double = 0.6   // 0 = arrêts courts, 1 = arrêts longs
    @State private var trafficSpeedJitter: Double = 0.4    // variations de vitesse

    private var routeModeLabel: String {
        switch routeMode {
        case .automobile: return L.car.lowercased()
        case .walking:    return L.walk.lowercased()
        case .transit:    return L.transit.lowercased()
        }
    }

    enum EasingPreset: String, CaseIterable, Identifiable { case linear, easeIn, easeOut, easeInOut, smoothstep, smootherstep, cubicBezier; var id: String { rawValue } }
    @State private var easing: EasingPreset = .easeInOut
    @State private var introPercent: Double = 0.1
    @State private var outroPercent: Double = 0.1
    @State private var bezierP1: CGPoint = CGPoint(x: 0.42, y: 0.0)
    @State private var bezierP2: CGPoint = CGPoint(x: 0.58, y: 1.0)

    // Preview
    @State private var showPreview = false
    @State private var previewPos: MapCameraPosition = .automatic
    @State private var previewProgress: CGFloat = 0
    @State private var playingPreview = false

    // State
    @State private var generating = false
    @State private var errorText: String? = nil
    @State private var savedOK = false

    // Output mode & cancellation
    enum OutputMode: String, CaseIterable, Identifiable { case preview, image, video, sequence; var id: String { rawValue } }
    @State private var outputMode: OutputMode = .video
    @State private var cancelRequested: Bool = false
    @State private var showHybridWarning: Bool = false
    @State private var showEasterEgg: Bool = false
    @State private var confettiPhase: Bool = false

    // Inserted new state properties as requested
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "system"
    
    // Réglages manette (persistants)
    @AppStorage("controllerPanSensitivity") private var controllerPanSensitivity: Double = 1.0
    @AppStorage("controllerTiltSensitivity") private var controllerTiltSensitivity: Double = 1.0
    @AppStorage("controllerDeadZone") private var controllerDeadZone: Double = 0.15
    
    @State private var showSettings: Bool = false
    @State private var isBootReady = false
    @State private var bootProgress: Double = 0.0

    // Added states for rendering overlay
    @State private var showRenderOverlay = false
    @State private var renderFinished = false

    // Map style & UX (no satellite)
    enum LiveMapStyle: String, CaseIterable, Identifiable {
        case standard
        case muted
        case hybrid
        var id: String { rawValue }
    }
    @State private var liveStyle: LiveMapStyle = .standard
    @State private var showPOI: Bool = false
    @State private var hideRoadLabels: Bool = false
    @State private var pitchDeg: Double = 45

    // Keyboard focus
    @FocusState private var isTyping: Bool

    // Tracking export share
    @State private var lastTrackJSON: URL? = nil
    @State private var lastTrackCSV: URL? = nil

    @State private var lastOutputFolder: URL? = nil

#if targetEnvironment(macCatalyst)
    @AppStorage("memBudgetGB") private var memBudgetGB: Double = 4.0
    @State private var useMaxMemory: Bool = false
    private var physicalMemoryGB: Double { Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0 }
#endif

    // Preset export/import
    @State private var presetToShareURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showImporter: Bool = false

    // Fichier .cxk généré pour Cap Playground
    @State private var capPlaygroundFileURL: URL? = nil

    // MARK: Game Controller Wiring
    @State private var leftX: Float = 0
    @State private var leftY: Float = 0
    @State private var rightX: Float = 0
    @State private var rightY: Float = 0

    // Game controller button states
    @State private var rotateLeftHeld: Bool = false
    @State private var rotateRightHeld: Bool = false
    @State private var zoomInHeld: Bool = false    // Triangle / Y
    @State private var zoomOutHeld: Bool = false   // Cross / A

    // Movement sensitivity & sprint
    @State private var moveSensitivity: Double = 0.0003 // reduced base sensitivity
    @State private var sprintMultiplier: Double = 2.0
    @State private var isSprintingToggled: Bool = false // toggled sprint (double-press)
    @State private var isSprintHeld: Bool = false       // momentary sprint while holding stick press
    @State private var lastLeftStickPressTime: CFTimeInterval = 0
    @State private var leftStickPressCount: Int = 0

    // Inserted new state
    @State private var leftStickHoldTime: Double = 0

    @State private var controllerConnected: Bool = false

    @State private var controllerNotificationsInstalled = false
    @State private var displayLink: CADisplayLink? { didSet { oldValue?.invalidate() } }

    // Address search state
    @State private var searchQuery: String = ""
    @State private var isSearchingAddress: Bool = false

    // Render progress state
    @State private var progressLabel: String = ""

    @MainActor private func startListeningForControllers() {
        guard !controllerNotificationsInstalled else { return }
        controllerNotificationsInstalled = true
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in
            Task { @MainActor in
                self.controllerConnected = true
                // Rebind deterministically without capturing a non-Sendable Notification/GCController
                for c in GCController.controllers() {
                    self.bindController(c)
                }
            }
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { _ in
            Task { @MainActor in
                // Reflect actual connection state after a disconnect event
                self.controllerConnected = !GCController.controllers().isEmpty
            }
        }
        GCController.startWirelessControllerDiscovery(completionHandler: nil)
        // Bind existing controllers if any
        for c in GCController.controllers() { bindController(c) }
    }

    @MainActor private func bindController(_ controller: GCController) {
        controllerConnected = true

        if let gamepad = controller.extendedGamepad {
            // Left stick → move (typed closure)
            gamepad.leftThumbstick.valueChangedHandler = { (pad: GCControllerDirectionPad, x: Float, y: Float) in
                Task { @MainActor in
                    self.leftX = x
                    self.leftY = y
                }
            }

            // L1 / R1 → rotate while held
            gamepad.leftShoulder.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.rotateLeftHeld = pressed }
            }
            gamepad.rightShoulder.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.rotateRightHeld = pressed }
            }

            // Triggers remapped: L2 = zoom in, R2 = zoom out (hold)
            gamepad.leftTrigger.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.zoomInHeld = pressed }
            }
            gamepad.rightTrigger.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.zoomOutHeld = pressed }
            }

            // Button A (X) now sets A, Triangle (Y) sets B on press down
            gamepad.buttonA.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                if pressed { Task { @MainActor in self.setA() } }
            }
            gamepad.buttonY.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                if pressed { Task { @MainActor in self.setB() } }
            }

            // Right stick: horizontal = rotate (like L1/R1), vertical = pitch
            gamepad.rightThumbstick.valueChangedHandler = { (pad: GCControllerDirectionPad, x: Float, y: Float) in
                Task { @MainActor in
                    self.rightX = x
                    self.rightY = y
                }
            }

            // Left stick press: single hold = momentary sprint, double-press = toggle sprint
            gamepad.leftThumbstickButton?.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in
                    let now = CACurrentMediaTime()
                    if pressed {
                        isSprintHeld = true
                        // double-press detection within 0.35s
                        if now - lastLeftStickPressTime < 0.35 {
                            leftStickPressCount += 1
                        } else {
                            leftStickPressTimeReset()
                        }
                        lastLeftStickPressTime = now
                        if leftStickPressCount >= 2 {
                            isSprintingToggled.toggle()
                            leftStickPressCount = 0
                        }
                    } else {
                        isSprintHeld = false
                    }
                }
            }

        } else if let micro = controller.microGamepad {
            micro.allowsRotation = true

            // D-pad → move
            micro.dpad.valueChangedHandler = { (pad: GCControllerDirectionPad, x: Float, y: Float) in
                Task { @MainActor in
                    self.leftX = x
                    self.leftY = y
                }
            }

            // GCMicroGamepad exposes only A and X → map X = zoom+, A = zoom-
            micro.buttonX.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.zoomInHeld = pressed }
            }
            micro.buttonA.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in self.zoomOutHeld = pressed }
            }

            // Sprint on micro gamepad using A button (single hold = momentary, double-press = toggle)
            micro.buttonA.pressedChangedHandler = { (btn: GCControllerButtonInput, value: Float, pressed: Bool) in
                Task { @MainActor in
                    if pressed {
                        isSprintHeld = true
                        let now = CACurrentMediaTime()
                        if now - lastLeftStickPressTime < 0.35 {
                            leftStickPressCount += 1
                        } else {
                            leftStickPressTimeReset()
                        }
                        lastLeftStickPressTime = now
                        if leftStickPressCount >= 2 {
                            isSprintingToggled.toggle()
                            leftStickPressCount = 0
                        }
                    } else {
                        isSprintHeld = false
                    }
                }
            }
        }
    }

    @MainActor private func startControllerUpdateLoop() {
        displayLink?.invalidate()
        var lastTs: CFTimeInterval = CACurrentMediaTime()
        let link = CADisplayLink(target: DisplayLinkProxy {
            let now = CACurrentMediaTime()
            let dt = max(0, now - lastTs)
            lastTs = now
            DispatchQueue.main.async {
                applyControllerInput(dt: dt)
            }
        }, selector: #selector(DisplayLinkProxy.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    private class DisplayLinkProxy: NSObject {
        let block: () -> Void
        init(_ block: @escaping () -> Void) { self.block = block }
        @objc func tick() { block() }
    }

    @MainActor private func leftStickPressTimeReset() {
        leftStickPressCount = 1
    }

    @MainActor
    private func applyControllerInput(dt: Double) {
        // This function updates map position or camera based on controller input

        guard controllerConnected else { return }

        // Update hold time for left stick (used for acceleration)
        let leftMagnitude = sqrt(Double(leftX * leftX + leftY * leftY))
        // Utilise controllerDeadZone au lieu d'une valeur fixe
        if leftMagnitude > controllerDeadZone {
            leftStickHoldTime += dt
        } else {
            leftStickHoldTime = 0
        }

        // Adjust pitch with right stick vertical (up = increase, down = decrease)
        // Utilise controllerTiltSensitivity
        let pitchSpeed: Double = 60 * controllerTiltSensitivity // degrees per second
        if abs(rightY) > Float(controllerDeadZone) {
            pitchDeg = max(0, min(70, pitchDeg + Double(rightY) * pitchSpeed * dt))
        }

        // Rotate with L1/R1 while held, or with right stick horizontal
        // Utilise controllerPanSensitivity
        let rotationSpeed: Double = 90 * controllerPanSensitivity // deg per second
        if rotateLeftHeld { currentPose.heading -= rotationSpeed * dt }
        if rotateRightHeld { currentPose.heading += rotationSpeed * dt }
        // Right stick X adds analog rotation (deadzone)
        if abs(rightX) > Float(controllerDeadZone) {
            currentPose.heading += Double(rightX) * rotationSpeed * dt
        }
        // Normalize heading to [0, 360)
        while currentPose.heading < 0 { currentPose.heading += 360 }
        while currentPose.heading >= 360 { currentPose.heading -= 360 }

        // Zoom with Triangle (in) / Cross (out) while held
        let zoomRate: Double = 1.35
        if zoomInHeld {
            currentPose.distance = max(50, currentPose.distance * pow(1/zoomRate, dt))
        }
        if zoomOutHeld {
            currentPose.distance = min(100_000, currentPose.distance * pow(zoomRate, dt))
        }

        // Base sensitivity reduced; apply acceleration with hold time and sprint multipliers
        // Utilise controllerPanSensitivity pour les déplacements
        let baseSpeed = moveSensitivity * controllerPanSensitivity

        if abs(leftX) > Float(controllerDeadZone) || abs(leftY) > Float(controllerDeadZone) {
            let mag = max(0.0, min(1.0, sqrt(Double(leftX * leftX + leftY * leftY))))
            // Acceleration grows smoothly up to ~2x over 2 seconds of hold
            let accel = 1.0 + min(1.0, leftStickHoldTime / 2.0)
            // Sprint if toggled or held
            let sprint = (isSprintingToggled || isSprintHeld) ? sprintMultiplier : 1.0
            let speed = baseSpeed * mag * accel * sprint
            let dx = Double(leftX) * speed
            let dy = Double(leftY) * speed
            let headingRad = currentPose.heading * .pi / 180.0
            let worldX = dx * cos(headingRad) + dy * sin(headingRad)
            let worldY = -dx * sin(headingRad) + dy * cos(headingRad)

            if var center = crosshairCenter {
                center.latitude += worldY
                center.longitude += worldX
                crosshairCenter = center
                let cam = MapCamera(centerCoordinate: center, distance: currentPose.distance, heading: currentPose.heading, pitch: CGFloat(pitchDeg))
                mapPos = .camera(cam)
            }
        }
        // If only rotating/zooming, still push camera update
        if let center = crosshairCenter {
            let cam = MapCamera(centerCoordinate: center, distance: currentPose.distance, heading: currentPose.heading, pitch: CGFloat(pitchDeg))
            mapPos = .camera(cam)
        }
    }

    // MARK: - Haptics helpers
    private func hapticButtonTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }

    private func hapticSliderChange() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    @MainActor
    private func triggerEasterEgg() {
        showEasterEgg = true
        confettiPhase = false

        // Démarre une simple animation de chute de confettis
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.2)) {
                confettiPhase = true
            }
        }

        // Masque automatiquement après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showEasterEgg = false
                confettiPhase = false
            }
        }
    }

    @MainActor
    private func recomputeRouteIfNeeded() {
        guard useRoutePath, let a = pointA, let b = pointB else {
            routePolyline = nil
            routeCoordinates = []
            return
        }

        isComputingRoute = true

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: a))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: b))
        switch routeMode {
        case .automobile:
            request.transportType = .automobile
        case .walking:
            request.transportType = .walking
        case .transit:
            request.transportType = .transit
        }

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isComputingRoute = false
                if let route = response?.routes.first {
                    self.routePolyline = route.polyline
                    var coords = [CLLocationCoordinate2D](
                        repeating: CLLocationCoordinate2D(),
                        count: route.polyline.pointCount
                    )
                    route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: route.polyline.pointCount))
                    self.routeCoordinates = coords
                    // Temps et distance réels pour affichage (approximation "vrai trajet")
                    self.routeTravelTime = route.expectedTravelTime
                    self.routeDistance = route.distance

                    // Added: Align live map heading with route start direction
                    if self.useRoutePath, self.routeCoordinates.count > 1 {
                        let p0 = self.routeCoordinates[0]
                        let p1 = self.routeCoordinates[1]
                        let dy = p1.latitude - p0.latitude
                        let dx = p1.longitude - p0.longitude
                        let heading = CLLocationDirection(atan2(dx, dy) * 180.0 / .pi)
                        let cam = MapCamera(
                            centerCoordinate: p0,
                            distance: self.currentPose.distance,
                            heading: heading,
                            pitch: CGFloat(self.pitchDeg)
                        )
                        self.mapPos = .camera(cam)
                    }
                } else {
                    self.routePolyline = nil
                    self.routeCoordinates = []
                    self.routeTravelTime = nil
                    self.routeDistance = nil
                    if let error = error {
                        self.errorText = "\(self.L.routeError): \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    @MainActor
    private func searchAddress() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearchingAddress = true
        defer { isSearchingAddress = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let center = crosshairCenter {
            request.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        }
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            if let item = response.mapItems.first {
                let coord = item.placemark.coordinate
                crosshairCenter = coord
                let cam = MapCamera(centerCoordinate: coord, distance: max(200, currentPose.distance), heading: currentPose.heading, pitch: CGFloat(pitchDeg))
                mapPos = .camera(cam)
            } else {
                errorText = L.addressNotFound
            }
        } catch {
            errorText = "\(L.searchError): \(error.localizedDescription)"
        }
    }

    // MARK: - Controls View Helper
    private var controlsView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                GlassSection(title: L.pointsAndTrajectory, icon: "location") {
                    pointsSection
                    cameraPathSection
                    durationAndTimingSection
                }

                GlassSection(title: L.map, icon: "map") {
                    Picker(L.style, selection: $liveStyle) {
                        Text(L.standard).tag(LiveMapStyle.standard)
                        Text(L.muted).tag(LiveMapStyle.muted)
                        Text(L.hybrid).tag(LiveMapStyle.hybrid)
                    }
                        .pickerStyle(.segmented)
                        .disabled(generating)

                    Toggle(L.pointsOfInterest, isOn: $showPOI)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                                TextField(L.searchAddress, text: $searchQuery)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .onSubmit {
                                        Task { await searchAddress() }
                                    }
                                    .onChange(of: searchQuery) { _, newValue in
                                        let lowered = newValue.lowercased()
                                        if lowered.contains("klavair"), !showEasterEgg {
                                            triggerEasterEgg()
                                        }
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2)))

                            Button {
                                hapticButtonTap()
                                Task { await searchAddress() }
                            } label: {
                                if isSearchingAddress {
                                    ProgressView().padding(.horizontal, 6)
                                } else {
                                    Image(systemName: "arrow.forward.circle.fill").font(.title3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Text(L.searchHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Text(L.lightModeHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassSection(title: L.resolutionAndImages, icon: "slider.horizontal.3") {
                    resolutionFormatSection
                    videoSection
                }

                GlassSection(title: L.preview, icon: "play.rectangle") {
                    previewGlassContent
                }

                GlassSection(title: L.quickActions, icon: "square.grid.2x2") {
                    mainActionButtonsBody

                    Divider().padding(.vertical, 4)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                        spacing: 12
                    ) {
                        Button {
                            hapticButtonTap()
                            Task { await exportTrackingData() }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                    .font(.title3)
                                Text(L.exportTracking)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button {
                            hapticButtonTap()
                            exportCurrentPreset()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .font(.title3)
                                Text(L.exportPreset)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button {
                            hapticButtonTap()
                            showImporter = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down.on.square")
                                    .font(.title3)
                                Text(L.importPreset)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }

                GlassSection(title: L.settings, icon: "gearshape") {
                    Button {
                        hapticButtonTap()
                        showSettings = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                            Text(L.openSettings)
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    var body: some View {
        mainLayout
            .tint(.blue)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L.ok) {
                        hideKeyboard()
                        isTyping = false
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if savedOK || errorText != nil {
                    Group {
                        if let error = errorText {
                            GlassToast(kind: .error, message: error)
                        } else if savedOK {
                            GlassToast(kind: .success, message: L.savedToPhotos)
                        }
                    }
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: savedOK)
                    .animation(.easeInOut(duration: 0.3), value: errorText)
                }
            }
            // Écran noir plein écran pour le rendu
            .overlay {
                renderingOverlay
            }
            // Écran d'accueil (onboarding) affiché uniquement au premier démarrage
            .overlay {
                if !hasSeenOnboarding {
                    onboardingOverlay
                }
            }
            // Easter egg toujours dispo au-dessus
            .overlay {
                if showEasterEgg {
                    easterEggOverlay
                }
            }
            // Écran de chargement au lancement (après l'intro)
            .overlay {
                if hasSeenOnboarding {
                    bootOverlay
                }
            }
            .sheet(isPresented: $showImporter) {
                DocumentPicker(onPick: { url in
                    if let u = url { importPreset(from: u) }
                    showImporter = false
                })
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { presetToShareURL = nil }) {
                if let url = presetToShareURL {
                    ShareView(url: url)
                }
            }
            .sheet(isPresented: $showTrafficSettings) {
                trafficSettingsSheet
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .alert(L.experimentalHybridMode, isPresented: $showHybridWarning) {
                Button(L.ok, role: .cancel) { }
            } message: {
                Text(L.hybridModeWarning)
            }
            .onAppear {
                if !oversampleOptions().contains(oversample) {
                    oversample = oversampleOptions().last ?? 1.0
                }
                startListeningForControllers()
                startControllerUpdateLoop()
                // Initialize stub states to reflect the saved enums
                imageFormat = imageFormatEnum.rawValue
                videoFormat = videoFormatEnum.rawValue
            }
    }

    // MARK: - Settings Sheet
    private var settingsSheet: some View {
        NavigationView {
            Form {
                Section(header: Text(L.language)) {
                    Picker(L.language, selection: $preferredLanguage) {
                        Text(L.system).tag("system")
                        Text(L.french).tag("fr")
                        Text(L.english).tag("en")
                    }
                    .pickerStyle(.segmented)
                    Text(L.languageNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section(header: Text(L.controllerSettings)) {
                    HStack {
                        Text(L.panSensitivity)
                        Slider(value: $controllerPanSensitivity, in: 0.1...2.0, step: 0.01)
                        Text(String(format: "%.2f", controllerPanSensitivity))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(L.tiltSensitivity)
                        Slider(value: $controllerTiltSensitivity, in: 0.1...2.0, step: 0.01)
                        Text(String(format: "%.2f", controllerTiltSensitivity))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(L.deadZone)
                        Slider(value: $controllerDeadZone, in: 0.05...0.4, step: 0.01)
                        Text(String(format: "%.2f", controllerDeadZone))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(L.controllerNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section(header: Text(L.networksAndGitHub)) {
                    // GitHub
                    Link(destination: URL(string: "https://github.com/0klavair/klamap")!) {
                        Label("GitHub", systemImage: "chevron.left.slash.chevron.right")
                    }
                    // Instagram
                    Link(destination: URL(string: "https://www.instagram.com/0klavair/")!) {
                        Label("Instagram", systemImage: "camera")
                    }
                    // Discord
                    Link(destination: URL(string: "https://discord.gg/xvA5rAc5eU")!) {
                        Label("Discord", systemImage: "bubble.left.and.bubble.right")
                    }
                }
            }
            .navigationTitle(L.settings)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.close) {
                        showSettings = false
                    }
                }
            }
        }
    }

    // MARK: - Preview Glass Content Helper
    private var previewGlassContent: some View {
        let metrics = exportPreviewMetrics()
        let screenWidth = UIScreen.main.bounds.width
        let isPhoneLandscape = UIDevice.current.userInterfaceIdiom == .phone
            && UIScreen.main.bounds.width > UIScreen.main.bounds.height

        // Aperçu large mais pas plein écran, qui respecte seulement l'aspect
        let targetWidth: CGFloat
        if isPhoneLandscape {
            // En paysage iPhone : aperçu plus compact pour ne pas faire grossir tout le menu
            targetWidth = min(screenWidth * 0.45, 260)
        } else {
            targetWidth = min(screenWidth * 0.8, 360)
        }
        let targetHeight = targetWidth / max(metrics.aspect, 0.01)

        return VStack(spacing: 12) {
            HStack {
                Spacer()
                ZStack(alignment: .bottomLeading) {
                    Map(position: $previewPos) {
                        if useRoutePath, let poly = routePolyline {
                            MapPolyline(poly)
                                .stroke(.blue, lineWidth: 3)
                        }
                    }
                    .mapStyle(hideRoadLabels ? ( (pitchDeg > 1) ? .standard(elevation: .realistic, emphasis: .muted) : .standard(elevation: .flat, emphasis: .muted) ) : mapStyleForLive(liveStyle))
                    .frame(width: targetWidth, height: targetHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.2))
                    )
                    .onAppear {
                        let center = pointA ?? crosshairCenter ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
                        let cam = MapCamera(centerCoordinate: center,
                                            distance: currentPose.distance,
                                            heading: currentPose.heading,
                                            pitch: CGFloat(pitchDeg))
                        previewPos = .camera(cam)
                    }
                    .onChange(of: resolution) { _, _ in applyPreview(previewProgress) }
                    .onChange(of: aspect) { _, _ in applyPreview(previewProgress) }
                    .onChange(of: wCustom) { _, _ in applyPreview(previewProgress) }
                    .onChange(of: hCustom) { _, _ in applyPreview(previewProgress) }
                    .onChange(of: orientation) { _, _ in applyPreview(previewProgress) }
                    .overlay(alignment: .topLeading) {
                        let px = exportPixelSize()
                        Text("\(Int(px.width))×\(Int(px.height))")
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .padding(8)
                    }
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    hapticButtonTap()
                    playingPreview.toggle()
                    if playingPreview {
                        Task { await runPreview() }
                    }
                } label: {
                    Image(systemName: playingPreview ? "pause.fill" : "play.fill")
                        .font(.body)
                }
                .buttonStyle(GlassButtonStyle())
                .frame(width: 44)

                Slider(value: $previewProgress, in: 0...1)
                    .onChange(of: previewProgress) { _, t in
                        applyPreview(CGFloat(t))
                    }

                Text("\(Int(previewProgress * 100))%")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var mainLayout: some View {
        GeometryReader { proxy in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let isPhone = UIDevice.current.userInterfaceIdiom == .phone
            let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height

            Group {
                if isPad && isLandscape {
                    // iPad paysage : layout d'origine (message-3.txt)
                    HStack(spacing: 0) {
                        controlsView
                            .frame(width: max(proxy.size.width * 0.4, 320))

                        VStack(spacing: 0) {
                            mapPicker
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if isPad && !isLandscape {
                    // iPad portrait : carte large en haut, réglages en dessous
                    VStack(spacing: 0) {
                        mapPicker
                            .frame(height: max(320, proxy.size.height * 0.55))

                        controlsView
                    }
                } else if isPhone && isLandscape {
                    // iPhone paysage : menu / carte en 55/45 (map ≤ 45%)
                    HStack(spacing: 0) {
                        controlsView
                            .frame(width: proxy.size.width * 0.50)

                        Divider()

                        mapPicker
                            .frame(width: proxy.size.width * 0.50,
                                   height: proxy.size.height)
                    }
                } else {
                    // iPhone portrait : la carte ne dépasse pas 45% de la hauteur
                    VStack(spacing: 0) {
                        mapPicker
                            .frame(height: proxy.size.height * 0.40)

                        controlsView
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }

    private var pointsSection: some View {
        Section(L.points) {
            HStack(spacing: 12) {
                Button { setA() } label: {
                    Label(L.setA, systemImage: "a.circle")
                        .font(.body)
                        .contentShape(Rectangle())
                }
                .buttonStyle(GlassButtonStyle())

                Button { setB() } label: {
                    Label(L.setB, systemImage: "b.circle")
                        .font(.body)
                        .contentShape(Rectangle())
                }
                .buttonStyle(GlassButtonStyle())
            }

            if let a = pointA, let b = pointB {
                Text(String(format: "A: %.4f, %.4f  •  B: %.4f, %.4f", a.latitude, a.longitude, b.latitude, b.longitude))
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text(L.moveMapInstruction)
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Text(L.controllerCompatibility)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var durationAndTimingSection: some View {
        Section(L.durationAndTiming) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L.duration)
                    Spacer()
                    TextField(
                        L.seconds,
                        text: Binding<String>(
                            get: { String(seconds) },
                            set: { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if let value = Int(filtered), value >= 0 {
                                    seconds = value
                                } else {
                                    seconds = 0
                                }
                            }
                        )
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
                    .textFieldStyle(.roundedBorder)

                    Text("s")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.85))
                        )
                }

                let total = Double(max(seconds, 0))
                let days = Int(total / 86_400)
                let hours = Int(total.truncatingRemainder(dividingBy: 86_400) / 3_600)
                let minutes = Int(total.truncatingRemainder(dividingBy: 3_600) / 60)
                let secs = Int(total.truncatingRemainder(dividingBy: 60))

                if total > 0 {
                    Text("≈ \(days)d \(hours)h \(minutes)min \(secs)s")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(L.durationHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Toggle(L.trafficMode, isOn: $simulateTraffic)

            Button(L.advancedSettings) {
                hapticButtonTap(style: .medium)
                showTrafficSettings = true
            }
            .disabled(!simulateTraffic)
            .buttonStyle(.bordered)
            .font(.footnote)

            if let travel = routeTravelTime, useRoutePath {
                // Affichage temps réel approx. (comme dans un vrai trajet)
                let minutes = Int(round(travel / 60.0))
                let km = (routeDistance ?? 0) / 1000.0
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: L.approximateTrip,
                                minutes,
                                routeModeLabel))
                    if km > 0 {
                        Text(String(format: L.distance, km))
                    }
                    Text(L.animationDurationNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Group {
                Text(L.timing).font(.headline)
                Picker(L.curve, selection: $easing) {
                    Text(L.linear).tag(EasingPreset.linear)
                    Text(L.easeIn).tag(EasingPreset.easeIn)
                    Text(L.easeOut).tag(EasingPreset.easeOut)
                    Text(L.easeInOut).tag(EasingPreset.easeInOut)
                    Text(L.smoothstep).tag(EasingPreset.smoothstep)
                    Text(L.smootherstep).tag(EasingPreset.smootherstep)
                    Text(L.cubicBezier).tag(EasingPreset.cubicBezier)
                }.pickerStyle(.menu)
                HStack {
                    VStack(alignment: .leading) {
                        Text(L.intro)
                        HStack { Spacer(); Text("\(Int(introPercent*100))%").foregroundStyle(.secondary) }
                        Slider(value: $introPercent, in: 0...0.4, step: 0.01)
                    }
                    VStack(alignment: .leading) {
                        Text(L.outro)
                        HStack { Spacer(); Text("\(Int(outroPercent*100))%").foregroundStyle(.secondary) }
                        Slider(value: $outroPercent, in: 0...0.4, step: 0.01)
                    }
                }
                .onChange(of: introPercent) { _, _ in
                    if introPercent + outroPercent > 0.8 { outroPercent = max(0, 0.8 - introPercent) }
                    hapticSliderChange()
                }
                .onChange(of: outroPercent) { _, _ in
                    if introPercent + outroPercent > 0.8 { introPercent = max(0, 0.8 - outroPercent) }
                    hapticSliderChange()
                }
                if easing == .cubicBezier {
                    VStack(alignment: .leading) {
                        HStack { Text("P1 x"); Slider(value: Binding(get: { bezierP1.x }, set: { bezierP1.x = max(0, min(1, $0)) }), in: 0...1) }
                        HStack { Text("P1 y"); Slider(value: Binding(get: { bezierP1.y }, set: { bezierP1.y = max(0, min(1, $0)) }), in: 0...1) }
                        HStack { Text("P2 x"); Slider(value: Binding(get: { bezierP2.x }, set: { bezierP2.x = max(0, min(1, $0)) }), in: 0...1) }
                        HStack { Text("P2 y"); Slider(value: Binding(get: { bezierP2.y }, set: { bezierP2.y = max(0, min(1, $0)) }), in: 0...1) }
                    }
                    .onChange(of: bezierP1) { _, _ in hapticSliderChange() }
                    .onChange(of: bezierP2) { _, _ in hapticSliderChange() }
                }
            }
        }
    }

    private var cameraPathSection: some View {
        Section(L.cameraAndTracking) {
            VStack(alignment: .leading) {
                HStack {
                    Text(L.viewAngle)
                    Spacer()
                    Text("\(Int(pitchDeg))°")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $pitchDeg, in: 0...70, step: 1)
                    .onChange(of: pitchDeg) { _, _ in
                        hapticSliderChange()
                    }
            }

            Toggle(L.keepCentered, isOn: $keepCentered)
            Toggle(L.curvedPath, isOn: $splineEnabled)

            if splineEnabled {
                HStack {
                    Text(L.curvature)
                    Slider(value: $splineCurvature, in: 0.05...0.6)
                        .onChange(of: splineCurvature) { _, _ in
                            hapticSliderChange()
                        }
                }
            }

            Toggle(L.followRealRoute, isOn: $useRoutePath)
                .onChange(of: useRoutePath) { _, newVal in
                    if newVal {
                        // Vue type CarPlay : caméra basse et centrée sur la route
                        pitchDeg = 70
                        keepCentered = true
                        recomputeRouteIfNeeded()
                    } else {
                        routePolyline = nil
                        routeCoordinates = []
                    }
                }

            if useRoutePath {
                Picker(L.transport, selection: $routeMode) {
                    Text(L.car).tag(RouteTransportMode.automobile)
                    Text(L.walk).tag(RouteTransportMode.walking)
                    Text(L.transit).tag(RouteTransportMode.transit)
                }
                .pickerStyle(.segmented)

                if isComputingRoute {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(L.computingRoute)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Note sur la carte claire / sombre
                Text(L.lightMapNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private var resolutionFormatSection: some View {
        Section(L.resolutionAndImages) {
            Picker(L.resolution, selection: $resolution) {
                Text(L.native).tag(ResolutionOption.native)
                Text("1080p").tag(ResolutionOption.p1080)
                Text("4K").tag(ResolutionOption.p4k)
            }
            .pickerStyle(.segmented)
            .onChange(of: resolution) { _, _ in hideKeyboard() }

            Picker(L.aspect, selection: $aspect) {
                Text(L.device).tag(AspectOption.device)
                Text("16:9").tag(AspectOption.r16x9)
                Text("4:3").tag(AspectOption.r4x3)
                Text("1:1").tag(AspectOption.r1x1)
                Text(L.custom).tag(AspectOption.custom)
            }
            .pickerStyle(.segmented)
            .onChange(of: aspect) { _, _ in hideKeyboard() }

            if aspect == .custom {
                HStack {
                    TextField(L.width, text: $wCustom).keyboardType(.numberPad).focused($isTyping)
                    Text("×")
                    TextField(L.height, text: $hCustom).keyboardType(.numberPad).focused($isTyping)
                }
            }

            Picker(L.orientation, selection: $orientation) {
                Text(L.portrait).tag(OrientationOption.portrait)
                Text(L.landscape).tag(OrientationOption.landscape)
            }
            .pickerStyle(.segmented)
            .disabled(aspect == .device)

            VStack(alignment: .leading) {
                HStack {
                    Text(L.oversampling)
                    Spacer()
                    Text("x\(oversample, specifier: "%.2g")")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Slider(value: $oversample, in: 1.0...5.0, step: 0.25)
                    .onChange(of: oversample) { _, _ in hapticSliderChange() }
                Text(L.oversamplingDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Picker(L.imageFormat, selection: $imageFormatEnum) {
                Text("PNG").tag(ImageFormat.png)
                Text("JPEG").tag(ImageFormat.jpeg)
                Text("HEIC").tag(ImageFormat.heic)
                Text("TIFF").tag(ImageFormat.tiff)
            }
            .pickerStyle(.menu)

            if imageFormatEnum == .png {
                VStack(alignment: .leading) {
                    Text("PNG")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(L.compression)
                        Spacer()
                        Text("\(pngCompressionLevel)")
                            .font(.caption.monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Slider(value: Binding(get: { Double(pngCompressionLevel) }, set: { pngCompressionLevel = Int($0.rounded()) }), in: 0...9, step: 1)
                        .onChange(of: pngCompressionLevel) { _, _ in hapticSliderChange() }
                    Text("\(L.noCompression), \(L.maxCompression)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if imageFormatEnum == .jpeg || imageFormatEnum == .heic {
                VStack(alignment: .leading) {
                    HStack { Text(L.quality); Spacer(); Text("\(Int(imageQuality * 100))%") .foregroundStyle(.secondary) }
                    Slider(value: $imageQuality, in: 0.6...1.0, step: 0.05)
                        .onChange(of: imageQuality) { _, _ in hapticSliderChange() }
                    Text(L.lossyCompression).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var videoSection: some View {
        Section(L.video) {
            Picker(L.videoFormat, selection: $videoFormatEnum) {
                Text("H.264 (MP4)").tag(VideoFormat.h264)
                Text("HEVC 8-bit (MOV)").tag(VideoFormat.hevc8)
                Text("HEVC 10-bit (MOV)").tag(VideoFormat.hevc10)
                Text("ProRes 422 (MOV)").tag(VideoFormat.proRes422)
                Text("ProRes 422 HQ (MOV)").tag(VideoFormat.proRes422HQ)
                Text("ProRes 4444 (MOV)").tag(VideoFormat.prores4444)
                Text(L.pngSequence).tag(VideoFormat.uncompressedSequence)
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading) {
                HStack {
                    Text("FPS")
                    Spacer()
                    Text("\(fps)")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Slider(value: Binding(get: { Double(fps) }, set: { fps = Int($0.rounded()) }), in: 1...120, step: 1)
                    .onChange(of: fps) { _, _ in hapticSliderChange() }
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(L.bitrate)
                    Spacer()
                    Text("\(bitrate) Mb/s")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Slider(value: Binding(get: { Double(bitrate) }, set: { bitrate = Int($0.rounded()) }), in: 5...80, step: 1)
                    .onChange(of: bitrate) { _, _ in hapticSliderChange() }
            }

            Picker(L.frames, selection: $frameCountMode) {
                Text("\(L.duration) × FPS").tag(FrameCountMode.duration)
                Text(L.fixedNumber).tag(FrameCountMode.fixedFrames)
            }
            .pickerStyle(.segmented)

            if frameCountMode == .fixedFrames {
                Stepper(value: $fixedFrameCount, in: 1...2000) {
                    Text("\(L.frameCount)\(fixedFrameCount)")
                }
                Text(L.frameCountDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func setA() {
        if let c = crosshairCenter {
            pointA = c
            poseA = currentPose
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if useRoutePath {
                recomputeRouteIfNeeded()
            }
        }
    }
    private func setB() {
        if let c = crosshairCenter {
            pointB = c
            poseB = currentPose
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if useRoutePath {
                recomputeRouteIfNeeded()
            }
        }
    }

    // Crosshair au centre de la carte principale
    private var crosshair: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                .frame(width: 18, height: 18)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 4, height: 4)
        }
    }

    private var mapPicker: some View {
        ZStack(alignment: .center) {
            let start = MapCamera(
                centerCoordinate: loc.location?.coordinate
                    ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
                distance: 900,
                heading: 0,
                pitch: 45
            )

            Map(position: $mapPos) {
                if let a = pointA {
                    Annotation("A", coordinate: a) { pin("A") }
                }
                if let b = pointB {
                    Annotation("B", coordinate: b) { pin("B") }
                }
                if useRoutePath, let poly = routePolyline {
                    MapPolyline(poly)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .mapStyle(
                hideRoadLabels
                ? (
                    (pitchDeg > 1)
                    ? .standard(elevation: .realistic, emphasis: .muted)
                    : .standard(elevation: .flat, emphasis: .muted)
                )
                : mapStyleForLive(liveStyle)
            )
            .id(liveMapIdentity)
            .onAppear {
                // Ne réinitialise la caméra qu'une seule fois, au tout premier affichage.
                if case .automatic = mapPos {
                    mapPos = .camera(start)
                }
            }
            .onMapCameraChange { ctx in
                crosshairCenter = ctx.region.center
                let cam = ctx.camera
                currentPose = CamPose(
                    distance: cam.distance,
                    pitch: cam.pitch,
                    heading: cam.heading
                )
                sharedCamera = ctx.camera
            }
            .onChange(of: liveStyle) { _, newVal in
                let center = crosshairCenter
                    ?? loc.location?.coordinate
                    ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
                let cam = MapCamera(
                    centerCoordinate: center,
                    distance: currentPose.distance,
                    heading: currentPose.heading,
                    pitch: CGFloat(pitchDeg)
                )
                mapPos = .camera(cam)
                if newVal == .hybrid {
                    showHybridWarning = true
                }
            }
            .onChange(of: pitchDeg) { _, newVal in
                let center = crosshairCenter
                    ?? loc.location?.coordinate
                    ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
                let cam = MapCamera(
                    centerCoordinate: center,
                    distance: currentPose.distance,
                    heading: currentPose.heading,
                    pitch: CGFloat(newVal)
                )
                mapPos = .camera(cam)
            }

            crosshair
        }
    }

    private func pin(_ t: String) -> some View {
        ZStack {
            Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34)
            Text(t).font(.headline)
        }
    }

    // Écran noir de rendu (utilisé pendant les exports) - VERSION CORRIGÉE
    @ViewBuilder
    fileprivate var renderingOverlay: some View {
        if showRenderOverlay {
            GeometryReader { geo in
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        if !renderFinished && errorText == nil {
                            VStack(spacing: 12) {
                                Text(progressLabel.isEmpty ? L.preparing : progressLabel)
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.white)

                                Button {
                                    hapticButtonTap(style: .medium)
                                    cancelRequested = true
                                    progressLabel = L.cancelling
                                } label: {
                                    Text(L.cancelRender)
                                        .font(.body)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }

                        } else if renderFinished && errorText == nil {
                            if outputMode == .sequence {
                                // Cas spécial : ZIP sequence (.zip)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 52))
                                    .foregroundColor(.green)

                                Text(L.exportZipComplete)
                                    .font(.headline)
                                    .foregroundColor(.green)

                                Text(L.yourZipFile)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                VStack(spacing: 12) {
                                    // 1) Enregistrer dans Fichiers (via la sheet de partage existante)
                                    Button {
                                        hapticButtonTap(style: .light)
                                        if let url = capPlaygroundFileURL {
                                            presetToShareURL = url
                                            showShareSheet = true
                                        }
                                    } label: {
                                        Text(L.saveToFiles)
                                            .font(.body)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(Color.blue.opacity(0.25))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }

                                    // 3) Retour au menu (fermer l'overlay)
                                    Button {
                                        hapticButtonTap(style: .light)
                                        showRenderOverlay = false
                                        renderFinished = false
                                        cancelRequested = false
                                        progressLabel = ""
                                    } label: {
                                        Text(L.backToMenu)
                                            .font(.body)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(Color.green.opacity(0.25))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            } else {
                                // Comportement générique pour les autres exports
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 52))
                                    .foregroundColor(.green)

                                Text(L.renderComplete)
                                    .font(.headline)
                                    .foregroundColor(.green)

                                HStack(spacing: 16) {
                                    Button {
                                        // Ouvrir l'app Photos
                                        #if canImport(UIKit)
                                        if let url = URL(string: "photos-redirect://") {
                                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                        }
                                        #endif
                                    } label: {
                                        Text(L.accessGallery)
                                            .font(.body)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(Color.green.opacity(0.25))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }

                                    Button {
                                        // Cacher l'overlay et revenir à l'app
                                        showRenderOverlay = false
                                        renderFinished = false
                                    } label: {
                                        Text(L.returnToApp)
                                            .font(.body)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.15))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        } else if errorText != nil {
                            // Erreur pendant le rendu
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)

                            Text(L.errorDuringRender)
                                .font(.headline)
                                .foregroundColor(.white)

                            Button {
                                showRenderOverlay = false
                                renderFinished = false
                            } label: {
                                Text(L.close)
                                    .font(.body)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: min(320, geo.size.width - 40))
                }
            }
        }
    }

    // Onboarding simple affiché au premier lancement
    @ViewBuilder
    fileprivate var onboardingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo de l'application
                AppIconView()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 8) {
                    Text(L.appName)
                        .font(.title)
                        .bold()
                    Text(L.appDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    Text(L.networksAndCode)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        if let url = URL(string: "https://github.com/0klavair/klamap") {
                            Link(destination: url) {
                                Label("GitHub", systemImage: "chevron.left.slash.chevron.right")
                            }
                        }
                        if let url = URL(string: "https://www.instagram.com/0klavair/") {
                            Link(destination: url) {
                                Label("Instagram", systemImage: "camera")
                            }
                        }
                        if let url = URL(string: "https://discord.gg/xvA5rAc5eU") {
                            Link(destination: url) {
                                Label("Discord", systemImage: "bubble.left.and.bubble.right")
                            }
                        }
                    }
                    .font(.footnote)
                }

                Button {
                    hapticButtonTap(style: .medium)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(L.accessApplication)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 40)
            }
        }
    }

    // Overlay pour l'easter egg "klavair"
    @ViewBuilder
    fileprivate var easterEggOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(L.howDidYouFindThis)
                    .font(.title2)
                    .bold()

                Text(L.easterEggExplanation)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                Button {
                    hapticButtonTap(style: .light)
                    withAnimation(.spring()) {
                        showEasterEgg = false
                    }
                } label: {
                    Text(L.close)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.horizontal, 40)
            }
        }
    }

    // Overlay de lancement (affiché au tout début)
    @ViewBuilder
    fileprivate var bootOverlay: some View {
        if isBootReady {
            EmptyView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    AppIconView()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Text(L.launching)
                        .font(.headline)

                    ProgressView(value: bootProgress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 200)
                }
            }
            .task {
                // Petite animation de démarrage très courte
                let steps = 12
                for step in 0...steps {
                    try? await Task.sleep(nanoseconds: 70_000_000) // ~0,07s par step
                    bootProgress = Double(step) / Double(steps)
                }
                isBootReady = true
            }
        }
    }

    // MARK: - Clean Export Engine (image, sequence, video)
    @ViewBuilder
    fileprivate var trafficSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(L.lightsAndStops) {
                    VStack(alignment: .leading) {
                        Text(L.stopDensity)
                        Slider(value: $trafficStopDensity, in:0...1)
                            .onChange(of: trafficStopDensity) { _, _ in hapticSliderChange() }
                    }
                    VStack(alignment: .leading) {
                        Text(L.stopDuration)
                        Slider(value: $trafficStopDuration, in: 0...1)
                            .onChange(of: trafficStopDuration) { _, _ in hapticSliderChange() }
                    }
                }

                Section(L.speedVariations) {
                    VStack(alignment: .leading) {
                        Text(L.variability)
                        Slider(value: $trafficSpeedJitter, in: 0...1)
                            .onChange(of: trafficSpeedJitter) { _, _ in hapticSliderChange() }
                    }
                    Text(L.variabilityNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L.advancedTraffic)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.close) {
                        hapticButtonTap(style: .medium)
                        showTrafficSettings = false
                    }
                }
            }
        }
    }


    @MainActor
    private func runPreview() async {
        // Lightweight preview playback: no rendering, no export state
        let rawTotal = max(1, seconds * fps)
        let total = min(rawTotal, 10_000)
        let step = 1.0 / Double(total)
        var t = Double(previewProgress)
        var frames = 0
        while playingPreview && frames < total {
            try? await Task.sleep(nanoseconds: 16_000_000) // ~60 FPS pacing
            t += step
            if t > 1.0 { t = 0.0 }
            previewProgress = CGFloat(t)
            applyPreview(CGFloat(t))
            frames += 1
        }
    }

    @MainActor
    private func makeBothWallpapers() async {
        await exportImageClean()
    }

    // Legacy wrappers gardés pour compatibilité avec les anciens boutons
    @MainActor
    private func makePathVideo() async {
        // Utilise le nouvel export vidéo
        await exportVideoClean()
    }

    @MainActor
    private func exportImageSequence() async {
        // Garde-fou : A et B requis
        guard pointA != nil && pointB != nil else {
            errorText = L.defineABBeforeSequence
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        generating = true
        showRenderOverlay = true
        renderFinished = false
        errorText = nil
        savedOK = false
        cancelRequested = false
        progressLabel = L.preparing

        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        defer {
            generating = false
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }

        // Paramètres figés: on reprend exactement la logique de l'export vidéo
        let px = exportPixelSize()
        let seconds_local = seconds
        let fps_local = max(1, fps)

        let totalFrames: Int
        switch frameCountMode {
        case .duration:
            // Même logique que la vidéo: durée × FPS
            totalFrames = max(1, seconds_local * fps_local)
        case .fixedFrames:
            // Mode nombre fixe d'images (par ex. 120, 240, etc.)
            totalFrames = max(1, fixedFrameCount)
        }

        guard totalFrames > 0 else {
            errorText = L.noFramesToGenerate
            showRenderOverlay = false
            return
        }

        let tmp = FileManager.default.temporaryDirectory
        let folderURL = tmp.appendingPathComponent("cxk-\(UUID().uuidString)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            errorText = "\(L.folderCreationError): \(error.localizedDescription)"
            showRenderOverlay = false
            return
        }

        // Nombre de chiffres pour le nommage : 001.png, 002.png, etc.
        let digits = max(3, String(totalFrames).count)

        for i in 0..<totalFrames {
            if cancelRequested {
                errorText = L.exportCancelled
                cancelRequested = false
                showRenderOverlay = false
                return
            }

            let t = CGFloat(i) / CGFloat(max(1, totalFrames - 1))
            progressLabel = String(format: "\(L.frame) %d / %d", i + 1, totalFrames)

            let cgOpt = await renderMapImage(size: px, t: t)

            guard let cg = cgOpt else {
                if cancelRequested {
                    errorText = L.exportCancelled
                    cancelRequested = false
                    showRenderOverlay = false
                    return
                }
                continue
            }

            let uiImage = UIImage(cgImage: cg)
            guard let data = uiImage.pngData() else {
                continue
            }

            let name = String(format: "%0*d.png", digits, i + 1)   // 001.png, 002.png…
            let fileURL = folderURL.appendingPathComponent(name)

            do {
                try data.write(to: fileURL)
            } catch {
                errorText = "\(L.imageWriteError) \(name): \(error.localizedDescription)"
                showRenderOverlay = false
                return
            }

            let p = Double(i + 1) / Double(totalFrames)
            renderProgress = p
            // On garde progressLabel comme texte descriptif (Image X / N)
        }

        // Création de l'archive ZIP
        #if canImport(ZIPFoundation)
        let zipURL = tmp.appendingPathComponent("sequence-\(UUID().uuidString).zip")
        do {
            try FileManager.default.zipItem(at: folderURL, to: zipURL, shouldKeepParent: false)
            presetToShareURL = zipURL
            capPlaygroundFileURL = zipURL
        } catch {
            errorText = "\(L.zipCreationError): \(error.localizedDescription)"
            showRenderOverlay = false
            return
        }
        renderFinished = true
        #else
        // Fallback : dossier brut si ZIPFoundation n'est pas intégré.
        presetToShareURL = folderURL
        capPlaygroundFileURL = folderURL
        renderFinished = true
        #endif
    }

    @MainActor
    private func exportTrackingData() async {
        // Nécessite au moins un point défini
        guard pointA != nil || pointB != nil else {
            errorText = L.defineAtLeastOnePoint
            return
        }

        errorText = nil
        generating = true
        defer { generating = false }

        let tmp = FileManager.default.temporaryDirectory
        let jsonURL = tmp.appendingPathComponent("tracking-\(UUID().uuidString).json")
        let csvURL  = tmp.appendingPathComponent("tracking-\(UUID().uuidString).csv")

        // JSON minimal avec lat/lon des points A/B
        var json: [String: Any] = [:]
        if let a = pointA {
            json["A_lat"] = a.latitude
            json["A_lon"] = a.longitude
        }
        if let b = pointB {
            json["B_lat"] = b.latitude
            json["B_lon"] = b.longitude
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            try data.write(to: jsonURL)
            lastTrackJSON = jsonURL
        } catch {
            errorText = "\(L.trackingExportError) (JSON): \(error.localizedDescription)"
            return
        }

        // CSV simple pour A/B
        let csvHeader = "point,label,lat,lon"
        var csvRows: [String] = [csvHeader]
        if let a = pointA {
            csvRows.append("A,A,\(a.latitude),\(a.longitude)")
        }
        if let b = pointB {
            csvRows.append("B,B,\(b.latitude),\(b.longitude)")
        }
        let csvString = csvRows.joined(separator: "\n") + "\n"
        do {
            if let data = csvString.data(using: .utf8) {
                try data.write(to: csvURL)
                lastTrackCSV = csvURL
            }
        } catch {
            errorText = "\(L.trackingExportError) (CSV): \(error.localizedDescription)"
            return
        }

        // Partage le JSON par défaut (même logique que Export preset)
        presetToShareURL = jsonURL
        showShareSheet = true
    }

    @MainActor
    private func exportCurrentPreset() {
        // Fichier texte .klav avec les principaux paramètres
        var lines: [String] = []
        lines.append("klamapPresetVersion=1")

        if let a = pointA {
            lines.append("pointA=\(a.latitude),\(a.longitude)")
        }
        if let b = pointB {
            lines.append("pointB=\(b.latitude),\(b.longitude)")
        }

        lines.append("seconds=\(seconds)")
        lines.append("fps=\(fps)")
        lines.append("bitrate=\(bitrate)")
        lines.append("resolution=\(resolution.rawValue)")
        lines.append("aspect=\(aspect.rawValue)")
        lines.append("orientation=\(orientation.rawValue)")
        lines.append("wCustom=\(wCustom)")
        lines.append("hCustom=\(hCustom)")
        lines.append("liveStyle=\(liveStyle.rawValue)")
        lines.append("oversample=\(oversample)")
        lines.append("imageFormat=\(imageFormatEnum.rawValue)")
        lines.append("videoFormat=\(videoFormatEnum.rawValue)")
        lines.append("frameCountMode=\(frameCountMode.rawValue)")
        lines.append("fixedFrameCount=\(fixedFrameCount)")
        lines.append("useRoutePath=\(useRoutePath)")
        lines.append("routeMode=\(routeMode.rawValue)")
        lines.append("introPercent=\(introPercent)")
        lines.append("outroPercent=\(outroPercent)")
        lines.append("easing=\(easing.rawValue)")
        lines.append("bezierP1=\(bezierP1.x),\(bezierP1.y)")
        lines.append("bezierP2=\(bezierP2.x),\(bezierP2.y)")
        lines.append("simulateTraffic=\(simulateTraffic)")
        lines.append("trafficStopDensity=\(trafficStopDensity)")
        lines.append("trafficStopDuration=\(trafficStopDuration)")
        lines.append("trafficSpeedJitter=\(trafficSpeedJitter)")

        // Camera & path options
        lines.append("pitchDeg=\(pitchDeg)")
        lines.append("keepCentered=\(keepCentered)")
        lines.append("splineEnabled=\(splineEnabled)")
        lines.append("splineCurvature=\(splineCurvature)")

        // Map options
        lines.append("showPOI=\(showPOI)")

        let content = lines.joined(separator: "\n")
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("preset-\(UUID().uuidString).klav")

        do {
            try content.data(using: .utf8)?.write(to: url)
            presetToShareURL = url
            showShareSheet = true
        } catch {
            errorText = "\(L.presetExportError): \(error.localizedDescription)"
        }
    }

    @MainActor
    private func importPreset(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            errorText = L.presetReadError
            return
        }

        let lines = text.split(whereSeparator: \.isNewline)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eq])
            let value = String(line[line.index(after: eq)...])

            switch key {
            case "pointA":
                let parts = value.split(separator: ",")
                if parts.count == 2,
                   let lat = Double(parts[0]),
                   let lon = Double(parts[1]) {
                    pointA = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            case "pointB":
                let parts = value.split(separator: ",")
                if parts.count == 2,
                   let lat = Double(parts[0]),
                   let lon = Double(parts[1]) {
                    pointB = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            case "seconds":
                if let v = Int(value) { seconds = v }
            case "fps":
                if let v = Int(value) { fps = v }
            case "bitrate":
                if let v = Int(value) { bitrate = v }
            case "resolution":
                if let v = ResolutionOption(rawValue: value) { resolution = v }
            case "aspect":
                if let v = AspectOption(rawValue: value) { aspect = v }
            case "orientation":
                if let v = OrientationOption(rawValue: value) { orientation = v }
            case "wCustom":
                wCustom = value
            case "hCustom":
                hCustom = value
            case "liveStyle":
                if let v = LiveMapStyle(rawValue: value) { liveStyle = v }
            case "oversample":
                if let v = Double(value) { oversample = v }
            case "imageFormat":
                if let v = ImageFormat(rawValue: value) { imageFormatEnum = v }
            case "videoFormat":
                if let v = VideoFormat(rawValue: value) { videoFormatEnum = v }
            case "frameCountMode":
                if let v = FrameCountMode(rawValue: value) { frameCountMode = v }
            case "fixedFrameCount":
                if let v = Int(value) { fixedFrameCount = v }
            case "useRoutePath":
                useRoutePath = (value as NSString).boolValue
            case "routeMode":
                if let v = RouteTransportMode(rawValue: value) { routeMode = v }
            case "introPercent":
                if let v = Double(value) { introPercent = v }
            case "outroPercent":
                if let v = Double(value) { outroPercent = v }
            case "easing":
                if let v = EasingPreset(rawValue: value) { easing = v }
            case "bezierP1":
                let parts = value.split(separator: ",")
                if parts.count == 2,
                   let x = Double(parts[0]),
                   let y = Double(parts[1]) {
                    bezierP1 = CGPoint(x: x, y: y)
                }
            case "bezierP2":
                let parts = value.split(separator: ",")
                if parts.count == 2,
                   let x = Double(parts[0]),
                   let y = Double(parts[1]) {
                    bezierP2 = CGPoint(x: x, y: y)
                }
            case "simulateTraffic":
                simulateTraffic = (value as NSString).boolValue
            case "trafficStopDensity":
                if let v = Double(value) { trafficStopDensity = v }
            case "trafficStopDuration":
                if let v = Double(value) { trafficStopDuration = v }
            case "trafficSpeedJitter":
                if let v = Double(value) { trafficSpeedJitter = v }

            case "pitchDeg":
                if let v = Double(value) { pitchDeg = v }
            case "keepCentered":
                keepCentered = (value as NSString).boolValue
            case "splineEnabled":
                splineEnabled = (value as NSString).boolValue
            case "splineCurvature":
                if let v = Double(value) { splineCurvature = v }
            case "showPOI":
                showPOI = (value as NSString).boolValue

            default:
                break
            }
        }

        // Recalcule la route si besoin et met à jour la preview
        if useRoutePath, pointA != nil, pointB != nil {
            recomputeRouteIfNeeded()
        }
        applyPreview(previewProgress)
    }

    // MARK: - Simple, compatible video export (sequential, single-threaded)

    private func makePixelBuffer(from cgImage: CGImage, width: Int, height: Int) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pb) == kCVReturnSuccess,
              let buf = pb else { return nil }

        CVPixelBufferLockBaseAddress(buf, [])
        defer { CVPixelBufferUnlockBaseAddress(buf, []) }

        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buf),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buf),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buf
    }

    private func snapshotCGImage(for state: (coord: CLLocationCoordinate2D, pose: CamPose), width: Int, height: Int) async -> CGImage? {
        let opts = MKMapSnapshotter.Options()
        opts.size = CGSize(width: width, height: height)

        // Capture camera + route + style + hideRoadLabels on MainActor
        let camConfig = await MainActor.run { () -> (MKMapCamera, LiveMapStyle, Bool, MKPolyline?, Bool) in
            let cam = MKMapCamera(lookingAtCenter: state.coord,
                                  fromDistance: state.pose.distance,
                                  pitch: state.pose.pitch,
                                  heading: state.pose.heading)
            return (cam, liveStyle, showPOI, routePolyline, hideRoadLabels)
        }

        let cam = camConfig.0
        let style = camConfig.1
        let poi = camConfig.2
        let routeForSnapshot = camConfig.3
        let noRoadLabels = camConfig.4

        opts.camera = cam

        if #available(iOS 16, *) {
            await MainActor.run {
                let elev: MKStandardMapConfiguration.ElevationStyle = (state.pose.pitch > 1) ? .realistic : .flat
                switch style {
                case .standard:
                    // Style Apple Maps classique
                    let cfg = MKStandardMapConfiguration(
                        elevationStyle: elev,
                        emphasisStyle: noRoadLabels ? .muted : .default
                    )
                    opts.preferredConfiguration = cfg

                case .muted:
                    // Palette désaturée / plus neutre
                    let cfg = MKStandardMapConfiguration(
                        elevationStyle: elev,
                        emphasisStyle: noRoadLabels ? .muted : .muted
                    )
                    opts.preferredConfiguration = cfg

                case .hybrid:
                    let cfg = MKHybridMapConfiguration(elevationStyle: elev)
                    opts.preferredConfiguration = cfg
                }

                // POI visibles ou non, indépendamment du style
                opts.pointOfInterestFilter = (poi && !noRoadLabels) ? .includingAll : .excludingAll
            }
        }

        let snap = MKMapSnapshotter(options: opts)
        return await withCheckedContinuation { (cont: CheckedContinuation<CGImage?, Never>) in
            snap.start { snapshot, err in
                guard err == nil, let snapshot = snapshot else {
                    cont.resume(returning: nil)
                    return
                }

                var image = snapshot.image

                // Ligne bleue par-dessus, façon CarPlay
                if let poly = routeForSnapshot {
                    UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                    image.draw(at: .zero)

                    let ctx = UIGraphicsGetCurrentContext()
                    ctx?.setStrokeColor(UIColor.systemBlue.cgColor)
                    ctx?.setLineWidth(5)
                    ctx?.setLineJoin(.round)
                    ctx?.setLineCap(.round)

                    var coords = [CLLocationCoordinate2D](
                        repeating: CLLocationCoordinate2D(),
                        count: poly.pointCount
                    )
                    poly.getCoordinates(&coords, range: NSRange(location: 0, length: poly.pointCount))

                    let bounds = CGRect(origin: .zero, size: image.size)
                    var didMove = false
                    for c in coords {
                        let pt = snapshot.point(for: c)
                        if !bounds.contains(pt) { continue }
                        if !didMove {
                            ctx?.move(to: pt)
                            didMove = true
                        } else {
                            ctx?.addLine(to: pt)
                        }
                    }
                    ctx?.strokePath()
                    image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                    UIGraphicsEndImageContext()
                }

                // Return the image without the dot overlay
                cont.resume(returning: image.cgImage)
            }
        }
    }

    @MainActor
    fileprivate func exportImageClean() async {
        guard pointA != nil && pointB != nil else {
            errorText = L.defineABBeforeImage
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        generating = true
        showRenderOverlay = true
        renderFinished = false
        errorText = nil
        savedOK = false
        cancelRequested = false
        progressLabel = L.preparing

        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        defer {
            generating = false
            progressLabel = ""
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }

        let px = exportPixelSize()
        progressLabel = L.renderingImage

        guard let baseCG = await renderMapImage(size: px, t: previewProgress) else {
            errorText = L.renderError
            return
        }

        if cancelRequested {
            errorText = L.exportCancelled
            cancelRequested = false
            showRenderOverlay = false
            return
        }

        let uiImg = UIImage(cgImage: baseCG)
        progressLabel = "\(L.encoding) (\(imageFormatEnum.rawValue))…"
        guard let (data, uti) = imageData(for: uiImg,
                                          format: imageFormatEnum,
                                          quality: imageQuality,
                                          pngCompressionLevel: pngCompressionLevel) else {
            errorText = L.encodingError
            return
        }

        progressLabel = L.savingToPhotos
        let authorized = await requestPhotoLibraryAccessIfNeeded()
        guard authorized else {
            errorText = L.photosAccessDenied
            return
        }
        do {
            try await saveImageDataToPhotos(data, uti: uti)
            savedOK = true
            renderFinished = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.savedOK = false
            }
        } catch {
            errorText = "Photos: \(error.localizedDescription)"
        }
    }

    // Export a sequence of images to Photos (with progress/log) - unchanged

    @MainActor private func exportVideoClean() async {
        // Garde-fou : A & B requis
        guard let _ = pointA, let _ = pointB else {
            errorText = L.defineABBeforeVideo
            return
        }

        generating = true
        showRenderOverlay = true
        renderFinished = false
        errorText = nil
        savedOK = false
        cancelRequested = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        defer {
            generating = false
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }

        // Paramètres figés (évite captures cross-actor)
        let px = exportPixelSize()
        let width = Int(px.width.rounded())
        let height = Int(px.height.rounded())
        let seconds_local = seconds
        let fps_local = max(1, fps)

        let totalFrames: Int
        switch frameCountMode {
        case .duration:
            totalFrames = max(1, seconds_local * fps_local)
        case .fixedFrames:
            totalFrames = max(1, fixedFrameCount)
        }
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps_local))

        // Handle uncompressed sequence first
        if videoFormatEnum == .uncompressedSequence {
            await exportImageSequence()
            return
        }

        let fileType: AVFileType
        let codec: AVVideoCodecType
        switch videoFormatEnum {
        case .h264:
            fileType = .mp4
            codec = .h264
        case .hevc8, .hevc10, .proRes422, .proRes422HQ, .prores4444:
            // On mappe tous ces formats avancés sur HEVC pour rester compatible
            fileType = .mov
            codec = .hevc
        case .uncompressedSequence:
            // Ce cas est géré plus haut via exportImageSequence(), il ne devrait pas arriver ici.
            fileType = .mov
            codec = .h264
        }

        let fileExtension = (fileType == .mp4) ? "mp4" : "mov"
        let outURL = FileManager.default.temporaryDirectory.appendingPathComponent("export_\(UUID().uuidString).\(fileExtension)")
        guard let writer = try? AVAssetWriter(outputURL: outURL, fileType: fileType) else {
            errorText = "\(L.exportError): impossible de créer l'écrivain."
            generating = false
            return
        }

        // Tag caché dans les métadonnées de la vidéo (visible en lisant le fichier brut)
        let meta = AVMutableMetadataItem()
        meta.keySpace = .common
        meta.key = AVMetadataKey.commonKeyDescription as (NSCopying & NSObjectProtocol)
        meta.value = "klavair" as (NSCopying & NSObjectProtocol & NSSecureCoding)
        writer.metadata = [meta]

        let br = max(1, bitrate) * 1_000_000
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: br,
                AVVideoExpectedSourceFrameRateKey: fps_local,
                AVVideoMaxKeyFrameIntervalKey: max(1, fps_local * 2)
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
        )

        guard writer.canAdd(input) else {
            errorText = "\(L.exportError): ajout input impossible."
            generating = false
            return
        }
        writer.add(input)

        guard writer.startWriting() else {
            errorText = writer.error?.localizedDescription ?? "\(L.exportError): démarrage impossible."
            generating = false
            return
        }
        writer.startSession(atSourceTime: .zero)

        // Pré-calcul des états de caméra
        let pathStates: [(coord: CLLocationCoordinate2D, pose: CamPose)] = (0..<totalFrames).map { i in
            let t = CGFloat(i) / CGFloat(max(1, totalFrames - 1))
            return self.pathPoint(t)
        }

        // Boucle séquentielle : snapshot -> pixelBuffer -> append
        for i in 0..<totalFrames {
            if cancelRequested { break }

            let state = pathStates[i]
            let cgOpt = await snapshotCGImage(for: state, width: width, height: height)

            if let cg = cgOpt {
                if let buf = makePixelBuffer(from: cg, width: width, height: height) {

                    while !input.isReadyForMoreMediaData {
                        try? await Task.sleep(nanoseconds: 2_000_000) // 2 ms
                    }
                    let pts = CMTimeMultiply(frameDuration, multiplier: Int32(i))
                    _ = adaptor.append(buf, withPresentationTime: pts)
                }
            } else {
                print("[Export] frame \(i) snapshot failed")
            }

            // Progress UI (only count frames, no percent text)
            let p = Double(i + 1) / Double(totalFrames)
            self.renderProgress = p
            self.progressLabel = "\(L.frame) \(i + 1) / \(totalFrames)"
        }

        // Si l'utilisateur a demandé l'annulation, on arrête proprement ici
        if cancelRequested {
            input.markAsFinished()
            writer.cancelWriting()
            cancelRequested = false
            errorText = L.exportCancelled
            showRenderOverlay = false
            return
        }

        input.markAsFinished()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            writer.finishWriting { cont.resume() }
        }

        // Sauvegarde Photos
        let authorized = await requestPhotoLibraryAccessIfNeeded()
        guard authorized else {
            errorText = "\(L.exportError): \(L.photosAccessDenied)"
            generating = false
            return
        }

        do {
            try await saveVideoToPhotos(outURL)
            savedOK = true
            renderFinished = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.savedOK = false }
        } catch {
            errorText = "\(L.exportError): \(error.localizedDescription)"
            showRenderOverlay = false
        }
    }

    // Helper: render a map snapshot for given size and t ∈ [0,1]
    fileprivate func renderMapImage(size: CGSize, t: CGFloat) async -> CGImage? {
        // Precompute state for t
        let (coord, pose) = await MainActor.run { self.pathPoint(t) }
        let opts = MKMapSnapshotter.Options()
        opts.size = size
        let cam = await MainActor.run {
            MKMapCamera(lookingAtCenter: coord,
                        fromDistance: pose.distance,
                        pitch: pose.pitch,
                        heading: pose.heading)
        }
        opts.camera = cam
        if #available(iOS 16, *) {
            await MainActor.run {
                let elev: MKStandardMapConfiguration.ElevationStyle = (pose.pitch > 1) ? .realistic : .flat
                switch liveStyle {
                case .standard:
                    // Style Apple Maps classique
                    let cfg = MKStandardMapConfiguration(
                        elevationStyle: elev,
                        emphasisStyle: hideRoadLabels ? .muted : (showPOI ? .default : .muted)
                    )
                    opts.preferredConfiguration = cfg
                case .muted:
                    let cfg = MKStandardMapConfiguration(elevationStyle: elev, emphasisStyle: hideRoadLabels ? .muted : (showPOI ? .default : .muted))
                    opts.preferredConfiguration = cfg
                case .hybrid:
                    let cfg = MKHybridMapConfiguration(elevationStyle: elev)
                    opts.preferredConfiguration = cfg
                }
                opts.pointOfInterestFilter = (showPOI && !hideRoadLabels) ? .includingAll : .excludingAll
            }
        }
        let snap = MKMapSnapshotter(options: opts)
        let cg: CGImage? = await withCheckedContinuation { (cont: CheckedContinuation<CGImage?, Never>) in
            snap.start { img, err in
                if let err = err { print("[Export] snapshot error: \(err.localizedDescription)") }
                guard let uiImage = img?.image else { cont.resume(returning: nil); return }
                Task { @MainActor in
                    cont.resume(returning: uiImage.cgImage)
                }
            }
        }
        return cg
    }

    fileprivate func applyNightVariant(to cgImage: CGImage) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        ctx.setFillColor(UIColor.black.withAlphaComponent(0.35).cgColor)
        ctx.setBlendMode(.multiply)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return ctx.makeImage()
    }
}


// Affiche automatiquement l'icône principale de l'application (celle déclarée comme App Icon)
struct AppIconView: View {
    var body: some View {
        if let uiImage = AppIconProvider.shared.icon {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            // Fallback si aucune icône n'est trouvée
            Image(systemName: "app.fill")
                .resizable()
        }
    }
}

final class AppIconProvider {
    static let shared = AppIconProvider()
    let icon: UIImage?

    private init() {
        #if canImport(UIKit)
        if let iconsDict = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last,
           let image = UIImage(named: last) {
            icon = image
        } else if let image = UIImage(named: "AppIcon") {
            // Fallback explicite sur un asset nommé AppIcon si présent
            icon = image
        } else {
            icon = nil
        }
        #else
        icon = nil
        #endif
    }
}

// MARK: - New reusable components and styles

struct GlassSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 8)
        } label: {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.vertical, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.white.opacity(0.2)))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .animation(.spring(duration: 0.35), value: isExpanded)
    }
}

struct GlassToast: View {
    enum Kind {
        case success, error, info
        var iconName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }

    let kind: Kind
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.iconName)
                .font(.title3)
                .foregroundColor(kind.color)
            Text(message)
                .foregroundStyle(.primary)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
        .frame(maxWidth: 320)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18)))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Minimal helpers for DocumentPicker & ShareView
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL?) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let c = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.data], asCopy: true)
        c.delegate = context.coordinator
        return c
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(parent: self) }
    final class Coord: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(parent: DocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { parent.onPick(urls.first) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { parent.onPick(nil) }
    }
}

struct ShareView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Rien à mettre à jour dynamiquement pour l'instant
    }
}

#Preview { RootView() }


// Photos access helper functions (added above existing saveImageDataToPhotos)
// Save raw image data with an explicit UTI to Photos (keeps the chosen format)
@MainActor
fileprivate func requestPhotoLibraryAccessIfNeeded() async -> Bool {
    // Utilise le mode .addOnly pour limiter aux ajouts
    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    switch status {
    case .authorized, .limited:
        return true
    case .notDetermined:
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                switch newStatus {
                case .authorized, .limited:
                    cont.resume(returning: true)
                default:
                    cont.resume(returning: false)
                }
            }
        }
    default:
        return false
    }
}

@MainActor
fileprivate func saveVideoToPhotos(_ fileURL: URL) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: .video, fileURL: fileURL, options: nil)
        }, completionHandler: { success, error in
            if let error = error {
                cont.resume(throwing: error)
                return
            }
            if success {
                cont.resume(returning: ())
            } else {
                let err = NSError(
                    domain: "Export",
                    code: -10,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown error saving video"]
                )
                cont.resume(throwing: err)
            }
        })
    }
}

// Save raw image data with an explicit UTI to Photos (keeps the chosen format)
@MainActor
fileprivate func saveImageDataToPhotos(_ data: Data, uti: UTType) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            let opts = PHAssetResourceCreationOptions()
            opts.uniformTypeIdentifier = uti.identifier
            req.addResource(with: .photo, data: data, options: opts)
        }, completionHandler: { success, error in
            if let error = error { cont.resume(throwing: error); return }
            if success { cont.resume(returning: ()) } else { cont.resume(throwing: NSError(domain: "Export", code: -9, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving image data"])) }
        })
    }
}

// Encode UIImage to the selected format
fileprivate func imageData(for image: UIImage, format: WallpaperMakerView.ImageFormat, quality: Double, pngCompressionLevel: Int) -> (Data, UTType)? {
    switch format {
    case .png:
        if let d = image.pngData() { return (d, .png) }
        return nil
    case .jpeg:
        if let d = image.jpegData(compressionQuality: quality) { return (d, .jpeg) }
        return nil
    case .heic:
        if let d = image.heicData(quality: quality) { return (d, .heic) }
        return nil
    case .tiff:
        guard let cg = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.tiff.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return (data as Data, .tiff)
    }
}

extension UIImage {
    func heicData(quality: Double) -> Data? {
        guard let cg = self.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, cg, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}

extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
