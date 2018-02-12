//
//  BoxAPI.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 15/01/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation
import JWT
import BoxContentSDK

class BoxAPI: NSObject {    //Need to inherit from NSObject to be able to conform to BOXAPIAccessTokenDelegate
    private let clientId = "fr23hr7q5fututlb7028kc7ecqbeuywu"
    private let clientSecret = "4dtJmnHrHlm1KnuOfBlEPQyFufr2irpf"
    private let enterpriseId = "37248674"
    let sharedUserId = "3183511991"
    //Need to set client to a specific user's client
    let client = BOXContentClient(forUser: BOXUser(userID: "3183511991", name: "Shared", login: "AppUser_523282_bweXCHyogt@boxdevedition.com")) //BOXContentClient.default()
    var accessToken:String?
    private let sharedFolderID = "46350020304"
    
    static let shared = BoxAPI()
    private override init(){
        super.init()
        //Needed for BoxContentSDK to be able to use the custom OAuth methods
        client?.accessTokenDelegate = self
    }
    
    func generateJWTToken(isEnterprise:Bool = false,userId:String)->String?{
        let payload:[String:Any] = ["iss":"fr23hr7q5fututlb7028kc7ecqbeuywu","sub":userId,"aud":"https://api.box.com/oauth2/token","exp":Int(Date().addingTimeInterval(59).timeIntervalSince1970),"jti":UUID().uuidString,"box_sub_type": isEnterprise ? "enterprise":"user"]
        let headers = ["alg":"RS256","typ":"jwt","kid":"hs2yr1uc"]
        /*
        let publicKeyString = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwjhaJdHIpvuH6wpOIooa
OqO5+eEPoFtD6mJsO24uqxZmvTahnY6ntYG6CXfz5MQD/K3IhhGdJq1SYQDFzS4a
RYpTKY+jBBLIfkAS5iD6D9Ylz8tuUGx6gfZqYWYFt7zMT6kD06LERctsSVM9ZLIb
rEq4MaFY7JnC80tovCUMrscRBUgpQGZ0+bs2RCJO1RzHw7xW2c1e30KxlWw2mwkh
Q7PlJbehVKIv45cr7Dd13tU0WtLsAYz415vql5EkZlv2vA8s9yRhEvkOqs2pVgaF
VNGLa2kBGeEH5AgpzTapDEARNHk7ct0cVLFsICHyr743P7DH2jECIie57k+NkpWP
7wIDAQAB
-----END PUBLIC KEY-----
"""
         */
        let privateKeyString = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAwjhaJdHIpvuH6wpOIooaOqO5+eEPoFtD6mJsO24uqxZmvTah
nY6ntYG6CXfz5MQD/K3IhhGdJq1SYQDFzS4aRYpTKY+jBBLIfkAS5iD6D9Ylz8tu
UGx6gfZqYWYFt7zMT6kD06LERctsSVM9ZLIbrEq4MaFY7JnC80tovCUMrscRBUgp
QGZ0+bs2RCJO1RzHw7xW2c1e30KxlWw2mwkhQ7PlJbehVKIv45cr7Dd13tU0WtLs
AYz415vql5EkZlv2vA8s9yRhEvkOqs2pVgaFVNGLa2kBGeEH5AgpzTapDEARNHk7
ct0cVLFsICHyr743P7DH2jECIie57k+NkpWP7wIDAQABAoIBAQDA47akWPUu4iDb
DiELrJzgIDtUMHGUkQ+ieJ2FaKhwwo7G3Lsl/8gQPAbH4JoZWZOcH/xHKrco8noe
XOYWIPN2nSp63GzKXt1AheI/LAEuOUDUXvXwacxBxrlggjKriJZhhzqFteG4b4/c
Qw92Mm3Jb2v/3n6yfQNhHkOmmCVAbjkPy+imC9bfYU62xe+3WNZUWkROz9koVJbQ
U2oZFDJqTOWNjuSWNPCPTizsiqnCxSVNRGTCHE0YzX7XFOdwVXIP+HYaZGGN6YM+
VD8JGl1F4rJlnslMOkuF+Gw2/mVhuuY1ob6wigNYuT7RGVxlN6TsgMskWJLUn03C
Z5UJXpABAoGBAOaW7GYExWOx3KmcJYTdaWRxsLGXWXFEXHTc0zn/S8wh73dafOla
OHISk+9UO43cZnNBh8/ZkTyH0D2JwUnDAj8bdEmh1GyTuzq4iLis5kv9sUY+Y878
HqNKeoH2ZqFERD88KLy67SRwzMHy37kNRZ34LI9RL7ZCW/jpsanujiTPAoGBANef
bKhaotd3ea4KVDyC3mDglHwRSbvLjaKF1ezToNfH59vxiU9ePuwdyt23OwAfMi8H
QdntlHhj1CQ5yRA7583iIwuIz5fq7zk7resB4iZVnahSNRcDUIWS/jqoVBJ6lBR8
L1BUeTQqo+FDUKVgcQHaX4CiCWLa0Oemg96qXurhAoGBAM25fPOP8iN9/eb8vqSJ
fYv1urTW2R+q4+oHUhR+Zrua0zDi9Gqk6ZMsa/usZO2t42GU53xTGbatXOZqTp5m
c0ymS9udnA26x+Id3S0WZOkLT+vhod57JUJ+Ikps8SeT5mecXqPzCbvnP2cSLvPE
mYXUcrzyq+Sp07CBntaDVSIVAoGBAMUCvVz1s2P7ngoPFfhT+qu5hvH1OdGEotyk
PFou4v9Ff+vOPQ9vpT5H2lvKVvY9irS9hMWB9e4qCGMxCSz0D1BmFm8ricHcvsck
aDwZdHBiObLZqfhk5uWk8PTXaDmaFkLBVNmo1TV84E+qGb2A6MAwrqHxa3IPTGDc
HBEOybsBAoGADZFGZ3zxqIpvMdzyF0u9j28lmPPIPrHrcsnIq8oS/RjFOgUH8oD2
GbYcXgSy0SFFnzm/mf9yBqHuyQ/7DJlDt/Srge+7FIYXg5+nlzq9E64kV1/c8jnc
Uh0GL/z1qN6g2yAridgPyvjofcayOCsxibfAG3lnD3aetP/4ED0+hHY=
-----END RSA PRIVATE KEY-----
"""
        //let publicKey = try? JWTCryptoKeyPublic(pemEncoded: publicKeyString, parameters: nil)
        let privateKey = try? JWTCryptoKeyPrivate(pemEncoded: privateKeyString, parameters: nil)
        let signDataHolder = JWTAlgorithmRSFamilyDataHolder().signKey(privateKey)?.secretData(privateKeyString.data(using: .utf8)!)?.algorithmName(JWTAlgorithmNameRS256)
        //let verifyDataHolder = JWTAlgorithmRSFamilyDataHolder().signKey(publicKey)?.secretData(publicKeyString.data(using: .utf8)!)?.algorithmName(JWTAlgorithmNameRS256)
        let signBuilder = JWTEncodingBuilder.encodePayload(payload).headers(headers)?.addHolder(signDataHolder)
        let signResult = signBuilder?.result
        if let token = signResult?.successResult?.encoded {
            //print("Builder 3.0 token: \(token)")
            /*
            let verifyResult = JWTDecodingBuilder.decodeMessage(token).addHolder(verifyDataHolder)?.result
            if verifyResult?.successResult != nil, let result = verifyResult?.successResult.encoded {
                print("Verification successful, result: \(result)")
            } else {
                print("Verification error: \(verifyResult?.errorResult.error as Any)")
            }
            */
            return token
        }
        if signResult?.errorResult != nil, let error = signResult?.errorResult.error {
            print("Builder 3.0 error: \(error)")
        }
        return nil
        
    }
    
    /**
     Authorize the app asynchronously with the Box Content API using OAuth2 and a JWT token
     
     - Returns:
     Void, since the function is asynchronous, but uses a completion handler to return the OAuth token or an error
     
     - Parameters:
        - jwtToken: JWT to use for the authentication
        - completion: completion handler returning the OAuth token as a String along with its expiration date or an error if the authorization wasn't successful
            - oAuthToken: the OAuth2 token as a String
            - expirationDate: the expiration date of the token as a Date
            - error: Error if the authorization request wasn't successful
     - Important:
        This is an asynchronous function
     - Preconditions:
     Valid JWT token needed for the authorization, the token can be generated by calling `generateJWTToken`
    */
    func getOAuth2Token(using jwtToken:String, completion: @escaping (_ oAuthToken:String?,_ expirationDate:Date?, _ error:Error?)->()){
        let oAuthUrl = URL(string: "https://api.box.com/oauth2/token")!
        var oAuthTokenrequest = URLRequest(url: oAuthUrl)
        oAuthTokenrequest.httpMethod = "POST"
        oAuthTokenrequest.httpBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&client_id=\(clientId)&client_secret=\(clientSecret)&assertion=\(jwtToken)".data(using: .utf8)
        URLSession.shared.dataTask(with: oAuthTokenrequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                completion(nil,nil,BoxErrors.OAuth2GenericError(error!)); return
            }
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String:Any] else {
                completion(nil,nil,BoxErrors.JSONResponse); return
            }
            guard let token = json["access_token"] as? String, let expiresInSeconds = json["expires_in"] as? Int else {
                completion(nil,nil,BoxErrors.NoOAuthToken); return
            }
            completion(token, Date().addingSeconds(expiresInSeconds), nil)
        }).resume()
    }
    
    func getFolderInfo(for folderId:String="46350020304", completion: @escaping ([BoxItemMetadata]?,Error?)->()){
        guard let folderInfoUrl = URL(string: "https://api.box.com/2.0/folders/\(folderId)") else {
            completion(nil,BoxErrors.IncorrectURL("https://api.box.com/2.0/folders/\(folderId)")); return
        }
        var folderInfoRequest = URLRequest(url: folderInfoUrl)
        guard let accessToken = self.accessToken else {completion(nil,BoxErrors.NoOAuthToken);return}
        folderInfoRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: folderInfoRequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, BoxErrors.GenericError(error!)); return
            }
            do {
                let items = try JSONDecoder().decode(BoxFolder.self, from: data).items
                completion(items, nil)
            } catch {
                completion(nil,BoxErrors.GenericError(error))
            }
        }).resume()
    }
    
    func createThumbnail(for fileId:String, completion: @escaping (UIImage?,Error?)->()){
        let urlString = "https://api.box.com/2.0/files/\(fileId)/thumbnail.jpg?min_height=256&min_width=256"
        guard let getThumbnailUrl = URL(string: urlString) else {
            completion(nil, BoxErrors.IncorrectURL(urlString)); return
        }
        var getThumbnailRequest = URLRequest(url: getThumbnailUrl)
        guard let accessToken = self.accessToken else {completion(nil,BoxErrors.NoOAuthToken);return}
        getThumbnailRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: getThumbnailRequest, completionHandler: { data, response, error in
            guard let data = data else {
                completion(nil, error); return
            }
            guard let thumbnail = UIImage(data: data) else {
                completion(nil,BoxErrors.CustomMessage("Couldn't get thumnail image")); return
            }
            completion(thumbnail,nil)
        }).resume()
    }
    
    func getEmbedLink(for fileId:String, completion: @escaping(URL?,Error?)->()){
        let urlString = "https://api.box.com/2.0/files/\(fileId)?fields=expiring_embed_link"
        guard let getEmbedLinkUrl = URL(string: urlString) else {
            completion(nil, BoxErrors.IncorrectURL(urlString)); return
        }
        var getEmbedLinkRequest = URLRequest(url: getEmbedLinkUrl)
        guard let accessToken = self.accessToken else {completion(nil,BoxErrors.NoOAuthToken);return}
        getEmbedLinkRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: getEmbedLinkRequest, completionHandler: { data, response, error in
            guard let data = data else {
                completion(nil, error); return
            }
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String:Any], let embedUrlDictionary = jsonResponse["expiring_embed_link"] as? [String:String], let embedUrlString = embedUrlDictionary["url"] else {
                    completion(nil,BoxErrors.JSONResponse); return
                }
                guard let embedUrl = URL(string: embedUrlString) else {
                    completion(nil,BoxErrors.IncorrectURL(embedUrlString)); return
                }
                completion(embedUrl,nil)
            } catch {
                completion(nil,error)
            }
        }).resume()
    }
    
    func downloadFile(with fileMetadata:BoxItemMetadata, completion: @escaping(URL?,Error?)->()){
        let urlString = "https://api.box.com/2.0/files/\(fileMetadata.id)/content?fields=download_url"
        guard let getDownloadLinkUrl = URL(string: urlString) else {
            completion(nil, BoxErrors.IncorrectURL(urlString)); return
        }
        var getDownloadLinkRequest = URLRequest(url: getDownloadLinkUrl)
        guard let accessToken = self.accessToken else {completion(nil,BoxErrors.NoOAuthToken);return}
        getDownloadLinkRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: getDownloadLinkRequest, completionHandler: { data, response, error in
            //Data is the raw file itself
            guard let rawFileData = data, error == nil else {
                completion(nil, error); return
            }
            do {
                let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileUrl = documentsDirectory.appendingPathComponent("\(fileMetadata.name).mp4")
                try rawFileData.write(to: fileUrl)
                completion(fileUrl,error)
            } catch {
                completion(nil,error)
            }
        }).resume()
    }
}

enum BoxErrors: Error {
    case OAuth2GenericError(Error)
    case JSONResponse
    case NoOAuthToken
    case GenericError(Error)
    case CustomMessage(String)
    case IncorrectURL(String)
}

extension Date {
    func addingSeconds(_ seconds:Int)->Date{
        return self.addingTimeInterval(TimeInterval(seconds))
    }
}

extension BoxAPI: BOXAPIAccessTokenDelegate {
    func fetchAccessToken(completion: ((String?, Date?, Error?) -> Void)!) {
        print("Fetching access token")
        if let jwtToken = BoxAPI.shared.generateJWTToken(isEnterprise: false, userId: BoxAPI.shared.sharedUserId) {
            BoxAPI.shared.getOAuth2Token(using: jwtToken, completion: { oAuthToken, expiryDate, error in
                completion(oAuthToken,expiryDate,error)
            })
        } else {
            completion(nil,nil,nil)
        }
    }
}
