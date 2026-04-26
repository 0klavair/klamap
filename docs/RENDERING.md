# Système de rendu klamap — Audit et plan de refonte

**Date :** avril 2026
**Auteur :** analyse complète du pipeline + propositions
**Objectif :** comprendre POURQUOI le rendu hybride+3D continue de glitcher malgré 6+ tentatives de fix, et proposer une refonte propre.

---

## 0. Contraintes dures (non-négociables)

Définies par l'utilisateur, en ordre de priorité :

| # | Contrainte | Implication |
|---|---|---|
| **C1** | **Zéro cut, zéro bond, zéro micro-cut de caméra**. La caméra ne doit JAMAIS sauter d'une position à une autre, même infinitésimalement. | Tout mécanisme qui change brutalement la vitesse, la position, ou qui passe de "en mouvement" à "figé" est interdit. Le `endHoldFrameCount` actuel viole cette contrainte. |
| **C2** | **Le rendu doit correspondre 1:1 à la live preview**. Si la preview marche, l'export doit marcher pareil. | Architecturalement : preview et export doivent partager le **même** moteur de rendu. |
| **C3** | **Mode hybride + 3D réaliste doit fonctionner sans tremblement, sans pop-in, sans flicker**. | Cible la cause racine, pas les symptômes. |
| **C4** | **Trajectoire C¹-smooth** (dérivée continue). | Pas de `cameraLead` qui taper en zone fin, pas de discontinuité aux limites de profT. |

---

## 1. Résumé exécutif

### Le bug
En mode `liveStyle = .hybrid` + `realisticElevationWhenPitched = true`, le rendu exporté présente des artefacts (tremblements, pop-in, parfois "vol dans le vide") **alors que la live preview rend parfaitement** sur les MÊMES paramètres caméra.

### La cause racine
Pas une seule, **trois racines superposées** :

