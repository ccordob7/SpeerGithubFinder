//
//  UserCacheManager.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-06.
//

import Foundation
import UIKit

/*
 Cache class used for cacheing, getting and deleting users from cache to make user interaction faster
 */
class UserCacheManager {
    //Using Singleton for Controllers/Managers
    static let shared = UserCacheManager()
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearOnMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    //Cache invalidation Setup to remove items from cache after 5 minutes
    private var expirationDates = [NSString: Date]()
    private let timeToExpiration: TimeInterval = 60 * 5
    
    //Cache Storage
    private let userCache = NSCache<NSString, GitHubUserWrapper>()
    
    
    /**
     func getCachedUser(for username: String) -> GitHubUser?
     - parameter username: Username for which user to look in the cache for
     - returns: Optional GitHubUser. Github User obtained in the cache if existing, nil if non existing
     This method handles the search in the cache for the given username, returning the User if it exists in the cache, and nil if not
     */
    func getCachedUser(for username: String) -> GitHubUser? {
        let key = username as NSString
        if let expiration = expirationDates[key], expiration < Date() {
            //If cache time is expired
            userCache.removeObject(forKey: key)
            expirationDates.removeValue(forKey: key)
            return nil
        }
        return userCache.object(forKey: key)?.user
    }
    
    /**
     func cacheUser(_ user: GitHubUser) -> void
     - parameter user: GitHubUser User to cache
     This method saves a user into the cache
     */
    func cacheUser(_ user: GitHubUser) {
        let key = user.login as NSString
        userCache.setObject(GitHubUserWrapper(user), forKey: key)
        expirationDates[key] = Date().addingTimeInterval(timeToExpiration)
    }
    
    /**
     func clearCache() -> void
     This function completely clears the cache.
     */
    func clearCache() {
        userCache.removeAllObjects()
        expirationDates.removeAll()
    }
    
    /**
     private func clearOnMemoryWarning() -> void
     Selector function. This selector function is called when an event happens, in this case, when UIApplication.didReceiveMemoryWarningNotification happens to clear the cache and free up memory in case memory is full. This calls clearCache()
     */
    @objc private func clearOnMemoryWarning() {
        clearCache()
    }
    
    //Creating a Wrapper class so that the Cache can handle objects
    private class GitHubUserWrapper: NSObject {
        let user: GitHubUser
        init(_ user: GitHubUser) { self.user = user }
    }
}
