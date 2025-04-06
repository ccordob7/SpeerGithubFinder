//
//  UserListView.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-05.
//

import SwiftUI
import Combine

/*
 UserListView. Contains the information for the user and whether the list is the following list or the followers list, then displays a list of the users obtained with the API call.
 This includes a search bar on the top that always displays with the .searchable property, a refresh setup with the .refreshable property, and other handlings that will be included in their respective comments
 */
struct UserListView: View {
    let user: GitHubUser
    let listType: ListType

    enum ListType {
        case followers, following
    }

    //User variables to contain the users
    @State private var users: [GitHubUserSummary] = []
    
    //Pagination setup, to allow github API to display as many users as the user wants to
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var canLoadMore = true
    
    //Search Properties, to allow search to exist an work
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [GitHubUserSummary] = []
    
    //Properties for search debouncing, as the search can have issues if it's updated too fast while it's loading
    @State private var searchCancellable: AnyCancellable? = nil
    @State private var searchDelay = 0.3 // Optional: can stay
    private let searchSubject = PassthroughSubject<String, Never>()

    /*
     Draw function. Here we dislay the list of the users with a List, displaying them as an HStack of the github image, and their name.
     Loads the users on Appear and sets up the search.
     This also includes a Loading screen in case the app takes a while to get the users
     */
    var body: some View {
        List {
            ForEach(displayedUsers, id: \.login) { user in
                NavigationLink(destination: UserView(username: user.login)) {
                    HStack {
                        AsyncImage(url: URL(string: user.avatar_url)) { image in
                            image.image?.resizable()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        Text(user.login)
                    }
                }
                .onAppear {
                    if user == displayedUsers.last && !isSearching {
                        loadMoreUsersIfNeeded()
                    }
                }
            }

            if isLoading && !isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: searchText) { _, newValue in
            debounceSearch(newValue)
            //handleSearchChange(newValue)
        }
        //Make it refreshable for Bonus feature 2
        .refreshable {
            refreshUsers()
        }
        //Title of page
        .navigationTitle(listType == .followers ? "Followers" : "Following")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if users.isEmpty && !isSearching {
                fetchUsers(page: currentPage)
            }
            
            searchCancellable = searchSubject
                .debounce(for: .seconds(searchDelay), scheduler: DispatchQueue.main)
                .sink { query in
                    handleSearchChange(query)
                }
        }
        .onDisappear {
            searchCancellable?.cancel()
        }
    }

    /*
     Property to chose which users to display based on if the user is searching or not
     */
    private var displayedUsers: [GitHubUserSummary] {
        isSearching ? searchResults : users
    }

    /**
    func refreshUsers() -> void
    This function resets the current variables on the user display list used by the GitHubAPI to display the users on the selected page. Runnin this functions resets the page to the beginning, refreshing the list completely and Getting the first page from the API.
     */
    func refreshUsers() {
        currentPage = 1
        users.removeAll()
        canLoadMore = true
        fetchUsers(page: currentPage)
    }

    /**
     func loadMoreUsersIfNeeded() -> void
     This function is called when the user reaches the end of the page, it's job is to make sure there's no users loading, and it's able to load more, and if so, it increments the page to do the GitHubAPI call and calls on the API
     */
    func loadMoreUsersIfNeeded() {
        guard !isLoading && canLoadMore else { return }
        currentPage += 1
        fetchUsers(page: currentPage)
    }

    /**
     func fetchUsers(page: Int) -> void
     - parameter page: number of page to call the GitHubUserAPI with
     This function uses the Controller Class to do the API call for users, either following or followers, based on global variables obtained when the UserListView was called.
     This sets the users list as empty if no users present, showing an empty user list
     */
    func fetchUsers(page: Int) {
        isLoading = true
        //Calling the Controller Singleton
        GitHubServiceController.shared.fetchUserList(
            for: user,
            type: listType == .followers ? .followers : .following,
            page: page
        ) { result in
            //Handle result
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let newUsers):
                    let uniqueUsers = newUsers.filter { newUser in
                        !self.users.contains(where: { $0.login == newUser.login })
                    }
                    self.users.append(contentsOf: uniqueUsers)
                    self.canLoadMore = !uniqueUsers.isEmpty
                case .failure(let error):
                    //For debugging only, print if there's no users
                    print("Failed to fetch users:", error.localizedDescription)
                    self.canLoadMore = false
                }
            }
        }
    }

    /**
     func performSearch(query: String) -> void
     - parameter query: Text string containing the information that wants to be searched
     This method handles the search for the search bar. Using the text that we want to query, we look for information with a Controller Function for an API call, this returns all users that contain the searched text, either in their bio, their name or their username
     */
    func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.searchResults = []
                self.isSearching = false
                return
            }

            isLoading = true
            GitHubServiceController.shared.searchGitHubUsers(query: query) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let results):
                        self.searchResults = results
                    case .failure(let error):
                        print("Search error:", error.localizedDescription)
                        self.searchResults = []
                    }
                }
            }
    }
    
    /**
     func handleSearchChange(_ newValue: String) -> void
     - parameter newValue: The string to trim and conduct the search on
     This function calls on performSearchFunction after handling the search query, trimming it for whitespaces and setting the searching state to true if there is one.
     */
    func handleSearchChange(_ newValue: String) {
        let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            isSearching = false
            searchResults = []
            return
        }

        isSearching = true
        performSearch(query: trimmedQuery)
    }
    
    /**
     func debounceSearch(_ query: String) -> void
     This is an event method. Which calls the SearchSubject event assigned on the onApear, this calls the search  if and only if the modification time for users has passed, hence the debounce name, asn it interacts as a debounce function.
     */
    func debounceSearch(_ query: String) {
        searchSubject.send(query)
    }
}


//For XCode debugging puproses. Create a mockUser using the github mascot data. Then, display on the preview 2 lists, one of them being the Followers List and another one the Following list
//If only one List is wanted for the display, comment one of the 2
#Preview() {
        // Mock user data
        let mockUser = GitHubUser(
            avatar_url: "https://avatars.githubusercontent.com/u/583231?v=4",
            login: "octocat",
            name: "The Octocat",
            bio: "I am the mascot of GitHub.",
            followers: 3939,
            following: 9,
            followers_url: "https://api.github.com/users/octocat/followers",
            following_url: "https://api.github.com/users/octocat/following"
        )
        
        // Provide a preview for the followers list
        UserListView(user: mockUser, listType: .followers)
        
        // Provide a preview for the following list
        UserListView(user: mockUser, listType: .following)
}