1. **Architecture fragmentée** : la live preview utilise SwiftUI `Map(position:)` (iOS 17+), persistante, état de tuiles préservé. L'export utilise `MKMapSnapshotter` (stateless) ou un MKMapView offscreen séparé. Pipelines différents = comportements différents.
2. **Race condition tile-load vs callback** : `MKMapSnapshotter.start()` appelle son callback dès que les **textures raster** sont prêtes, **pas le 3D mesh**. Resultat : snapshot rendu avant que le mesh photoréaliste finisse de charger → flat satellite + buildings popping → tremblement.
3. **Hacks accumulés** : 6 tentatives de fix successives ont laissé des workarounds dans le code (taper du `cameraLead`, `endHoldFrameCount`, `previewModeRender` toggle, blank-frame retry avec nudge de distance, preheat END, déduplication d'états identiques). Chacun a été ajouté en réaction à un symptôme. Ils peuvent maintenant interagir entre eux et **violer C1** (le hold viole déjà C1 explicitement).

### La conclusion
On a empilé des couches sur une fondation cassée. **Il faut refaire la fondation**.

---

## 2. Inventaire du système actuel

### 2.1 Fichiers du pipeline de rendu

| Fichier | LOC | Rôle |
|---|---:|---|
| `RenderEngine.swift` | 508 | Orchestrateur : dispatcher (parallèle/persistent), preheat, retry |
| `AppleMapsViewRenderer.swift` | 248 | MKMapView offscreen persistante, mode hybride+3D |
| `GoogleMapsRenderer.swift` | 219 | GMSMapView offscreen (créée par frame, pas persistante) |
| `RenderFilter.swift` | 143 | CIFilter post-processing (vintage, cinematic, noir, etc.) |
| `TendiesExporter.swift` | 284 | Empaquetage final en bundle .tendies |
| `TendiesTemplate.swift` | 301 | Génération du CAML (Core Animation Markup Language) |
| `ContentView.swift` | 5184 | UI + `pathPoint`, `buildPathStates`, `exportTendies`, `exportVideoClean`, `applyPreview`, `mapPicker` |

### 2.2 Les deux pipelines en concurrence

```
                    ┌──────────────────┐
                    │  pathPoint(t)    │  Un seul calcul de trajectoire
                    │  (deterministe)  │  partagé entre preview et export
                    └────────┬─────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐           ┌─────────────────────┐
    │   PREVIEW LIVE  │           │       EXPORT        │
    │  (parfaite)     │           │  (cassée en hybrid+3D)
    └─────────────────┘           └─────────────────────┘
              │                             │
              ▼                             ▼
    SwiftUI `Map(position:)`        ┌──────┴──────┐
    persistant 1 instance           │             │
    iOS 17+ APIs                    ▼             ▼
                            MKMapSnapshotter   AppleMapsViewRenderer
                            (parallèle 4×)     (MKMapView persistent
                            stateless          séquentiel offscreen)
                            ↓                  ↓
                            Trembling          Plus stable mais
                            inévitable         encore des résidus
```

### 2.3 Hacks empilés (à supprimer dans la refonte)

| Hack | Fichier:ligne | Pourquoi il existe | Pourquoi il pose problème |
|---|---|---|---|
| `cameraLead` + `leadTaper` | ContentView.swift:977-986 | Effet "caméra regarde un peu en avant" type CarPlay | Le tapering crée une discontinuité de vélocité aux 15% finaux → **viole C4** |
| `endHoldFrameCount` | ContentView.swift:1996-2014 | Camoufler le bug de fin en figeant la caméra | **Viole C1** : passage de "mouvement" à "figé" = cut perçu |
| `previewModeRender` | AppleMapsViewRenderer.swift:65-76 | Match comportement preview en réduisant les attentes | Toggle qui n'aurait jamais dû exister — preview = défaut, point. |
| `isLikelyBlank` + retry | RenderEngine.swift:154-167 | Détecter frames "vides" et re-render | Heuristique imparfaite + retry change la distance × 1.001 → **viole C1** |
| END-WARMUP preheat | RenderEngine.swift:85-100 | Pré-charger tuiles destination | Sequential avant batch parallèle → batch refait quand même la race |
| Blank variance threshold | RenderEngine.swift:430 (variance < 25) | Magic number empirique | Ne détecte pas les frames flat-mesh (qui ont une variance haute) |
| Déduplication `statesEqual` | RenderEngine.swift:267-274 | Réutiliser image précédente si camera state identique | Existe **uniquement** pour cacher le bug du hold-frame |
| `safeBearing` + `findValidBearingTarget` | RenderEngine.swift, pathPoint | Garde-fou contre atan2(0,0) sur points dupliqués | Workaround légitime pour MKDirections, à garder |
| Distance/pitch guards relâchés | RenderEngine.swift:471-484 | User voulait pouvoir descendre près du sol | Légitime, à garder |

**Bilan :** 7 hacks, dont 4 violent C1 ou C4. Le reste sont des compensations pour des bugs de couches inférieures.

---

## 3. Analyse pourquoi la preview marche

### 3.1 Architecture preview

La preview est UNE seule instance SwiftUI `Map(position:)` (iOS 17+). Caractéristiques clés :

```swift
Map(position: $mapPos) {
    if let a = pointA { Annotation("A", coordinate: a) { pin("A") } }
    if let b = pointB { Annotation("B", coordinate: b) { pin("B") } }
    if useRoutePath, let poly = routePolyline {
        MapPolyline(poly).stroke(.blue, lineWidth: 4)
    }
}
.mapStyle(...)
.onMapCameraChange { ctx in ... }
```

**Pourquoi c'est parfait :**

1. **Une seule view persistante** pour toute la session. Le tile cache est continu.
2. **Rendu Metal continu** : la view redraws à chaque Vsync (60Hz ou 120Hz) tant qu'elle est à l'écran.
3. **Tuile cache partagée** entre frames. Quand la caméra bouge, MKMapView ne refetch que ce qui manque.
4. **Pas de "snapshot" discret** : c'est une animation continue. Les tuiles convergent au fur et à mesure que l'œil les voit.
5. **3D mesh** : MapKit charge le mesh une fois, le réutilise. Quand il manque, c'est progressif et l'œil l'accepte comme "live data".

### 3.2 Pourquoi l'export ne marche pas (même avec AppleMapsViewRenderer)

`AppleMapsViewRenderer` essaie de répliquer la preview avec une MKMapView offscreen persistante. **Mieux mais pas suffisant**, parce que :

1. **Setup discret** : `setCamera(_, animated: false)` puis `wait` puis `drawHierarchy`. C'est trois pas distincts. Le wait est soit trop court (race) soit trop long (perte de qualité par rapport à la preview).
2. **Capture via `drawHierarchy`** : oui, ça capte le Metal output, mais à un MOMENT précis. Si Metal est en train de transitionner, on peut capter un mid-frame.
3. **Pas de continuité** : entre frame N et frame N+1, MapKit voit deux camera moves consécutifs très proches mais distincts. Selon comment son scheduler interne dispatch les requêtes mesh, la stabilité varie frame-par-frame.
4. **`previewLike` mode** réduit l'attente à 33ms (~2 Vsync). Mais 33ms c'est encore une attente DISCRÈTE entre setCamera et capture. La preview, elle, ne fait pas ça : elle redraws en continu et N'EST JAMAIS "snapshotted".

---

## 4. Le vrai fix : architecture continue

### 4.1 Principe

> **Au lieu de SNAPSHOT discrets, on FAIT TOURNER la preview à plein régime et on ENREGISTRE ce qu'elle affiche.**

Comme un screen recorder. La preview reste la source de vérité. Le rendu n'est plus une "génération" de frames mais une "capture" de l'animation continue de la preview.

### 4.2 Comparaison conceptuelle

| Aspect | Architecture actuelle (export discret) | Architecture proposée (capture continue) |
|---|---|---|
| Source des frames | Snapshot d'une vue offscreen | Capture de la preview live |
| Cadence camera | Frame-par-frame, set + wait + capture | CADisplayLink @ 60/120Hz, interpolation continue |
| Tile loading | Démarre à chaque snapshot | Continu, partagé avec preview |
| 3D mesh stability | Race condition par frame | Stable, mêmes tuiles que preview |
| Différence vs preview | Architecturalement différent | Architecturalement identique (par construction) |
| Workarounds nécessaires | 7+ (voir §2.3) | 0 |

### 4.3 Comment ça marche concrètement

1. **Une seule MKMapView** dans l'app, partagée entre preview UI et export.
2. **CADisplayLink** synchronisé sur Vsync (60 ou 120Hz selon device).
3. **À chaque tick du DisplayLink** :
   - Calculer `t = currentTime / totalDuration`
   - `let state = pathPoint(t)`
   - `mapView.setCamera(stateToMapCamera(state), animated: false)` *(au minimum, ça pourrait même être animated avec keyTimes)*
   - **Sur le Vsync SUIVANT**, capturer l'image rendue via `drawHierarchy` ou `CARenderer`
4. **Encoder** dans un AVAssetWriter ou écrire en JPEG (selon export type)
5. **Pour Tendies** : packaging idem (juste les frames qui changent)

**Détail crucial :** la capture se fait sur le Vsync SUIVANT le setCamera, pas le même. Ça laisse Metal terminer son rendu naturellement.

### 4.4 Pourquoi ça résout C1 (zéro cut)

- La trajectoire `pathPoint(t)` est déterministe et lisse partout par construction (modulo `cameraLead` qu'on enlève — voir §5)
- À chaque Vsync, `t` avance d'exactement `1 / (totalFrames - 1)`. Pas de saut.
- Pas de `endHoldFrameCount` : la trajectoire couvre profT 0 → 1.0, point.
- Pas de retry avec nudge de distance.
- Le DisplayLink garantit un timing rigoureux et uniforme.

### 4.5 Pourquoi ça résout C2 (rendu = preview)

- La même MKMapView est utilisée. Il N'Y A PAS DE "deuxième pipeline".
- Le Metal frame qui s'affiche dans la preview est exactement celui qu'on capture.
- Tile loading, mesh state, tout converge naturellement comme la preview.

### 4.6 Pourquoi ça résout C3 (hybride+3D stable)

- Pas de race entre snapshots concurrents. Une seule view, un seul cache, un seul scheduler MapKit.
- Le 3D mesh charge une fois et reste chargé tant que la caméra reste dans la zone.
- Pop-in éventuel, mais identique à la preview (que l'utilisateur trouve acceptable).

---

## 5. Plan de refonte concret

### 5.1 Fichiers nouveaux

#### `ContinuousRenderEngine.swift` (~250 lignes)

Le nouveau cœur. Remplace `RenderEngine.swift` (réduit à des helpers stateless).

```swift
@MainActor
final class ContinuousRenderEngine {
    private var displayLink: CADisplayLink?
    private weak var mapView: MKMapView?
    private var currentJob: RenderJob?
    private var captureBuffer: CVPixelBufferPool?

    func startRender(
        states: [CameraState],
        targetFPS: Int,           // matched to nearest Vsync rate
        onFrame: @MainActor (Int, CGImage) async -> Void,
        onComplete: @MainActor () -> Void
    ) async

    private func tick(_ link: CADisplayLink) {
        let t = currentFrameIndex / Double(totalFrames - 1)
        let state = states[currentFrameIndex]
        applyCamera(state)
        scheduleCapture(at: nextVsync)  // capture happens N+1
        currentFrameIndex += 1
    }
}
```

Détails :
- `mapView` est passée en référence (pas créée localement) — la même que la preview
- `displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)`
- Capture à Vsync N+1 via `view.drawHierarchy(...)` sur le main thread

#### `RenderHostView.swift` (~80 lignes)

Un `UIViewRepresentable` qui partage UNE même MKMapView entre la preview et l'export. Évite la divergence d'état.

```swift
struct RenderHostView: UIViewRepresentable {
    @Binding var camera: MKMapCamera
    @Binding var styleConfig: SnapshotConfig
    @Binding var polyline: MKPolyline?

    func makeUIView(context: Context) -> MKMapView {
        SharedMapViewRegistry.shared.view  // singleton
    }
    // ...
}
```

#### `SharedMapViewRegistry.swift` (~40 lignes)

Singleton pour la MKMapView unique. Partagée preview/export.

### 5.2 Fichiers à supprimer

- `AppleMapsViewRenderer.swift` (248 lignes) → fonctionnalité absorbée par ContinuousRenderEngine
- Les méthodes `renderFramesParallel`, `renderFramesViaPersistentMapView`, `snapshotPure`, `isLikelyBlank` dans `RenderEngine.swift` (~300 lignes)
- Le mode `previewModeRender` (toggle UI + plumbing)
- Le mécanisme `endHoldFrameCount` + ses overrides
- La déduplication `statesEqual`
- Le blank-frame retry

### 5.3 Fichiers à modifier

#### `ContentView.swift`

- `pathPoint(_ t:)` : retirer le tapering du `cameraLead` (ligne 977-986). Soit pas de lead du tout, soit un lead constant. La taper viole C4.
- `buildPathStates` : passer de `totalFrames + endHoldFrameCount` à juste `totalFrames`. La trajectoire est exacte 0 → 1.0.
- `exportTendies`, `exportVideoClean` : remplacer les appels à `RenderEngine.renderFramesParallel` par `ContinuousRenderEngine.startRender`. Suppression du buffer ordered-write (plus nécessaire car les frames arrivent dans l'ordre par construction).
- `mapPicker` : utilise `RenderHostView` à la place de SwiftUI `Map`.

#### `TendiesExporter.swift`

Pas de changement majeur. Les frames JPEG arrivent dans l'ordre, l'empaquetage est identique.

#### `TendiesTemplate.swift`

Pas de changement.

#### `RenderFilter.swift`

Pas de changement. Les filtres CIFilter s'appliquent toujours en post-process sur chaque CGImage capturé.

### 5.4 Ce qui reste

| Fonctionnalité | Statut |
|---|---|
| **Trajectoire** (`pathPoint`, route follow, profil traffic, easing, splines) | ✅ Inchangé sauf retrait du lead taper |
| **Preset caméra** (Cinematic Drive, Aerial Tour, etc.) | ✅ Inchangé |
| **Filtres** (vintage, cinematic, noir, etc.) | ✅ Inchangé |
| **Polyline overlay** (route bleue) | ✅ Native MKMapView overlay (déjà) |
| **Export Tendies** | ✅ Frames feed inchangées |
| **Export Vidéo** | ✅ Plus simple (pas de reorder) |
| **Google Maps backend** | ✅ Path séparé inchangé |
| **Mode présentation** | ✅ Inchangé |
| **Mode site web (HTTP server)** | ✅ Inchangé |
| **Logs trajectoire CSV** | ✅ Inchangé |
| **Stabilize end (`trimEndFrames`)** | ❌ Supprimé (viole C1) |
| **Preview-mode toggle** | ❌ Supprimé (devient le default unique) |

### 5.5 Effort estimé

| Étape | Effort | Risque |
|---|---|---|
| Implémenter `ContinuousRenderEngine` | 1 jour | Moyen (CADisplayLink + capture timing) |
| Implémenter `RenderHostView` + `SharedMapViewRegistry` | 0.5 jour | Faible |
| Modifier exports + retirer hacks | 0.5 jour | Faible |
| Tests sur device | 0.5 jour | Élevé (Windows ne peut pas tester) |
| **Total** | **~2.5 jours** | |

### 5.6 Plan de migration

**Phase 1 — Foundation (sans casser l'existant)**
- Créer `ContinuousRenderEngine.swift` et `RenderHostView.swift`
- Ajouter un toggle `useContinuousEngine` (défaut OFF)
- Quand ON → exports passent par le nouveau pipeline
- Quand OFF → comportement actuel
- L'utilisateur peut comparer les deux côte à côte

**Phase 2 — Validation**
- Si Phase 1 résout le bug et respecte C1/C2/C3/C4, le toggle passe à ON par défaut
- Les hacks sont marqués `@available(*, deprecated)` mais restent pour rollback

**Phase 3 — Cleanup**
- Suppression définitive des hacks
- Suppression de l'ancien `RenderEngine.parallel*`
- Suppression du toggle (l'engine continu devient le seul)

---

## 6. Risques et inconnues

### 6.1 Risques techniques

| Risque | Probabilité | Mitigation |
|---|---|---|
| `CADisplayLink` ne fournit pas un timing rigoureux pour `setCamera + capture` à 60Hz | Moyenne | Fallback à 30Hz avec downsampling, ou render à 60Hz mais setCamera animé |
| `view.drawHierarchy` capte un mid-frame pendant que Metal compose | Faible | Capture sur Vsync N+1 explicitement, pas sur le même tick |
| Partager UNE MKMapView entre preview et export crée des conflits (camera bouge pendant que l'utilisateur edite) | Moyenne | Bloquer l'UI pendant l'export (overlay déjà existant), restaurer la caméra preview à la fin |
| Performance trop lente sur device | Faible | DisplayLink à 60Hz, capture inline, pas de wait — c'est plus rapide que le snapshot actuel |
| iPhone bas de gamme (iOS 16) ne suit pas | Élevée pour iOS 16 | Garder le path actuel comme fallback iOS 16 (déjà bloqué via `iOS16UnsupportedView`) |

### 6.2 Inconnues

- **CARenderer vs drawHierarchy** : laquelle est plus rapide et fiable pour capturer Metal ? À tester.
- **Comportement de `MKMapView.setCamera(_, animated: false)` à 60Hz** : MapKit accepte-t-il cette cadence sans dégradation ? Probable mais à valider.
- **Tile prefetching pour la trajectoire** : peut-on demander à MKMapView de pré-charger les tuiles le long de la trajectoire avant de commencer ? L'API n'expose rien de tel directement, mais on peut faire un pre-pass virtuel (comme le END-WARMUP actuel mais étendu à toute la trajectoire).

---

## 7. Questions pour décider

Avant d'implémenter, points à confirmer :

1. **Migration progressive (toggle) ou refonte sèche ?**
   - Toggle = sûr, comparable, +0.5j de scaffolding
   - Sèche = plus propre, on rollback via git si besoin

2. **Keep `cameraLead` ou retirer entièrement ?**
   - Effet CarPlay sympa mais le tapering viole C4
   - Option : lead **constant** (sans taper) + pas de clamp à profT=1
   - Ou : lead = 0 (la caméra est exactement sur la position courante)

3. **iOS 16 compat — vraie refonte ou stub ?**
   - Toggle iOS 16 actuel = écran "iOS 17 required". On garde ?
   - Vraie compat iOS 16 = +1 jour de UIViewRepresentable supplémentaire

4. **Refactor `pathPoint` pour être C¹-smooth garanti ?**
   - Aujourd'hui : profilage trafic + spline + interpolation route. Il y a des transitions par morceaux qui peuvent ne pas être C¹.
   - Si C1 demande mathématique, faut peut-être lisser la dérivée.

---

## 8. Bénéfices secondaires de la refonte

Une fois le pipeline continu en place, plein de choses deviennent gratuites :

- **Streaming** : envoyer le flux MJPEG ou H264 directement vers le serveur HTTP, pour la fonctionnalité "site web" demandée. La même boucle de capture sert à l'export ET au streaming.
- **Multi-device** : le serveur de rendu peut accepter une trajectoire en JSON et la rejouer dans son propre `ContinuousRenderEngine`. Plus simple que de passer des CGImages sur le réseau.
- **Performance** : un pipeline continu qui partage les tuiles avec la preview est strictement plus rapide que le pipeline actuel (qui re-init tout à chaque snapshot).
- **Code clarity** : passer de ~750 LOC de pipeline (RenderEngine + AppleMapsViewRenderer) à ~330 LOC (ContinuousRenderEngine + RenderHostView).

---

## 9. Conclusion

**Le bug actuel n'est pas réparable par une 7e tentative de patch.** Chaque hack ajoute un cas spécial qui en cache un autre. La preview marche parce qu'elle est sur la bonne architecture (une view continue, persistante, Metal continu). L'export ne marchera correctement que sur la même architecture.

**La refonte est ~2.5 jours** et résout simultanément :
- Le bug hybride+3D
- La violation de C1 par le hold-frame
- La violation de C4 par le lead taper
- Le besoin de streaming pour le futur serveur web
- Le besoin de stabilité pour le multi-device

**Je propose d'attaquer la Phase 1 (foundation + toggle) la prochaine itération si tu valides.** La Phase 1 ne casse rien — elle ajoute le nouveau pipeline en parallèle, tu testes, on compare.

Si Phase 1 échoue, l'inertie est minimale (juste les nouveaux fichiers à supprimer). Si Phase 1 réussit, on enchaîne Phase 2 et 3 dans la même session.
