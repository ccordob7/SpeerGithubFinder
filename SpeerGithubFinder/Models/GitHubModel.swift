//
//  GitHubModel.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-05.
//

import Foundation

struct SearchResults: Decodable {
    let items: [GitHubUserSummary]
}

/**
 GitHubUser Model Following MVC Patterns.
 This model contains the information needed on the app for a GitHub user and can be expanded to get more if needed by adding GitHub API response items to the variables
 */
struct GitHubUser: Decodable, Identifiable, Hashable, Equatable {
    let avatar_url: String
    let login: String
    let name: String?
    let bio: String?
    let followers: Int
    let following: Int
    let followers_url: String
    let following_url: String
    
    //For Identifiable
    var id: String { login }
    static func == (lhs: GitHubUser, rhs: GitHubUser) -> Bool {
        lhs.login == rhs.login
    }
}

/**
 Small GitHubUser Model for displaying only user username and picture for UserListView
 */
struct GitHubUserSummary: Codable, Identifiable, Equatable {
    let login: String
    let avatar_url: String
    
    var id: String { login }
    
    static func == (lhs: GitHubUserSummary, rhs: GitHubUserSummary) -> Bool {
        lhs.login == rhs.login
    }
}
