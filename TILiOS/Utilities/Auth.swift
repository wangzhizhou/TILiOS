/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit

enum AuthResult {
  case success
  case failure
}

class Auth: NSObject, URLSessionDelegate {
  static let defaultsKey = "TIL-API-KEY"
  let defaults = UserDefaults.standard
  
  var token: String? {
    get {
      return defaults.string(forKey: Auth.defaultsKey)
    }
    set {
      defaults.set(newValue, forKey: Auth.defaultsKey)
    }
  }
  
  func logout() {
    self.token = nil
    DispatchQueue.main.async {
      guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        return
      }
      let rootController = UIStoryboard(name: "Login", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginNavigation")
      appDelegate.window?.rootViewController = rootController
    }
  }
  
  func login(
    username: String,
    password: String,
    completion: @escaping (AuthResult) -> Void) {
    let path = "https://til.jokerhub.cn/api/users/login"
    guard let url = URL(string: path) else {
      fatalError()
    }
    guard let loginString = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() else {
      fatalError()
    }
    
    var loginRequest = URLRequest(url: url)
    loginRequest.addValue("Basic \(loginString)", forHTTPHeaderField: "Authorization")
    loginRequest.httpMethod = "POST"
    
    let dataTask = self.session().dataTask(with: loginRequest) {
      (data, response, _) in
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200,
        let jsonData = data else {
          completion(.failure)
          return
      }
      
      do {
        let token = try JSONDecoder().decode(Token.self, from: jsonData)
        self.token = token.token
        completion(.success)
      } catch {
        completion(.failure)
      }
    }
    dataTask.resume()
  }
  
  func session() -> URLSession {
    let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    return session
  }
  
  //https所有证书都验证通过
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
    completionHandler(.useCredential, credential)
    
  }
}
