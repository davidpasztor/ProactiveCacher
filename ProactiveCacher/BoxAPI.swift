//
//  BoxAPI.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 15/01/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation
import JWT

class BoxAPI {
    private let clientId = "fr23hr7q5fututlb7028kc7ecqbeuywu"
    private let clientSecret = "4dtJmnHrHlm1KnuOfBlEPQyFufr2irpf"
    let enterpriseId = "37248674"
    
    static let shared = BoxAPI()
    private init(){}
    
    func generateJWTToken(isEnterprise:Bool = false,userId:String)->String?{
        let payload:[String:Any] = ["iss":"fr23hr7q5fututlb7028kc7ecqbeuywu","sub":userId,"aud":"https://api.box.com/oauth2/token","exp":Int(Date().addingTimeInterval(59).timeIntervalSince1970),"jti":UUID().uuidString,"box_sub_type": isEnterprise ? "enterprise":"user"]
        let headers = ["alg":"RS256","typ":"jwt","kid":"hs2yr1uc"]
        
        //let publicKeyData = try! Data(contentsOf: Bundle.main.url(forResource: "publicKey", withExtension: "pem")!)
        //let privateKeyData = try! Data(contentsOf: Bundle.main.url(forResource: "privateKeyCert", withExtension: "p12")!)
        //let privateKeyData = try! Data(contentsOf: Bundle.main.url(forResource: "privateKey", withExtension: "pem")!)
        
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
        let publicKey = try? JWTCryptoKeyPublic(pemEncoded: publicKeyString, parameters: nil)
        let privateKey = try? JWTCryptoKeyPrivate(pemEncoded: privateKeyString, parameters: nil)
        let signDataHolder = JWTAlgorithmRSFamilyDataHolder().signKey(privateKey)?.secretData(privateKeyString.data(using: .utf8)!)?.algorithmName(JWTAlgorithmNameRS256)
        //let signDataHolder = JWTAlgorithmRSFamilyDataHolder().keyExtractorType(JWTCryptoKeyExtractor.privateKeyWithPEMBase64().type)?.algorithmName(JWTAlgorithmNameRS256)?.secretData(privateKeyData)
        
        //let signDataHolder = JWTAlgorithmRSFamilyDataHolder().keyExtractorType(JWTCryptoKeyExtractor.privateKeyInP12().type)?.privateKeyCertificatePassphrase(passphraseForPrivateKey)?.algorithmName(JWTAlgorithmNameRS256)?.secretData(privateKeyData)
        //let verifyDataHolder = JWTAlgorithmRSFamilyDataHolder().keyExtractorType(JWTCryptoKeyExtractor.publicKeyWithPEMBase64().type)?.algorithmName(JWTAlgorithmNameRS256)?.secretData(publicKeyData)
        let verifyDataHolder = JWTAlgorithmRSFamilyDataHolder().signKey(publicKey)?.secretData(publicKeyString.data(using: .utf8)!)?.algorithmName(JWTAlgorithmNameRS256)
        let signBuilder = JWTEncodingBuilder.encodePayload(payload).headers(headers)?.addHolder(signDataHolder)
        let signResult = signBuilder?.result
        if let token = signResult?.successResult?.encoded {
            print("Builder 3.0 token: \(token)")
            let verifyResult = JWTDecodingBuilder.decodeMessage(token).addHolder(verifyDataHolder)?.result
            if verifyResult?.successResult != nil, let result = verifyResult?.successResult.encoded {
                print("Verification successful, result: \(result)")
            } else {
                print("Verification error: \(verifyResult?.errorResult.error as Any)")
            }
            return token
        }
        if signResult?.errorResult != nil, let error = signResult?.errorResult.error {
            print("Builder 3.0 error: \(error)")
        }
        return nil
        
        /*
        let builder = JWTBuilder.encodePayload(payload).headers(headers)?.secretData(privateKeyData)?.privateKeyCertificatePassphrase(passphraseForPrivateKey)?.algorithmName(JWTAlgorithmNameRS256)
        //let builder = JWTBuilder.encode(claims).headers(headers)?.secretData(privateKeyData)?.privateKeyCertificatePassphrase(passphraseForPrivateKey)?.algorithmName(JWTAlgorithmNameRS256)
        let token = builder?.encode
        print("Builder error: ",builder?.jwtError ?? "none")
        print("JWT token: \(token ?? "no token")")
        return token
        */
    }
    
    func getOAuth2Token(using jwtToken:String, completion: @escaping (_ oAuthToken:String?, _ error:Error?)->()){
        let oAuthUrl = URL(string: "https://api.box.com/oauth2/token")!
        var oAuthTokenrequest = URLRequest(url: oAuthUrl)
        oAuthTokenrequest.httpMethod = "POST"
        oAuthTokenrequest.httpBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&client_id=\(clientId)&client_secret=\(clientSecret)&assertion=\(jwtToken)".data(using: .utf8)
        URLSession.shared.dataTask(with: oAuthTokenrequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print("Error retrieving OAuth2 token: \(error!)")
                completion(nil,error)
                return
            }
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String:Any] else {
                print("Response is not JSON Dictionary")
                completion(nil, NSError(domain: "Response is not JSON Dictionary", code: 1))
                return
            }
            print(json)
        }).resume()
    }
}
