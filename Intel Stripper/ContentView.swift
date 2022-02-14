//
//  ContentView.swift
//  Intel Stripper
//
//  Created by Alexander Makhov on 14.02.2022.
//

import SwiftUI
import Foundation
import FileProvider

@discardableResult
func shell(_ command: String) -> (String?, Int32) {
  let task = Process()

  task.launchPath = "/bin/zsh"
  task.arguments = ["-c", command]

  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = pipe
  task.launch()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8)
  task.waitUntilExit()
  return (output, task.terminationStatus)
}

func showOpenPanel() -> URL? {
  let openPanel = NSOpenPanel()
  openPanel.allowedContentTypes = [.applicationBundle]
  openPanel.allowsMultipleSelection = false
  openPanel.canChooseDirectories = false
  openPanel.canChooseFiles = true
  openPanel.directoryURL = URL(fileURLWithPath: "/Applications/")
  openPanel.prompt = "Select Universal Application"
  let response = openPanel.runModal()
  return response == .OK ? openPanel.url : nil
}

struct ContentView: View {

  var title: String = "Intel Stripper"

  var body: some View {
    Text("Please select desired application. Warning! Apps may break.")
      .multilineTextAlignment(.center)
      .frame(width: 200, height: 80, alignment: .center)
      .padding(10.0)

    Button(action: {

      let destinationURL = showOpenPanel()?.absoluteURL

      print(destinationURL?.path as Any)
      let stringPath = destinationURL?.path
      let appName = (stringPath! as NSString).lastPathComponent
      print("App Name: ", appName)

      var temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

      do {
        temporaryDirectoryURL = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: destinationURL, create: true)
      } catch {

      }

      let temporaryFileURL =
      temporaryDirectoryURL.appendingPathComponent(appName)
      print(temporaryFileURL.path)

      print( shell("/usr/bin/ditto --rsrc --arch arm64 " + "\"" + stringPath! + "\" " + "\"" + temporaryFileURL.path + "\"") )

      print( shell("sudo rm -rf " + "\"" + stringPath! + "\"") )

      do {
        try FileManager.default.moveItem(at: temporaryFileURL, to: destinationURL!)
        // try FileManager.default.removeItem(at: temporaryFileURL)
      } catch { print ("replace error") }


    }) {
      Text("Select Application")
    }
    .frame(alignment: .center)
    .padding(10.0)
  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
