import Foundation

enum TendiesTemplate {

    static func indexXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>assetManifest</key>
        \t<string>assetManifest.caml</string>
        \t<key>documentHeight</key>
        \t<real>844</real>
        \t<key>documentResizesToView</key>
        \t<false/>
        \t<key>documentWidth</key>
        \t<real>390</real>
        \t<key>geometryFlipped</key>
        \t<false/>
        \t<key>loopEnd</key>
        \t<real>+infinity</real>
        \t<key>loopStart</key>
        \t<real>0.0</real>
        \t<key>loopingEnabled</key>
        \t<true/>
        \t<key>plugins</key>
        \t<array/>
        \t<key>rootDocument</key>
        \t<string>main.caml</string>
        </dict>
        </plist>
        """
    }

    static func assetManifestCAML(framePaths: [String]) -> String {
        let entries = framePaths.map { p in
            "    <CAAsset src=\"\(escapeXML(p))\"/>"
        }.joined(separator: "\n")
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <assets>
        \(entries)
          </assets>
        </caml>
        """
    }

    static func emptyMainCAML(layerName: String, width: Int, height: Int) -> String {
        let cx = width / 2
        let cy = height / 2
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer id="__capRootLayer__" name="CAPlayground Root Layer" bounds="0 0 \(width) \(height)" position="\(cx) \(cy)" zPosition="undefined" geometryFlipped="0" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular">
            <sublayers>
              <CALayer id="\(layerName)Inner" name="Root Layer" bounds="0 0 \(width) \(height)" position="\(cx) \(cy)" zPosition="undefined" geometryFlipped="0" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular"/>
            </sublayers>
            <states>
              <LKState name="Locked"><elements/></LKState>
              <LKState name="Unlock"><elements/></LKState>
              <LKState name="Sleep"><elements/></LKState>
            </states>
            <stateTransitions>
              <LKStateTransition fromState="*" toState="Unlock"><elements/></LKStateTransition>
              <LKStateTransition fromState="Unlock" toState="*"><elements/></LKStateTransition>
              <LKStateTransition fromState="*" toState="Locked"><elements/></LKStateTransition>
              <LKStateTransition fromState="Locked" toState="*"><elements/></LKStateTransition>
              <LKStateTransition fromState="*" toState="Sleep"><elements/></LKStateTransition>
              <LKStateTransition fromState="Sleep" toState="*"><elements/></LKStateTransition>
            </stateTransitions>
          </CALayer>
        </caml>
        """
    }

    /// Generates the Floating .ca main.caml that contains a video layer with frame keyframes.
    /// Replicates Apple's WWDC22 wallpaper structure EXACTLY (attribute names, ordering,
    /// values) — including all the transform.rotation.* attributes, zPosition="undefined"
    /// on parents, and consistent CALayer attributes on every frame sublayer.
    ///
    /// Spring duration is FIXED at 0.8s — that's the duration of the iOS slide-to-unlock
    /// gesture. Matching it makes the z-stack scrub feel native. Adaptive duration
    /// (= video duration) was a mistake: a 6 s video gave a 2 s spring → user perceives
    /// "rien ne se passe" because the slide finishes way before the spring scrub.
    static func videoMainCAML(
        layerName: String,
        width: Int,
        height: Int,
        frameCount: Int,
        fps: Int,
        duration: Double,
        framePrefix: String,
        frameExt: String,
        autoReverses: Bool,
        syncWithState: Bool
    ) -> String {
        let cx = width / 2
        let cy = height / 2
        let normalizedExt = frameExt.hasPrefix(".") ? frameExt : ".\(frameExt)"
        let durationStr = String(format: "%.6f", duration)
        let videoLayerId = "videoLayer_\(UUID().uuidString.prefix(16))"

        // Apple uses bounds slightly bigger than the wallpaper for parallax headroom
        // (~+1.745% on each axis, with 9-decimal precision).
        let scale = 1.01745846
        let videoBoundsW = Double(width) * scale
        let videoBoundsH = Double(height) * scale
        let videoBoundsStr = String(format: "0 0 %.14f %.14f", videoBoundsW, videoBoundsH)
        // Apple positions the frame layers at +3, +7 from the wallpaper centre.
        let videoFramePosX = cx + 3
        let videoFramePosY = cy + 7
        // Apple names the video layer "export_<UUID>.mov" (the source video name).
        // We pick the same UUID as the frame prefix for consistency.
        let videoLayerName: String = {
            if framePrefix.hasPrefix("export_") && framePrefix.hasSuffix("_") {
                let uuidPart = framePrefix
                    .dropFirst("export_".count)
                    .dropLast()
                return "export_\(uuidPart).mov"
            }
            return layerName
        }()

        // One sublayer per frame. zPosition follows triangular progression so the
        // unlock spring has something to interpolate between.
        var frameSublayers = ""
        for i in 0..<frameCount {
            let zPos = -(i * (i + 1)) / 2  // 0, -1, -3, -6, -10, -15, -21, …
            let path = "assets/\(framePrefix)\(i)\(normalizedExt)"
            // EVERY attribute Apple uses, in Apple's ordering.
            frameSublayers += """
                      <CALayer id="\(videoLayerId)_frame_\(i)" name="\(videoLayerId)_frame_\(i)" bounds="\(videoBoundsStr)" position="\(videoFramePosX) \(videoFramePosY)" zPosition="\(zPos)" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular">
                        <contents>
                          <CGImage src="\(escapeXML(path))"/>
                        </contents>
                      </CALayer>

            """
        }

        // State transitions: each frame sublayer's zPosition gets animated with a
        // CASpringAnimation. Spring duration HARDCODED at 0.8s = matches the iOS
        // slide-to-unlock gesture (8/10 of a second). Apple uses 0.8 across all
        // their wallpaper samples — it's the "right" duration for the gesture.
        let springDuration = "0.8"
        let transitionElements = (0..<frameCount).map { i in
            """
                  <LKStateTransitionElement targetId="\(videoLayerId)_frame_\(i)" key="zPosition">
                    <animation type="CASpringAnimation" damping="50" mass="2" stiffness="300" velocity="0" duration="\(springDuration)" fillMode="backwards" keyPath="zPosition" mica_autorecalculatesDuration="1"/>
                  </LKStateTransitionElement>
            """
        }.joined(separator: "\n")

        // Apple's video layer attribute order (left-to-right):
        // id, name, bounds, position, zPosition="undefined", opacity, transform.rotation.*,
        // transform, cornerRadius, allowsEdgeAntialiasing, allowsGroupOpacity, contentsFormat,
        // cornerCurve, then the caplay* attributes.
        let videoAttrs = """
        caplayKind="video" caplayFrameCount="\(frameCount)" caplayFPS="\(fps)" caplayDuration="\(durationStr)" caplayAutoReverses="\(autoReverses ? 1 : 0)" caplayFramePrefix="\(escapeXMLAttr(framePrefix))" caplayFrameExtension="\(escapeXMLAttr(normalizedExt))" caplaySyncWWithState="\(syncWithState ? 1 : 0)"
        """

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer id="__capRootLayer__" name="CAPlayground Root Layer" bounds="0 0 \(width) \(height)" position="\(cx) \(cy)" zPosition="undefined" geometryFlipped="0" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular">
            <sublayers>
              <CALayer id="rootInner" name="Root Layer" bounds="0 0 \(width) \(height)" position="\(cx) \(cy)" zPosition="undefined" geometryFlipped="0" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular">
                <sublayers>
                  <CALayer id="\(videoLayerId)" name="\(escapeXML(videoLayerName))" bounds="\(videoBoundsStr)" position="\(cx) \(cy)" zPosition="undefined" opacity="1" transform.rotation.z="0" transform.rotation.x="0" transform.rotation.y="0" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" cornerRadius="0" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" contentsFormat="RGBA8" cornerCurve="circular" \(videoAttrs)>
                    <sublayers>
        \(frameSublayers)            </sublayers>
                  </CALayer>
                </sublayers>
              </CALayer>
            </sublayers>
            <states>
              <LKState name="Locked"><elements/></LKState>
              <LKState name="Unlock"><elements/></LKState>
              <LKState name="Sleep"><elements/></LKState>
            </states>
            <stateTransitions>
              <LKStateTransition fromState="*" toState="Unlock">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
              <LKStateTransition fromState="Unlock" toState="*">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
              <LKStateTransition fromState="*" toState="Locked">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
              <LKStateTransition fromState="Locked" toState="*">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
              <LKStateTransition fromState="*" toState="Sleep">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
              <LKStateTransition fromState="Sleep" toState="*">
                <elements>
        \(transitionElements)
                </elements>
              </LKStateTransition>
            </stateTransitions>
          </CALayer>
        </caml>
        """
    }

    static func wallpaperPlistXML(
        identifier: String,
        name: String,
        backgroundCAName: String,
        floatingCAName: String,
        foregroundCAName: String
    ) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>assets</key>
        \t<dict>
        \t\t<key>lockAndHome</key>
        \t\t<dict>
        \t\t\t<key>default</key>
        \t\t\t<dict>
        \t\t\t\t<key>backgroundAnimationFileName</key>
        \t\t\t\t<string>\(escapeXML(backgroundCAName))</string>
        \t\t\t\t<key>floatingAnimationFileNameKey</key>
        \t\t\t\t<string>\(escapeXML(floatingCAName))</string>
        \t\t\t\t<key>foregroundAnimationFileName</key>
        \t\t\t\t<string>\(escapeXML(foregroundCAName))</string>
        \t\t\t\t<key>name</key>
        \t\t\t\t<string>\(escapeXML(name))</string>
        \t\t\t\t<key>identifier</key>
        \t\t\t\t<integer>7400</integer>
        \t\t\t\t<key>type</key>
        \t\t\t\t<string>LayeredAnimation</string>
        \t\t\t</dict>
        \t\t</dict>
        \t</dict>
        \t<key>family</key>
        \t<string>WWDC22</string>
        \t<key>logicalScreenClass</key>
        \t<string>390w-844h@3x~iphone</string>
        \t<key>appearanceAware</key>
        \t<false/>
        \t<key>identifier</key>
        \t<integer>7400</integer>
        \t<key>version</key>
        \t<integer>1</integer>
        \t<key>name</key>
        \t<string>\(escapeXML(name))</string>
        </dict>
        </plist>
        """
    }

    private static func escapeXML(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        return out
    }

    private static func escapeXMLAttr(_ s: String) -> String {
        var out = escapeXML(s)
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&apos;")
        return out
    }
}
