//
//  BoxFolder.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 08/02/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

struct BoxFolder:Decodable{
    let name:String
    let items:[BoxItemMetadata]
    let id:String
    let size:Int
    
    private enum RootKeys: String, CodingKey {
        case name, id, size
        case items = "item_collection"
    }
    
    private enum ItemKeys: String, CodingKey {
        case entries
    }
    
    init(from decoder:Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        self.name = try root.decode(String.self, forKey: .name)
        self.id = try root.decode(String.self, forKey: .id)
        self.size = try root.decode(Int.self, forKey: .size)
        let itemsContainer = try root.nestedContainer(keyedBy: ItemKeys.self, forKey: .items)
        self.items = try itemsContainer.decode([BoxItemMetadata].self, forKey: .entries)
    }
}

struct BoxItemMetadata:Decodable{
    let name:String
    let id:String
}
