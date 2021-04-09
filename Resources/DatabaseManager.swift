//
//  DatabaseManager.swift
//  MessengerApp
//
//  Created by Akdag on 30.03.2021.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
 
    
    static func safeEmail(emailAdress : String) -> String{
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}
extension DatabaseManager {
    public func getDataFor(path : String , completion : @escaping (Result<Any , Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: {  snapShot in
            guard let value = snapShot.value as? String else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
            
        })
    }
}
extension DatabaseManager {
    
    public func userExist(with email : String , completion : @escaping ((Bool)-> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        
        database.child(safeEmail ).observeSingleEvent(of: .value) { (snapshot) in
           
            guard snapshot.value as? [String:Any] != nil else {
                completion(false)
                return
            }
            completion(true )
        }
    }
    
    public func  insertUser(with user : ChatAppUser , completion :@escaping (Bool)-> Void){
        database.child(user.safeEmail).setValue([
            
            "first_Name" : user.firstName ,
            "last_Name" : user.lastName
            
        ], withCompletionBlock: { error , _ in
            guard error == nil else {
                completion(false)
                return
                
            }
            self.database.child("user").observeSingleEvent(of : .value) { (snapshot) in
                if var userCollection = snapshot.value as? [[String : String]] {
                    // kullanıcı kütüphanesi ekle
                    let newElement = [
                        "name" : user.firstName + " " + user.lastName,
                        "safeEmail" : user.safeEmail
                    ]
                    userCollection.append(newElement)
                    
                    self.database.child("user").setValue(userCollection) { (error, _) in
                        guard error == nil else{
                           completion(false)
                            return
                            
                        }
                        completion(true)
                    }
                }else{
                    // kullanıcı array ' i oluştur
                    let newCollection : [[String : String]] = [
                        [
                            "name" : user.firstName + " " + user.lastName,
                            "safeEmail" : user.safeEmail
                        ]
                        
                    ]
                    self.database.child("user").setValue(newCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                            
                        }
                        completion(true)
                    }
                }
            }
            
        })
    }
    func getAllUsers(completion : @escaping (Result<[[String:String]], Error>)-> Void ){
        database.child("user").observeSingleEvent(of: .value) { (snapShot) in
            guard let value = snapShot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
                
            }
            completion(.success(value))
        }
    }
    public enum DatabaseError : Error {
        case failedToFetch
    }
    
}
extension DatabaseManager {
    public func createNewConversation(with otherUserEmail : String ,name : String, firstMessage : Message , completion :@escaping (Bool)-> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              
              let currentName = UserDefaults.standard.value(forKey: "name") as? String  else {return}
        
       
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
       
        ref.observeSingleEvent(of: .value) {[weak self ] (snapShot) in
           
            guard var userNode = snapShot.value as? [String: Any] else {
                completion(false)
                print("kullanıcı bulunamadı")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            
            case .text(let messageText):
               message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversation : [String : Any] = [
                "id" : conversationID,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date" : dateString,
                    "message":message,
                    "is_read" : false
                    
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            // Update recipient conversaiton entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            if var conversations = userNode["conversations"] as? [[String:Any]]{
                
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode , withCompletionBlock: { [weak self] error, _  in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                   
                })
                
            }else{
                userNode["conversations"] = [
                
                newConversation
                ]
                ref.setValue(userNode , withCompletionBlock: {[weak self] error, _  in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishConversation(name: name  , conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                   
                })
            }
        }
    }
    private func finishConversation(name : String, conversationID : String , firstMessage : Message , completion : @escaping (Bool) -> Void){
        var message = ""
        switch firstMessage.kind{
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
      
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
       
       
        let collectionMessage : [String : Any] = [
            "id" : firstMessage.messageId,
            "type" : firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : currentUserEmail,
            "is_read" : false,
            "name" : name
        ]
        let value : [String : Any] = [
            "messages" : [
                collectionMessage
            ]
        ]
        database.child("\(conversationID)").setValue(value , withCompletionBlock: {error , _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
   
    public func getAllConversations(for email : String , completion : @escaping (Result<[Conversation],Error>) -> Void){
        database.child("\(email)/conversations").observe(.value) { (snapsahot) in
            guard let value = snapsahot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
        }
            let conversations : [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String ,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else{
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationID, name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
            
        }
        
    }
    public func getAllMessagesForConversation(with id : String , completion : @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
        }
            let messages : [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)else {
                    return nil
                }
                var kind : MessageKind?
                if type == "photo" {
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    
                }else  if type == "video" {
                    guard let videoUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                       placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                    
                }
                else if type == "location" {
                                  let locationComponents = content.components(separatedBy: ",")
                                  guard let longitude = Double(locationComponents[0]),
                                      let latitude = Double(locationComponents[1]) else {
                                      return nil
                                  }
                                  print("Rendering location; long=\(longitude) | lat=\(latitude)")
                                  let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                                          size: CGSize(width: 300, height: 300))
                                  kind = .location(location)
                              }
                else{
                    kind = .text(content)
                }
                guard let finalKind = kind  else {
                    return nil
                }
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            })
            completion(.success(messages))
            
        }
        
    }
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
          // add new message to messages
          // update sender latest message
          // update recipient latest message
          guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
              completion(false)
              return
          }

        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)

          database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
              guard let strongSelf = self else {
                  return
              }

              guard var currentMessages = snapshot.value as? [[String: Any]] else {
                  completion(false)
                  return
              }

              let messageDate = newMessage.sentDate
              let dateString = ChatViewController.dateFormatter.string(from: messageDate)

              var message = ""
              switch newMessage.kind {
              case .text(let messageText):
                  message = messageText
              case .attributedText(_):
                  break
              case .photo(let mediaItem):
                  if let targetUrlString = mediaItem.url?.absoluteString {
                      message = targetUrlString
                  }
                  break
              case .video(let mediaItem):
                  if let targetUrlString = mediaItem.url?.absoluteString {
                      message = targetUrlString
                  }
                  break
              case .location(let locationData):
                  let location = locationData.location
                  message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                  break
              case .emoji(_):
                  break
              case .audio(_):
                  break
              case .contact(_):
                  break
              case .custom(_):
                  break
              case .linkPreview(_):
                break
              }

              guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                  completion(false)
                  return
              }

            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmmail)

              let newMessageEntry: [String: Any] = [
                  "id": newMessage.messageId,
                  "type": newMessage.kind.messageKindString,
                  "content": message,
                  "date": dateString,
                  "sender_email": currentUserEmail,
                  "is_read": false,
                  "name": name
              ]

              currentMessages.append(newMessageEntry)

              strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                  guard error == nil else {
                      completion(false)
                      return
                  }

                  strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                      var databaseEntryConversations = [[String: Any]]()
                      let updatedValue: [String: Any] = [
                          "date": dateString,
                          "is_read": false,
                          "message": message
                      ]

                      if var currentUserConversations = snapshot.value as? [[String: Any]] {
                          var targetConversation: [String: Any]?
                          var position = 0

                          for conversationDictionary in currentUserConversations {
                              if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                  targetConversation = conversationDictionary
                                  break
                              }
                              position += 1
                          }

                          if var targetConversation = targetConversation {
                              targetConversation["latest_message"] = updatedValue
                              currentUserConversations[position] = targetConversation
                              databaseEntryConversations = currentUserConversations
                          }
                          else {
                              let newConversationData: [String: Any] = [
                                  "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                                  "name": name,
                                  "latest_message": updatedValue
                              ]
                              currentUserConversations.append(newConversationData)
                              databaseEntryConversations = currentUserConversations
                          }
                      }
                      else {
                          let newConversationData: [String: Any] = [
                              "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                              "name": name,
                              "latest_message": updatedValue
                          ]
                          databaseEntryConversations = [
                              newConversationData
                          ]
                      }

                      strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                          guard error == nil else {
                              completion(false)
                              return
                          }


                          // Update latest message for recipient user
                          strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                              let updatedValue: [String: Any] = [
                                  "date": dateString,
                                  "is_read": false,
                                  "message": message
                              ]
                              var databaseEntryConversations = [[String: Any]]()

                              guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                  return
                              }

                              if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                  var targetConversation: [String: Any]?
                                  var position = 0

                                  for conversationDictionary in otherUserConversations {
                                      if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                          targetConversation = conversationDictionary
                                          break
                                      }
                                      position += 1
                                  }

                                  if var targetConversation = targetConversation {
                                      targetConversation["latest_message"] = updatedValue
                                      otherUserConversations[position] = targetConversation
                                      databaseEntryConversations = otherUserConversations
                                  }
                                  else {
                                      // failed to find in current collection
                                      let newConversationData: [String: Any] = [
                                          "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAdress: currentEmail),
                                          "name": currentName,
                                          "latest_message": updatedValue
                                      ]
                                      otherUserConversations.append(newConversationData)
                                      databaseEntryConversations = otherUserConversations
                                  }
                              }
                              else {
                                  // current collection does not exist
                                  let newConversationData: [String: Any] = [
                                      "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAdress: currentEmail),
                                      "name": currentName,
                                      "latest_message": updatedValue
                                  ]
                                  databaseEntryConversations = [
                                      newConversationData
                                  ]
                              }

                              strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                  guard error == nil else {
                                      completion(false)
                                      return
                                  }

                                  completion(true)
                              })
                          })
                      })
                  })
              }
          })
      }
    public func deleteConverdation(converdationId : String , completion : @escaping (Bool)-> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: {snapshot in
            if var conversaitons = snapshot.value as? [[String:Any]] {
                var positionToRemove = 0
                for conversation in conversaitons {
                    if let id = conversation["id"] as? String ,
                       id == converdationId {
                        break
                    }
                    positionToRemove += 1
                }
                conversaitons.remove(at: positionToRemove)
                ref.setValue(conversaitons , withCompletionBlock: { error , _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
            
        })
    }
    public func conversationExists(with targetResipientEmail : String , completion : @escaping (Result<String,Error>)->Void) {
        let safeRecepientEmail = DatabaseManager.safeEmail(emailAdress: targetResipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAdress: senderEmail)
    
        database.child("\(safeRecepientEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
            guard let collection = snapshot.value  as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }){
                guard let id = conversation ["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
}
struct ChatAppUser {
    let firstName :String
    let lastName : String
    let emailAdress : String
    var safeEmail : String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName : String {
        return "\(safeEmail)_profile_picture.png"
    }

}

