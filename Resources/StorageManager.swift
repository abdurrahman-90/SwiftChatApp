//
//  StorageManager.swift
//  MessengerApp
//
//  Created by Akdag on 30.03.2021.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    public typealias UpLoadPictureCompletion = (Result<String,Error>) -> Void

    
    public func uploadProfilePicture(with data : Data , fileName : String , completion : @escaping UpLoadPictureCompletion){
        storage.child("images/\(fileName)").putData(data , metadata : nil , completion : { [self]metadata , error in
            guard error == nil else {
                // failed
                print("resim indirilirken hata oluştu")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            storage.child("images/\(fileName)").downloadURL(completion: { url , error in
             
                guard let url = url else{
                    completion(.failure(StorageErrors.failedToDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
        
    }
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UpLoadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload video file to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }

            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToDownloadUrl))
                    return
                }

                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
        
    public enum StorageErrors : Error {
        case failedToUpload
        case failedToDownloadUrl
    }
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UpLoadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }

            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToDownloadUrl))
                    return
                }

                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path : String , completion : @escaping (Result<URL ,Error>) -> Void){
        let reference = storage.child(path)
        reference.downloadURL { (url, error) in
            guard let url = url , error == nil else {
                print("resim indirilemedi")
                completion(.failure(error!))
                return
            }
            print("resim yüklendi")
            completion(.success(url))
        }
    }
}
