import Cocoa
import cef

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var simpleHandler: SimpleHandler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createApplication()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let handler = simpleHandler, !handler.isClosing() {
            handler.showMainWindow()
        }
        return false
    }

    func createApplication() {
        Bundle.main.loadNibNamed("MainMenu", owner: NSApp, topLevelObjects: nil)
        NSApp.delegate = self
    }

    func tryToTerminateApplication(_ app: NSApplication) {
        if let handler = simpleHandler, !handler.isClosing() {
            handler.closeAllBrowsers(false)
        }
    }
}

class SimpleApplication: NSApplication, CefAppProtocol {
    private var handlingSendEvent = false

    override func sendEvent(_ event: NSEvent) {
        let _ = CefScopedSendingEvent()
        super.sendEvent(event)
    }

    override func terminate(_ sender: Any?) {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.tryToTerminateApplication(self)
        }
    }

    func isHandlingSendEvent() -> Bool {
        return handlingSendEvent
    }

    func setHandlingSendEvent(_ handlingSendEvent: Bool) {
        self.handlingSendEvent = handlingSendEvent
    }
}

func main(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Int32 {
    let libraryLoader = CefScopedLibraryLoader()
    if !libraryLoader.loadInMain() {
        return 1
    }

    let mainArgs = CefMainArgs(argc: argc, argv: argv)

    autoreleasepool {
        SimpleApplication.shared

        assert(NSApp is SimpleApplication)

        let commandLine = CefCommandLine.createCommandLine()
        commandLine.initFromArgv(argc: argc, argv: argv)

        var settings = CefSettings()
#if !CEF_USE_SANDBOX
        settings.no_sandbox = true
#endif

        let app = SimpleApp()
        if !CefInitialize(mainArgs, settings, app, nil) {
            return CefGetExitCode()
        }

        let delegate = AppDelegate()
        NSApp.delegate = delegate

        delegate.performSelector(onMainThread: #selector(AppDelegate.createApplication), with: nil, waitUntilDone: false)

        CefRunMessageLoop()
        CefShutdown()
    }

    return 0
}