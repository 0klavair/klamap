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
    /// The video layer references frames stored in `assets/<framePrefix><i><frameExt>`.
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
        let stateBlock = standardStateBlock()

        let firstFrame = "assets/\(framePrefix)0\(normalizedExt)"

        var contentsBlock = ""
        var animationsBlock = ""

        if frameCount > 0 {
            contentsBlock = """
                  <contents type="CGImage" src="\(escapeXML(firstFrame))"/>
            """
        }

        if frameCount > 1 && !syncWithState {
            var values = ""
            for i in 0..<frameCount {
                let path = "assets/\(framePrefix)\(i)\(normalizedExt)"
                values += "            <CGImage src=\"\(escapeXML(path))\"/>\n"
            }
            animationsBlock = """
                  <animations>
                    <animation type="CAKeyframeAnimation" calculationMode="linear" keyPath="contents" beginTime="1e-100" duration="\(durationStr)" removedOnCompletion="0" repeatCount="inf" repeatDuration="0" speed="1" timeOffset="0" autoreverses="\(autoReverses ? 1 : 0)">
                      <values>
            \(values)          </values>
                    </animation>
                  </animations>
            """
        } else if frameCount > 1 && syncWithState {
            // Sync mode: contents is driven by a single keyframe array, but state machine
            // re-targets the time. iOS interprets caplaySyncWWithState=1 to scrub the animation
            // based on lock-screen unlock progress.
            var values = ""
            for i in 0..<frameCount {
                let path = "assets/\(framePrefix)\(i)\(normalizedExt)"
                values += "            <CGImage src=\"\(escapeXML(path))\"/>\n"
            }
            animationsBlock = """
                  <animations>
                    <animation type="CAKeyframeAnimation" calculationMode="linear" keyPath="contents" beginTime="1e-100" duration="\(durationStr)" removedOnCompletion="0" repeatCount="inf" repeatDuration="0" speed="1" timeOffset="0" autoreverses="\(autoReverses ? 1 : 0)">
                      <values>
            \(values)          </values>
                    </animation>
                  </animations>
            """
        }

        let videoAttrs = """
        caplayKind="video" caplayFrameCount="\(frameCount)" caplayFPS="\(fps)" caplayDuration="\(durationStr)" caplayAutoReverses="\(autoReverses ? 1 : 0)" caplayFramePrefix="\(escapeXMLAttr(framePrefix))" caplayFrameExtension="\(escapeXMLAttr(normalizedExt))" caplaySyncWWithState="\(syncWithState ? 1 : 0)" caplaySyncStateFrameMode="{}"
        """

        return """
        <?xml version="1.0" encoding="UTF-8"?>

        <caml xmlns="http://www.apple.com/CoreAnimation/1.0">
          <CALayer allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" geometryFlipped="1" hidden="0" name="Root Layer" position="\(cx) \(cy)">
            <sublayers>
              <CALayer id="videoLayer" allowsEdgeAntialiasing="1" allowsGroupOpacity="1" bounds="0 0 \(width) \(height)" contentsFormat="RGBA8" cornerCurve="circular" name="\(escapeXML(layerName))" position="\(cx) \(cy)" \(videoAttrs)>
        \(contentsBlock)
        \(animationsBlock)
              </CALayer>
            </sublayers>
            <scriptComponents/>
        \(stateBlock)
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
