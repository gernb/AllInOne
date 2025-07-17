import ElementaryDOM
import JavaScriptEventLoop

JavaScriptEventLoop.installGlobalExecutor()

MainView().mount(in: .body)
