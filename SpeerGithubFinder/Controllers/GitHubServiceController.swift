//
//  GitHubServiceController.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-06.
//

import Foundation

/**
 GitHub Controller Class following MVC pattern.
 This class handles all the API Calls. It's a singleton Class as well, only allowing and instance that handles the api calls
 */
class GitHubServiceController {
    //For List fetching
    enum UserListType {
        case followers
        case following
    }
    
    //Using Singleton for Controllers/Managers
    static let shared = GitHubServiceController()
    private init() {}

    /**
     fetchUser(username: String, completion: @escaping (Result<GitHubUser, Error>) -> Void)
     - parameter username: Username of the user to fetch
     - parameter forceRefresh: Force refresh flag, to refresh even if the cached user is cached, for refreshing the page
     - returns: Completion variable as reference. Returns wether the User API call was succesful or not with the given user.
     This function calls the GitHubAPI with an user and processes and decodes the data into the GitHubUser model in our app.
     This method also uses cached users (As Bonus point 3 requested)  with a UserCahceManager returning from cache if it exists in it, or saving it to cache if not 
     */
    func fetchUser(username: String, forceRefresh: Bool = false, completion: @escaping (Result<GitHubUser, Error>) -> Void) {
        //Check cache first to avoid long loading
        if let cached = UserCacheManager.shared.getCachedUser(for: username), !forceRefresh{
            completion(.success(cached))
            return
        }
        guard let url = URL(string: "https://api.github.com/users/\(username)") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let user = try JSONDecoder().decode(GitHubUser.self, from: data)
                //Save to cache
                UserCacheManager.shared.cacheUser(user)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /**
     func fetchUserList(for user: GitHubUser, type: UserListType, page: Int, perPage: Int = 30, completion: @escaping (Result<[GitHubUserSummary], Error>) -> Void)
     - parameter user: GitHubUser to fetch the user list for
     - parameter type: Whether it's a following or a follower list the one getting fetched, as they have different URLs
     - parameter page: Number of page to get, used in pagination,a s GitHubApi only returns a default of 30 users per page
     - parameter perPage: Number of users per page to get. Default being 30
     - returns: Completion variable as reference. Returning the list of users the user is following/being followed by in the given page by a given amount of users
     This method obtains a paginated list of users the user is either following or followers of the user with an API call. This is affected by the given page number and user list
     */
    func fetchUserList(
        for user: GitHubUser,
        type: UserListType,
        page: Int,
        perPage: Int = 30,
        completion: @escaping (Result<[GitHubUserSummary], Error>) -> Void
    ) {
        let baseURL: String
        switch type {
        case .followers:
            baseURL = user.followers_url
        case .following:
            baseURL = user.following_url.replacingOccurrences(of: "{/other_user}", with: "")
        }

        let urlString = "\(baseURL)?per_page=\(perPage)&page=\(page)"

        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let users = try JSONDecoder().decode([GitHubUserSummary].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    /**
     func searchGitHubUsers(query: String, completion: @escaping (Result<[GitHubUserSummary], Error>) -> Void)
     - parameter query: String of user name the query is made for
     - returns: Completion variable as reference. Returns a list of GitHubUserSummary of users who match the query
     This method uses a string query (name, username or bio) to search for all the users that are part of all the user lists.
     This method is used to ignore pagination when searching and displays not only users with the username searched, but also users tha thave the search query in their bio, or name as well
     */
    func searchGitHubUsers(query: String, completion: @escaping (Result<[GitHubUserSummary], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://api.github.com/search/users?q=\(encodedQuery)&per_page=30") else {
                completion(.failure(URLError(.badURL)))
                return
            }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(SearchResults.self, from: data)
                completion(.success(decoded.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
