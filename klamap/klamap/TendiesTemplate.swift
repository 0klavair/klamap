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
        let stateBlock = standardStateBlock()
        return """
        <?xml version="1.0" encoding="UTF-8"?>

        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" geometryFlipped="1" hidden="0" name="Root Layer" position="\(cx) \(cy)">
            <sublayers>
              <CALayer id="\(layerName)Layer" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" name="\(escapeXML(layerName))" position="\(cx) \(cy)"/>
            </sublayers>
            <scriptComponents/>
        \(stateBlock)
          </CALayer>
        </caml>
        """
    }

    /// Generates the Floating .ca main.caml that contains a video layer with frame keyframes.
    /// Replicates Apple's WWDC22 wallpaper structure exactly:
    /// - One CALayer sublayer PER FRAME, each with its own zPosition (triangular: 0, -1, -3, -6, -10…)
    /// - Animation driven by stateTransitions on zPosition with CASpringAnimation
    /// - This is what makes caplaySyncWWithState actually work — the slide-to-unlock
    ///   gesture interpolates the spring animation, scrubbing through the frames
    ///   by changing which one is on top of the z-stack
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
        let videoLayerId = "videoLayer"

        // Apple uses slightly larger video bounds than the wallpaper (≈ 1.017× extra
        // for parallax headroom) and offsets position by +3pt in both axes.
        let videoBoundsW = Double(width) * 1.0174
        let videoBoundsH = Double(height) * 1.0174
        let videoBoundsStr = String(format: "0 0 %.10f %.10f", videoBoundsW, videoBoundsH)
        let videoPosX = cx + 3
        let videoPosY = cy + 7

        // One sublayer per frame. zPosition follows triangular progression so the
        // unlock spring has something to interpolate between.
        var frameSublayers = ""
        for i in 0..<frameCount {
            let zPos = -(i * (i + 1)) / 2  // 0, -1, -3, -6, -10, -15, -21, …
            let path = "assets/\(framePrefix)\(i)\(normalizedExt)"
            frameSublayers += """
                      <CALayer id="\(videoLayerId)_frame_\(i)" name="\(videoLayerId)_frame_\(i)" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="\(videoBoundsStr)" contentsFormat="RGBA8" cornerCurve="circular" opacity="1" position="\(videoPosX) \(videoPosY)" zPosition="\(zPos)">
                        <contents>
                          <CGImage src="\(escapeXML(path))"/>
                        </contents>
                      </CALayer>

            """
        }

        // State transitions: each frame sublayer's zPosition gets animated with a
        // CASpringAnimation when the lock-screen state changes. The slide gesture
        // drives the spring's progress, scrubbing through frames.
        //
        // Spring duration is now ADAPTIVE: it tracks the video duration so the
        // slide-to-unlock gesture covers the full animation. With more frames
        // (higher fps × same duration) the user gets a smoother z-stack scrub
        // because there are more interpolation steps.
        // Capped at [0.4, 2.0] so very short / very long wallpapers still feel
        // natural during the unlock gesture.
        let springDuration = max(0.4, min(2.0, duration))
        let springDurationStr = String(format: "%.6f", springDuration)
        let transitionElements = (0..<frameCount).map { i in
            """
                  <LKStateTransitionElement targetId="\(videoLayerId)_frame_\(i)" key="zPosition">
                    <animation type="CASpringAnimation" damping="50" mass="2" stiffness="300" velocity="0" duration="\(springDurationStr)" fillMode="backwards" keyPath="zPosition" mica_autorecalculatesDuration="1"/>
                  </LKStateTransitionElement>
            """
        }.joined(separator: "\n")

        let videoAttrs = """
        caplayKind="video" caplayFrameCount="\(frameCount)" caplayFPS="\(fps)" caplayDuration="\(durationStr)" caplayAutoReverses="\(autoReverses ? 1 : 0)" caplayFramePrefix="\(escapeXMLAttr(framePrefix))" caplayFrameExtension="\(escapeXMLAttr(normalizedExt))" caplaySyncWWithState="\(syncWithState ? 1 : 0)"
        """

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer id="__capRootLayer__" name="CAPlayground Root Layer" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" geometryFlipped="0" opacity="1" position="\(cx) \(cy)" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)">
            <sublayers>
              <CALayer id="rootInner" name="Root Layer" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" geometryFlipped="0" opacity="1" position="\(cx) \(cy)" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)">
                <sublayers>
                  <CALayer id="\(videoLayerId)" name="\(escapeXML(layerName))" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="\(videoBoundsStr)" contentsFormat="RGBA8" cornerCurve="circular" cornerRadius="0" opacity="1" position="\(cx) \(cy)" transform="rotate(0deg) rotate(0deg, 0, 1, 0) rotate(0deg, 1, 0, 0)" \(videoAttrs)>
                    <sublayers>
        \(frameSublayers)            </sublayers>
                  </CALayer>
                </sublayers>
              </CALayer>
            </sublayers>
            <states>
              <LKState name="Locked"><elements></elements></LKState>
              <LKState name="Unlock"><elements></elements></LKState>
              <LKState name="Sleep"><elements></elements></LKState>
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

    private static func standardStateBlock() -> String {
        return """
            <states>
              <LKState name="Locked">
        \t<elements>
        \t</elements>
              </LKState>
              <LKState name="Unlock">
        \t<elements>
        \t</elements>
              </LKState>
              <LKState name="Sleep">
        \t<elements>
        \t</elements>
              </LKState>
            </states>
            <stateTransitions>
              <LKStateTransition fromState="*" toState="Unlock">
        \t<elements>
        \t</elements>
              </LKStateTransition>
              <LKStateTransition fromState="Unlock" toState="*">
        \t<elements>
        \t</elements>
              </LKStateTransition>
              <LKStateTransition fromState="*" toState="Locked">
        \t<elements>
        \t</elements>
              </LKStateTransition>
              <LKStateTransition fromState="Locked" toState="*">
        \t<elements>
        \t</elements>
              </LKStateTransition>
              <LKStateTransition fromState="*" toState="Sleep">
        \t<elements>
        \t</elements>
              </LKStateTransition>
              <LKStateTransition fromState="Sleep" toState="*">
        \t<elements>
        \t</elements>
              </LKStateTransition>
            </stateTransitions>
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
        \t\t\t\t<key>floatingAnimationFileName</key>
        \t\t\t\t<string>\(escapeXML(floatingCAName))</string>
        \t\t\t\t<key>foregroundAnimationFileName</key>
        \t\t\t\t<string>\(escapeXML(foregroundCAName))</string>
        \t\t\t</dict>
        \t\t</dict>
        \t</dict>
        \t<key>family</key>
        \t<integer>1</integer>
        \t<key>logicalScreenClass</key>
        \t<string>iphone3x-844h</string>
        \t<key>appearanceAware</key>
        \t<false/>
        \t<key>identifier</key>
        \t<string>\(escapeXML(identifier))</string>
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
